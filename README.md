# Docker Swarm Playground
This project contains a `Vagrantfile` and associated `Ansible` playbooks
to provision a 3 nodes Docker Swarm cluster using `VirtualBox` and `Ubuntu
16.04`.

### Prerequisites
You need the following installed to use this playground.
- `Vagrant`, version 1.8.6 or better. Earlier versions of vagrant may not work
with the Vagrant Ubuntu 16.04 box and network configuration.
- `VirtualBox`, tested with Version 5.0.26 r108824
- Internet access, this playground pulls Vagrant boxes from the Internet as well
as installs Ubuntu application packages from the Internet.

### Bringing Up The cluster
To bring up the cluster, clone this repository to a working directory.

```
git clone http://github.com/davidkbainbridge/swarm-playground
```

Change into the working directory and `vagrant up`

```
cd swarm-playground
vagrant up
```

Vagrant will start three machines. Each machine will have a NAT-ed network
interface, through which it can access the Internet, and a `private-network`
interface in the subnet 172.42.42.0/24. The private network is used for
intra-cluster communication.

The machines created are:

| NAME | IP ADDRESS | ROLE |
| --- | --- | --- |
| swarm1 | 172.42.42.1 | Cluster Leader |
| swarm2 | 172.42.42.2 | Cluster Worker |
| swarm2 | 172.42.42.3 | Cluster Worker |

As the cluster brought up the cluster leader (**swarm1**) will perform a
`docker swarm init` and the cluster workers will perform a `docker swarm join`.

After the `vagrant up` is complete, the following command and output should be
visible on the cluster master (**swarm1**).

```
vagrant ssh swarm1
sudo docker node ls
```
