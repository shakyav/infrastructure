
# this file contains all the variables that will be used to create the vpc such as region,availability zone,
# dnsSupport, vpcCIDRblock, subnet block

/* variable "aws_access_key" {
     type = string
     
}
variable "aws_secret_key" {
     type = string
     
} */
variable "region" {
     type = string
     default = "us-east-1"
}
variable "availabilityZone" {
    type = list
    
    
}
variable "instanceTenancy" {
    type = string
    default = "default"
}
variable "dnsSupport" {
    type = bool
    default = true
}
    
variable "dnsHostNames" {
    type = bool
    default = true
    
}
variable "vpcCIDRblock" {
    type = string
    
    
}
variable "subnetCIDRblock" {
    type = list
    
}
variable "privateCIDRblock" {
    type = list
    
}
variable "destinationCIDRblock" {
    type = string
    
}
    
variable "ingressCIDRblock" {
    type = list
} 
    
variable "egressCIDRblock" {
    type = list
    
}
variable "mapPublicIP" {
   
    type = bool
    default = true
}
variable "source_ami"{
    type = string
}
variable "aws_s3_bucket_name"{
    type = string
}
variable "aws_profile_name"{
    type = string
}
variable "ami_owners_id"{
    type = number
}
variable "rds_dbindentifier"{
    type = string
}
variable "rds_db_name"{
    type = string
}
variable "rds_dbusername"{
    type = string
}
variable "rds_dbpassword"{
    type = string
}
variable "rds_allocated_storage"{
    type = number
}

variable "dynamo_read_capacity"{
    type = number
}

variable "dynamo_write_capacity"{
    type = number
}
variable "dynamo_dbname"{
    type = string
}
variable "domain_Name"{
    type = string
}
/* variable "aws_user_account_id"{
    type = number
} */