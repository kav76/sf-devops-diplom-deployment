terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.84.0"
    }
  }

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "sf-devops"
    region     = "ru-central1-a"
    key        = "terraform/terraform.tfstate"
    access_key = ""
    secret_key = ""
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}


provider "yandex" {
  token     = "${var.auth_token}"
  cloud_id  = "${var.cloud_id}"
  folder_id = "${var.folder_id}"
  zone      = "${var.zone}"
}


resource "yandex_vpc_network" "cluster_net" {
  name = "cluster_net"
}

resource "yandex_vpc_subnet" "subnet_10_128_0_0" {
  name           = "subnet_10_128_0_0"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.cluster_net.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}


resource "yandex_compute_image" "ubuntu22" {
   source_family = "ubuntu-2204-lts"
}

resource "yandex_compute_disk" "vm1-sda" {
  name       = "sda"
  type       = "network-ssd"
  zone       = "ru-central1-a"
  size       = 10
  block_size = 4096
}


resource "yandex_compute_instance" "kuber-master" {
  name = "kuber-master"
  allow_stopping_for_update = true
  hostname ="master.local"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.ubuntu22.id
      size = 16
    }
  }


  network_interface {
#    subnet_id = "${var.local_subnet_id}"
    subnet_id = yandex_vpc_subnet.subnet_10_128_0_0.id
    ip_address = "${var.kuber-master_int_ip}"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

}

resource "yandex_compute_instance" "kuber-app-1" {
  name = "kuber-app-1"
  allow_stopping_for_update = true
  hostname ="app-1.local"

  resources {
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.ubuntu22.id
      size = 32
    }
  }

  network_interface {
#    subnet_id = "${var.local_subnet_id}"
    subnet_id = yandex_vpc_subnet.subnet_10_128_0_0.id    
    ip_address = "${var.kuber-app-1_int_ip}"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "management" {
  name = "management"
  allow_stopping_for_update = true
  hostname ="management.local"

  resources {
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.ubuntu22.id
      size = 32
    }
  }

  network_interface {
#    subnet_id = "${var.local_subnet_id}"
    subnet_id = yandex_vpc_subnet.subnet_10_128_0_0.id    
    ip_address = "${var.management_int_ip}"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

output "internal_ip_address_kuber-master" {
  value = yandex_compute_instance.kuber-master.network_interface.0.ip_address
}

output "internal_ip_address_kuber-app-1" {
  value = yandex_compute_instance.kuber-app-1.network_interface.0.ip_address
}

output "internal_ip_address_management" {
  value = yandex_compute_instance.management.network_interface.0.ip_address
}


output "external_ip_address_kuber-master" {
  value = yandex_compute_instance.kuber-master.network_interface.0.nat_ip_address
}

output "external_ip_address_kuber-app-1" {
  value = yandex_compute_instance.kuber-app-1.network_interface.0.nat_ip_address
}

output "external_ip_address_management" {
  value = yandex_compute_instance.management.network_interface.0.nat_ip_address
}

