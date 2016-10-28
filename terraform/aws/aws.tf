#
# Amazonia - Terraform Configuration for
# AWS BOSH + Cloud Foundry
#
# author:  James Hunt <james@niftylogic.com>
# created: 2016-06-14
#

variable "aws_access_key" {} # Your Access Key ID                       (required)
variable "aws_secret_key" {} # Your Secret Access Key                   (required)
variable "aws_vpc_name"   {} # Name of your VPC                         (required)
variable "aws_key_name"   {} # Name of EC2 Keypair                      (required)
variable "aws_key_file"   {} # Location of the private EC2 Keypair file (required)

variable "aws_region"     { default = "us-west-2" } # AWS Region
variable "network"        { default = "10.4" }      # First 2 octets of your /16

variable "aws_az1"        { default = "a" }
variable "aws_az2"        { default = "b" }
variable "aws_az3"        { default = "c" }

variable "aws_rds_dev_enabled"     { default = 0 } # Set to 1 to create the DEV RDS cluster
variable "aws_rds_staging_enabled" { default = 0 } # Set to 1 to create the STAGING RDS cluster
variable "aws_rds_prod_enabled"    { default = 0 } # Set to 1 to create the PROD RDS cluster
variable "aws_rds_dev_instance_class"    { default = "db.t2.small" } # Instance Class for DEV RDS Databases
variable "aws_rds_staging_instance_class"    { default = "db.t2.small" } # Instance Class for STAGING RDS Databases
variable "aws_rds_prod_instance_class"    { default = "db.t2.small" } # Instance Class for PROD RDS Databases
variable "aws_rds_master_user"             { default = "cfdbadmin" } # Username for RDS Databases
variable "aws_rds_dev_master_password"     { default = "admin" } # Password for DEV RDS Databases
variable "aws_rds_staging_master_password" { default = "admin" } # Password for STAGING RDS Databases
variable "aws_rds_prod_master_password"    { default = "admin" } # Password for PROD RDS Databases

variable "aws_elb_dev_enabled"     { default = 0 } # Set to 1 to create the DEV ELB
variable "aws_elb_staging_enabled" { default = 0 } # Set to 1 to create the STAGING ELB
variable "aws_elb_prod_enabled"    { default = 0 } # Set to 1 to create the PROD ELB

variable "aws_elb_dev_cert_path"            { default = "/dev/null" } # Path to the DEV ELB Certificate
variable "aws_elb_dev_private_key_path"     { default = "/dev/null" } # Path to the DEV ELB Private Key
variable "aws_elb_staging_cert_path"        { default = "/dev/null" } # Path to the STAGING ELB Certificate
variable "aws_elb_staging_private_key_path" { default = "/dev/null" } # Path to the STAGING ELB Private Key
variable "aws_elb_prod_cert_path"           { default = "/dev/null" } # Path to the PROD ELB Certificate
variable "aws_elb_prod_private_key_path"    { default = "/dev/null" } # Path to the PROD ELB Private Key

variable "aws_route53_dev_enabled"     { default = 0 } # Set to 1 to create a DEV CNAME
variable "aws_route53_staging_enabled" { default = 0 } # Set to 1 to create a STAGING CNAME
variable "aws_route53_prod_enabled"    { default = 0 } # Set to 1 to create a PROD CNAME

variable "aws_route53_dev_hosted_zone_id"     { default = "" } # DEV Hosted Zone ID
variable "aws_route53_staging_hosted_zone_id" { default = "" } # STAGING Hosted Zone ID
variable "aws_route53_prod_hosted_zone_id"    { default = "" } # PROD Hosted Zone ID

#
# VPC NAT AMI
#
# These are the region-specific IDs for the Amazon-suggested
# AMI for running a NAT instance inside of a VPC:
#
#    amzn-ami-vpc-nat-hvm-2016.03.3.x86_64-ebs
#
# The username to log into the nat box is `ec2-user'
#
# The regions, in order, are: N Virginia, N California, 
#   Oregon, Ireland, Frankfurt, Tokyo, Seoul, Singapore,
#   Sydney, Mumbai, and Sao Paulo.

variable "aws_nat_ami" {
  default = {
    us-east-1      = "ami-4868ab25"
    us-east-2      = "ami-92a6fef7"
    us-west-1      = "ami-004b0f60"
    us-west-2      = "ami-a275b1c2"
    eu-west-1      = "ami-a8dd45db"
    eu-central-1   = "ami-5825cd37"
    ap-northeast-1 = "ami-2443b745"
    ap-northeast-2 = "ami-d14388bf"
    ap-southeast-1 = "ami-a79b49c4"
    ap-southeast-2 = "ami-53371f30"
    ap-south-1     = "ami-e2b9d38d"
    sa-east-1      = "ami-9336bcff"
  }
}

#
# Generic Ubuntu AMI
#
# These are the region-specific IDs for an
# HVM-compatible Ubuntu image:
#
#    ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20160830
#
# The username to log into the bastion is `ubuntu'
#
# The regions, in order, are: N Virginia, N California,
#   Oregon, Ireland, Frankfurt, Tokyo, Seoul, Singapore,
#   Sydney, Mumbai, and Sao Paulo.

variable "aws_ubuntu_ami" {
  default = {
    us-east-1      = "ami-4f680658"
    us-west-1      = "ami-68a9e408"
    us-west-2      = "ami-8936e0e9"
    eu-west-1      = "ami-ee6b189d"
    eu-central-1   = "ami-c954a4a6"
    ap-northeast-1 = "ami-a7428ac6"
    ap-northeast-2 = "ami-9824f1f6"
    ap-southeast-1 = "ami-4b9b4028"
    ap-southeast-2 = "ami-ef1a2c8c"
    ap-south-1     = "ami-cef98ca1"
    sa-east-1      = "ami-4e1f8e22"
  }
}

###############################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

###############################################################

resource "aws_vpc" "default" {
  cidr_block           = "${var.network}.0.0/16"
  enable_dns_hostnames = "true"
  tags { Name = "${var.aws_vpc_name}" }
}



########   #######  ##     ## ######## #### ##    ##  ######
##     ## ##     ## ##     ##    ##     ##  ###   ## ##    ##
##     ## ##     ## ##     ##    ##     ##  ####  ## ##
########  ##     ## ##     ##    ##     ##  ## ## ## ##   ####
##   ##   ##     ## ##     ##    ##     ##  ##  #### ##    ##
##    ##  ##     ## ##     ##    ##     ##  ##   ### ##    ##
##     ##  #######   #######     ##    #### ##    ##  ######

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}
resource "aws_route_table" "external" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
  tags { Name = "${var.aws_vpc_name}-external" }
}
resource "aws_route_table" "internal" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat.id}"
  }
  tags { Name = "${var.aws_vpc_name}-internal" }
}



 ######  ##     ## ########  ##    ## ######## ########  ######
