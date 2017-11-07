# -*- mode: ruby -*-
# # vi: set ft=ruby :

Vagrant.configure(2) do |config|

  (1..3).each do |i|
    config.vm.define "swarm#{i}" do |s|
      s.ssh.forward_agent = true
      s.vm.box = "ubuntu/xenial64"
      s.vm.hostname = "swarm#{i}"
      s.vm.network "private_network", ip: "172.42.43.10#{i}", netmask: "255.255.255.0",
        auto_config: true,
        virtualbox__intnet: "swarm-net"
      s.vm.provider "virtualbox" do |v|
        v.name = "swarm#{i}"
        v.memory = 2048
        v.gui = false
      end
      s.vm.provision :shell, path: "scripts/bootstrap_host.sh"
    end
  end

  config.vm.define "deployer" do |d|
    d.ssh.forward_agent = true
    d.vm.box = "ubuntu/xenial64"
    d.vm.hostname = "swarm-deployer"
    d.vm.provision :shell, path: "scripts/bootstrap_ansible.sh"
    d.vm.network "private_network", ip: "172.42.43.240", netmask: "255.255.255.0",
      auto_config: true,
      virtualbox__intnet: "swarm-net"
    d.vm.provider "virtualbox" do |v|
      v.name = "swarm-deployer"
      v.memory = 2048
      v.gui = false
    end
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

end
