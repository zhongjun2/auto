
output "default_key_name" {
  value = "${huaweicloud_compute_keypair_v2.validator.name}"
}

output "external_ip" {
  value = "${huaweicloud_networking_floatingip_v2.bosh.address}"
}

output "network_id" {
  value = "${huaweicloud_networking_subnet_v2.bosh_subnet.id}"
}


output "internal_ip" {
  value = "${cidrhost(huaweicloud_networking_subnet_v2.bosh_subnet.cidr, 10)}"
}


output "default_security_groups" {
  value = "[${huaweicloud_networking_secgroup_v2.secgroup.name}]"
}



