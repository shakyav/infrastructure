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
  profile = var.aws_profile_name
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

/* resource "aws_subnet" "privateSubnet" {
  count = "${length(var.privateCIDRblock)}"
  vpc_id = "${aws_vpc.test_VPC.id}"
  cidr_block = "${element(var.privateCIDRblock,count.index)}"
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone = "${element(var.availabilityZone,count.index)}"
  tags = {
    Name = "privateSubnet-${count.index+1}"
  }
} */



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


# Create the private Route Table
/* resource "aws_route_table" "privateroute_table" {
 vpc_id = aws_vpc.test_VPC.id
 tags = {
        Name = "test VPC private Route Table"
} */
# end resource


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


# Associate the Route Table with the private Subnet

/* resource "aws_route_table_association" "test_VPC_private_association" {
  count = "${length(var.privateCIDRblock)}"
  subnet_id      = "${element(aws_subnet.privateSubnet.*.id,count.index)}"
  route_table_id = "${aws_route_table.privateroute_table.id}"
} */


resource "aws_security_group" "test_VPC_Security_Group" {
  vpc_id = aws_vpc.test_VPC.id
  name   = "application"

  # allow ingress of port 22
  ingress {
    cidr_blocks = "${var.ingressCIDRblock}"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  # allow ingress of port 80
  ingress {
    cidr_blocks = "${var.ingressCIDRblock}"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  # allow ingress of port 443
  ingress {
    cidr_blocks = "${var.ingressCIDRblock}"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

   ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.ingressCIDRblock

  }



  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "${var.egressCIDRblock}"
  }

  tags = {
    Name = "application"
  }
}


resource "aws_iam_role" "role" {
  name = "EC2-CSYE6225"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
EOF
}



resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}


/* resource "aws_subnet" "private-subnet1" {


vpc_id = "${aws_vpc.test_VPC.id}"
cidr_block = "10.0.5.0/24"
availability_zone = "us-east-1a"
}

resource "aws_subnet" "private-subnet2" {


vpc_id = "${aws_vpc.test_VPC.id}"
cidr_block = "10.0.6.0/24"
availability_zone = "us-east-1b"
} */

resource "aws_db_subnet_group" "db-subnet" {
name = "db-subnet-group"

subnet_ids = "${aws_subnet.test_VPC_Subnet.*.id}"
tags = {
   Name = "rds db subnet group"
}
}


data "aws_ami" "ami"{
  most_recent = true
  owners = [720038752375]
}

resource "aws_instance" "test_terraform_ec2_instance" {
  ami           = data.aws_ami.ami.id
  instance_type = "t2.micro"
  
  
  subnet_id = "${aws_subnet.test_VPC_Subnet[0].id}"
  vpc_security_group_ids = "${aws_security_group.test_VPC_Security_Group.*.id}"
  key_name = "csye6225-fall2020-aws"
  associate_public_ip_address = true
  user_data = <<-EOF
               #!/bin/bash
               sudo echo export "Bucket_Name=${aws_s3_bucket.bucket.bucket}" >> /etc/environment
               sudo echo export "RDS_HOSTNAME=${aws_db_instance.rds_ins.address}" >> /etc/environment
               sudo echo export "DBendpoint=${aws_db_instance.rds_ins.endpoint}" >> /etc/environment
               sudo echo export "RDS_DB_NAME=${aws_db_instance.rds_ins.name}" >> /etc/environment
               sudo echo export "RDS_USERNAME=${aws_db_instance.rds_ins.username}" >> /etc/environment
               sudo echo export "RDS_PASSWORD=${aws_db_instance.rds_ins.password}" >> /etc/environment
               sudo echo export "AWS_ACCESS_KEY=${var.aws_access_key}" >> /etc/environment
               sudo echo export "AWS_SECRET_KEY=${var.aws_secret_key}" >> /etc/environment
               EOF
 
  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = true
  }
  depends_on = [aws_s3_bucket.bucket,aws_db_instance.rds_ins]

}


# s3 buckket creation

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.aws_s3_bucket_name}"
  acl = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    
  }
}

resource "aws_iam_policy" "policy" {
  name        = "WebAppS3"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::${var.aws_s3_bucket_name}",
                "arn:aws:s3:::${var.aws_s3_bucket_name}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_security_group" "database"{
description = "RDS mysql servers (terraform-managed)"
  vpc_id = aws_vpc.test_VPC.id
  name = "database"

  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # means all ports
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "database"
  }
}

resource "aws_security_group_rule" "database" {
  

  

  # Only mysql in
    type = "ingress"
    
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.test_VPC_Security_Group.id}"
    security_group_id = "${aws_security_group.database.id}"
  


}
/* 

resource "aws_security_group_rule" "database_egress" {
  

  

  # Only mysql in
    type = "egress"
    
    from_port = 0
    to_port = 0
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.database.id}"
    security_group_id = "${aws_security_group.database.id}"
  


} */

resource "aws_security_group_rule" "test_VPC_Security_Group"{

  
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.database.id}"
    /* cidr_blocks = "${var.ingressCIDRblock}" */
    security_group_id = "${aws_security_group.test_VPC_Security_Group.id}"
    
  


}




resource "aws_db_instance" "rds_ins"{

  db_subnet_group_name = "${aws_db_subnet_group.db-subnet.name}"

  allocated_storage        = 5 # gigabytes
  
  engine                   = "mysql"
  engine_version           = "8.0.17"
  identifier               = "csye6225-f20"
  instance_class           = "db.t3.micro"
  multi_az                 = false
  name                     = "csye6225"
  
  password          = "test1234"
  port                     = 3306
  publicly_accessible = false
  
  /* storage_encrypted        = true # you should always do this */
  storage_type             = "gp2"
  username                 = "csye6225fall2020"
  skip_final_snapshot = true
  vpc_security_group_ids   = "${aws_security_group.database.*.id}"

  tags = {
    "Name" = "rds_ins"
  }

}


# dynamo db creation

resource "aws_dynamo_db" "mytable"{

}

# end vpc.tf