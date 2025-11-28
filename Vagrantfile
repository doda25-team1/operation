NODE_COUNT = 2  # workers count

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: "192.168.56.100"
    node.vm.network "public_network"
    ctrl.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 1
    end
  end

  (1..NODE_COUNT).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{100+i}"
      node.vm.network "public_network"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "6144"
        vb.cpus = 2
      end
    end
  end
end