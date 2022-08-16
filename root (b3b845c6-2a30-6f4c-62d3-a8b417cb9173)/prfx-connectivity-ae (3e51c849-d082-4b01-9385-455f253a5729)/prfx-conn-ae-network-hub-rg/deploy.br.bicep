targetScope = 'subscription'

module resourceGroup_br 'br/ResourceModules:bicep/modules/microsoft.resources.resourcegroups:0.5.1296-prerelease' = {
  name: 'resourceGroup_br'
  params: {
    name: 'prfx-conn-ae-network-hub-rg'
  }
}

// TS
module resourceGroup_ts 'ts/ResourceModules:microsoft.resources.resourcegroups:0.5.1296-prerelease' = {
  name: 'resourceGroup_ts'
  params: {
    name: 'prfx-conn-ae-network-hub-rg'
  }
}
