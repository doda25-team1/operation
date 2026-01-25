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

  config.trigger.after [:up, :reload, :provision, :halt, :destroy] do |t|
  t.info = "Generating Ansible inventory: inventory.cfg (Active machines only)"
  t.ruby do |env, machine|
    File.open("inventory.cfg", "w") do |f|
      f.puts "# Auto-generated Ansible inventory"
      f.puts ""

      # Controller
      f.puts "[ctrl]"
      if env.machine(:ctrl, :virtualbox).state.id == :running
        f.puts "#{CTRL_IP} ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/ctrl/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"
      end

      # Workers
      f.puts ""
      f.puts "[workers]"
      (1..WORKER_COUNT).each do |i|
        node_name = "node-#{i}".to_sym
        if env.machine(node_name, :virtualbox).state.id == :running
          f.puts "192.168.56.#{100+i} ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/node-#{i}/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"
        end
      end

    end
    puts "Successfully created inventory.cfg"
  end
end

end