##    ## ##     ## ##     ## ###   ## ##          ##    ##    ##
##       ##     ## ##     ## ####  ## ##          ##    ##
 ######  ##     ## ########  ## ## ## ######      ##     ######
      ## ##     ## ##     ## ##  #### ##          ##          ##
##    ## ##     ## ##     ## ##   ### ##          ##    ##    ##
 ######   #######  ########  ##    ## ########    ##     ######

###############################################################
# DMZ - De-militarized Zone for NAT box ONLY
#
resource "aws_subnet" "dmz" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "${var.network}.0.0/24"
  tags { Name = "${var.aws_vpc_name}-dmz" }
}
resource "aws_route_table_association" "dmz" {
  subnet_id      = "${aws_subnet.dmz.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.dmz.subnet" {
  value = "${aws_subnet.dmz.id}"
}

###############################################################
# GLOBAL - Global Infrastructure
#
# This includes the following:
#   - proto-BOSH
#   - SHIELD
#   - Vault (for deployment credentials)
#   - Concourse (for deployment automation)
#   - Bolo
#
resource "aws_subnet" "global-infra-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.1.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-global-infra-0" }
}
resource "aws_route_table_association" "global-infra-0" {
  subnet_id      = "${aws_subnet.global-infra-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.global-infra-0.subnet" {
  value = "${aws_subnet.global-infra-0.id}"
}
resource "aws_subnet" "global-infra-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.2.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-global-infra-1" }
}
resource "aws_route_table_association" "global-infra-1" {
  subnet_id      = "${aws_subnet.global-infra-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.global-infra-1.subnet" {
  value = "${aws_subnet.global-infra-1.id}"
}
resource "aws_subnet" "global-infra-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.3.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-global-infra-2" }
}
resource "aws_route_table_association" "global-infra-2" {
  subnet_id      = "${aws_subnet.global-infra-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.global-infra-2.subnet" {
  value = "${aws_subnet.global-infra-2.id}"
}

resource "aws_subnet" "global-openvpn-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.4.0/25"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-global-openvpn-0" }
}
resource "aws_route_table_association" "global-openvpn-0" {
  subnet_id      = "${aws_subnet.global-openvpn-0.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.global-openvpn-0" {
  value = "${aws_subnet.global-openvpn-0.id}"
}
resource "aws_subnet" "global-openvpn-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.4.128/25"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-global-openvpn-1" }
}
resource "aws_route_table_association" "global-openvpn-1" {
  subnet_id      = "${aws_subnet.global-openvpn-1.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.global-openvpn-1" {
  value = "${aws_subnet.global-openvpn-1.id}"
}


###############################################################
# DEV-INFRA - Development Site Infrastructure
#
#  Primarily used for BOSH directors, deployed by proto-BOSH
#
#  Also reserved for situations where you prefer to have
#  dedicated, per-site infrastructure (SHIELD, Bolo, etc.)
#
#  Three zone-isolated networks are provided for HA and
#  fault-tolerance in deployments that support / require it.
#
resource "aws_subnet" "dev-infra-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.16.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-dev-infra-0" }
}
resource "aws_route_table_association" "dev-infra-0" {
  subnet_id      = "${aws_subnet.dev-infra-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-infra-0.subnet" {
  value = "${aws_subnet.dev-infra-0.id}"
}
resource "aws_subnet" "dev-infra-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.17.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-dev-infra-1" }
}
resource "aws_route_table_association" "dev-infra-1" {
  subnet_id      = "${aws_subnet.dev-infra-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-infra-1.subnet" {
  value = "${aws_subnet.dev-infra-1.id}"
}
resource "aws_subnet" "dev-infra-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.18.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-dev-infra-2" }
}
resource "aws_route_table_association" "dev-infra-2" {
  subnet_id      = "${aws_subnet.dev-infra-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-infra-2.subnet" {
  value = "${aws_subnet.dev-infra-2.id}"
}

###############################################################
# DEV-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#
resource "aws_subnet" "dev-cf-edge-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.19.0/25"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-edge-0" }
}
resource "aws_route_table_association" "dev-cf-edge-0" {
  subnet_id      = "${aws_subnet.dev-cf-edge-0.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.dev-cf-edge-0.subnet" {
  value = "${aws_subnet.dev-cf-edge-0.id}"
}
resource "aws_subnet" "dev-cf-edge-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.19.128/25"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-edge-1" }
}
resource "aws_route_table_association" "dev-cf-edge-1" {
  subnet_id      = "${aws_subnet.dev-cf-edge-1.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.dev-cf-edge-1.subnet" {
  value = "${aws_subnet.dev-cf-edge-1.id}"
}

###############################################################
# DEV-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#
resource "aws_subnet" "dev-cf-core-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.20.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-core-0" }
}
resource "aws_route_table_association" "dev-cf-core-0" {
  subnet_id      = "${aws_subnet.dev-cf-core-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-core-0.subnet" {
  value = "${aws_subnet.dev-cf-core-0.id}"
}
resource "aws_subnet" "dev-cf-core-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.21.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-core-1" }
}
resource "aws_route_table_association" "dev-cf-core-1" {
  subnet_id      = "${aws_subnet.dev-cf-core-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-core-1.subnet" {
  value = "${aws_subnet.dev-cf-core-1.id}"
}
resource "aws_subnet" "dev-cf-core-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.22.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-core-2" }
}
resource "aws_route_table_association" "dev-cf-core-2" {
  subnet_id      = "${aws_subnet.dev-cf-core-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-core-2.subnet" {
  value = "${aws_subnet.dev-cf-core-2.id}"
}

###############################################################
# DEV-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "aws_subnet" "dev-cf-runtime-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.23.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-runtime-0" }
}
resource "aws_route_table_association" "dev-cf-runtime-0" {
  subnet_id      = "${aws_subnet.dev-cf-runtime-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-runtime-0.subnet" {
  value = "${aws_subnet.dev-cf-runtime-0.id}"
}
resource "aws_subnet" "dev-cf-runtime-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.24.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-runtime-1" }
}
resource "aws_route_table_association" "dev-cf-runtime-1" {
  subnet_id      = "${aws_subnet.dev-cf-runtime-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-runtime-1.subnet" {
  value = "${aws_subnet.dev-cf-runtime-1.id}"
}
resource "aws_subnet" "dev-cf-runtime-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.25.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-runtime-2" }
}
resource "aws_route_table_association" "dev-cf-runtime-2" {
  subnet_id      = "${aws_subnet.dev-cf-runtime-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-runtime-2.subnet" {
  value = "${aws_subnet.dev-cf-runtime-2.id}"
}

###############################################################
# DEV-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#
resource "aws_subnet" "dev-cf-svc-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.26.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-svc-0" }
}
resource "aws_route_table_association" "dev-cf-svc-0" {
  subnet_id      = "${aws_subnet.dev-cf-svc-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-svc-0.subnet" {
  value = "${aws_subnet.dev-cf-svc-0.id}"
}
resource "aws_subnet" "dev-cf-svc-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.27.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-svc-1" }
}
resource "aws_route_table_association" "dev-cf-svc-1" {
  subnet_id      = "${aws_subnet.dev-cf-svc-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-svc-1.subnet" {
  value = "${aws_subnet.dev-cf-svc-1.id}"
}
resource "aws_subnet" "dev-cf-svc-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.28.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-svc-2" }
}
resource "aws_route_table_association" "dev-cf-svc-2" {
  subnet_id      = "${aws_subnet.dev-cf-svc-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-svc-2.subnet" {
  value = "${aws_subnet.dev-cf-svc-2.id}"
}

###############################################################
# DEV-CF-DB - Cloud Foundry Databases
#
#  These subnets house the internal Cloud Foundry
#  databases (either MySQL release or RDS DBs).
#
resource "aws_subnet" "dev-cf-db-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.29.0/28"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-db-0" }
}
resource "aws_route_table_association" "dev-cf-db-0" {
  subnet_id      = "${aws_subnet.dev-cf-db-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-db-0.subnet" {
  value = "${aws_subnet.dev-cf-db-0.id}"
}
resource "aws_subnet" "dev-cf-db-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.29.16/28"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-db-1" }
}
resource "aws_route_table_association" "dev-cf-db-1" {
  subnet_id      = "${aws_subnet.dev-cf-db-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-db-1.subnet" {
  value = "${aws_subnet.dev-cf-db-1.id}"
}
resource "aws_subnet" "dev-cf-db-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.29.32/28"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-dev-cf-db-2" }
}
resource "aws_route_table_association" "dev-cf-db-2" {
  subnet_id      = "${aws_subnet.dev-cf-db-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.dev-cf-db-2.subnet" {
  value = "${aws_subnet.dev-cf-db-2.id}"
}
resource "aws_db_subnet_group" "dev-cf-db" {
    name = "${var.aws_vpc_name}-dev-cf-db"
    description = "Managed by Terraform"
    subnet_ids = ["${aws_subnet.dev-cf-db-0.id}", "${aws_subnet.dev-cf-db-1.id}", "${aws_subnet.dev-cf-db-2.id}"]
    tags { Name = "${var.aws_vpc_name}-dev-cf-db" }
}
output "aws.rds.dev-cf-db.db_subnet_group" {
  value = "${aws_db_subnet_group.dev-cf-db.id}"
}

###############################################################
# STAGING-INFRA - Staging Site Infrastructure
#
#  Primarily used for BOSH directors, deployed by proto-BOSH
#
#  Also reserved for situations where you prefer to have
#  dedicated, per-site infrastructure (SHIELD, Bolo, etc.)
#
#  Three zone-isolated networks are provided for HA and
#  fault-tolerance in deployments that support / require it.
#
resource "aws_subnet" "staging-infra-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.32.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-staging-infra-0" }
}
resource "aws_route_table_association" "staging-infra-0" {
  subnet_id      = "${aws_subnet.staging-infra-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-infra-0.subnet" {
  value = "${aws_subnet.staging-infra-0.id}"
}
resource "aws_subnet" "staging-infra-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.33.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-staging-infra-1" }
}
resource "aws_route_table_association" "staging-infra-1" {
  subnet_id      = "${aws_subnet.staging-infra-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-infra-1.subnet" {
  value = "${aws_subnet.staging-infra-1.id}"
}
resource "aws_subnet" "staging-infra-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.34.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-staging-infra-2" }
}
resource "aws_route_table_association" "staging-infra-2" {
  subnet_id      = "${aws_subnet.staging-infra-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-infra-2.subnet" {
  value = "${aws_subnet.staging-infra-2.id}"
}

###############################################################
# STAGING-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#
resource "aws_subnet" "staging-cf-edge-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.35.0/25"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-edge-0" }
}
resource "aws_route_table_association" "staging-cf-edge-0" {
  subnet_id      = "${aws_subnet.staging-cf-edge-0.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.staging-cf-edge-0.subnet" {
  value = "${aws_subnet.staging-cf-edge-0.id}"
}
resource "aws_subnet" "staging-cf-edge-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.35.128/25"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-edge-1" }
}
resource "aws_route_table_association" "staging-cf-edge-1" {
  subnet_id      = "${aws_subnet.staging-cf-edge-1.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.staging-cf-edge-1.subnet" {
  value = "${aws_subnet.staging-cf-edge-1.id}"
}

###############################################################
# STAGING-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#
resource "aws_subnet" "staging-cf-core-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.36.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-core-0" }
}
resource "aws_route_table_association" "staging-cf-core-0" {
  subnet_id      = "${aws_subnet.staging-cf-core-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-core-0.subnet" {
  value = "${aws_subnet.staging-cf-core-0.id}"
}
resource "aws_subnet" "staging-cf-core-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.37.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-core-1" }
}
resource "aws_route_table_association" "staging-cf-core-1" {
  subnet_id      = "${aws_subnet.staging-cf-core-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-core-1.subnet" {
  value = "${aws_subnet.staging-cf-core-1.id}"
}
resource "aws_subnet" "staging-cf-core-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.38.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-core-2" }
}
resource "aws_route_table_association" "staging-cf-core-2" {
  subnet_id      = "${aws_subnet.staging-cf-core-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-core-2.subnet" {
  value = "${aws_subnet.staging-cf-core-2.id}"
}

###############################################################
# STAGING-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "aws_subnet" "staging-cf-runtime-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.39.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-runtime-0" }
}
resource "aws_route_table_association" "staging-cf-runtime-0" {
  subnet_id      = "${aws_subnet.staging-cf-runtime-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-runtime-0.subnet" {
  value = "${aws_subnet.staging-cf-runtime-0.id}"
}
resource "aws_subnet" "staging-cf-runtime-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.40.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-runtime-1" }
}
resource "aws_route_table_association" "staging-cf-runtime-1" {
  subnet_id      = "${aws_subnet.staging-cf-runtime-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-runtime-1.subnet" {
  value = "${aws_subnet.staging-cf-runtime-1.id}"
}
resource "aws_subnet" "staging-cf-runtime-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.41.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-runtime-2" }
}
resource "aws_route_table_association" "staging-cf-runtime-2" {
  subnet_id      = "${aws_subnet.staging-cf-runtime-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-runtime-2.subnet" {
  value = "${aws_subnet.staging-cf-runtime-2.id}"
}

###############################################################
# STAGING-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#
resource "aws_subnet" "staging-cf-svc-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.42.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-svc-0" }
}
resource "aws_route_table_association" "staging-cf-svc-0" {
  subnet_id      = "${aws_subnet.staging-cf-svc-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-svc-0.subnet" {
  value = "${aws_subnet.staging-cf-svc-0.id}"
}
resource "aws_subnet" "staging-cf-svc-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.43.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-svc-1" }
}
resource "aws_route_table_association" "staging-cf-svc-1" {
  subnet_id      = "${aws_subnet.staging-cf-svc-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-svc-1.subnet" {
  value = "${aws_subnet.staging-cf-svc-1.id}"
}
resource "aws_subnet" "staging-cf-svc-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.44.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-svc-2" }
}
resource "aws_route_table_association" "staging-cf-svc-2" {
  subnet_id      = "${aws_subnet.staging-cf-svc-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-svc-2.subnet" {
  value = "${aws_subnet.staging-cf-svc-2.id}"
}

###############################################################
# STAGING-CF-DB - Cloud Foundry Databases
#
#  These subnets house the internal Cloud Foundry
#  databases (either MySQL release or RDS DBs).
#
resource "aws_subnet" "staging-cf-db-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.45.0/28"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-db-0" }
}
resource "aws_route_table_association" "staging-cf-db-0" {
  subnet_id      = "${aws_subnet.staging-cf-db-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-db-0.subnet" {
  value = "${aws_subnet.staging-cf-db-0.id}"
}
resource "aws_subnet" "staging-cf-db-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.45.16/28"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-db-1" }
}
resource "aws_route_table_association" "staging-cf-db-1" {
  subnet_id      = "${aws_subnet.staging-cf-db-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-db-1.subnet" {
  value = "${aws_subnet.staging-cf-db-1.id}"
}
resource "aws_subnet" "staging-cf-db-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.45.32/28"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-staging-cf-db-2" }
}
resource "aws_route_table_association" "staging-cf-db-2" {
  subnet_id      = "${aws_subnet.staging-cf-db-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.staging-cf-db-2.subnet" {
  value = "${aws_subnet.staging-cf-db-2.id}"
}
resource "aws_db_subnet_group" "staging-cf-db" {
    name = "${var.aws_vpc_name}-staging-cf-db"
    description = "Managed by Terraform"
    subnet_ids = ["${aws_subnet.staging-cf-db-0.id}", "${aws_subnet.staging-cf-db-1.id}", "${aws_subnet.staging-cf-db-2.id}"]
    tags { Name = "${var.aws_vpc_name}-staging-cf-db" }
}
output "aws.rds.staging-cf-db.db_subnet_group" {
  value = "${aws_db_subnet_group.staging-cf-db.id}"
}

###############################################################
# PROD-INFRA - Production Site Infrastructure
#
#  Primarily used for BOSH directors, deployed by proto-BOSH
#
#  Also reserved for situations where you prefer to have
#  dedicated, per-site infrastructure (SHIELD, Bolo, etc.)
#
#  Three zone-isolated networks are provided for HA and
#  fault-tolerance in deployments that support / require it.
#
resource "aws_subnet" "prod-infra-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.48.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-infra-0" }
}
resource "aws_route_table_association" "prod-infra-0" {
  subnet_id      = "${aws_subnet.prod-infra-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-infra-0.subnet" {
  value = "${aws_subnet.prod-infra-0.id}"
}
resource "aws_subnet" "prod-infra-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.49.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-infra-1" }
}
resource "aws_route_table_association" "prod-infra-1" {
  subnet_id      = "${aws_subnet.prod-infra-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-infra-1.subnet" {
  value = "${aws_subnet.prod-infra-1.id}"
}
resource "aws_subnet" "prod-infra-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.50.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-infra-2" }
}
resource "aws_route_table_association" "prod-infra-2" {
  subnet_id      = "${aws_subnet.prod-infra-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-infra-2.subnet" {
  value = "${aws_subnet.prod-infra-2.id}"
}

###############################################################
# PROD-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#
resource "aws_subnet" "prod-cf-edge-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.51.0/25"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-edge-0" }
}
resource "aws_route_table_association" "prod-cf-edge-0" {
  subnet_id      = "${aws_subnet.prod-cf-edge-0.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.prod-cf-edge-0.subnet" {
  value = "${aws_subnet.prod-cf-edge-0.id}"
}
resource "aws_subnet" "prod-cf-edge-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.51.128/25"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-edge-1" }
}
resource "aws_route_table_association" "prod-cf-edge-1" {
  subnet_id      = "${aws_subnet.prod-cf-edge-1.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.prod-cf-edge-1.subnet" {
  value = "${aws_subnet.prod-cf-edge-1.id}"
}

###############################################################
# PROD-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#
resource "aws_subnet" "prod-cf-core-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.52.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-core-0" }
}
resource "aws_route_table_association" "prod-cf-core-0" {
  subnet_id      = "${aws_subnet.prod-cf-core-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-core-0.subnet" {
  value = "${aws_subnet.prod-cf-core-0.id}"
}
resource "aws_subnet" "prod-cf-core-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.53.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-core-1" }
}
resource "aws_route_table_association" "prod-cf-core-1" {
  subnet_id      = "${aws_subnet.prod-cf-core-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-core-1.subnet" {
  value = "${aws_subnet.prod-cf-core-1.id}"
}
resource "aws_subnet" "prod-cf-core-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.54.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-core-2" }
}
resource "aws_route_table_association" "prod-cf-core-2" {
  subnet_id      = "${aws_subnet.prod-cf-core-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-core-2.subnet" {
  value = "${aws_subnet.prod-cf-core-2.id}"
}

###############################################################
# PROD-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "aws_subnet" "prod-cf-runtime-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.55.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-runtime-0" }
}
resource "aws_route_table_association" "prod-cf-runtime-0" {
  subnet_id      = "${aws_subnet.prod-cf-runtime-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-runtime-0.subnet" {
  value = "${aws_subnet.prod-cf-runtime-0.id}"
}
resource "aws_subnet" "prod-cf-runtime-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.56.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-runtime-1" }
}
resource "aws_route_table_association" "prod-cf-runtime-1" {
  subnet_id      = "${aws_subnet.prod-cf-runtime-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-runtime-1.subnet" {
  value = "${aws_subnet.prod-cf-runtime-1.id}"
}
resource "aws_subnet" "prod-cf-runtime-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.57.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-runtime-2" }
}
resource "aws_route_table_association" "prod-cf-runtime-2" {
  subnet_id      = "${aws_subnet.prod-cf-runtime-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-runtime-2.subnet" {
  value = "${aws_subnet.prod-cf-runtime-2.id}"
}

###############################################################
# PROD-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#
resource "aws_subnet" "prod-cf-svc-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.58.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-svc-0" }
}
resource "aws_route_table_association" "prod-cf-svc-0" {
  subnet_id      = "${aws_subnet.prod-cf-svc-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-svc-0.subnet" {
  value = "${aws_subnet.prod-cf-svc-0.id}"
}
resource "aws_subnet" "prod-cf-svc-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.59.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-svc-1" }
}
resource "aws_route_table_association" "prod-cf-svc-1" {
  subnet_id      = "${aws_subnet.prod-cf-svc-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-svc-1.subnet" {
  value = "${aws_subnet.prod-cf-svc-1.id}"
}
resource "aws_subnet" "prod-cf-svc-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.60.0/24"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-svc-2" }
}
resource "aws_route_table_association" "prod-cf-svc-2" {
  subnet_id      = "${aws_subnet.prod-cf-svc-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-svc-2.subnet" {
  value = "${aws_subnet.prod-cf-svc-2.id}"
}

###############################################################
# PROD-CF-DB - Cloud Foundry Databases
#
#  These subnets house the internal Cloud Foundry
#  databases (either MySQL release or RDS DBs).
#
resource "aws_subnet" "prod-cf-db-0" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.61.0/28"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-db-0" }
}
resource "aws_route_table_association" "prod-cf-db-0" {
  subnet_id      = "${aws_subnet.prod-cf-db-0.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-db-0.subnet" {
  value = "${aws_subnet.prod-cf-db-0.id}"
}
resource "aws_subnet" "prod-cf-db-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.61.16/28"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-db-1" }
}
resource "aws_route_table_association" "prod-cf-db-1" {
  subnet_id      = "${aws_subnet.prod-cf-db-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-db-1.subnet" {
  value = "${aws_subnet.prod-cf-db-1.id}"
}
resource "aws_subnet" "prod-cf-db-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.61.32/28"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-db-2" }
}
resource "aws_route_table_association" "prod-cf-db-2" {
  subnet_id      = "${aws_subnet.prod-cf-db-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
output "aws.network.prod-cf-db-2.subnet" {
  value = "${aws_subnet.prod-cf-db-2.id}"
}
resource "aws_db_subnet_group" "prod-cf-db" {
    name = "${var.aws_vpc_name}-prod-cf-db"
    description = "Managed by Terraform"
    subnet_ids = ["${aws_subnet.prod-cf-db-0.id}", "${aws_subnet.prod-cf-db-1.id}", "${aws_subnet.prod-cf-db-2.id}"]
    tags { Name = "${var.aws_vpc_name}-prod-cf-db" }
}
output "aws.rds.prod-cf-db.db_subnet_group" {
  value = "${aws_db_subnet_group.prod-cf-db.id}"
}


##    ##    ###     ######  ##        ######
###   ##   ## ##   ##    ## ##       ##    ##
####  ##  ##   ##  ##       ##       ##
## ## ## ##     ## ##       ##        ######
##  #### ######### ##       ##             ##
##   ### ##     ## ##    ## ##       ##    ##
##    ## ##     ##  ######  ########  ######

resource "aws_network_acl" "hardened" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.dev-infra-0.id}",
    "${aws_subnet.dev-infra-1.id}",
    "${aws_subnet.dev-infra-2.id}",
    "${aws_subnet.dev-cf-edge-0.id}",
    "${aws_subnet.dev-cf-edge-1.id}",
    "${aws_subnet.dev-cf-core-0.id}",
    "${aws_subnet.dev-cf-core-1.id}",
    "${aws_subnet.dev-cf-core-2.id}",
    "${aws_subnet.dev-cf-runtime-0.id}",
    "${aws_subnet.dev-cf-runtime-1.id}",
    "${aws_subnet.dev-cf-runtime-2.id}",
    "${aws_subnet.dev-cf-svc-0.id}",
    "${aws_subnet.dev-cf-svc-1.id}",
    "${aws_subnet.dev-cf-svc-2.id}",

    "${aws_subnet.staging-infra-0.id}",
    "${aws_subnet.staging-infra-1.id}",
    "${aws_subnet.staging-infra-2.id}",
    "${aws_subnet.staging-cf-edge-0.id}",
    "${aws_subnet.staging-cf-edge-1.id}",
    "${aws_subnet.staging-cf-core-0.id}",
    "${aws_subnet.staging-cf-core-1.id}",
    "${aws_subnet.staging-cf-core-2.id}",
    "${aws_subnet.staging-cf-runtime-0.id}",
    "${aws_subnet.staging-cf-runtime-1.id}",
    "${aws_subnet.staging-cf-runtime-2.id}",
    "${aws_subnet.staging-cf-svc-0.id}",
    "${aws_subnet.staging-cf-svc-1.id}",
    "${aws_subnet.staging-cf-svc-2.id}",

    "${aws_subnet.prod-infra-0.id}",
    "${aws_subnet.prod-infra-1.id}",
    "${aws_subnet.prod-infra-2.id}",
    "${aws_subnet.prod-cf-edge-0.id}",
    "${aws_subnet.prod-cf-edge-1.id}",
    "${aws_subnet.prod-cf-core-0.id}",
    "${aws_subnet.prod-cf-core-1.id}",
    "${aws_subnet.prod-cf-core-2.id}",
    "${aws_subnet.prod-cf-runtime-0.id}",
    "${aws_subnet.prod-cf-runtime-1.id}",
    "${aws_subnet.prod-cf-runtime-2.id}",
    "${aws_subnet.prod-cf-svc-0.id}",
    "${aws_subnet.prod-cf-svc-1.id}",
    "${aws_subnet.prod-cf-svc-2.id}"
  ]
  tags { Name = "${var.aws_vpc_name}-hardened" }



  #### ##    ##  ######   ########  ########  ######   ######
   ##  ###   ## ##    ##  ##     ## ##       ##    ## ##    ##
   ##  ####  ## ##        ##     ## ##       ##       ##
   ##  ## ## ## ##   #### ########  ######    ######   ######
   ##  ##  #### ##    ##  ##   ##   ##             ##       ##
   ##  ##   ### ##    ##  ##    ##  ##       ##    ## ##    ##
  #### ##    ##  ######   ##     ## ########  ######   ######

  # Allow ICMP Echo Reply packets (type 0)
  # (response to ping/tracepath)
  ingress {
    rule_no    = "1"
    protocol   = "icmp"
    icmp_type  = "0"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Destination Unreachable (type 3) packets
  # (host/net unreachables, port closed, fragmentation
  #  issues, etc.)
  ingress {
    rule_no    = "2"
    protocol   = "icmp"
    icmp_type  = "3"
    icmp_code  = "-1"

    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Echo packets (type 8)
  # (ping/tracepath initiator)
  ingress {
    rule_no    = "3"
    protocol   = "icmp"
    icmp_type  = "8"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Time Exceeded (type 11)
  # (tracepath TTL issue)
  ingress {
    rule_no    = "4"
    protocol   = "icmp"
    icmp_type  = "11"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow SSH traffic from the Bastion Host (in the DMZ)
  ingress {
    rule_no    = "101"
    protocol   = "tcp"
    from_port  = "22"
    to_port    = "22"
    cidr_block = "${aws_instance.bastion.private_ip}/32"
    action     = "allow"
  }

  # OTHER RULES NEEDED:
  #  - BOSH (for proto-BOSH to deploy BOSH directors)
  #  - SHIELD (for backups to/from infranet)
  #  - Bolo (to submit monitoring egress to infranet)
  #  - Concourse (either direct acccess to BOSH, or worker communication)
  #  - Vault (jumpboxen need to get to Vault for creds.  also, concourse workers)

  # All other traffic is blocked by an implicit
  # Block all other traffic.



  ########  ######   ########  ########  ######   ######
  ##       ##    ##  ##     ## ##       ##    ## ##    ##
  ##       ##        ##     ## ##       ##       ##
  ######   ##   #### ########  ######    ######   ######
  ##       ##    ##  ##   ##   ##             ##       ##
  ##       ##    ##  ##    ##  ##       ##    ## ##    ##
  ########  ######   ##     ## ########  ######   ######

  # Allow ICMP Echo Reply packets (type 0)
  # (response to ping/tracepath)
  egress {
    rule_no    = "1"
    protocol   = "icmp"
    icmp_type  = "0"
    icmp_code  = "-1"
    to_port    = "0"
    from_port  = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Destination Unreachable (type 3) packets
  # (host/net unreachables, port closed, fragmentation
  #  issues, etc.)
  egress {
    rule_no    = "2"
    protocol   = "icmp"
    icmp_type  = "3"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Echo packets (type 8)
  # (ping/tracepath initiator)
  egress {
    rule_no    = "3"
    protocol   = "icmp"
    icmp_type  = "8"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Time Exceeded (type 11)
  # (tracepath TTL issue)
  egress {
    rule_no    = "4"
    protocol   = "icmp"
    icmp_type  = "11"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow return traffic on ephemeral ports.
  # (Linux kernels use 32768-61000 for ephemeral ports)
  egress {
    rule_no    = "101"
    protocol   = "tcp"
    from_port  = "32768"
    to_port    = "65535"
    cidr_block = "0.0.0.0/0" # FIXME: lockdown to prod / bastion
    action     = "allow"
  }
  egress {
    rule_no    = "102"
    protocol   = "udp"
    from_port  = "32768"
    to_port    = "65535"
    cidr_block = "0.0.0.0/0" # FIXME: lockdown to prod / bastion
    action     = "allow"
  }

  # All other traffic is blocked by an implicit
  # DENY rule in the Network ACL (inside of AWS)
}



 ######  ########  ######          ######   ########   #######  ##     ## ########   ######
##    ## ##       ##    ##        ##    ##  ##     ## ##     ## ##     ## ##     ## ##    ##
##       ##       ##              ##        ##     ## ##     ## ##     ## ##     ## ##
 ######  ######   ##              ##   #### ########  ##     ## ##     ## ########   ######
      ## ##       ##              ##    ##  ##   ##   ##     ## ##     ## ##              ##
##    ## ##       ##    ## ###    ##    ##  ##    ##  ##     ## ##     ## ##        ##    ##
 ######  ########  ######  ###     ######   ##     ##  #######   #######  ##         ######

resource "aws_security_group" "dmz" {
  name        = "dmz"
  description = "Allow services from the private subnet through NAT"
  vpc_id      = "${aws_vpc.default.id}"
  tags { Name = "${var.aws_vpc_name}-dmz" }

  # ICMP traffic control
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow SSH traffic into the NAT box
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all traffic through the NAT from inside the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.network}.0.0/16"]
  }


  # ICMP traffic control (outbound)
  # Allows diagnostic utilities like ping / traceroute
  # to function as expected, and aid in troubleshooting.
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow *ALL* outbound TCP traffic.
  # (security ppl may not like this...)
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow *ALL* outbound UDP traffic.
  # (security ppl may not like this...)
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "wide-open" {
  name        = "wide-open"
  description = "Allow everything in and out"
  vpc_id      = "${aws_vpc.default.id}"
  tags { Name = "${var.aws_vpc_name}-wide-open" }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "cf-db" {
  name        = "cf-db"
  description = "Allow only ingress access to the MySQL port"
  vpc_id      = "${aws_vpc.default.id}"
  tags { Name = "${var.aws_vpc_name}-cf-db" }

  ingress {
    from_port   = 5432 
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "cf-elb" {
  name        = "cf-elb"
  description = "Allow 80,443 and 4443 in"
  vpc_id      = "${aws_vpc.default.id}"
  tags { Name = "${var.aws_vpc_name}-cf-elb" }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 4443
    to_port     = 4443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "cf-ssh-elb" {
  name = "cf-ssh-elb"
  description = "Allow only 2222 in"
  vpc_id = "${aws_vpc.default.id}"
  tags { Name = "${var.aws_vpc_name}-cf-ssh-elb" }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "openvpn" {
  name = "openvpn"
  description = "Allow only 443 in"
  vpc_id = "${aws_vpc.default.id}"
  tags { Name = "${var.aws_vpc_name}-openvpn" }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



##    ##    ###    ########
###   ##   ## ##      ##
####  ##  ##   ##     ##
## ## ## ##     ##    ##
##  #### #########    ##
##   ### ##     ##    ##
##    ## ##     ##    ##

resource "aws_instance" "nat" {
  ami             = "${lookup(var.aws_nat_ami, var.aws_region)}"
  instance_type   = "t2.small"
  key_name        = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.dmz.id}"]
  subnet_id       = "${aws_subnet.dmz.id}"

  associate_public_ip_address = true
  source_dest_check           = false

  tags { Name = "nat" }
}
resource "aws_eip" "nat" {
  instance = "${aws_instance.nat.id}"
  vpc      = true
}
output "box.nat.public" {
  value = "${aws_eip.nat.public_ip}"
}



########  ########   ######
##     ## ##     ## ##    ##
##     ## ##     ## ##
########  ##     ##  ######
##   ##   ##     ##       ##
##    ##  ##     ## ##    ##
##     ## ########   ######

###############################################################
# DEV-CF-DB AWS RDS PostgreSql DB
#
resource "aws_db_instance" "dev-cf-db" {
  count                   = "${var.aws_rds_dev_enabled}"
  identifier              = "${var.aws_vpc_name}-dev-cf-db"
  allocated_storage       = 50
  engine                  = "postgres"
  engine_version          = "9.5.2"
  instance_class          = "${var.aws_rds_dev_instance_class}"
  username                = "${var.aws_rds_master_user}"
  password                = "${var.aws_rds_dev_master_password}" 
  port                    = "5432"
  db_subnet_group_name    = "${aws_db_subnet_group.dev-cf-db.name}"
  multi_az                = true
  vpc_security_group_ids  = ["${aws_security_group.cf-db.id}"]
  backup_retention_period = 5
}

output "aws.rds.dev-cf-db.endpoint" {
  value = "${aws_db_instance.dev-cf-db.endpoint}"
}

###############################################################
# STAGING-CF-DB AWS RDS PostgreSql DB
#
resource "aws_db_instance" "staging-cf-db" {
  count                   = "${var.aws_rds_staging_enabled}"
  identifier              = "${var.aws_vpc_name}-staging-cf-db"
  allocated_storage       = 50
  engine                  = "postgres"
  engine_version          = "9.5.2"
  instance_class          = "${var.aws_rds_staging_instance_class}"
  username                = "${var.aws_rds_master_user}"
  password                = "${var.aws_rds_staging_master_password}" 
  port                    = "5432"
  db_subnet_group_name    = "${aws_db_subnet_group.staging-cf-db.name}"
  multi_az                = true 
  vpc_security_group_ids  = ["${aws_security_group.cf-db.id}"]
  backup_retention_period = 5
}

output "aws.rds.staging-cf-db.endpoint" {
  value = "${aws_db_instance.staging-cf-db.endpoint}"
}

###############################################################
# PROD-CF-DB AWS RDS PostgreSql DB
#
resource "aws_db_instance" "prod-cf-db" {
  count                   = "${var.aws_rds_prod_enabled}"
  identifier              = "${var.aws_vpc_name}-prod-cf-db"
  allocated_storage       = 50
  engine                  = "postgres"
  engine_version          = "9.5.2"
  instance_class          = "${var.aws_rds_prod_instance_class}"
  username                = "${var.aws_rds_master_user}"
  password                = "${var.aws_rds_prod_master_password}" 
  port                    = "5432"
  db_subnet_group_name    = "${aws_db_subnet_group.prod-cf-db.name}"
  multi_az                = true
  vpc_security_group_ids  = ["${aws_security_group.cf-db.id}"]
  backup_retention_period = 5
}

output "aws.rds.prod-cf-db.endpoint" {
  value = "${aws_db_instance.prod-cf-db.endpoint}"
}

######## ##       ########
##       ##       ##     ##
##       ##       ##     ##
######   ##       ########
##       ##       ##     ##
##       ##       ##     ##
######## ######## ########

###############################################################
# DEV-CF-ELB Elastic Load Balancer
#
resource "aws_iam_server_certificate" "dev-cf-elb-cert" {
  count            = "${var.aws_elb_dev_enabled}"
  name_prefix      = "${var.aws_vpc_name}-dev-cf-elb-cert"
  certificate_body = "${file("${var.aws_elb_dev_cert_path}")}"
  private_key      = "${file("${var.aws_elb_dev_private_key_path}")}"
  lifecycle {
   create_before_destroy = true
  }
}
resource "aws_elb" "dev-cf-elb" {
  count                     = "${var.aws_elb_dev_enabled}"
  name                      = "${var.aws_vpc_name}-dev-cf-elb"
  security_groups           = ["${aws_security_group.cf-elb.id}"]
  subnets                   = ["${aws_subnet.dev-cf-edge-0.id}","${aws_subnet.dev-cf-edge-1.id}"]
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    target              = "TCP:80"
    interval            = 30
    timeout             = 5
  }
  listener {
    instance_port      = 80
    instance_protocol  = "HTTP"
    lb_port            = 80
    lb_protocol        = "HTTP"
  }
  listener {
    instance_port      = 80
    instance_protocol  = "HTTP"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = "${aws_iam_server_certificate.dev-cf-elb-cert.arn}"
  }
  listener {
    instance_port      = 80
    instance_protocol  = "TCP"
    lb_port            = 4443
    lb_protocol        = "SSL"
    ssl_certificate_id = "${aws_iam_server_certificate.dev-cf-elb-cert.arn}"
  }
  tags { Name = "${var.aws_vpc_name}-dev-cf-elb" }
}
output "aws.elb.dev-cf-elb.dns_name" {
  value = "${aws_elb.dev-cf-elb.dns_name}"
}
resource "aws_elb" "dev-cf-ssh-elb" {
  count                     = "${var.aws_elb_dev_enabled}"
  name                      = "${var.aws_vpc_name}-dev-cf-ssh-elb"
  security_groups           = ["${aws_security_group.cf-ssh-elb.id}"]
  subnets                   = ["${aws_subnet.dev-cf-edge-0.id}","${aws_subnet.dev-cf-edge-1.id}"]
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    target              = "TCP:2222"
    interval            = 30
    timeout             = 5
  }
  listener {
    instance_port      = 2222
    instance_protocol  = "TCP"
    lb_port            = 2222
    lb_protocol        = "TCP"
  }
  tags { Name = "${var.aws_vpc_name}-dev-cf-ssh-elb" }
}
output "aws.elb.dev-cf-ssh-elb.dns_name" {
  value = "${aws_elb.dev-cf-ssh-elb.dns_name}"
}

###############################################################
# STAGING-CF-ELB Elastic Load Balancer
#
resource "aws_iam_server_certificate" "staging-cf-elb-cert" {
  count            = "${var.aws_elb_staging_enabled}"
  name_prefix      = "${var.aws_vpc_name}-staging-cf-elb-cert"
  certificate_body = "${file("${var.aws_elb_staging_cert_path}")}"
  private_key      = "${file("${var.aws_elb_staging_private_key_path}")}"
  lifecycle {
   create_before_destroy = true
  }
}
resource "aws_elb" "staging-cf-elb" {
  count                     = "${var.aws_elb_staging_enabled}"
  name                      = "${var.aws_vpc_name}-staging-cf-elb"
  security_groups           = ["${aws_security_group.cf-elb.id}"]
  subnets                   = ["${aws_subnet.staging-cf-edge-0.id}","${aws_subnet.staging-cf-edge-1.id}"]
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    target              = "TCP:80"
    interval            = 30
    timeout             = 5
  }
  listener {
    instance_port      = 80
    instance_protocol  = "HTTP"
    lb_port            = 80
    lb_protocol        = "HTTP"
  }
  listener {
    instance_port      = 80
    instance_protocol  = "HTTP"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = "${aws_iam_server_certificate.staging-cf-elb-cert.arn}"
  }
  listener {
    instance_port      = 80
    instance_protocol  = "TCP"
    lb_port            = 4443
    lb_protocol        = "SSL"
    ssl_certificate_id = "${aws_iam_server_certificate.staging-cf-elb-cert.arn}"
  }
  tags { Name = "${var.aws_vpc_name}-staging-cf-elb" }
}
output "aws.elb.staging-cf-elb.dns_name" {
  value = "${aws_elb.staging-cf-elb.dns_name}"
}
resource "aws_elb" "staging-cf-ssh-elb" {
  count                     = "${var.aws_elb_staging_enabled}"
  name                      = "${var.aws_vpc_name}-staging-cf-ssh-elb"
  security_groups           = ["${aws_security_group.cf-ssh-elb.id}"]
  subnets                   = ["${aws_subnet.staging-cf-edge-0.id}","${aws_subnet.staging-cf-edge-1.id}"]
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    target              = "TCP:2222"
    interval            = 30
    timeout             = 5
  }
  listener {
    instance_port      = 2222
    instance_protocol  = "TCP"
    lb_port            = 2222
    lb_protocol        = "TCP"
  }
  tags { Name = "${var.aws_vpc_name}-staging-cf-ssh-elb" }
}
output "aws.elb.staging-cf-ssh-elb.dns_name" {
  value = "${aws_elb.staging-cf-ssh-elb.dns_name}"
}

###############################################################
# PROD-CF-ELB Elastic Load Balancer
#
resource "aws_iam_server_certificate" "prod-cf-elb-cert" {
  count            = "${var.aws_elb_prod_enabled}"
  name_prefix      = "${var.aws_vpc_name}-prod-cf-elb-cert"
  certificate_body = "${file("${var.aws_elb_prod_cert_path}")}"
  private_key      = "${file("${var.aws_elb_prod_private_key_path}")}"
  lifecycle {
   create_before_destroy = true
  }
}
resource "aws_elb" "prod-cf-elb" {
  count                     = "${var.aws_elb_prod_enabled}"
  name                      = "${var.aws_vpc_name}-prod-cf-elb"
  security_groups           = ["${aws_security_group.cf-elb.id}"]
  subnets                   = ["${aws_subnet.prod-cf-edge-0.id}","${aws_subnet.prod-cf-edge-1.id}"]
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    target              = "TCP:80"
    interval            = 30
    timeout             = 5
  }
  listener {
    instance_port      = 80
    instance_protocol  = "HTTP"
    lb_port            = 80
    lb_protocol        = "HTTP"
  }
  listener {
    instance_port      = 80
    instance_protocol  = "HTTP"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = "${aws_iam_server_certificate.prod-cf-elb-cert.arn}"
  }
  listener {
    instance_port      = 80
    instance_protocol  = "TCP"
    lb_port            = 4443
    lb_protocol        = "SSL"
    ssl_certificate_id = "${aws_iam_server_certificate.prod-cf-elb-cert.arn}"
  }
  tags { Name = "${var.aws_vpc_name}-prod-cf-elb" }
}
output "aws.elb.prod-cf-elb.dns_name" {
  value = "${aws_elb.prod-cf-elb.dns_name}"
}
resource "aws_elb" "prod-cf-ssh-elb" {
  count                     = "${var.aws_elb_prod_enabled}"
  name                      = "${var.aws_vpc_name}-prod-cf-ssh-elb"
  security_groups           = ["${aws_security_group.cf-ssh-elb.id}"]
  subnets                   = ["${aws_subnet.prod-cf-edge-0.id}","${aws_subnet.prod-cf-edge-1.id}"]
  cross_zone_load_balancing = true
  idle_timeout              = 3600
  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    target              = "TCP:2222"
    interval            = 30
    timeout             = 5
  }
  listener {
    instance_port      = 2222
    instance_protocol  = "TCP"
    lb_port            = 2222
    lb_protocol        = "TCP"
  }
  tags { Name = "${var.aws_vpc_name}-prod-cf-ssh-elb" }
}
output "aws.elb.prod-cf-ssh-elb.dns_name" {
  value = "${aws_elb.prod-cf-ssh-elb.dns_name}"
}



########   #######  ##     ## ######## ########    ########  #######
##     ## ##     ## ##     ##    ##    ##          ##       ##     ##
##     ## ##     ## ##     ##    ##    ##          ##              ##
########  ##     ## ##     ##    ##    ######      #######   #######
##   ##   ##     ## ##     ##    ##    ##                ##        ##
##    ##  ##     ## ##     ##    ##    ##          ##    ## ##     ##
##     ##  #######   #######     ##    ########     ######   #######

###############################################################
# DEV-CF-ROUTE53 Route53 CNAME
#
resource "aws_route53_record" "dev-cf-cname" {
   count   = "${var.aws_route53_dev_enabled}"
   zone_id = "${var.aws_route53_dev_hosted_zone_id}"
   name    = "*.dev"
   type    = "CNAME"
   ttl     = "300"
   records = ["${aws_elb.dev-cf-elb.dns_name}"]
}

###############################################################
# STAGING-CF-ROUTE53 Route53 CNAME
#
resource "aws_route53_record" "staging-cf-cname" {
   count   = "${var.aws_route53_staging_enabled}"
   zone_id = "${var.aws_route53_staging_hosted_zone_id}"
   name    = "*.staging"
   type    = "CNAME"
   ttl     = "300"
   records = ["${aws_elb.staging-cf-elb.dns_name}"]
}

###############################################################
# PROD-CF-ROUTE53 Route53 CNAME
#
resource "aws_route53_record" "prod-cf-cname" {
   count   = "${var.aws_route53_prod_enabled}"
   zone_id = "${var.aws_route53_prod_hosted_zone_id}"
   name    = "*.prod"
   type    = "CNAME"
   ttl     = "300"
   records = ["${aws_elb.prod-cf-elb.dns_name}"]
}



########     ###     ######  ######## ####  #######  ##    ##
##     ##   ## ##   ##    ##    ##     ##  ##     ## ###   ##
##     ##  ##   ##  ##          ##     ##  ##     ## ####  ##
########  ##     ##  ######     ##     ##  ##     ## ## ## ##
##     ## #########       ##    ##     ##  ##     ## ##  ####
##     ## ##     ## ##    ##    ##     ##  ##     ## ##   ###
########  ##     ##  ######     ##    ####  #######  ##    ##

resource "aws_instance" "bastion" {
  ami                         = "${lookup(var.aws_ubuntu_ami, var.aws_region)}"
  instance_type               = "t2.small"
  key_name                    = "${var.aws_key_name}"
  vpc_security_group_ids      = ["${aws_security_group.dmz.id}"]
  subnet_id                   = "${aws_subnet.dmz.id}"
  associate_public_ip_address = true

  tags { Name = "bastion" }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -o /usr/local/bin/jumpbox https://raw.githubusercontent.com/starkandwayne/jumpbox/master/bin/jumpbox",
      "sudo chmod 0755 /usr/local/bin/jumpbox",
      "sudo jumpbox system"
    ]
    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file("${var.aws_key_file}")}"
    }
  }
  provisioner "file" {
    source = "${var.aws_key_file}"
    destination = "/home/ubuntu/.ssh/bosh.pem"
    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file("${var.aws_key_file}")}"
    }
  }
}
output "box.bastion.public" {
  value = "${aws_instance.bastion.public_ip}"
}
