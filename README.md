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
interface in the subnet 172.42.43.0/24. The private network is used for
intra-cluster communication.

The machines created are:

| NAME | IP ADDRESS | ROLE |
| --- | --- | --- |
| swarm1 | 172.42.43.101 | Cluster Leader |
| swarm2 | 172.42.43.102 | Cluster Worker |
| swarm2 | 172.42.43.103 | Cluster Worker |

As the cluster brought up the cluster leader (**swarm1**) will perform a
`docker swarm init` and the cluster workers will perform a `docker swarm join`.

After the `vagrant up` is complete, the following command and output should be
visible on the cluster master (**swarm1**).

```
vagrant ssh swarm1
docker node ls

ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
05lgfqsk8q83kx6arv0s6m9jv *  swarm1    Ready   Active        Leader
3tq6x7mu2a3dbtmai14j0484y    swarm2    Ready   Active
b012782fzwkjkvru6svna3ynf    swarm3    Ready   Active
```

### Starting A Sample Service / Deployment
As a sample service the docer image `davidkbainbridge/docker-hello-world` can
be used. This image is a simple HTTP service that outputs the the hostname and
the IP address information on which the request was processed. An example
output is:

```
Hello, "/"
HOST: hello-deployment-2911225940-qhfn2
ADDRESSES:
    127.0.0.1/8
    10.40.0.5/12
    ::1/128
    fe80::dcc9:4ff:fe5c:f793/64
```

To start the service you can issue the following command on the swarm leader
(**swarm1**).

```
docker service create --replicas 3 --detach=true --name hello-service \
    --publish 80:8080 davidkbainbridge/docker-hello-world:latest
```

The status of the service can be viewed with the following command:

```
ubuntu@swarm1:~$ docker service ls
ID            NAME           REPLICAS  IMAGE                                       COMMAND
1c098b4tfg8j  hello-service  0/3       davidkbainbridge/docker-hello-world:latest
```

After all the instances of the service have started the replica count will be
changed to `3/3`.

### Accessing the Service
The service can be access through any of the node's IP address as Docker Swarm
load balances the request to any server to one of the instances. The example
below accesses the service via the IP address of swarm1.

```
ubuntu@swarm1:~$ curl -sSL http://172.42.43.101:80
Hello, "/"
HOST: 7198084f1b91
ADDRESSES:
    127.0.0.1/8
    10.255.0.8/16
    10.255.0.6/32
    172.18.0.3/16
    ::1/128
    fe80::42:aff:feff:8/64
    fe80::42:acff:fe12:3/64
```

### Scaling the Service
To test the scaling of the service, you can open a second terminal and ssh
to a node in the cluster (e.g. `vagrant up ssh swarm1`). In this terminal if you
issue the following command it will periodically issue a `curl` request to
the service and display the output, highlighting the difference from the
previous request. This demonstrates that the request is being handled by
different services.

```
watch -d curl -sSL http://172.42.43.101:80
```

Currently there should be 3 instances of the service implementation being
used. To scale to a single instance, issue the following command:

```
ubuntu@swarm1:~$ docker service scale hello-service=1
hello-service scaled to 1
```

After scaling to a single instance the `watch` command from above should show
no differences between successive request as all requests are being handled by
the same instance.

The following command scales the number of instances to 5 and after issuing
this command differences in the `watch` command should be highlighted.

```
ubuntu@swarm1:~$ docker service scale hello-service=5
hello-service scaled to 5
```

### Service Health Check
The test container image used above `davidkbainbridge/docker-hello-world:latest`
is build with a health check capability. The container provides a REST end
point that will return `200 Ok` by default, but this can be manual set to a
different value to test error cases. See the container documentation
at https://github.com/davidkbainbridge/docker-hello-world for more information.

To see the health of any given instance of the service implementation, you can
`ssh` to the node and perform a `docker ps`. This will show the running
containers augmented with their health status.

```
ubuntu@swarm1:~$  docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                    PORTS               NAMES
d8af515b0aa4        local-test:now      "go-wrapper run"    12 minutes ago      Up 12 minutes (healthy)                       hello-service.1.aguae4r9zq7oacqndckz0f5hj
```

To demonstrate the health check capability of the cluster, you can open up a
`ssh` session to each node in the swarm and run the command
`watch -d docker ps`. This command will periodically update the screen with
information about which containers are running on the node. For each container
running there will be a value indicating how long the container has running
under the title `STATUS`.

To cause one of the container instances to start reporting a failed health
value you can set a random instance to fail using

```
curl -XPOST --sSL http://localhost:80/health -d '{"status":501}'
```

This will set the health check on a random instance in the cluster to return
"501 Internal Server Error". If you want to fail the health check on a specific
instance you will nee to make a similar `curl` request to the specific
container instance.

After setting the health check to return a failure value monitor the three
`ssh` sessions that are *watching* the `docker ps` output. After about one
minute one of the instances should be killed and restarted. You may see the
`docker ps` output go blank. A new instance will be started and the `STATUS`
of that new instance is evidence that a new container instance was started as
the time it has between running should be less than the time running of the
other instances.

*NOTE: the frequency of health checks is configurable*
