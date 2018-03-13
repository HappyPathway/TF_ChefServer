data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "chef_server" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  subnet_id                   = "${var.public_subnet_id}"
  vpc_security_group_ids      = ["${aws_security_group.chef_server.id}"]
  associate_public_ip_address = true

  tags {
    Name     = "chef"
    role     = "chef"
    hostname = "${var.server_name}.${var.domain}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python python-dev python-pip",
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
    }
  }
}


resource "null_resource" "cluster" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${join(",", aws_instance.chef_server.*.id)}"
  }
  
  provisioner "local-exec" {
    command = "ansible-playbook ${module.root}/playbooks/chef_setup.yaml -i ${module.root}/playbooks/inventories/ec2.py -e org"
  }
}