#!/bin/bash
RDS_HOSTNAME=csye6225-f20.cavwwt6wqc4a.us-east-1.rds.amazonaws.com
RDS_PORT=3306
RDS_DB_NAME=csye6225
RDS_USERNAME=csye6225fall2020
RDS_PASSWORD=test1234
export RDS_HOSTNAME 
export RDS_PORT
export RDS_USERNAME
export RDS_PASSWORD
export RDS_DB_NAME
echo $RDS_HOSTNAME
echo $RDS_PORT
echo $RDS_USERNAME
echo $RDS_PASSWORD
echo $RDS_DB_NAME
