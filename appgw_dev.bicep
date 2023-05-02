param enviroment string = 'dev'
param landingzonename string = 'integration'
param certificateName string = 'Wildcard2023'
param company string = 'contoso'
param location string = resourceGroup().location
param subnetSize string = '172.16.0.0/28'


var agwName  = 'agw-${landingzonename}-${enviroment}-sc-001'
var wafpolicyName  = 'waf-policy-${landingzonename}-${enviroment}-sc-001'
var vnet  = 'vnet-${landingzonename}-${enviroment}-sc-001'
var vnetRG  = 'rg-vnet-${landingzonename}-${enviroment}-001'
var snetName  = 'snet-agw-${enviroment}-sc'
var apiminstance  = 'apim-${company}-${enviroment}-sc'
var apimrg = 'rg-apim-${enviroment}-sc'
var publicIpName  = 'pip-agw-${landingzonename}-${enviroment}-sc-001'
var probeAPIM  = '${enviroment}-apim.${company}.se'
var probePortal  = '${enviroment}-portal-apim.${company}.se'
var probeManagement  = '${enviroment}-management-apim.${company}.se'
var hostnameSCM  = '${enviroment}-scm-apim.${company}.se'
var hostnameDevPortal  = '${enviroment}-portal-apim.${company}.se'
var hostnameApim  = '${enviroment}-apim.${company}.se'
var hostnameManagement  = '${enviroment}-management-apim.${company}.se'
var nsgname = 'nsg-contoso-agw-${enviroment}-sc'
var managedIdentityAGW  = 'id-agw-${landingzonename}-${enviroment}-sc-001'
var kvName = 'kv-agw-${enviroment}-sc'


resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
}

resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiminstance
  scope:resourceGroup(apimrg)
}

module publicIpAddress './modules/pip/pip.bicep' = {
  name: '${publicIpName}-Deploy'
  params: {
    location: location
    publicIpName: publicIpName
  }
}

module nsg './modules/nsg/appgwnsg.bicep' = {
 name: 'nsg-deployment'
 params:{
  nsgname: nsgname
  location: location
  }
}

module AppGWSubnet './modules/subnets/subnet.bicep' = {
  name: 'Deploy-appgw-subnet'
  params: {
    name: snetName
    addressPrefix: subnetSize
    virtualNetworkName: vnet
    networkSecurityGroupId: nsg.outputs.resourceId
     privateEndpointNetworkPolicies: 'Disabled'
     serviceEndpoints: [
      {
       service: 'Microsoft.KeyVault'
      }
      ]
  }
  scope: resourceGroup(vnetRG)
}
 
resource applicationGatewayFirewallPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2020-11-01' = {
  name: wafpolicyName
  location: location
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }

  }
}


