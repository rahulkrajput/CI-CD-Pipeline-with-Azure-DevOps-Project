# Provision Azure AKS using Terraform & Azure DevOps

## Step-01: Introduction
- Create Azure DevOps Pipeline to create AKS cluster using Terraform
- We are going to create two environments Dev and QA using single pipeline. 
- Terraform Manifests Validate
- Provision Dev AKS Cluster
- Provision QA AKS Cluster

## Step-02: Install Azure Market Place Plugins in Azure DevOps
- Install below listed two plugins in your respective Azure DevOps Organization
- Discuss about which plugin to use
- We are going to use plugin-2 as on today it is very actively managed and good reviews and good features
- [Plugin-1: Terraform by Microsoft Devlabs](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks)
- [Plugin-2: Terraform Build & Release Tasks](https://marketplace.visualstudio.com/items?itemName=charleszipp.azure-pipelines-tasks-terraform)


## Step-03: Review Terraform Manifests
### 01-main.tf
- Comment Terraform Backend, because we are going to configure that in Azure DevOps

### 02-variables.tf
- Two variables we will define in Azure DevOps and use it
  - Environment 
  - SSH Public Key
- Just comment the default values here (ideally not needed but we will do that)  

### 03-resource-group.tf
- We are going to create resource groups for each environment with **terraform-aks-envname**
- Example Name:
  - terraform-aks-dev
  - terraform-aks-qa

### 04-aks-versions-datasource.tf
- We will get the latest version of AKS using this datasource. 
- `include_preview = false` will ensure that preview versions are not listed

### 05-log-analytics-workspace.tf
- Log Analytics workspace will be created per environment. 
- Example Name:
  - dev-logs-some-random-petname
  - qa-logs-some-random-petname

### 06-aks-administrators-azure-ad.tf
- We are going to create Azure AD Group per environment for AKS Admins
- To create this group we need to ensure Azure AD Directory Write permission is there for our Service Principal (Service Connection) created in Azure DevOps
- We will see that in detail in upcoming steps. 
- VERY VERY IMPORTANT FIX TO MAKE THIS WORK

### 07-aks-cluster.tf
- Name of the AKS Cluster going to be **ResourceGroupName-Cluster**
- Example Names:
  - terraform-aks-dev-cluster
  - terraform-aks-qa-cluster
-  Node Lables and Tags will have a environment with respective environment name  

### 08-outputs.tf  
- We will put out output values very simple
- Resource Group 
  - Location
  - Name
  - ID
- AKS Cluster 
  - AKS Versions
  - AKS Latest Version
  - AKS Cluster ID
  - AKS Cluster Name
  - AKS Cluster Kubernetes Version
- AD Group
  - ID
  - Object ID
 
 ### 09-aks-cluster-linux-user-nodepools.tf
 - We will comment this file and leave it that way.
 - If you need to provision the new nodepool , uncomment all lines except first line and check-in code and new nodepool will be created
 -  Node Lables and Tags will have a environment with respective environment name

 ### 10-aks-cluster-windows-user-nodepools.tf
 - We will comment this file and leave it that way.
 - If you need to provision the new nodepool windows, uncomment all lines except first line and check-in code and new nodepool will be created
 -  Node Lables and Tags will have a environment with respective environment name



## Step-04: Create Github Repository

### Create Github Repository in Github
- Create Repository in your github
- Name: azure-devops-aks-kubernetes-terraform-pipeline
- Descritpion: Provision AKS Cluster using Azure DevOps Pipelines
- Repository Type: Public or Private (Your Choice)
- Click on **Create Repository**

### Copy files, Initialize Local Repo, Push to Remote Git Repo
```
# Create folder in local deskop
cd azure-devops-aks-demo-repos
mkdir azure-devops-aks-kubernetes-terraform-pipeline
cd azure-devops-aks-kubernetes-terraform-pipeline

# Copy folders from Git-Repo-Files folder to new folder created in local desktop
kube-manifests
terraform-manifests
pipeline-backups


# Initialize Git Repo
cd azure-devops-aks-kubernetes-terraform-pipeline
git init

# Add Files & Commit to Local Repo
git add .
git commit -am "First Commit"

# Add Remote Origin and Push to Remote Repo
git remote add origin https://github.com/stacksimplify/azure-devops-aks-kubernetes-terraform-pipeline.git
git push --set-upstream origin master 

# Verify the same on Github Repository
Refersh browser for Repo you have created
Example: https://github.com/stacksimplify/azure-devops-aks-kubernetes-terraform-pipeline.git
```     


## Step-05: Create New Azure DevOps Project for IAC
- Go to -> Azure DevOps -> Select Organization -> aksdemo2 ->  Create New Project
- Project Name: terraform-azure-aks
- Project Descritpion: Provision Azure AKS Cluster using Azure DevOps & Terraform
- Visibility: Private
- Click on **Create**

## Step-07: Create Azure RM Service Connection for Terraform Commands
- This is a pre-requisite step required during Azure Pipelines
- We can create from Azure Pipelines -> Terraform commands screen but just to be in a orderly manner we are creating early.
- Go to -> Azure DevOps -> Select Organization -> Select project **Provision Terraform AKS Cluster**
- Go to **Project Settings**
- Go to Pipelines -> Service Connections -> Create Service Connection
- Choose a Service Connection type: Azure Resource Manager
- Identity type: App registration (automatic)
- Credential: Workload identity federation (automatic)
- Scope Level: Subscription
- Subscription: Select_Your_Subscription
- Resource Group: No need to select any resource group
- Service Connection Name: terraform-aks-cluster-svc-conn
- Description: Azure RM Service Connection for provisioning AKS Cluster using Terraform on Azure DevOps
- Security: Grant access permissions to all pipelines (check it - leave to default)
- Click on **SAVE**


## Step-08: VERY IMPORTANT FIX: Provide Permission to create Azure AD Groups
- Provide permission for Service connection created in previous step to create Azure AD Groups
- Go to -> Azure DevOps -> Select Organization -> Select project **Provision Terraform AKS Cluster**
- Go to **Project Settings** -> Pipelines -> Service Connections 
- Open **terraform-aks-cluster-svc-conn**
- Click on **Manage App registration**, new tab will be opened 
- Click on **View API Permissions**
- Click on **Add Permission**
- Select an API: Microsoft APIs
- Microsoft APIs: Use **Microsoft Graph**
- Click on **Application Permissions**
- Select permissions : "Directory" and click on it 
- Check **Directory.ReadWrite.All** and click on **Add Permission**
- Click on **Grant Admin consent for Default Directory**



## Step-09: Create SSH Public Key for Linux VMs
- Create this out of your git repository 
- **Important Note:**  We should not have these files in our git repos for security Reasons
```
# Create Folder
mkdir $HOME/ssh-keys-terraform-aks-devops

# Create SSH Keys
ssh-keygen \
    -m PEM \
    -t rsa \
    -b 4096 \
    -C "azureuser@myserver" \
    -f ~/ssh-keys-terraform-aks-devops/aks-terraform-devops-ssh-key-ubuntu \

Note: We will have passphrase as : empty when asked

# List Files
ls -lrt $HOME/ssh-keys-terraform-aks-devops
Private File: aks-terraform-devops-ssh-key-ubuntu (To be stored safe with us)
Public File: aks-terraform-devops-ssh-key-ubuntu.pub (To be uploaded to Azure DevOps)
```

## Step-10: Upload file to Azure DevOps as Secure File
- Go to Azure DevOps -> CI-CD-Pipeline-For-Provision-AKS-Cluster -> Provision Terraform AKS Cluster -> Pipelines -> Library
- Secure File -> Upload file named **aks-terraform-devops-ssh-key-ubuntu.pub**
- Open the file and click on **Pipeline permissions -> Click on three dots -> Confirm open access -> Click on Open access**
- Click on **SAVE**


## Step-11: Create Azure Pipeline to Provision AKS Cluster
- Go to -> Azure DevOps -> Select Organization -> Select project 
- Go to Pipelines -> Pipelines -> Create Pipeline
### Where is your Code?
- Github
- Select Your Repository
- Provide your github password
- Click on **Approve and Install** on Github
### Configure your Pipeline
- Select Pipeline: Starter Pipeline  
- Design your Pipeline
- Pipeline Name: 01-provision-terraform-aks-cluster-pipeline.yml
### Stage-1: Validate Stage
- **Stage-1:** Terraform Validate Stage
  - **Step-1:** Publish Artifacts to Pipeline (Pipeline artifacts provide a way to share files between stages in a pipeline or between different pipelines. )
  - **Step-2:** Install Latest Terraform 
  - **Step-3:** Validate Terraform Manifests
```yaml
trigger:
- main

pool: Default #(Self-Hosted-Agent)
  


stages:
- stage: TerraformValidate
  jobs:
    - job: TerraformValidateJob
      continueOnError: false
      steps:
      - task: PublishPipelineArtifact@1
        displayName: Publish Artifacts
        inputs:
          targetPath: '$(System.DefaultWorkingDirectory)/terraform-manifests'
          artifact: 'terraform-manifests-out'
          publishLocation: 'pipeline'
      - task: TerraformInstaller@0
        displayName: Terraform Install
        inputs:
          terraformVersion: 'latest'
      - task: TerraformCLI@0
        displayName: Terraform Init
        inputs:
          command: 'init'
          workingDirectory: '$(System.DefaultWorkingDirectory)/terraform-manifests'
          backendType: 'azurerm'
          backendServiceArm: 'terraform-aks-cluster-svc-conn'
          backendAzureRmResourceGroupName: 'terraform-storage-rg'
          backendAzureRmStorageAccountName: 'terraformstorage05'
          backendAzureRmContainerName: 'tfstatebackupfile'
          backendAzureRmKey: 'aks-base.tfstate'
          allowTelemetryCollection: false
      - task: TerraformCLI@0
        displayName: Terraform Validate
        inputs:
          command: 'validate'
          workingDirectory: '$(System.DefaultWorkingDirectory)/terraform-manifests'
          allowTelemetryCollection: false       
```


### Pipeline Save and Run
- Click on **Save and Run**
- Commit Message: First Pipeline Commit - Validate terraform manifests
- Click on **Job** and Verify Pipeline


## Stage-12: Deploy Dev AKS Cluster
- **Stage-2:** Deploy Stages for Dev & QA
  - **Deployment-1:** Deploy Dev AKS Cluster
    - **Step-1:** Define Variables for environments
    - **Step-2:** Download SSH Secure File
    - **Step-3:** Terraform Initialize (State Storage to store in Azure Storage Account for Dev AKS Cluster)
    - **Step-4:** Terraform Plan (Create Plan)
    - **Step-5:** Terraform Apply (Use the plan created in previous step)
- [Azure DevOps Pipelines - Deployment Jobs](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/deployment-jobs?view=azure-devops)
- [Azure DevOps Pipelines - Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops)

### Stage-2: Deployment-1: Deploy Dev AKS Cluster
```yaml
# Stage-2: Deploy Stages for Dev & QA
# Deployment-1: Deploy Dev AKS Cluster
## Step-1: Define Variables for environments
## Step-2: Download SSH Secure File
## Step-3: Terraform Initialize (State Storage to store in Azure Storage Account for Dev AKS Cluster)
## Step-4: Terraform Plan (Create Plan)
## Step-5: Terraform Apply (Use the plan created in previous step)

# Define Variables
variables:
- name: PROD_ENVIRONMENT
  value: prod
- name: DEV_ENVIRONMENT
  value: dev
- name: QA_ENVIRONMENT
  value: qa
 


- stage: DeployPRODAKSCluster
  jobs:
    - deployment: DeployPRODAKSCluster
      displayName: DeployPRODAKSCluster
      pool: Default #(Self-Hosted-Agent)
      environment: $(PROD_ENVIRONMENT)      
      strategy:
        runOnce:
          deploy:
            steps:            
            - task: DownloadSecureFile@1
              displayName: Download SSH Key
              name: sshkey
              inputs:
                secureFile: 'aks-terraform-devops-ssh-key-ubuntu.pub'
            - task: TerraformCLI@0
              displayName: Terraform Init
              inputs:
                command: 'init'
                workingDirectory: '$(Pipeline.Workspace)/terraform-manifests-out'
                backendType: 'azurerm'
                backendServiceArm: 'terraform-aks-cluster-svc-conn'
                backendAzureRmResourceGroupName: 'terraform-storage-rg'
                backendAzureRmStorageAccountName: 'terraformstorage05'
                backendAzureRmContainerName: 'tfstatebackupfile'
                backendAzureRmKey: 'aks-$(PROD_ENVIRONMENT).tfstate'
                
            - task: TerraformTaskV4@4
              displayName: Terraform Plan
              inputs:
                provider: 'azurerm'
                command: 'plan'
                workingDirectory: '$(Pipeline.Workspace)/terraform-manifests-out'
                commandOptions: '-var ssh_public_key=$(sshkey.secureFilePath) -var environment=$(PROD_ENVIRONMENT) -out $(Pipeline.Workspace)/terraform-manifests-out/$(PROD_ENVIRONMENT)-$(Build.BuildId).out'
                environmentServiceNameAzureRM: 'terraform-aks-cluster-svc-conn'
            - task: TerraformTaskV4@4
              displayName: Terraform Apply
              inputs:
                provider: 'azurerm'
                command: 'apply'
                workingDirectory: '$(Pipeline.Workspace)/terraform-manifests-out'
                commandOptions: '$(Pipeline.Workspace)/terraform-manifests-out/$(PROD_ENVIRONMENT)-$(Build.BuildId).out'
                environmentServiceNameAzureRM: 'terraform-aks-cluster-svc-conn'  
```


### Pipeline Save and Run
- Click on **Save and Run**
- Commit Message: Second Commit - Dev AKS Provision via terraform
- Click on **Job** and Verify Pipeline


## Step-13: Verify all the resources created 
### Verify Pipeline logs
- Verify Pipeline logs for all the tasks

### Verify new Storage Account in Azure Mgmt Console
- Verify if `terraform init` command ran successfully from Azure Pipelines
- Verify Storage Account
- Verify Storage Container
- Verify tfstate file got created in storage container

### Verify new AKS Cluster in Azure Mgmt Console
- Verify Resource Group 
- Verify AKS Cluster
- Verify AD Group
- Verify Tags for a nodepool

### Connect to AKS Cluster
```
# Setup kubeconfig
az aks get-credentials --resource-group <Resource-Group-Name>  --name <AKS-Cluster-Name>
az aks get-credentials --resource-group terraform-aks-dev  --name terraform-aks-dev-cluster --admin

# View Cluster Info
kubectl cluster-info

# List Kubernetes Worker Nodes
kubectl get nodes
```


### Connect to Dev AKS Cluster & verify
```
# List Nodepools
az aks nodepool list --cluster-name terraform-aks-dev-cluster --resource-group terraform-aks-dev -o table

# Setup kubeconfig
az aks get-credentials --resource-group <Resource-Group-Name>  --name <AKS-Cluster-Name>
az aks get-credentials --resource-group terraform-aks-dev  --name terraform-aks-dev-cluster --admin

# View Cluster Info
kubectl cluster-info

# List Kubernetes Worker Nodes
kubectl get nodes
```

## Step-17: Delete Resources
- Delete the Resource group which will delete all resources
  - terraform-aks-prod
  
- Delete AD Groups  


## References
- [Publish & Download Artifacts in Azure DevOps Pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/artifacts/pipeline-artifacts?view=azure-devops&tabs=yaml)
- [Azure Pipelines - Deployment Jobs](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/deployment-jobs?view=azure-devops)


