data "template_file" "chef_users" {
  template = "${file("${path.module}/playbooks/chef_users.yaml.tmpl")}"
  vars {
    chef_admin_user     = "${var.chef_admin_user}"
    chef_admin_fname    = "${var.chef_admin_fname}"
    chef_admin_lname    = "${var.chef_admin_lname}"
    chef_admin_email    = "${var.chef_admin_email}"
    chef_admin_password = "${var.chef_admin_password}"
  }
}

data "template_file" "chef_server" {
  template = "${file("${path.module}/playbooks/chef_server.yaml.tmpl")}"
  vars {
    chef_admin_user     = "${var.chef_admin_user}"
    chef_admin_fname    = "${var.chef_admin_fname}"
    chef_admin_lname    = "${var.chef_admin_lname}"
    chef_admin_email    = "${var.chef_admin_email}"
    chef_admin_password = "${var.chef_admin_password}"
  }
}

resource "null_resource" "ansible" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${join(",", aws_instance.chef_server.*.id)}"
  }
  provisioner "local-exec" {
    command = "echo ${data.template_file.chef_users.rendered} > ${path.module}/playbooks/chef_users.yaml"
  }
  provisioner "local-exec" {
    command = "echo ${data.template_file.chef_server.rendered} > ${path.module}/playbooks/chef_server.yaml"
  }
  provisioner "local-exec" {
    command = "sudo pip install -r ${path.module}/requirements.txt"
  }
  provisioner "local-exec" {
    command = "ansible-playbook ${path.module}/playbooks/chef_setup.yaml -i ${path.module}/playbooks/inventories/ec2.py -e chef_dir=${path.cwd}}/.chef"
  }
  provisioner "local-exec" {
    command = "rm ${path.module}/playbooks/chef_server.yaml ${path.module}/playbooks/chef_users.yaml"
  }
}