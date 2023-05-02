param location string = resourceGroup().location
param nsgname string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: nsgname
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAzureActiveDirectoryAccess'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAzureKeyVault'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureKeyVault'
          access: 'Allow'
          priority: 101
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAzureGateWayManager'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 103
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowProbeFromAzureLoadBalancer'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 4000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowVNetToAPIM'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AppService'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 4010
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AppServices'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AppService'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'HealthMonitoring'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '65503-65534'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'IP-filter'
        properties: {
          description: 'For incoming request to APIM'
          protocol: 'TCP'
          sourcePortRange: '*'
          sourceAddressPrefix: '83.248.186.136'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'IP-Filter_APIManagement'
        properties: {
          description: 'Allow calls from API Management Test'
          protocol: 'TCP'
          sourcePortRange: '*'
          sourceAddressPrefix: '52.232.63.176'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 313
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }  
      }
      {
        name: 'IP-Filter_2'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 310
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefixes: [
            '10.210.20.23'
            '10.80.100.253'
            '10.32.10.25'
          ]
          destinationAddressPrefixes: []
  }
      }
      {
        name: 'P-Filter_LogicApps'
        properties: {
          description: 'Allow calls to API Management from Logic Apps'
          protocol: 'TCP'
          sourcePortRange: '*'
          sourceAddressPrefix: 'LogicApps'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 302
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

output resourceId string = networkSecurityGroup.id
