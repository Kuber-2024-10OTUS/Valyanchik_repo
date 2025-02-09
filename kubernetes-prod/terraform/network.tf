resource "yandex_vpc_network" "kuber-network" {
  name = "vpc-net-a"
}

resource "yandex_vpc_subnet" "subnet-a" {  #public
  name = "kuber-subnet-a"
  zone = var.yc_zone_1a
  network_id  = yandex_vpc_network.kuber-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
