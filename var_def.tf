
# this file contains all the variables that will be used to create the vpc such as region,availability zone,
# dnsSupport, vpcCIDRblock, subnet block

/* variable "access_key" {
     type = string
     
}
variable "secret_key" {
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