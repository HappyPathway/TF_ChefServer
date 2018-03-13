data "template_file" "chef_users" {
  template = "${file("${path.module}/playbooks/chef_users.yaml.tmpl")}"
  vars {
    chef_admin_user     = ${var.chef_admin_user}
    chef_admin_fname    = ${var.chef_admin_fname}
    chef_admin_lname    = ${var.chef_admin_lname}
    chef_admin_email    = ${var.chef_admin_email}
    chef_admin_password = ${var.chef_admin_password}
  }
}

data "template_file" "chef_server" {
  template = "${file("${path.module}/playbooks/chef_server.yaml.tmpl")}"
  vars {
    chef_admin_user     = ${var.chef_admin_user}
    chef_admin_fname    = ${var.chef_admin_fname}
    chef_admin_lname    = ${var.chef_admin_lname}
    chef_admin_email    = ${var.chef_admin_email}
    chef_admin_password = ${var.chef_admin_password}
  }
}

resource "null_resource" "ansible" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${join(",", aws_instance.chef_server.*.id)}"
  }
  provisioner "local-exec" {
    command = "echo ${data.template_file.init.rendered} > ${path.module}/playbooks/chef_users.yaml"
  }
  provisioner "local-exec" {
    command = "sudo pip install -r ${module.root}/requirements.txt"
  }
  provisioner "local-exec" {
    command = "ansible-playbook ${module.root}/playbooks/chef_setup.yaml -i ${module.root}/playbooks/inventories/ec2.py"
  }
  provisioner "local-exec" {
    command "rm ${module.root}/playbooks/chef_server.yaml ${module.root}/playbooks/chef_users.yaml"
  }
}