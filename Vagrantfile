NODE_COUNT = 2  # workers count

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: "192.168.56.100"
    ctrl.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 1
    end
  end

  (1..NODE_COUNT).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{100+i}"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "6144"
        vb.cpus = 2
      end
    end
  end

  # create the directory, file and fill it in
  config.vm.provision "shell", inline: <<-SHELL
    mkdir -p /vagrant/inventory
    cat <<EOF > /vagrant/inventory/hosts.ini
[ctrl]
192.168.56.100 ansible_user=vagrant

[nodes]
EOF

    for i in $(seq 1 #{NODE_COUNT}); do
      echo "192.168.56.$((100+i)) ansible_user=vagrant" >> /vagrant/inventory/hosts.ini
    done
  SHELL

  config.vm.provision "ansible" do |ansible| # use ansible to configure vms
    ansible.playbook = "playbooks/general.yml" # this one will run first as it is general
    ansible.inventory_path = "inventory/hosts.ini" # where inventory will be generated

    ansible.extra_vars = {
      worker_count: NODE_COUNT,
      controller_ip: "192.168.56.100"
    }
  end

  # controller tasks
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/ctrl.yml"
    ansible.inventory_path = "inventory/hosts.ini"
    ansible.limit = "ctrl"
  end

  # node tasks
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/node.yml"
    ansible.inventory_path = "inventory/hosts.ini"
    ansible.limit = "nodes"
  end
end