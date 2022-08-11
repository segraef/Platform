﻿<#
.SYNOPSIS
Print a list of all local references for the modules in a given path

.DESCRIPTION
The result will be a list of all modules in the given path alongside their individual references to other modules in the folder structure

.PARAMETER path
Optional. The path to search in. Defaults to the 'modules' folder

.EXAMPLE
Get-LinkedLocalModuleList

Invoke the function with the default path. Prints a list such as:

> The modules in path [C:\dev\ip\Azure-ResourceModules\ResourceModules\modules] have the following local folder dependencies:
>
> Resource: Microsoft.EventGrid/topics
> - Microsoft.EventGrid/Microsoft.Network/privateEndpoints
>
> Resource: Microsoft.Synapse/privateLinkHubs
> - Microsoft.Synapse/Microsoft.Network/privateEndpoints

.EXAMPLE
Get-LinkedLocalModuleList -Path './Microsoft.Sql'

Get only the references of the modules in folder path './Microsoft.Sql'

> The modules in path [..\..\modules\Microsoft.Sql\] have the following local folder dependencies:
>
> Resource: Microsoft.Sql/servers
> - Microsoft.Sql/Microsoft.Network/privateEndpoints
#>
function Get-LinkedLocalModuleList {

    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $path = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'modules')
    )

    # Load used functions
    . (Join-Path $PSScriptRoot 'Get-LinkedModuleList.ps1')

    $allReferences = Get-LinkedModuleList -path $path

    $resultSet = @{}

    foreach ($resourceType in $allReferences.Keys) {
        $relevantLocalReferences = $allReferences[$resourceType].localPathReferences | Where-Object { $_ -match '^\.\..*$' }
        if ($relevantLocalReferences) {
            $relevantLocalReferences = $relevantLocalReferences | ForEach-Object {
                # remove deploy.bicep
                Split-Path $_ -Parent
            } | ForEach-Object {
                # remove leading path elements
                ($_ -replace '\\', '/') -match '^[\.\/]*(.+)$'
            } | ForEach-Object {
                # We have to differentate the case that the referenced resources is inside or outside the same provider namespace (e.g. '../publicIPAddresses')
                if ($matches[1] -like '*/*') {
                    # Reference outside of namespace
                    $matches[1]
                } else {
                    # Reference inside of namespace (-> we rebuild the namespace)
                    '{0}/{1}' -f (Split-Path $resourceType -Parent), $matches[1]
                }
            }
            $resultSet[$resourceType] = $relevantLocalReferences
        }
    }

    Write-Verbose "The modules in path [$path] have the following local folder dependencies:" -Verbose
    foreach ($resourceType in $resultSet.Keys) {
        Write-Verbose '' -Verbose
        Write-Verbose "Resource: $resourceType" -Verbose
        $resultSet[$resourceType] | ForEach-Object {
            Write-Verbose "- $_" -Verbose
        }
    }
}
