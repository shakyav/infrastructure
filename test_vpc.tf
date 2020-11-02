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
  count                   = "${length(var.subnetCIDRblock)}"
  vpc_id                  = "${aws_vpc.test_VPC.id}"
  cidr_block              = "${element(var.subnetCIDRblock, count.index)}"
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone       = "${element(var.availabilityZone, count.index)}"
  tags = {
    Name = "Subnet-${count.index + 1}"
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
  count          = "${length(var.subnetCIDRblock)}"
  subnet_id      = "${element(aws_subnet.test_VPC_Subnet.*.id, count.index)}"
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
  tags = {
    Name = "CodeDeployEC2ServiceRole"
  }
}



resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = "${aws_iam_role.role.name}"
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


data "aws_ami" "ami" {
  most_recent = true
  owners      = [var.ami_owners_id]
}

resource "aws_instance" "test_terraform_ec2_instance" {
  ami           = data.aws_ami.ami.id
  instance_type = "t2.micro"


  subnet_id                   = "${aws_subnet.test_VPC_Subnet[0].id}"
  vpc_security_group_ids      = "${aws_security_group.test_VPC_Security_Group.*.id}"
  key_name                    = "csye6225-fall2020-aws"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.ec2_profile.name}"
  user_data                   = <<-EOF
               #!/bin/bash
               sudo echo export "Bucket_Name=${aws_s3_bucket.bucket.bucket}" >> /etc/environment
               sudo echo export "RDS_HOSTNAME=${aws_db_instance.rds_ins.address}" >> /etc/environment
               sudo echo export "DBendpoint=${aws_db_instance.rds_ins.endpoint}" >> /etc/environment
               sudo echo export "RDS_DB_NAME=${aws_db_instance.rds_ins.name}" >> /etc/environment
               sudo echo export "RDS_USERNAME=${aws_db_instance.rds_ins.username}" >> /etc/environment
               sudo echo export "RDS_PASSWORD=${aws_db_instance.rds_ins.password}" >> /etc/environment
               
               EOF

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }
  depends_on = [aws_s3_bucket.bucket, aws_db_instance.rds_ins]

}


# s3 buckket creation

