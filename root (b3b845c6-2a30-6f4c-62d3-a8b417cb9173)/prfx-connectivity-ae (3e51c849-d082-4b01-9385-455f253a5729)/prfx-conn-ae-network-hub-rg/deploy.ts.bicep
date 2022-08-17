targetScope = 'subscription'

param name string

module resourceGroup_ts 'ts/ResourceModules:microsoft.resources.resourcegroups:0.5.1296-prerelease' = {
  name: 'resourceGroup_ts'
  params: {
    name: name
  }
}
