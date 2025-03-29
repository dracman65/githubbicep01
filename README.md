# Test and Deploy Code

## Test

- az deployment sub what-if --name dsdghdep05 --location 'eastus2' --parameters .\parameters\github-bicep-var.bicepparam --template-file main.bicep

## Deploy

- Name is the deployment name listed in Subscriptions/Azure. Change per run or the other deployments will be overwritten.

- az deployment sub create --name dsdghdep06 --location 'eastus2' --parameters .\parameters\github-bicep-var.bicepparam --template-file main.bicep

## Azure GitActions Deployment

- Create app registration in Azure.
- After app registration, add permissions to the app registration. Click Certificate & secrets. Federal Credentials. Add in the ORG and Repo.
- Go to Subscription. Add a new Role Assignment for the app registration. You will need to make a custom role - Contributor and edit it, removing write and delete. You need write and delete for the Key Vault permissions. Save new role. You will have to type in the app name in order to see it. Save
- Add the app and then run the GitActions workflows.
- See this repo for GitActions pipeline.