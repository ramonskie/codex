
variable "network"          { default = "10.4" }      # First 2 octets of your /16

variable "tenant_name"      { default = "codex"}
variable "user_name"        { default = "admin"}
variable "password"         { default = "supersecret"}
variable "auth_url"         { default = ""}
variable "key_pair"         { default = "codex"}
variable "bastion_image"    { default = "ubuntu-16.04"}
variable "bastion_name"     { default = "bastion"}
variable "region"           { default = "RegionOne"}

variable "pub_net_uuid"     { default = ""}

provider "openstack" {
    user_name  = "${var.user_name}"
    tenant_name = "${var.tenant_name}"
    password  = "${var.password}"
    auth_url  = "${var.auth_url}"
}


######################################
#         Security Groups
#####################################

resource "openstack_networking_secgroup_v2" "dmz" {
  name = "dmz"
  description = "Allow services from the private subnet through NAT"
}

resource "openstack_networking_secgroup_rule_v2" "icmp_traffic_ingress" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "icmp"                    # Required if specifying port range
  region = "${var.region}"
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.dmz.id}"
}

resource "openstack_networking_secgroup_rule_v2" "nat_ssh_ingress" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"                    # Required if specifying port range
  port_range_min = 22
  port_range_max = 22
  region = "${var.region}"
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.dmz.id}"
}

resource "openstack_networking_secgroup_rule_v2" "vpc_tcp_ingress" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"                    # Required if specifying port range
  port_range_min = 1
  port_range_max = 65535
  region = "${var.region}" 
  remote_ip_prefix = "${var.network}.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.dmz.id}"
}

resource "openstack_networking_secgroup_rule_v2" "vpc_udp_ingress" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "udp"                    # Required if specifying port range
  port_range_min = 1
  port_range_max = 65535
  region = "${var.region}" 
  remote_ip_prefix = "${var.network}.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.dmz.id}"
}

resource "openstack_networking_secgroup_rule_v2" "tcp_egress" {
  direction = "egress"
  ethertype = "IPv4"
  protocol = "tcp"                    # Required if specifying port range
  port_range_min = 1
  port_range_max = 65535
  region = "${var.region}" 
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.dmz.id}"
}

resource "openstack_networking_secgroup_rule_v2" "udp_egress" {
  direction = "egress"
  ethertype = "IPv4"
  protocol = "udp"                    # Required if specifying port range
  port_range_min = 1
  port_range_max = 65535
  region = "${var.region}" 
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.dmz.id}"
}

resource "openstack_networking_secgroup_v2" "wide-open" {
  name = "wide-open"
  description = "Allow everything in and out"
}

resource "openstack_networking_secgroup_rule_v2" "wide-open_ingress" {
  direction = "ingress"
  ethertype = "IPv4"
  region = "${var.region}"
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.wide-open.id}"
}

resource "openstack_networking_secgroup_rule_v2" "wide-open_ingress-IPv6" {
  direction = "ingress"
  ethertype = "IPv6"
  region = "${var.region}"
  security_group_id = "${openstack_networking_secgroup_v2.wide-open.id}"
}

resource "openstack_networking_secgroup_rule_v2" "wide-open_egress" {
  direction = "egress"
  ethertype = "IPv4"
  region = "${var.region}"
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.wide-open.id}"
}

resource "openstack_networking_secgroup_rule_v2" "wide-open_egress-IPv6" {
  direction = "egress"
  ethertype = "IPv6"
  region = "${var.region}"
  security_group_id = "${openstack_networking_secgroup_v2.wide-open.id}"
}

resource "openstack_networking_secgroup_v2" "cf-db" {
  name = "cf-db"
  description = "Allow access to the MySQL port"
}

resource "openstack_networking_secgroup_rule_v2" "cf-db_ingress" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"                    # Required if specifying port range
  port_range_min = 3306
  port_range_max = 3306
  region = "${var.region}" 
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.cf-db.id}"
}

resource "openstack_networking_secgroup_v2" "openvpn" {
  name = "openvpn"
  description = "Allow HTTPS in and out"
}

resource "openstack_networking_secgroup_rule_v2" "openvpn_ingress" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"                    # Required if specifying port range
  port_range_min = 443
  port_range_max = 443
  region = "${var.region}" 
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.openvpn.id}"
}

###############################
#      Networked Subnets
###############################

#########   DMZ  ############