resource "aws_s3_bucket" "bucket" {
  bucket        = "${var.aws_s3_bucket_name}"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    transition {
      days          = 30
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

resource "aws_security_group" "database" {
  description = "RDS mysql servers (terraform-managed)"
  vpc_id      = aws_vpc.test_VPC.id
  name        = "database"

  egress {
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

  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.test_VPC_Security_Group.id}"
  security_group_id        = "${aws_security_group.database.id}"



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

resource "aws_security_group_rule" "test_VPC_Security_Group" {


  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.database.id}"
  /* cidr_blocks = "${var.ingressCIDRblock}" */
  security_group_id = "${aws_security_group.test_VPC_Security_Group.id}"




}




resource "aws_db_instance" "rds_ins" {

  db_subnet_group_name = "${aws_db_subnet_group.db-subnet.name}"

  allocated_storage = var.rds_allocated_storage # gigabytes

  engine         = "mysql"
  engine_version = "8.0.17"
  identifier     = var.rds_dbindentifier
  instance_class = "db.t3.micro"
  multi_az       = false
  name           = var.rds_db_name

  password            = var.rds_dbpassword
  port                = 3306
  publicly_accessible = false

  /* storage_encrypted        = true # you should always do this */
  storage_type           = "gp2"
  username               = var.rds_dbusername
  skip_final_snapshot    = true
  vpc_security_group_ids = "${aws_security_group.database.*.id}"

  tags = {
    "Name" = "rds_ins"
  }

}


# dynamo db creation

resource "aws_dynamodb_table" "dynamodb-table" {

  name           = var.dynamo_dbname
  read_capacity  = var.dynamo_read_capacity
  write_capacity = var.dynamo_write_capacity
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
  tags = {
    Name = "${var.dynamo_dbname}"
  }

}





# CodeDeploy-EC2-S3 policy allows EC2 instances to read data from S3 buckets. This policy is required for EC2 instances to download latest application revision.
resource "aws_iam_role_policy" "CodeDeploy_EC2_S3" {
  name = "CodeDeploy-EC2-S3"
  role = "${aws_iam_role.role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::codedeploy.${var.aws_profile_name}.${var.domain_Name}/*",
        "arn:aws:s3:::webapp.${var.aws_profile_name}.${var.domain_Name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "gh_upload_s3" {
  name   = "gh_upload_s3"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::codedeploy.${var.aws_profile_name}.${var.domain_Name}/*"
              ]
        }
    ]
}
EOF
}

# GH-Code-Deploy Policy for GitHub Actions to Call CodeDeploy

resource "aws_iam_policy" "GH_Code_Deploy" {
  name   = "GH_Code_Deploy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${local.aws_user_account_id}:application:${aws_codedeploy_app.code_deploy_app.name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
         "arn:aws:codedeploy:${var.region}:${local.aws_user_account_id}:deploymentgroup:${aws_codedeploy_app.code_deploy_app.name}/${aws_codedeploy_deployment_group.code_deploy_deployment_group.deployment_group_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${local.aws_user_account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${var.region}:${local.aws_user_account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${var.region}:${local.aws_user_account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}



# IAM Role for CodeDeploy




# IAM Role for CodeDeploy
resource "aws_iam_role" "code_deploy_role" {
  name = "CodeDeployServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ghactions_user_policy" {
  name   = "ghactions_user_policy"
  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Action": [
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CopyImage",
          "ec2:CreateImage",
          "ec2:CreateKeypair",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteKeyPair",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSnapshot",
          "ec2:DeleteVolume",
          "ec2:DeregisterImage",
          "ec2:DescribeImageAttribute",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeRegions",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DetachVolume",
          "ec2:GetPasswordData",
          "ec2:ModifyImageAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifySnapshotAttribute",
          "ec2:RegisterImage",
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ],
        "Resource" : "*"
      }]
  }
  EOF

}



#CodeDeploy App and Group for webapp
resource "aws_codedeploy_app" "code_deploy_app" {
  compute_platform = "Server"
  name             = "csye6225-webapp"
}

resource "aws_codedeploy_deployment_group" "code_deploy_deployment_group" {
  app_name               = "${aws_codedeploy_app.code_deploy_app.name}"
  deployment_group_name  = "csye6225-webapp-deployment"
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = "${aws_iam_role.code_deploy_role.arn}"
  



  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "myEC2Instance"
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = ["Deployment-Alarm"]
    enabled = true
  }

  depends_on = [aws_codedeploy_app.code_deploy_app]
}


data "aws_caller_identity" "current" {}

locals {
  aws_user_account_id = "${data.aws_caller_identity.current.account_id}"
}

# Attach the policy for CodeDeploy role for webapp
resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = "${aws_iam_role.code_deploy_role.name}"
}

resource "aws_iam_user_policy_attachment" "ghactions_ec2_policy_attach" {
  user       = "ghactions"
  policy_arn = "${aws_iam_policy.ghactions_user_policy.arn}"
}

resource "aws_iam_user_policy_attachment" "ghactions_s3_policy_attach" {
  user       = "ghactions"
  policy_arn = "${aws_iam_policy.gh_upload_s3.arn}"
}


resource "aws_iam_user_policy_attachment" "ghactions_codedeploy_policy_attach" {
  user = "ghactions"
  policy_arn = "${aws_iam_policy.GH_Code_Deploy.arn}"
}


/* data "aws_route53_zone" "route53" {
  name         = "${var.aws_profile_name}.${var.domain_Name}."
  # private_zone = false
}

resource "aws_route53_record" "recordset" {
  zone_id = "${data.aws_route53_zone.route53.zone_id}"
  name    = "${data.aws_route53_zone.route53.name}"
  type    = "A"

  alias {
    name    = "${aws_lb.appLoadbalancer.dns_name}"
    zone_id = "${aws_lb.appLoadbalancer.zone_id}"
    evaluate_target_health = true
  }
} */
# end vpc.tf
