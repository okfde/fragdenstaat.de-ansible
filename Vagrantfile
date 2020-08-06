# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.network :private_network, ip: "192.168.33.15"

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

  # Ansible provisioner.
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "vagrant.yml"
    ansible.host_key_checking = false
    ansible.verbose = "vvv"
    ansible.raw_arguments = ["-e", "ansible_python_interpreter=/usr/bin/python3"]
  end
end