resource appgwManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityAGW
  
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2020-11-01' = {
  name: agwName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appgwManagedIdentity.id}' : {} 
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'ipconf-${agwName}'
        properties: {
          subnet: {
            id: AppGWSubnet.outputs.resourceId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'ipconf-fp-${agwName}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddress.outputs.resourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'fp-${agwName}'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'pool-${agwName}'
        properties: {
          backendAddresses: [
           {
            // ipAddress: empty(agwBackendIp) ? null : agwBackendIp
            ipAddress: apim.properties.privateIPAddresses[0]
           }
          ]
        }
      }
      {
        name: 'sinkpool-${agwName}'
        properties: {
           backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'poolsetting-apim-${agwName}'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 180
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes',agwName,'probeconf-apim-${agwName}')
          }
        }
      }
      {
        name: 'poolsetting-management-${agwName}'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes',agwName,'probeconf-management-${agwName}')
          }
        }
      }
      {
        name: 'poolsettings-portal-${agwName}'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 180
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes',agwName,'probeconf-portal-${agwName}')
          }
        }
      }
      {
        name: 'poolsetting-scm-${agwName}'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'lis-scm-${agwName}'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners',agwName,'lis-scm-${agwName}')
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations',agwName,'ipconf-fp-${agwName}')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts',agwName,'fp-${agwName}')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates',agwName,'certconf-apim-${agwName}')
          }
          hostName: hostnameSCM
          hostNames: []
          requireServerNameIndication: true
        }
      }
      {
        name: 'lis-portal-${agwName}'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners',agwName,'lis-portal-${agwName}')
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations',agwName,'ipconf-fp-${agwName}')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts',agwName,'fp-${agwName}')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates',agwName,'certconf-apim-${agwName}')
          }
          hostName: hostnameDevPortal
          hostNames: []
          requireServerNameIndication: true
        }
      }
      {
        name: 'lis-management-${agwName}'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners',agwName,'lis-management-${agwName}')
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations',agwName,'ipconf-fp-${agwName}')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts',agwName,'fp-${agwName}')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates',agwName,'certconf-apim-${agwName}')
          }
          hostName: hostnameManagement
          hostNames: []
          requireServerNameIndication: true
        }
      }
      {
        name: 'lis-apim-${agwName}'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners',agwName,'lis-apim-${agwName}')
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations',agwName,'ipconf-fp-${agwName}')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts',agwName,'fp-${agwName}')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates',agwName,'certconf-apim-${agwName}')
          }
          hostName: hostnameApim
          hostNames: []
          requireServerNameIndication: true
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'external-urlpathmapconfig-${agwName}'
        id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps',agwName,'external-urlpathmapconfig-${agwName}')
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools',agwName,'sinkpool-${agwName}')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection',agwName,'poolsetting-apim-${agwName}')
          }
          pathRules: [
            {
              name: 'external-pathrule-${agwName}'
              id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps/pathRules',agwName,'external-urlpathmapconfig-${agwName}','external-pathrule-${agwName}')
              properties: {
                paths: [
                  '/external/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools',agwName,'pool-${agwName}')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection',agwName,'poolsetting-apim-${agwName}')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rr-external-${agwName}'
        id: resourceId('Microsoft.Network/applicationGateways/requestRoutingRules',agwName,'rr-external-${agwName}')
        properties: {
          priority: 10
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners',agwName,'lis-apim-${agwName}')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps',agwName,'external-urlpathmapconfig-${agwName}')
          }
        }
      }
      {
        name: 'rr-management-${agwName}'
        id: resourceId('Microsoft.Network/applicationGateways/requestRoutingRules',agwName,'rr-management-${agwName}')
        properties: {
          priority: 20
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners',agwName,'lis-management-${agwName}')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools',agwName,'pool-${agwName}')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection',agwName,'poolsetting-management-${agwName}')
          }
        }
      }
      {
        name: 'rr-portal-${agwName}'
        id: resourceId('Microsoft.Network/applicationGateways/requestRoutingRules',agwName,'rr-portal-${agwName}')
        properties: {
          priority: 30
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners',agwName,'lis-portal-${agwName}')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools',agwName,'pool-${agwName}')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection',agwName,'poolsetting-apim-${agwName}')
          }
        }
      }
      {
        name: 'rr-scm-${agwName}'
        id: resourceId('Microsoft.Network/applicationGateways/requestRoutingRules',agwName,'rr-scm-${agwName}')
        properties: {
          priority: 40
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners',agwName,'lis-scm-${agwName}')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools',agwName,'pool-${agwName}')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection',agwName,'poolsetting-apim-${agwName}')
          }
        }
      }
    ]
    probes: [
      {
        name: 'probeconf-apim-${agwName}'
        properties: {
          protocol: 'Https'
          host: probeAPIM
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 120
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: 'probeconf-portal-${agwName}'
        properties: {
          protocol: 'Https'
          host: probePortal
          path: '/signin'
          interval: 60
          timeout: 300
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: 'probeconf-management-${agwName}'
        properties: {
          protocol: 'Https'
          host: probeManagement
          path: '/ServiceStatus'
          interval: 60
          timeout: 300
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    trustedRootCertificates: []
    sslCertificates: [
      // Exempel för att hämta ifrån keyvault
      {
        name: 'certconf-apim-${agwName}'
        properties:{
          keyVaultSecretId: '${keyvault.properties.vaultUri}secrets/${certificateName}'
        }
      }
    ]
    
    firewallPolicy: {
      id: applicationGatewayFirewallPolicy.id
    }
    sslPolicy: {
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20220101'
    }
  }
}


output pip string = publicIpAddress.outputs.resourceId
output kv object = keyvault
output subnet object = AppGWSubnet
output ident object = appgwManagedIdentity
output applicationgateway object = applicationGateway
