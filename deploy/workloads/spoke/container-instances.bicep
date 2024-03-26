param name string
param subnetId string
param location string

resource aci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: name
  location: location
  properties: {
    containers: [
      {
        name: 'webapp-network-tester'
        properties: {
          image: 'jannemattila/webapp-network-tester:1.0.69'
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '80'
            }
          ]
          ports: [
            {
              port: 80
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
    restartPolicy: 'OnFailure'
    osType: 'Linux'
    ipAddress: {
      type: 'Private'
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
      ]
    }
    subnetIds: [
      {
        id: subnetId
      }
    ]
  }
}
