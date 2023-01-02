param name string = 'afw-hub'
param location string
param parentVirtualHubName string

module firewallPolicy 'firewall-policy.bicep' = {
  name: 'firewallPolicy-deployment'
  params: {
    name: 'afwp-hub'
    tier: 'Standard'
    location: location
  }
}

module firewall 'firewall.bicep' = {
  name: 'firewall-deployment'
  params: {
    name: name
    skuName: 'AZFW_Hub'
    skuTier: 'Standard'
    firewallPolicyId: firewallPolicy.outputs.id
    parentVirtualHubName: parentVirtualHubName
    location: location
  }
}

output firewallId string = firewall.outputs.id
output firewallPrivateIp string = firewall.outputs.privateIPAddress
