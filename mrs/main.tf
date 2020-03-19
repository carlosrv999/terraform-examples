# Configure the HuaweiCloud Provider with AK/SK
# This will work with a single defined/default network, otherwise you need to specify network
# to fix errors about multiple networks found.
provider "huaweicloud" {
  tenant_name = "${var.region}"
  region      = "${var.region}"
  access_key  = "${var.ak}"
  secret_key  = "${var.sk}"
  # the auth url format follows: https://iam.{region_id}.myhwclouds.com:443/v3
  auth_url    = "https://iam.${var.region}.myhuaweicloud.com/v3"
}

# Create a VPC, Network and Subnet
resource "huaweicloud_vpc_v1" "vpc_v1" {
  name = "terraform"
  cidr = "192.168.0.0/16"
}

resource "huaweicloud_vpc_subnet_v1" "subnet_v1" {
  name              = "sb-terraform"
  cidr              = "192.168.0.0/24"
  gateway_ip        = "192.168.0.1"
  vpc_id            = "${huaweicloud_vpc_v1.vpc_v1.id}"
  dns_list          = ["100.125.1.250","8.8.8.8"]
  availability_zone = "${var.region}a"
}

resource "huaweicloud_mrs_cluster_v1" "cluster1" {
  cluster_name          = "mrs-cluster"
  region                = "${var.region}"
  billing_type          = 12
  master_node_num       = 2
  core_node_num         = 3
  master_node_size      = "c3.xlarge.2.linux.bigdata"
  core_node_size        = "c3.xlarge.2.linux.bigdata"
  available_zone_id     = "${var.region}a"
  vpc_id                = "${huaweicloud_vpc_v1.vpc_v1.id}"
  subnet_id             = "${huaweicloud_vpc_subnet_v1.subnet_v1.id}"
  cluster_version       = "MRS 1.8.7"
  volume_type           = "SATA"
  volume_size           = 100
  safe_mode             = 0
  cluster_type          = 0
  node_public_cert_name = "KeyPair-TF"
  cluster_admin_secret  = ""
  component_list {
    component_name = "Hadoop"
  }
  component_list {
    component_name = "Spark"
  }
  component_list {
    component_name = "Hive"
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
