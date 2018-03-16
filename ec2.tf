data "aws_ami" "ChefServer" {
  most_recent = true

  filter {
    name   = "tag:role"
    values = ["ChefServer"]
  }

  owners = ["061371841117"] # HappyPathway
}

resource "aws_instance" "chef_server" {
  ami                         = "${data.aws_ami.ChefServer.id}"
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
      "sudo chef-server-ctl org-create ${var.chef_org} ${var.chef_org}",
      "sudo chef-server-ctl user-create ${var.chef_admin_user} ${var.chef_admin_fname} ${var.chef_admin_lname} ${var.chef_admin_email} '${var.chef_admin_password}'",
      "sudo chef-server-ctl org-user-add --admin ${var.chef_org} ${var.chef_admin_user}"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
    }
  }
}
