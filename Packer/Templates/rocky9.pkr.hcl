#---
# Packer Template to create an Ubuntu 24.04 Server Image on Proxmox from a cloned Template  

packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}
# Variable Definitions
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

variable "proxmox_host_node" {
    type = string
    sensitive = true
} 

variable "storage_pool" {
    type = string
}

variable "vmid" {
    type = string
}

locals {
  formatted_date = formatdate("MM-YYYY", timestamp())
  build_time = timestamp()
}


# Resource Definiation for the VM Template
source "proxmox-clone" "Rocky9" {

    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true

    # VM General Settings
    node = "pve1"
    vm_id = "${var.vmid}"
    vm_name   = "PACT-Rocky-Linux-9"
    template_description = "An Image Customized by Packer. Build Date: ${local.build_time}"
    clone_vm = "Template-Rocky-9"
    ssh_username = "root"
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    # VM CPU/MEM Settings
    cores = "1"
    cpu_type = "host"
    memory = "1024"

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    }

    ipconfig {
      ip = "dhcp"
          }

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "${var.storage_pool}"


}

# Build Definition to create the VM Template
build {

    name = "Rocky9"
    sources = ["proxmox-clone.Rocky9"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
            "sudo dnf update -y",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo dnf -y autoremove",
            "sudo dnf clean all",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync",
            "sudo rm -rf /var/log/* /home/*/.bash_history"
        ]
    }
   
    provisioner "ansible" {
         playbook_file = "./Ansible/Playbooks/rocky9.yml"
         use_proxy = false
         extra_arguments = ["-e", "@./Ansible/Variables/vars.yml"]
    }

}