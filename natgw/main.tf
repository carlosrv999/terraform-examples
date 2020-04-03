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

resource "huaweicloud_nat_gateway_v2" "nat_1" {
  name                = "Terraform"
  description         = "test for terraform2"
  spec                = "1"
  router_id           = huaweicloud_vpc_v1.vpc_v1.id
  internal_network_id = huaweicloud_vpc_subnet_v1.subnet_v1.id
}

resource "huaweicloud_vpc_eip_v1" "eip_1" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "test"
    size        = 10
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_nat_snat_rule_v2" "snat_1" {
  nat_gateway_id = huaweicloud_nat_gateway_v2.nat_1.id
  network_id     = huaweicloud_vpc_subnet_v1.subnet_v1.id
  floating_ip_id = huaweicloud_vpc_eip_v1.eip_1.id
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
