terraform {
  required_version = ">= 0.12"
}

provider "cloudflare" {
  version = "~> 2.0"
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

resource "cloudflare_record" "dns_k3s_nodes" {
  for_each = var.nodes
  zone_id  = var.cloudflare_zone_id
  name     = each.key
  value    = each.value
  type     = "A"
  ttl      = 120
}

resource "null_resource" "raspberry_pi_public_key" {
  for_each   = var.nodes

  connection {
    type     = "ssh"
    user     = var.username
    password = var.password
    host     = each.value
  }

  provisioner "file" {
    source      = var.public_key_path
    destination = "/tmp/id_rsa.pub"
  }
}

resource "null_resource" "raspberry_pi_setup" {
  for_each   = var.nodes

  connection {
    type     = "ssh"
    user     = var.username
    password = var.password
    host     = each.value
  }

  provisioner "remote-exec" {
    inline = [
      # Configure timezone and NTP
      "sudo timedatectl set-timezone ${var.timezone}",
      "sudo timedatectl set-ntp true",

      # Configure new hostname
      "sudo hostnamectl set-hostname ${each.key}.${var.domain}",
      "echo '127.0.1.1 ${each.key}.${var.domain}' | sudo tee -a /etc/hosts",

      # Update password
      "echo 'pi:${var.new_password}' | sudo chpasswd",

      # Trust added ssh key
      "mkdir -p ~/.ssh",
      "cat /tmp/id_rsa.pub >> ~/.ssh/authorized_keys",

      # Update all system packages
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get dist-upgrade -y",
      "sudo apt-get --fix-broken install -y",
      "sudo apt-get install git htop ncdu build-essential libssl-dev libffi-dev -y",

      # Install Python
      "sudo apt-get purge python-minimal -y",
      "sudo apt-get install python3 python3-pip python3-venv python3-dev -y",
      "sudo apt-get autoremove -y",
      "sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1",
      "sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1",
      "sudo pip install pip --upgrade",
      "sudo pip install urllib3 requests poetry --upgrade",

      # Configure networking interface
      "echo 'interface eth0\nstatic ip_address=${each.value}${var.subnet_mask}\nstatic routers=${var.static_router}\nstatic domain_name_servers=${var.static_dns}' | cat >> /etc/dhcpcd.conf",

      # Configure GPU memory
      "echo 'gpu_mem=8' | sudo tee -a /boot/config.txt",

      # Reboot pi
      "sudo shutdown -r +0"
    ]
  }
}
