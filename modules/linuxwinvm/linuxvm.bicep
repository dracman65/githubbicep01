//Parameters \\
param location string
param tags object
param vnetName string
param vnetSubnetName string
param authenticationType string = 'password'
param vmName string = 'GitHubLinuxVM'

// Linux VM Username and Password
param vmUserName string
@secure()

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
#disable-next-line secure-parameter-default
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id)}')
@secure()

// Allowed Linux VM \\
@allowed([
  'Ubuntu-2404-Server' //LTS
  'Ubuntu-2204-LTS' //LTS
  'Ubuntu-2404-Professional'
])

//Choose Linux Version
@description('''
- To choose which linux VM to deploy, enter either: 'Ubuntu-2004' or 'Ubuntu-2204'
''')

#disable-next-line secure-parameter-default
param linuxversion string = 'Ubuntu-2204-LTS'

var publicIPAddressName = 'ip${baseName}'
var networkInterfaceName = 'nic${baseName}'

var baseName = substring(uniqueString(deployment().name), 0, 6)
var vmSize = 'Standard_B1ms' //'Standard_DS1_v2' //Standard_B1s

// New Linux Sizes for Azure: https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/?msockid=211aac7bdedb641f0560b9dfdf7665bb

// Security Type \\
@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.LinuxAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var maaEndpoint = substring('emptystring', 0, 0)

// Image Reference Variables
var imageReference  = {
  'Ubuntu-2404-Server': {
    publisher: 'Canonical'
    offer: 'ubuntu-24_04-lts'
    sku: 'server'
    version: 'latest'
  }
  'Ubuntu-2204-LTS': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2404-Professional': {
    publisher: 'Canonical'
    offer: 'ubuntu-24_04-lts'
    sku: 'ubuntu-pro'
    version: 'latest'
  }
}

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param vmPass string

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmUserName}/.ssh/authorized_keys'
        keyData: vmPass
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      imageReference: imageReference[linuxversion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: 'vm${baseName}'
      adminUsername: vmUserName
      adminPassword: vmPass
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    securityProfile: (securityType == 'TrustedLaunch') ? securityProfileJson : null
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (securityType == 'TrustedLaunch' && securityProfileJson.uefiSettings.secureBootEnabled && securityProfileJson.uefiSettings.vTpmEnabled) {
  dependsOn: [vm]
  parent: vm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, vnetSubnetName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', 'nsg${baseName}')
    }
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg${baseName}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 310
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'HTTP'
        properties: {
          priority: 320
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80' //for NGINX Landing Page
        }
      }
    ]
  }
}

resource deploynginx 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  dependsOn: [vmExtension]
  parent: vm
  name: 'installApache'
  location: location
  properties: {
    source: {
      script: '''
                # Update the list of packages.
                sudo apt update;
                # Update the list of packages.
                sudo apt install -y nginx;
                # Start Nginx
                sudo systemctl start nginx;
                # Enable Nginx on boot
                sudo systemctl enable nginx
                #Set TimeZone
                sudo timedatectl set-timezone America/New_York
                '''
      }
   }
}

resource deploypwsh 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  dependsOn: [vmExtension]
  parent: vm
  name: 'InstallPowerShell'
  location: location
  properties: {
    source: {
      script: '''
                # Update the list of packages
                sudo apt update;
                #Install pre-requisite packages.
                sudo apt install -y wget apt-transport-https software-properties-common;
                #Download the Microsoft repository GPG keys
                wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb";
                #Register the Microsoft repository GPG keys
                sudo dpkg -i packages-microsoft-prod.deb;
                #Update the list of packages after we added packages.microsoft.com
                sudo apt update;
                #Install PowerShell
                sudo apt install -y powershell;
                #Start PowerShell
                pwsh
                '''
    }
  }
}

output adminUsername string = vmUserName
output hostname string = publicIp.properties.dnsSettings.fqdn
output sshCommand string = 'ssh ${vmUserName}@${publicIp.properties.dnsSettings.fqdn}'
output vmname string = vmName
//output publicIp string = publicIp.properties.ipAddress