resource "openstack_networking_network_v2" "dmz" {
  name = "dmz"
}

resource "openstack_networking_subnet_v2" "dmz-subnet" {
  name = "dmz-subnet"
  network_id = "${openstack_networking_network_v2.dmz.id}"
  cidr = "${var.network}.0.0/24"
}

output "openstack_networking_network_v2.dmz.dmz-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dmz-subnet.id}"
}

resource "openstack_networking_port_v2" "dmz-port" {
  name = "dmz-port"
  network_id = "${openstack_networking_network_v2.dmz.id}"
}

######### Global ############


resource "openstack_networking_network_v2" "global-infra-0" {
  name = "global-infra-0"
}

resource "openstack_networking_subnet_v2" "global-infra-0-subnet" {
  name = "global-infra-0-subnet"
  network_id = "${openstack_networking_network_v2.global-infra-0.id}"
  cidr = "${var.network}.1.0/24"
  dns_nameservers = ["8.8.8.8","8.8.4.4"]
}

resource "openstack_networking_port_v2" "global-infra-0-port" {
  name = "global-infra-0-port"
  network_id = "${openstack_networking_network_v2.global-infra-0.id}"
}

output "openstack_networking_network_v2.global-infra-0.global-infra-0-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.global-infra-0-subnet.id}"
}

resource "openstack_networking_network_v2" "global-infra-1" {
  name = "global-infra-1"
}

resource "openstack_networking_subnet_v2" "global-infra-1-subnet" {
  name = "global-infra-1-subnet"
  network_id = "${openstack_networking_network_v2.global-infra-1.id}"
  cidr = "${var.network}.2.0/24"
  dns_nameservers = ["8.8.8.8","8.8.4.4"]
}

resource "openstack_networking_port_v2" "global-infra-1-port" {
  name = "global-infra-1-port"
  network_id = "${openstack_networking_network_v2.global-infra-1.id}"
}

output "openstack_networking_network_v2.global-infra-1.global-infra-1-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.global-infra-1-subnet.id}"
}

resource "openstack_networking_network_v2" "global-infra-2" {
  name = "global-infra-2"
}

resource "openstack_networking_subnet_v2" "global-infra-2-subnet" {
  name = "global-infra-2-subnet"
  network_id = "${openstack_networking_network_v2.global-infra-2.id}"
  cidr = "${var.network}.3.0/24"
  dns_nameservers = ["8.8.8.8","8.8.4.4"]
}

resource "openstack_networking_port_v2" "global-infra-2-port" {
  name = "global-infra-2-port"
  network_id = "${openstack_networking_network_v2.global-infra-2.id}"
}

output "openstack_networking_network_v2.global-infra-2.global-infra-2-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.global-infra-2-subnet.id}"
}

resource "openstack_networking_network_v2" "global-openvpn-0" {
  name = "global-openvpn-0"
}

resource "openstack_networking_subnet_v2" "global-openvpn-0-subnet" {
  name = "global-openvpn-0-subnet"
  network_id = "${openstack_networking_network_v2.global-openvpn-0.id}"
  cidr = "${var.network}.4.0/25"
}

output "openstack_networking_network_v2.global-openvpn-0.global-openvpn-0-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.global-openvpn-0-subnet.id}"
}

resource "openstack_networking_network_v2" "global-openvpn-1" {
  name = "global-openvpn-1"
}

resource "openstack_networking_subnet_v2" "global-openvpn-1-subnet" {
  name = "global-openvpn-1-subnet"
  network_id = "${openstack_networking_network_v2.global-openvpn-1.id}"
  cidr = "${var.network}.4.128/25"
}

output "openstack_networking_network_v2.global-openvpn-1.global-openvpn-1-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.global-openvpn-1-subnet.id}"
}

######## Development ##########

########  DEV-INFRA  ##########

resource "openstack_networking_network_v2" "dev-infra-0" {
  name = "dev-infra-0"
}

resource "openstack_networking_subnet_v2" "dev-infra-0-subnet" {
  name = "dev-infra-0-subnet"
  network_id = "${openstack_networking_network_v2.dev-infra-0.id}"
  cidr = "${var.network}.16.0/24"
}

resource "openstack_networking_port_v2" "dev-infra-0-port" {
  name = "dev-infra-0-port"
  network_id = "${openstack_networking_network_v2.dev-infra-0.id}"
}

