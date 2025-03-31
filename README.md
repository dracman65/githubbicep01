# Test and Deploy Code

## Test

- az deployment sub what-if --name dsdghdep05 --location 'eastus2' --parameters .\parameters\github-bicep-var.bicepparam --template-file main.bicep

## Deploy

- Name is the deployment name listed in Subscriptions/Azure. Change per run or the other deployments will be overwritten.

- az deployment sub create --name dsdghdep06 --location 'eastus2' --parameters .\parameters\github-bicep-var.bicepparam --template-file main.bicep

# Azure GitActions Deployment

- Create app registration in Azure.
- After app registration, add permissions to the app registration. Click Certificate & secrets. Federal Credentials. Add in the ORG and Repo.
- Go to Subscription. Add a new Role Assignment for the app registration. You will need to create a custom role. Use Contributor but edit it to (via the JSON screen) and remove WRITE and DELETE. The Key Vault permissions require WRITE and DELETE (DELETE is required for modifying the permission). This will allow GitHub to create the service and modify it as necessary. Add the new role assignment you just created to the app registration. When selecting the service/app, ou will have to type in the app name in order to see it. Save.
- Add the app/code to GitHub and then run the GitActions workflows YAML file.
- See this repo for GitActions pipeline.