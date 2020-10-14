# vpc.tf 
# Create VPC/Subnet/Security Group/Network ACL


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

/* provider "aws" {
  version = "~> 2.70"
  access_key = var.access_key 
  secret_key = var.secret_key 
  region     = var.region

} */

provider "aws" {
  profile = "dev"
  region  = "us-east-1"
}


# create the VPC
resource "aws_vpc" "test_VPC" {
  cidr_block           = var.vpcCIDRblock
  instance_tenancy     = var.instanceTenancy 
  enable_dns_support   = var.dnsSupport 
  enable_dns_hostnames = var.dnsHostNames
  tags = {
    Name = "Test VPC"
}
} 
# end resource


resource "aws_subnet" "test_VPC_Subnet" {
  count = "${length(var.subnetCIDRblock)}"
  vpc_id = "${aws_vpc.test_VPC.id}"
  cidr_block = "${element(var.subnetCIDRblock,count.index)}"
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone = "${element(var.availabilityZone,count.index)}"
  tags = {
    Name = "Subnet-${count.index+1}"
  }
}



# Create the Internet Gateway
resource "aws_internet_gateway" "test_VPC_GW" {
 vpc_id = aws_vpc.test_VPC.id
 tags = {
        Name = "test VPC Internet Gateway"
}
} # end resource


# Create the Route Table
resource "aws_route_table" "test_VPC_route_table" {
 vpc_id = aws_vpc.test_VPC.id
 tags = {
        Name = "test VPC Route Table"
}
} # end resource


# Create the Internet Access
resource "aws_route" "test_VPC_internet_access" {
  route_table_id         = aws_route_table.test_VPC_route_table.id
  destination_cidr_block = var.destinationCIDRblock
  gateway_id             = aws_internet_gateway.test_VPC_GW.id
} # end resource

# Associate the Route Table with the Subnet

resource "aws_route_table_association" "test_VPC_association" {
  count = "${length(var.subnetCIDRblock)}"
  subnet_id      = "${element(aws_subnet.test_VPC_Subnet.*.id,count.index)}"
  route_table_id = "${aws_route_table.test_VPC_route_table.id}"
}




# end vpc.tf