output "openstack_networking_network_v2.dev-infra-0.dev-infra-0-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-infra-0-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-infra-1" {
  name = "dev-infra-1"
}

resource "openstack_networking_port_v2" "dev-infra-1-port" {
  name = "dev-infra-1-port"
  network_id = "${openstack_networking_network_v2.dev-infra-1.id}"
}

resource "openstack_networking_subnet_v2" "dev-infra-1-subnet" {
  name = "dev-infra-1-subnet"
  network_id = "${openstack_networking_network_v2.dev-infra-1.id}"
  cidr = "${var.network}.17.0/24"
}

output "openstack_networking_network_v2.dev-infra-1.dev-infra-1-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-infra-1-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-infra-2" {
  name = "dev-infra-2"
}

resource "openstack_networking_port_v2" "dev-infra-2-port" {
  name = "dev-infra-2-port"
  network_id = "${openstack_networking_network_v2.dev-infra-2.id}"
}

resource "openstack_networking_subnet_v2" "dev-infra-2-subnet" {
  name = "dev-infra-2-subnet"
  network_id = "${openstack_networking_network_v2.dev-infra-2.id}"
  cidr = "${var.network}.18.0/24"
}

output "openstack_networking_network_v2.dev-infra-2.dev-infra-2-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-infra-2-subnet.id}"
}


######## DEV-CF-EDGE ##########

resource "openstack_networking_network_v2" "dev-cf-edge-0" {
  name = "dev-cf-edge-0"
}

resource "openstack_networking_subnet_v2" "dev-cf-edge-0-subnet" {
  name = "dev-cf-edge-0-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-edge-0.id}"
  cidr = "${var.network}.19.0/25"
}

output "openstack_networking_network_v2.dev-cf-edge-0.dev-cf-edge-0-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-edge-0-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-cf-edge-1" {
  name = "dev-cf-edge-1"
}

resource "openstack_networking_subnet_v2" "dev-cf-edge-1-subnet" {
  name = "dev-cf-edge-1-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-edge-1.id}"
  cidr = "${var.network}.19.128/25"
}

output "openstack_networking_network_v2.dev-cf-edge-1.dev-cf-edge-1-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-edge-1-subnet.id}"
}


######## DEV-CF-CORE #########

resource "openstack_networking_network_v2" "dev-cf-core-0" {
  name = "dev-cf-core-0"
}

resource "openstack_networking_port_v2" "dev-cf-core-0-port" {
  name = "dev-cf-core-0-port"
  network_id = "${openstack_networking_network_v2.dev-cf-core-0.id}"
}

resource "openstack_networking_subnet_v2" "dev-cf-core-0-subnet" {
  name = "dev-cf-core-0-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-core-0.id}"
  cidr = "${var.network}.20.0/24"
}

output "openstack_networking_network_v2.dev-cf-core-0.dev-cf-core-0-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-core-0-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-cf-core-1" {
  name = "dev-cf-core-1"
}

resource "openstack_networking_port_v2" "dev-cf-core-1-port" {
  name = "dev-cf-core-1-port"
  network_id = "${openstack_networking_network_v2.dev-cf-core-1.id}"
}

resource "openstack_networking_subnet_v2" "dev-cf-core-1-subnet" {
  name = "dev-cf-core-1-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-core-1.id}"
  cidr = "${var.network}.21.0/24"
}

output "openstack_networking_network_v2.dev-cf-core-1.dev-cf-core-1-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-core-1-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-cf-core-2" {
  name = "dev-cf-core-2"
}

resource "openstack_networking_port_v2" "dev-cf-core-2-port" {
  name = "dev-cf-core-2-port"
  network_id = "${openstack_networking_network_v2.dev-cf-core-2.id}"
}

resource "openstack_networking_subnet_v2" "dev-cf-core-2-subnet" {
  name = "dev-cf-core-2-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-core-2.id}"
  cidr = "${var.network}.22.0/24"
}

output "openstack_networking_network_v2.dev-cf-core-2.dev-cf-core-2-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-core-2-subnet.id}"
}


######## DEV-CF-RUNTIME #########

resource "openstack_networking_network_v2" "dev-cf-runtime-0" {
  name = "dev-cf-runtime-0"
}

resource "openstack_networking_subnet_v2" "dev-cf-runtime-0-subnet" {
  name = "dev-cf-runtime-0-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-runtime-0.id}"
  cidr = "${var.network}.23.0/24"
}

