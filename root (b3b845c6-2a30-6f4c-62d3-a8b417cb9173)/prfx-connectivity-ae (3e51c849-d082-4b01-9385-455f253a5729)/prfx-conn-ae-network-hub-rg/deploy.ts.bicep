targetScope = 'subscription'

module resourceGroup_ts 'ts/ResourceModules:microsoft.resources.resourcegroups:0.5.1296-prerelease' = {
  name: 'resourceGroup_ts'
  params: {
    name: 'prfx-conn-ae-network-hub-rg'
  }
}
