param firewallPolicyId string
param parentVirtualHubName string
param name string
@allowed([
  'AZFW_Hub'
  'AZFW_VNet'
])
param skuName string = 'AZFW_Hub'
@allowed([
  'Premium'
  'Standard'
])
param skuTier string = 'Standard'
param location string = resourceGroup().location

resource parentVirtualHub 'Microsoft.Network/virtualHubs@2023-04-01' existing = {
  name: parentVirtualHubName
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: name
  location: location
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    sku: {
      name: skuName
      tier: skuTier
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    virtualHub: {
      id: parentVirtualHub.id
    }
    firewallPolicy: {
      id: firewallPolicyId
    }
    applicationRuleCollections: []
    natRuleCollections: []
    networkRuleCollections: []
  }
}

module diagnosticSettings 'log-analytics.bicep' = {
  name: 'firewall-diagnosticSettings-deployment'
  params: {
    name: 'diag-${firewall.name}'
    parentName: firewall.name
    location: location
  }
}

output privateIPAddress string = firewall.properties.hubIPAddresses.privateIPAddress
output id string = firewall.id