output "openstack_networking_network_v2.dev-cf-runtime-0.dev-cf-runtime-0-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-runtime-0-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-cf-runtime-1" {
  name = "dev-cf-runtime-1"
}

resource "openstack_networking_subnet_v2" "dev-cf-runtime-1-subnet" {
  name = "dev-cf-runtime-1-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-runtime-1.id}"
  cidr = "${var.network}.24.0/24"
}

output "openstack_networking_network_v2.dev-cf-runtime-1.dev-cf-runtime-1-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-runtime-1-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-cf-runtime-2" {
  name = "dev-cf-runtime-2"
}

resource "openstack_networking_subnet_v2" "dev-cf-runtime-2-subnet" {
  name = "dev-cf-runtime-2-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-runtime-2.id}"
  cidr = "${var.network}.25.0/24"
}

output "openstack_networking_network_v2.dev-cf-runtime-2.dev-cf-runtime-2-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-runtime-2-subnet.id}"
}

######## DEV-CF-SERVICES #########

resource "openstack_networking_network_v2" "dev-cf-svcs-0" {
  name = "dev-cf-svcs-0"
}

resource "openstack_networking_subnet_v2" "dev-cf-svcs-0-subnet" {
  name = "dev-cf-svcs-0-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-svcs-0.id}"
  cidr = "${var.network}.26.0/24"
}

output "openstack_networking_network_v2.dev-cf-svcs-0.dev-cf-svcs-0-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-svcs-0-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-cf-svcs-1" {
  name = "dev-cf-svcs-1"
}

resource "openstack_networking_subnet_v2" "dev-cf-svcs-1-subnet" {
  name = "dev-cf-svcs-1-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-svcs-1.id}"
  cidr = "${var.network}.27.0/24"
}

output "openstack_networking_network_v2.dev-cf-svcs-1.dev-cf-svcs-1-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-svcs-1-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-cf-svcs-2" {
  name = "dev-cf-svcs-2"
}

resource "openstack_networking_subnet_v2" "dev-cf-svcs-2-subnet" {
  name = "dev-cf-svcs-2-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-svcs-2.id}"
  cidr = "${var.network}.28.0/24"
}

output "openstack_networking_network_v2.dev-cf-svcs-2.dev-cf-svcs-2-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-svcs-2-subnet.id}"
}

######## DEV-CF-DATABASE #########

resource "openstack_networking_network_v2" "dev-cf-db-0" {
  name = "dev-cf-db-0"
}

resource "openstack_networking_subnet_v2" "dev-cf-db-0-subnet" {
  name = "dev-cf-db-0-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-db-0.id}"
  cidr = "${var.network}.29.0/28"
}

output "openstack_networking_network_v2.dev-cf-db-0.dev-cf-db-0-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-db-0-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-cf-db-1" {
  name = "dev-cf-db-1"
}

resource "openstack_networking_subnet_v2" "dev-cf-db-1-subnet" {
  name = "dev-cf-db-1-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-db-1.id}"
  cidr = "${var.network}.29.16/28"
}

output "openstack_networking_network_v2.dev-cf-db-1.dev-cf-db-1-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-db-1-subnet.id}"
}

resource "openstack_networking_network_v2" "dev-cf-db-2" {
  name = "dev-cf-db-2"
}

resource "openstack_networking_subnet_v2" "dev-cf-db-2-subnet" {
  name = "dev-cf-db-2-subnet"
  network_id = "${openstack_networking_network_v2.dev-cf-db-2.id}"
  cidr = "${var.network}.29.32/28"
}

output "openstack_networking_network_v2.dev-cf-db-2.dev-cf-db-2-subnet.subnet" {
  value = "${openstack_networking_subnet_v2.dev-cf-db-2-subnet.id}"
}


###############################
#           Routers
###############################

#########   DMZ  ############

resource "openstack_networking_router_v2" "dmz-to-pub" {
  name = "dmz-to-pub"
  external_gateway = "${var.pub_net_uuid}"
}

