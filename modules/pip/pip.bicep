param publicIpName string
param location string

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-07-01' = { 
  name: publicIpName
  location: location
  sku: {
    name:'Standard'
    tier: 'Regional'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    ddosSettings:{
      protectionMode: 'VirtualNetworkInherited'
    }
  }
}

output resourceId string = publicIpAddress.id
