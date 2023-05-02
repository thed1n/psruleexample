var nsgname = 'nsg-testing-extreme-sc'
param parLocation string = 'swedencentral'

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: nsgname
  location: parLocation
  properties: {
    securityRules: [
      {
        name: 'BLOCK_22'
        properties: {
          description: 'Blocks port 22 from internet by default'
          protocol: '*'
          sourcePortRange: '22'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'BLOCK_3389'
        properties: {
          description: 'Blockes port 3389 from internet by default'
          protocol: '*'
          sourcePortRange: '3389'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}
