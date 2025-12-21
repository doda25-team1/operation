CTRL_MEM_SIZE = 4096
CTRL_CPUS = 2 # kubeadm requires 2 cores
CTRL_IP = "192.168.56.100"

WORKER_COUNT = 2
WORKER_MEM_SIZE = 6144
WORKER_CPUS = 2

# Shared Ansible configuration
ANSIBLE_COMMON_VARS = {
  worker_count: WORKER_COUNT,
  controller_ip: CTRL_IP
}

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  # Controller configuration
  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: CTRL_IP
    
    ctrl.vm.provider "virtualbox" do |vb|
      vb.memory = CTRL_MEM_SIZE
      vb.cpus = CTRL_CPUS
    end

    # Run general playbook
    ctrl.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/general.yml"
      ansible.extra_vars = ANSIBLE_COMMON_VARS
    end

    # Run controller-specific playbook
    ctrl.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/ctrl.yml"
      ansible.extra_vars = ANSIBLE_COMMON_VARS.merge({
        pod_network_cidr: "10.244.0.0/16"
      })
    end
  end

  # Worker node configuration
  (1..WORKER_COUNT).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{100+i}"
      
      node.vm.provider "virtualbox" do |vb|
        vb.memory = WORKER_MEM_SIZE
        vb.cpus = WORKER_CPUS
      end

      # Run general playbook
      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbooks/general.yml"
        ansible.extra_vars = ANSIBLE_COMMON_VARS
      end

      # Run node-specific playbook
      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbooks/node.yml"
        ansible.extra_vars = ANSIBLE_COMMON_VARS
      end
    end
  end

end
