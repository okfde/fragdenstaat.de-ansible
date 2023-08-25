# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

ansible_groups = {
  "db" => [
    "ansible"
  ],
  "web" => [
    "ansible"
  ],
  "app" => [
    "ansible"
  ],
  "broker" => [
    "ansible"
  ],
  "queue" => [
    "ansible"
  ],
  "worker" => [
    "ansible"
  ],
  "search" => [
    "ansible"
  ],
  "cache" => [
    "ansible"
  ],
}

# Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
#   config.ssh.username   = 'root'
#   config.ssh.password   = 'root'

#   config.vm.provider :docker do |d|
#     d.build_dir       = "."
#     d.has_ssh         = true
#     d.remains_running = true
#     # Needed for using ufw/iptables
#     d.create_args  = ["--cap-add=NET_ADMIN"]
#   end

#   config.vm.hostname = "ansible"
#   config.vm.define "ansible"
#   config.vm.network "forwarded_port", guest: 8080, host: 8085, host_ip: "127.0.0.1", auto_correct: true
#   config.ssh.connect_timeout = 30

#   # Ansible provisioner.
#   config.vm.provision "ansible" do |ansible|
#     ansible.playbook = "playbooks/vagrant.yml"
#     ansible.groups = ansible_groups
#     ansible.host_key_checking = false
#     ansible.verbose = "vvv"
#     ansible.raw_arguments = ["-e", "ansible_python_interpreter=/usr/bin/python3"]
#   end
# end


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/jammy64"

  # config.vm.network :private_network, :type => 'dhcp', :name => 'vboxnet0', :adapter => 2

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--name", "FragDenStaat.de", "--memory", "6144"]
  end

  # Shared folder from the host machine to the guest machine. Uncomment the line
  # below to enable it.
  # config.vm.synced_folder "../fragdenstaat_de", "/var/www/fragdenstaat.de/fragdenstaat.de"
  # config.vm.synced_folder "../froide", "/var/www/fragdenstaat.de/src/froide"
  # config.vm.synced_folder "../froide-fax", "/var/www/fragdenstaat.de/src/froide-fax"
  # etc.

  config.ssh.connect_timeout = 30
  config.ssh.insert_key = false

  # Ansible provisioner.
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/vagrant.yml"
    ansible.host_key_checking = false
    ansible.verbose = "vvv"
    ansible.raw_arguments = ["-e", "ansible_python_interpreter=/usr/bin/python3"]
  end
end
