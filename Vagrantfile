CTRL_MEM_SIZE = 4096
CTRL_CPUS = 2 # kubeadm requires 2 cores

WORKER_COUNT = 2
WORKER_MEM_SIZE = 6144
WORKER_CPUS = 2

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: "192.168.56.100"
    ctrl.vm.provider "virtualbox" do |vb|
      vb.memory = CTRL_MEM_SIZE
      vb.cpus = CTRL_CPUS
    end
  end

  (1..WORKER_COUNT).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{100+i}"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = WORKER_MEM_SIZE
        vb.cpus = WORKER_CPUS
      end
    end
  end


  config.vm.provision "ansible" do |ansible| # use ansible to configure vms
    ansible.playbook = "playbooks/general.yml" # this one will run first as it is general

    ansible.extra_vars = {
      worker_count: WORKER_COUNT,
      controller_ip: "192.168.56.100",
    }
  end

  # controller tasks
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/ctrl.yml"

    ansible.extra_vars = {
      controller_ip: "192.168.56.100",
      pod_network_cidr: "10.244.0.0/16",
    }
  end

  # node tasks
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/node.yml"

    ansible.extra_vars = {
      controller_ip: "192.168.56.100",
    }
  end
end