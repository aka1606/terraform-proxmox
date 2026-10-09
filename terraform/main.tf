terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.46"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.4.20:8006/"
  username = "root@pam"
  password = var.proxmox_password
  insecure = true
}

locals {
  vms = [
    { name = "k8s-master",  id = 200, ip = "192.168.4.203", ram = 4096 },
    { name = "k8s-worker1", id = 201, ip = "192.168.4.204", ram = 2048 },
    { name = "k8s-worker2", id = 202, ip = "192.168.4.205", ram = 2048 },
  ]
}

resource "proxmox_virtual_environment_vm" "k8s_vms" {
  count     = length(local.vms)
  name      = local.vms[count.index].name
  node_name = "pve2"
  vm_id     = local.vms[count.index].id

  reboot_after_update = true

  clone {
    vm_id = 9000
    full  = true
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
    interface    = "scsi0"
  }

  cpu {
    cores   = 2
    sockets = 1
  }

  memory {
    dedicated = local.vms[count.index].ram
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${local.vms[count.index].ip}/24"
        gateway = "192.168.4.1"
      }
    }
    user_account {
      username = "ubuntu"
      password = var.vm_password
      keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIGgPlaXWcGER6loouxqiexDBiBFKep4FCl4iC1gUGxn terraform-proxmox"]
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}