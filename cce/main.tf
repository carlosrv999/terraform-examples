# Configure the HuaweiCloud Provider with AK/SK
# This will work with a single defined/default network, otherwise you need to specify network
# to fix errors about multiple networks found.
provider "huaweicloud" {
  tenant_name = var.region
  region      = var.region
  access_key  = var.ak
  secret_key  = var.sk
  # the auth url format follows: https://iam.{region_id}.myhwclouds.com:443/v3
  auth_url    = "https://iam.${var.region}.myhuaweicloud.com/v3"
}

# Create a VPC, Network and Subnet
resource "huaweicloud_vpc_v1" "vpc_v1" {
  name = "vpc-tftest"
  cidr = "192.168.0.0/16"
}

resource "huaweicloud_vpc_subnet_v1" "subnet_v1" {
  name              = "subnet-test"
  cidr              = "192.168.0.0/24"
  gateway_ip        = "192.168.0.1"
  vpc_id            = huaweicloud_vpc_v1.vpc_v1.id
  dns_list          = ["100.125.1.250","8.8.8.8"]
  availability_zone = "${var.region}a"
}

# Create Security Group and rule ssh
resource "huaweicloud_networking_secgroup_v2" "secgroup_1" {
  name        = "secgroup_1"
  description = "My neutron security group"
}

resource "huaweicloud_networking_secgroup_rule_v2" "secgroup_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup_v2.secgroup_1.id
}

resource "huaweicloud_cce_cluster_v3" "cluster_1" {
  name                   = "cluster-test"
  billing_mode           = 0
  cluster_type           = "VirtualMachine"
  cluster_version        = "v1.13.7-r0"
  flavor_id              = "cce.s1.small"
  vpc_id                 = huaweicloud_vpc_v1.vpc_v1.id
  subnet_id              = huaweicloud_vpc_subnet_v1.subnet_v1.id
  container_network_type = "overlay_l2"
  authentication_mode    = "rbac"
  container_network_cidr = "172.16.0.0/16"
}

resource "huaweicloud_cce_node_v3" "node_1" {
  cluster_id        = huaweicloud_cce_cluster_v3.cluster_1.id
  name              = "node1"
  flavor_id         = "s3.large.2"
  iptype            = "5_bgp"
  availability_zone = huaweicloud_vpc_subnet_v1.subnet_v1.availability_zone
  key_pair          = "KeyPair-TF"
  
  root_volume {
    size            = 40
    volumetype      = "SATA"
  }
  
  sharetype         = "PER"
  bandwidth_size    = 100
  
  data_volumes {
    size            = 100
    volumetype      = "SATA"
  }
}

# Variables
variable "ak" {
  type = string
}

variable "sk" {
  type = string
}

variable "region" {
  type = string
}
