# Task 4.1.1 Azure Infra EN

We need to be registered in Azure and have installed Azure CLI Powershell module.
Next we need to login and obtain auth data
```ps1
az login

[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "6c1a6488-b140-4b7f-****-024bde74a8db",
    "id": "be0ac8a4-cf75-414b-****-95fcf3fa8c21",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Azure subscription 1",
    "state": "Enabled",
    "tenantId": "6c1a6488-b140-4b7f-****-024bde74a8db",
    "user": {
      "name": "magicgts@gmail.com",
      "type": "user"
    }
  }
]

az account set --subscription "be0ac8a4-cf75-414b-****-95fcf3fa8c21"
$SP = (az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/be0ac8a4-cf75-414b-****-95fcf3fa8c21")
$SP
{
  "appId": "********-****-****-****-*************",
  "displayName": "azure-cli-2022-12-21-16-25-21",
  "password": "******",
  "tenant": "*******-****-****-****-************"
}

$Env:ARM_CLIENT_ID = $SP.appId
$Env:ARM_CLIENT_SECRET = $SP.password
$Env:ARM_SUBSCRIPTION_ID = "be0ac8a4-cf75-414b-****-95fcf3fa8c21"
$Env:ARM_TENANT_ID = $SP.tenant

New-Item -Path "D:\GitHub\InternDevOpsEngineer" -Name "learn-terraform-azure" -ItemType "directory"
```
Now we preparing some basic TF configuration in tf-azure/main.cf
```
terraform init


Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.36.0"...
- Installing hashicorp/azurerm v3.36.0...
- Installed hashicorp/azurerm v3.36.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
```
terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_resource_group.rg will be created
  + resource "azurerm_resource_group" "rg" {
      + id       = (known after apply)
      + location = "westeurope"
      + name     = "myTFResourceGroup"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

azurerm_resource_group.rg: Creating...
azurerm_resource_group.rg: Creation complete after 2s [id=/subscriptions/be0ac8a4-cf75-414b-****-95fcf3fa8c21/resourceGroups/myTFResourceGroup]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
```
terraform show
# azurerm_resource_group.rg:
resource "azurerm_resource_group" "rg" {
    id       = "/subscriptions/be0ac8a4-cf75-414b-****-95fcf3fa8c21/resourceGroups/myTFResourceGroup"
    location = "westeurope"
    name     = "myTFResourceGroup"
}
```