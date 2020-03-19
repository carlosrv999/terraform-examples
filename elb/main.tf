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
  name = "vpc-tftest"
  cidr = "192.168.0.0/16"
}

resource "huaweicloud_vpc_subnet_v1" "subnet_v1" {
  name              = "subnet-test"
#  network_id       = "${huaweicloud_networking_network_v2.network_1.id}"
  cidr              = "192.168.0.0/24"
  gateway_ip        = "192.168.0.1"
  vpc_id            = "${huaweicloud_vpc_v1.vpc_v1.id}"
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
  security_group_id = "${huaweicloud_networking_secgroup_v2.secgroup_1.id}"
}

resource "huaweicloud_lb_loadbalancer_v2" "lb_1" {
  name          = "elb-test"
  vip_subnet_id = "${huaweicloud_vpc_subnet_v1.subnet_v1.subnet_id}"
}

resource "huaweicloud_lb_listener_v2" "listener_1" {
  name            = "listener-ssh"
  protocol        = "TCP"
  protocol_port   = 22
  loadbalancer_id = "${huaweicloud_lb_loadbalancer_v2.lb_1.id}"
}

resource "huaweicloud_lb_pool_v2" "pool_1" {
  name        = "pool-ssh"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${huaweicloud_lb_listener_v2.listener_1.id}"
}

# Create ECS

resource "huaweicloud_compute_instance_v2" "basic" {
  name              = "basic-test"
  image_name        = "Ubuntu 18.04 server 64bit"
  flavor_name       = "s3.medium.2"
  key_pair          = "KeyPair-TF"
  security_groups   = ["${huaweicloud_networking_secgroup_v2.secgroup_1.name}"]
  availability_zone = "${var.region}a"

  network {
    uuid = "${huaweicloud_vpc_subnet_v1.subnet_v1.id}"
  }
}

resource "huaweicloud_compute_instance_v2" "basic2" {
  name              = "basic-test2"
  image_name        = "Ubuntu 18.04 server 64bit"
  flavor_name       = "s3.medium.2"
  key_pair          = "KeyPair-TF"
  security_groups   = ["${huaweicloud_networking_secgroup_v2.secgroup_1.name}"]
  availability_zone = "${var.region}a"

  network {
    uuid = "${huaweicloud_vpc_subnet_v1.subnet_v1.id}"
  }
}

resource "huaweicloud_lb_member_v2" "member_1" {
  address       = "${huaweicloud_compute_instance_v2.basic.access_ip_v4}"
  protocol_port = 22
  pool_id       = "${huaweicloud_lb_pool_v2.pool_1.id}"
  subnet_id     = "${huaweicloud_vpc_subnet_v1.subnet_v1.subnet_id}"
}

resource "huaweicloud_lb_member_v2" "member_2" {
  address       = "${huaweicloud_compute_instance_v2.basic2.access_ip_v4}"
  protocol_port = 22
  pool_id       = "${huaweicloud_lb_pool_v2.pool_1.id}"
  subnet_id     = "${huaweicloud_vpc_subnet_v1.subnet_v1.subnet_id}"
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