resource "openstack_networking_router_interface_v2" "dmz-to-pub" {
  router_id = "${openstack_networking_router_v2.dmz-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dmz-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-0-to-dmz" {
  router_id = "${openstack_networking_router_v2.dmz-to-pub.id}"
  port_id = "${openstack_networking_port_v2.global-infra-0-port.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-1-to-dmz" {
  router_id = "${openstack_networking_router_v2.dmz-to-pub.id}"
  port_id = "${openstack_networking_port_v2.global-infra-1-port.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-2-to-dmz" {
  router_id = "${openstack_networking_router_v2.dmz-to-pub.id}"
  port_id = "${openstack_networking_port_v2.global-infra-2-port.id}"
}

######### Global ############

resource "openstack_networking_router_v2" "global-to-pub" {
  name = "global-to-pub"
  external_gateway = "${var.pub_net_uuid}"
}

resource "openstack_networking_router_interface_v2" "global-infra-0-to-pub" {
  router_id = "${openstack_networking_router_v2.global-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.global-infra-0-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-1-to-pub" {
  router_id = "${openstack_networking_router_v2.global-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.global-infra-1-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-2-to-pub" {
  router_id = "${openstack_networking_router_v2.global-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.global-infra-2-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-0-to-dev-infra-0" {
  router_id = "${openstack_networking_router_v2.global-to-pub.id}"
  port_id = "${openstack_networking_port_v2.dev-infra-0-port.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-1-to-dev-infra-1" {
  router_id = "${openstack_networking_router_v2.global-to-pub.id}"
  port_id = "${openstack_networking_port_v2.dev-infra-1-port.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-2-to-dev-infra-2" {
  router_id = "${openstack_networking_router_v2.global-to-pub.id}"
  port_id = "${openstack_networking_port_v2.dev-infra-2-port.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-to-dev-cf-core-0" {
  router_id = "${openstack_networking_router_v2.global-to-pub.id}"
  port_id = "${openstack_networking_port_v2.dev-cf-core-0-port.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-to-dev-cf-core-1" {
  router_id = "${openstack_networking_router_v2.global-to-pub.id}"
  port_id = "${openstack_networking_port_v2.dev-cf-core-1-port.id}"
}

resource "openstack_networking_router_interface_v2" "global-infra-to-dev-cf-core-2" {
  router_id = "${openstack_networking_router_v2.global-to-pub.id}"
  port_id = "${openstack_networking_port_v2.dev-cf-core-2-port.id}"
}

######## Development ##########

resource "openstack_networking_router_v2" "dev-to-pub" {
  name = "dev-to-pub"
  external_gateway = "${var.pub_net_uuid}"
}

resource "openstack_networking_router_interface_v2" "dev-infra-0-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-infra-0-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-infra-1-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-infra-1-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-infra-2-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-infra-2-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-runtime-0-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-runtime-0-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-runtime-1-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-runtime-1-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-runtime-2-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-runtime-2-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-core-0-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-core-0-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-core-1-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-core-1-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-core-2-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-core-2-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-svcs-0-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-svcs-0-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-svcs-1-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-svcs-1-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-svcs-2-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-svcs-2-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-db-0-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-db-0-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-db-1-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-db-1-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-db-2-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-db-2-subnet.id}"
}

###############################
#    Volumes and Instances
###############################

resource "openstack_compute_floatingip_v2" "bastion_ip" {
  pool = "public"
  region = "${var.region}" 
}

resource "openstack_blockstorage_volume_v2" "volume_bastion" {
  region = "${var.region}" 
  name = "volume_bastion"
  description = "bastion volume"
  size = 2
}

resource "openstack_compute_instance_v2" "bastion" {
  name = "${var.bastion_name}"
  image_name = "${var.bastion_image}"
  flavor_id = "3"
  key_pair = "${var.key_pair}"
  security_groups = ["default"]
  floating_ip = "${openstack_compute_floatingip_v2.bastion_ip.address}"

  config_drive = true
  user_data = <<EOF
#!/bin/bash

sed -i '1s/127.0.0.1 localhost/127.0.0.1 localhost ${var.bastion_name}/' /etc/hosts
EOF

  network {
    name = "dmz"
    uuid = "${openstack_networking_network_v2.dmz.id}"
  }

  volume {
    volume_id = "${openstack_blockstorage_volume_v2.volume_bastion.id}"
  }
}

resource "openstack_networking_router_interface_v2" "dev-cf-edge-0-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-edge-0-subnet.id}"
}

resource "openstack_networking_router_interface_v2" "dev-cf-edge-1-to-pub" {
  router_id = "${openstack_networking_router_v2.dev-to-pub.id}"
  subnet_id = "${openstack_networking_subnet_v2.dev-cf-edge-1-subnet.id}"
}
