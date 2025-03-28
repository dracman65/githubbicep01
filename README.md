# Test and Deploy Code

## Test

- az deployment sub what-if --name dsdghdep05 --location 'eastus2' --parameters .\parameters\github-bicep-var.bicepparam --template-file main.bicep

## Deploy

- Name is the deployment name listed in Subscriptions/Azure. Change per run or the other deployments will be overwritten.

- az deployment sub create --name dsdghdep06 --location 'eastus2' --parameters .\parameters\github-bicep-var.bicepparam --template-file main.bicep