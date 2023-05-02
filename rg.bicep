targetScope = 'subscription'
param name string = 'rg-test'
param location string = 'swedencentral'
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
  tags: {
    env: 'keso'
  }
}
