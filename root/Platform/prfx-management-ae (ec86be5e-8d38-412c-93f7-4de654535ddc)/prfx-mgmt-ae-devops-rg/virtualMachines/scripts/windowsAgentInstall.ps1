# -----  Agent Setup for Windows ----

## Set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"

## Install Azure Pipelines Agent
$organization = "prfx" # Read-Host "Azure DevOps Organization Name"
$Env:AZP_URL = "https://dev.azure.com/$organization/"
$Env:AZP_TOKEN = "" # Read-Host "Azure DevOps Personal Access Token"
$Env:AZP_POOL= "prfx-Prod-WindowsPool-001" # Read-Host "Azure DevOps Agent Pool: prfx-NonProd-WindowsPool-001 / prfx-Prod-WindowsPool-001

if (-not (Test-Path "$PWD\agent\")) {
    # Install Agent
    New-Item -ItemType Directory "$PWD\agent\" -Force
    Set-Location "$PWD\agent\"

    if (-not (Test-Path Env:AZP_URL)) {
      Write-Error "error: missing AZP_URL environment variable"
      exit 1
    }

    if (-not (Test-Path Env:AZP_TOKEN_FILE)) {
      if (-not (Test-Path Env:AZP_TOKEN)) {
        Write-Error "error: missing AZP_TOKEN environment variable"
        exit 1
      }

      $Env:AZP_TOKEN_FILE = "$PWD\.token"
      $Env:AZP_TOKEN | Out-File -FilePath $Env:AZP_TOKEN_FILE
    }

    Remove-Item Env:AZP_TOKEN

    if (Test-Path Env:AZP_WORK) {
      New-Item $Env:AZP_WORK -ItemType directory | Out-Null
    }

    # Let the agent ignore the token env variables
    $Env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"

    Write-Host "1. Determining matching Azure Pipelines agent..." -ForegroundColor Cyan

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-Content ${Env:AZP_TOKEN_FILE})"))
    $package = Invoke-RestMethod -Headers @{Authorization=("Basic $base64AuthInfo")} "$(${Env:AZP_URL})/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
    $packageUrl = $package[0].Value.downloadUrl

    Write-Host $packageUrl

    Write-Host "2. Downloading and installing Azure Pipelines agent $env:computername ..." -ForegroundColor Cyan

    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($packageUrl, "$(Get-Location)\agent.zip")

    Expand-Archive -Path "agent.zip" -DestinationPath ".\"

    try
    {
      if (-not (Test-Path Env:AZP_CLEANUP)) {
      Write-Host "4. Configuring Azure Pipelines agent $env:computername ..." -ForegroundColor Cyan

      .\config.cmd --unattended `
        --agent "$(if (Test-Path Env:AZP_AGENT_NAME) { ${Env:AZP_AGENT_NAME} } else { ${Env:computername} })" `
        --url "$(${Env:AZP_URL})" `
        --auth PAT `
        --token "$(Get-Content ${Env:AZP_TOKEN_FILE})" `
        --pool "$(if (Test-Path Env:AZP_POOL) { ${Env:AZP_POOL} } else { 'Default' })" `
        --work "$(if (Test-Path Env:AZP_WORK) { ${Env:AZP_WORK} } else { '_work' })" `
        --replace `
        --runAsService `
        --windowsLogonAccount "NT AUTHORITY\SYSTEM" `
        --acceptTeeEula
      } else {
        Write-Host "Cleanup. Removing Azure Pipelines agent $env:computername ..." -ForegroundColor Cyan

        .\config.cmd remove --unattended `
          --auth PAT `
          --token "$(Get-Content ${Env:AZP_TOKEN_FILE})"
        Remove-Item Env:AZP_CLEANUP
      }
    }
    Catch {}
}

# Tools
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install git -fy
choco install pwsh -fy

## Azure CLI
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

## Azure Bicep (PowerShell)
$installPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
(New-Object Net.WebClient).DownloadFile("https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe", "$installPath\bicep.exe")

## Restart Service
Get-Service -Name vsts* | Stop-Service
Get-Service -Name vsts* | Start-Service

## Az Module
Install-Module -Name Az -AllowClobber -Scope AllUsers -Force
Install-Module -Name Pester -Force -SkipPublisherCheck

## Az extension and config
Start-Process pwsh -ArgumentList "-Command 'Install-Module -Name Az -AllowClobber -Scope AllUsers -Force'"
Start-Process pwsh -ArgumentList "-Command 'az extension add --name azure-devops'"
Start-Process pwsh -ArgumentList "-Command 'az config set extension.use_dynamic_install=yes_without_prompt'"
