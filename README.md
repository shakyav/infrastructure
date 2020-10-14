# infrastructure

Create a VPC with 3 subnets , routing table , internet gateway and create a public route in the public route table created above with destination CIDR block 0.0.0.0/0 and internet gateway created above as the target

# Steps to install and setup Terraform on fedora
     
# - Run the following commands to install 
        
         1.   sudo dnf install -y dnf-plugins-core
         2.   sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
         3.   sudo dnf -y install terraform

# - Enable tab complettion
         4.   terraform -install-autocomplete
# - Build the infrastructure 
         5. Configure aws CLI 
         6. Create the directory for your terraform files
         7. create a terraform file for eaxample "test_vpc.tf"
         8. create a var_def.tf file , it contains variable definition for all the input variables
         9. create variables.tfvars , assign values to the variables defined in this file
         10. Initialize the terraform directory , run following command
             - terraform init
         11. Format and validate the configuration
             - terraform fmt
         12. terraform validate to chekc any syntax errors
             - terraform validate -var-file="variables.tfvars"
         13. Build infrastructure 
             - terraform apply -var-file="variables.tfvars"
         14. Create another VPC 
             - switch to new terraform workspace
                 - terraform workspace new workspace_name
                 - terraform apply -var-file="variables.tfvars"
         15. Destroy the created infrastructure
                 - terraform destroy -var-file="variables.tfvars"
             
