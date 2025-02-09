resource "yandex_compute_disk" "boot-disk-w2" {
  name     = "worker2-network-hdd"
  type     = "network-hdd"
  zone     = var.yc_zone_1a
  size     = "20"
  image_id = "fd83r8l1erja63002a2h"
}

resource "yandex_compute_instance" "worker-2" {
  name                      = "kubernetes-worker-2"
  hostname = "worker-2"
  allow_stopping_for_update = true
  platform_id               = "standard-v1"
  zone                      = var.yc_zone_1a

  resources {
    cores  = 2
    memory = 8
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-w2.id
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-a.id}"
    nat       = true
  }

  metadata = {
    ssh-keys = "valyan:${file("~/.ssh/id_ed25519.pub")}"
    user-data = "${file("cloud-init.yaml")}"
  }
}