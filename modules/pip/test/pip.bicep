param publicIpName string = 'pip-awsome-001'
param location string = 'westeurope'

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-07-01' = { 
  name: publicIpName
  location: location
  sku: {
    name:'Standard'
    tier: 'Regional'
  }
  zones:[
    '1'
    // '2' to fail  it.
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
