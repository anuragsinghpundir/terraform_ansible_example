provider "aws" {
  shared_config_files      = ["$HOME/.aws/conf"]
  shared_credentials_files = ["$HOME/.aws/credentials"]
  profile                  = "custom"
  region                   = "us-east-2"
}
resource "aws_instance" "web" {
  ami                    = "ami-0ea3c35c5c3284d82"
  key_name               = "login_from_terraform"
  instance_type          = "t3.micro"
  instance_name          = "Webserver"
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = file("prerequisite.sh")
  tags = {
    name  = "Web-Server Built with Terraform"
    owner = "Anurag Singh Pundir"
  }

  provisioner "file" {
    source      = "~/.ssh/id_ed25519.pub"
    destination = "/home/ubuntu/id_ed25519.pub"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file("login_from_terraform.pem")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/ubuntu/",
      "cat id_ed25519.pub >> authorized_keys",
      "exit"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file("login_from_terraform.pem")
    }
  }

}

resource "aws_security_group" "web" {
  name        = "webserver-sg"
  description = "security group for my webserver"
  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      description = "Allow Port HTTP"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }
  ingress {
    description = "Allow Port SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "command1" {
  provisioner "local-exec" {
    command = "echo ${aws_instance.web.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=login_from_terraform.pem > inventory.ini  && ansible-playbook -i inventory.ini playbook.yml"
  }
}