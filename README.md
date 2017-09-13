# How to use this image 

[RoboMQ](https://robomq.io) broker is a pre-configured messaging broker image built upon [RabbitMQ](https://www.rabbitmq.com/) 3.6.12. Supporting cluster and management, it is customized for deployment in production environment. 

* [Standalone Broker](#option-1-standalone-broker)
* [Clustered Broker](#option-2-clustered-broker)
* [Network Settings](#network-settings)

## Option 1: Standalone Broker

### Run broker

	$ docker run -d -P --name broker robomq/rabbitmq

You can choose a different container name by changing `--name broker`. To view status and port mapping of the broker daemon:

	$ docker ps -f name=broker

### Read logs

	$ docker logs broker

You will see logs similar to:

	==========================================================================
	Broker rabbit@8823c6d94248 is running. Supports AMQP/MQTT by default.

		Default User     : admin
		Default Password : 942b020d5962
		Default Vhost    : /
		ERLANG_COOKIE    : QAYBCTIFOSOIYVMABAED

	Please update system generated default password by this command:
	$ docker exec <container> rabbitmqctl change_password admin <password>
	Web Management UI can be accessed with admin:942b020d5962 from:
			http://<broker-host>:<ui-port>/
	To get <ui-port>, run: $ docker port <container> 15672 | cut -d : -f 2	
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

### Restart, stop, or remove broker

	$ docker restart broker
	$ docker stop broker
	$ docker rm -v broker

### Access web management UI
***Access web management UI from the same host***

From the host running broker daemon, first find out which published port corresponds to container's private port 15672: 

    $ docker port broker 15672 | cut -d : -f 2

Then run the following command to list virtual hosts, after replacing `<user>:<password>` with values given in broker logs, and replacing `<ui-port>`with port number discovered in last step:

    $ curl -u <user>:<password> http://localhost:<ui-port>/api/vhosts

You should see outputs like	`[{"name":"/","tracing":false}]`,    indicating you have correct login credentials to access broker's HTTP API. 

If the host has a web browser, open it and go to `http//localhost:<ui-port>`. Use same credentials to login, and you will see web interface similar to:

![Broker Web Management UI](https://www.robomq.io/images/management_ui.png)

***Access web management UI from a different host***

If no firewall blocks `<ui-port>` access to broker host,  open web browser from the other host and go to `http//<broker-host>:<ui-port>/`. 

If the broker runs behind a firewall which blocks `<ui-port>` access, you need to either change firewall rule to unblock it, or switch to an available port permitted by firewall. For example, assuming port 8080 is permitted by firewall rules and not in use, you can recreate broker to use it:

	$ docker rm -f -v broker
	$ docker run -d -P -p 8080:15672 --name broker robomq/rabbitmq

Open web browser from the other host and go to `http//<broker-host>:8080/`. In the same way, you can provide for [AMQP/MQTT](#network) port access across firewall.  

***How to use web management UI***

Please refer to [Rabbitmq Management Plugin Guide](https://www.rabbitmq.com/management.html) for how to manage your broker via web UI or HTTP API, for example, to create and manage virtual hosts and users.

### Set container hostname (Recommended)
It is a good practice to use `--hostname` or `-h` option to choose a container hostname for the broker. You can also run broker in auto restart mode:
	
	$ docker run -d -P --name broker -h broker --restart always robomq/rabbitmq
	
### Specify published ports (Recommended)

With `--publish all` or `-P` option, all exposed ports are published to some random ports. When this is not desired you can specify which ports are to be used:
	
	$ docker run -d --name broker \
		-p 5672:5672 -p 1883:1883 -p 15672:15672 \
		robomq/rabbitmq
		
Specifying ports is necessary when running firewalled brokers. Choose ports that are permitted by firewall rules. Refer to [Network Settings](#network-settings) for more details.

### Set default user/password/vhost (Recommended)
For better security, set default user, default password, default vhost, or any combination of these to your own choice:

	$ docker run -d -P --name broker \
		-e DEFAULT_USER=myuser -e DEFAULT_PASSWORD=mypass \
		-e DEFAULT_VHOST=myvhost \ 
		robomq/rabbitmq

If you do not choose a password for default user, system will automatically generate a random password. You can either change it from web management UI or run this command:

	docker exec <container> rabbitmqctl change_password <user> <password>
		
### Persist broker data (Recommended)
To persist broker data and configurations, mount a host directory to container volume `/var/lib/rabbitmq`: 
	
	$ docker run -d -P --name broker -h broker \
		-v "$PWD"/hostdir:/var/lib/rabbitmq \
		robomq/rabbitmq
		
Please change `"$PWD"/hostdir` to a designated folder on your host to store the persistent data. In case the broker is removed, run the same command to recreate it; the new broker will recover its data and configurations from the last known state.

After removing a broker with persistent data, if you want to recreate broker with clean state, you need to either delete the contents in the host directory, or mount a different host directory. 

***Important Reminder***: When making broker persistent, you should always use `--hostname` or `-h` option as well. When you recreate a new broker from the last known state, you should reuse the same hostname of the removed container and not change it to a new one. 

### Enable/disable web management UI
By default web management UI is enabled, but you can disable it to get better performance:

	$ docker run -d -P --name broker -e WEB_MANAGE_UI=false robomq/rabbitmq

### Mount startup config files
You can mount startup config file `/etc/rabbitmq/rabbitmq.config`, `/etc/rabbitmq/enabled_plugins`, or both:

	$ docker run -d -P --name broker \
		-v "$PWD"/rabbitmq.config:/etc/rabbitmq/rabbitmq.config \
		-v "$PWD"/enabled_plugins:/etc/rabbitmq/enabled_plugins \
		robomq/rabbitmq

Please change `"$PWD"` to the full path of the host directory where you place these config files. When config files are mounted, their settings override conflicting environment variables:

* When `rabbitmq.config` file is mounted, `DEFAULT_USER`, `DEFAULT_PASSWORD` and `DEFAULT_VHOST` are ignored.
* When `enabled_plugins` file is mounted, `WEB_MANAGE_UI` is ignored.

### Set log level
Connection related events are logged to console, with default verbosity level of `info`. The supported options are `debug|info|warning|error|none`:
	
	$ docker run -d -P --name broker -e BROKER_LOG_LEVEL=error robomq/rabbitmq	

### Use rabbitmqctl
Rabbitmq provides a CLI tool, rabbitmqctl, to manage broker. For example, to query status, users, and vhosts of the running broker:

	$ docker exec -it broker rabbitmqctl status
	$ docker exec -it broker rabbitmqctl list_users
	$ docker exec -it broker rabbitmqctl list_vhosts	

Please refer to [rabbitmqctl manual page](https://www.rabbitmq.com/man/rabbitmqctl.1.man.html) for how to use this tool to manage your broker.

### Tune performance
The default memory threshold at which memory alarm and [flow control](https://www.rabbitmq.com/memory.html) are triggered is 0.8, or 80% of installed RAM or available virtual address space. The advanced user can tune it:
	
	$ docker run -d -P --name broker \
		-e RABBITMQ_VM_MEMORY_HIGH_WATERMARK=0.4 \
		robomq/rabbitmq	

You can also precompile parts of RabbitMQ with HiPE (High Performance Erlang Engine):
	
	$ docker run -d -P --name broker \
		-e RABBITMQ_HIPE_COMPILE=true \
		robomq/rabbitmq	

This will increase server throughput at the cost of increased startup time. Performance varies, but you might see 20-50% improvement at the cost of a few minutes delay at startup. 

## Option 2: Clustered Broker

### Setup hosts
You can create a cluster with any number of broker nodes. One node is designated as cluster head node, which is joined by other nodes. Broker nodes address each other using domain names, either short or fully-qualified (FQDNs). Therefore [hostnames of all cluster members must be resolvable from all cluster nodes](https://www.rabbitmq.com/clustering.html#clustering).  

In this example setup, each broker node runs on a separate server or VM host to avoid port conflicts. They are connected via reliable LAN links. 

You need to find out each host's `IP address/short hostname/long hostname/domain name`. For example, on Linux system, this command prints them on separate lines: 

	$ hostname --ip-address; hostname --short; hostname --long; hostname --domain

The following sections assumes that host N is configured to `192.168.1.10N`/`hostN`/`hostN.example.com`/`example.com`. Please replace them in the following commands with values of your own setting. 

### Run broker cluster

***Clustering using IP address***

In environments without DNS service, as long as broker nodes can ping each other, you can still set up broker cluster by passing IP addresses as long hostnames. Therefore, this is a special case of clustering using long hostname: you must specify published ports; you should set `RABBITMQ_ERLANG_COOKIE`, the [cluster shared secret](#erlangcookie); you should set `RABBITMQ_USE_LONGNAME=true`, which cause brokers to use long hostnames to identify nodes. 

1. Start broker node 1 as head node of the cluster:

		$ docker run -d --name broker01 -h 192.168.1.101 \
			-p 5672:5672 -p 1883:1883 -p 15672:15672 \
			-p 4369:4369 -p 25672:25672 \
			-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
			-e RABBITMQ_USE_LONGNAME=true \
			robomq/rabbitmq
2. From broker node 2, verify that head node can be reached via ports 4369 and 25672:

		$ nc -z -v 192.168.1.101 4369
		$ nc -z -v 192.168.1.101 25672
	Then start broker node 2 to join node 1:
	
		$ docker run -d --name broker02 -h 192.168.1.102 \
			-p 5672:5672 -p 1883:1883 -p 15672:15672 \
			-p 4369:4369 -p 25672:25672 \
			-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
			-e RABBITMQ_USE_LONGNAME=true \
			-e HEAD_NODE=192.168.1.101 \
			robomq/rabbitmq
			
3. You can add any number of additional nodes to join node 1:
	  	
		$ docker run -d --name broker03 -h 192.168.1.103 \
			-p 5672:5672 -p 1883:1883 -p 15672:15672 \
			-p 4369:4369 -p 25672:25672 \
			-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
			-e RABBITMQ_USE_LONGNAME=true \
			-e HEAD_NODE=192.168.1.101 \
			robomq/rabbitmq
	     
	Broke03 logs should indicate success of cluster formation:
		
		Broker rabbit@192.168.1.103 is running. Supports AMQP/MQTT by default.
		Success: Join cluster with HEAD_NODE: rabbit@192.168.1.101
		....
		 {running_nodes,['rabbit@192.168.1.101','rabbit@192.168.1.102',
                 'rabbit@192.168.1.103']},

***Note:*** If you pass IP or long hostname but forget to set `RABBITMQ_USE_LONGNAME`, IP or long hostname is still accepted, but you will get warnings: 
	
	WARN: you use long hostname but RABBITMQ_USE_LONGNAME!=true.
	WARN: run "export RABBITMQ_USE_LONGNAME=true" before using rabbitmqctl.

***Clustering using long hostname***

Although using IP addresses works, the standard way is to use hostnames. Before creating cluster, verify that all hosts are DNS-reachable via long hostnames:
		
	$ nslookup hostN.example.com
	$ ping -c 1 hostN.example.com 

Run the commands in last section to create the cluster, after replacing `192.168.1.10N` with `hostN.example.com`.

***Note***: To create a standalone broker, `--hostname` or `-h` is optional and you can choose any value for container's hostname. However, to create clustered brokers, you must assign container hostnames resolvable by all broker nodes. In our example, broker container hostnames are set to server/VM hostnames; therefore, broker nodes can rely on server/VMs' DNS settings to resolve each other without additional DNS and network setup. 

***Clustering using short hostname***

The most common way to create broker cluster is to use short hostnames. Before proceeding, verify that all hosts are DNS-reachable via short hostnames:
		
	$ nslookup hostN
	$ ping -c 1 hostN

To set up broker cluster using short hostnames,  set `RABBITMQ_USE_LONGNAME=false` or just remove it:
				
	$ docker run -d --name broker01 -h host1 \
		-p 5672:5672 -p 1883:1883 -p 15672:15672 \
		-p 4369:4369 -p 25672:25672 \
		-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
		robomq/rabbitmq
    	
	$ docker run -d --name broker02 -h host2 \
		-p 5672:5672 -p 1883:1883 -p 15672:15672 \
		-p 4369:4369 -p 25672:25672 \
		-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
		-e HEAD_NODE=host1 \
		robomq/rabbitmq	

***Note***: In some environments, `$ nslookup hostN` fails but `$ nslookup hostN.example.com` succeeds. If you still want to use short hostnames, you need to add `--dns-search example.com` option to the commands. 
			
***Clustering in private DNS setting***

In some restrictive environments, such as a private network, an internal DNS server is set up to resolve private hostnames and private IP addresses. For example, if a company `example.com` has a private subnet or zone `dc1`, and this zone has a broker node N with short hostname `hostN`, then broker node N has a private FQDN of "hostN.dc1.example.com":
 
	$ nslookup hostN.dc1.example.com <Private-DNS-Server-IP>

Specify DNS server and DNS search domain to handle this case:
	
	$ docker run -d --name broker01 -h host1 \
		--dns=<Private-DNS-Server-IP> --dns-search=dc1.example.com \
		-p 5672:5672 -p 1883:1883 -p 15672:15672 \
		-p 4369:4369 -p 25672:25672 \
		-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
		robomq/rabbitmq
    	
	$ docker run -d --name broker02 -h host2 \
		--dns=<Private-DNS-Server-IP> --dns-search=dc1.example.com \
		-p 5672:5672 -p 1883:1883 -p 15672:15672 \
		-p 4369:4369 -p 25672:25672 \
		-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
		-e HEAD_NODE=host1 \
		robomq/rabbitmq	

### Manage broker cluster
 
	$ docker logs broker01
	$ docker exec broker01 rabbitmqctl cluster_status

* You can read cluster status from the logs.
* You can access web management UI; login credentials are given in head node logs when it is created. 
* You can remove the cluster by stopping and removing all broker nodes.
* You can specify `DEFAULT_USER`,`DEFAULT_PASSWORD`, `DEFAULT_VHOST` when creating the head node (Recommended to achieve better security).
* You can enable/disable web management UI for any broker node; by default it is enabled.
* You can use `--restart always` to run any broker node in auto restart mode.
* You can use rabbitmqctl tool to manage your broker cluster.

### Choose your own shared secret (Recommended)

The broker nodes authenticate to each other using a shared secret, called the  [Erlang Cookie](https://www.rabbitmq.com/clustering.html). The cookie is just an alphanumeric string. It can be of any length. All cluster nodes must have the same cookie. For security reason, please choose a long string as your own cookie in production, and replace `ClusterSecret2468` with it in the commands. In testing environment, you can also choose not to pass `RABBITMQ_ERLANG_COOKIE` when creating head node. In this case, head node will create a random cookie automatically, which can then be used to create other nodes. 

Erlang cookie is saved in cookie file `/var/lib/rabbitmq/.erlang.cookie`. If volume `/var/lib/rabbitmq/` is mounted (see next section), you can supply a cookie file before broker creation. The cookie file content overrides `RABBITMQ_ERLANG_COOKIE` when both are present; moreover, if the values mismatch, you will get a warning:

	 * Use erlang cookie saved in file /var/lib/rabbitmq/.erlang.cookie
	WARN: erlang cookie file content does not match RABBITMQ_ERLANG_COOKIE

### Persist broker cluster data (Recommended)
To persist broker cluster data and configurations, you should mount a volume for each broker node:

	$ docker run -d --name broker01 -h host1 --restart always \
		-p 5672:5672 -p 1883:1883 -p 15672:15672 \
		-p 4369:4369 -p 25672:25672 \
		-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
		-v ${PWD}/hostdir:/var/lib/rabbitmq \
		robomq/rabbitmq
		
	$ docker run -d --name broker02 -h host2 --restart always \
		-p 5672:5672 -p 1883:1883 -p 15672:15672 \
		-p 4369:4369 -p 25672:25672 \
		-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
		-v ${PWD}/hostdir:/var/lib/rabbitmq \
		-e HEAD_NODE=host1 \
		robomq/rabbitmq
		
Please replace `${PWD}/hostdir` with your designated folder on broker host to store the persistent data. In case any broker is removed, run command again to recreate it; the new broker will recover its data and configurations from the last known state. You can eve remove and recreate the whole cluster; the new cluster will recover from the last known state. This minimizes service interruption and data loss when you [upgrade the cluster](https://www.rabbitmq.com/clustering.html##upgrading) to a newer version. 

***Important reminder***: When making broker persistent, You should always use `-h` or `--hostname` option as well. When you remove a broker container and recreate a new one in its place, you should reuse the same hostname of the removed container and not change it to a new one.

### Use RAM node (for advanced users only) 
Broker node can be either disk node or RAM node. By default, broker node runs as disk node. In some cases, you may set broker to RAM node to get better performance:

	$ docker run -d --name broker03 -h host3 \
		-p 5672:5672 -p 1883:1883 -p 15672:15672 \
		-p 4369:4369 -p 25672:25672 \
		-e RABBITMQ_ERLANG_COOKIE=ClusterSecret2468 \
		-e HEAD_NODE=host1 \
		-e RAM_NODE=true
		robomq/rabbitmq

You will see logs like:

	Broker rabbit@broker03 is running as a ram node. Supports AMQP/MQTT by default.
RAM node is a special case. [Use RAM node with care](https://www.rabbitmq.com/clustering.html#ram-nodes) and if in doubt, use the default disc node.  

		
## Network Settings 
### Default ports

The image exposes the following ports by default: 

1. Ports applicable to both standalone and clustered setup:
	* AMQP: 5672, 5671 (without or with TLS)
	* MQTT: 1883, 8883 (without or with TLS)
	* Management UI: 15672 
	
	These ports are used by clients to access or manage broker service. Please check your firewall settings, and map these internal ports to permissible ports.     

2.  Ports used by clustered broker nodes, not applicable to standalone setup:
	* Peer discovery: 4369
	* Inter-node communication: 25672


Please refer to [Rabbitmq Clustering Guide](https://www.rabbitmq.com/clustering.html#firewall) and [Rabbitmq Networking Guide](https://www.rabbitmq.com/networking.html) for more details.

### Control which ports to publish

You can be selective in which ports to publish. For example, in standalone broker setup, when you only need AMQP without TLS:

	$ docker run -d -p 5672:5672 -e WEB_MANAGE_UI=false robomq/rabbitmq
You can also choose which port numbers to use. For example, firewall rules may require you to use a firewall friendly URL such as `http://<broker-host>:8080/` to access web management UI:

	$ docker run -d -p 5672:5672 -p 8080:15672 robomq/rabbitmq
In another use case, suppose you run a client container which links to the broker. There is no need for the broker to publish port, because broker service is available via link name:

	$ docker run -d --name rabbit-service robomq/rabbitmq
	$ docker run -d --name client-app --link rabbit-service:broker client-app-image
	
Finally, if you run broker in Swarm, Kubernetes, or similar environments, please refer to networking documents for more specific instructions. 

## Get started with supported messaging protocols

Built on RabbitMQ, the broker supports several messaging protocols including AMQP 0-9-1 and MQTT.

* AMQP 0-9-1: This protocol is the "core" protocol supported by the broker. Please refer to [AMPQ client guide](https://www.rabbitmq.com/getstarted.html) for examples of client messaging scenarios in multiple languages.
* MQTT: Lightweight protocol for pub/sub messaging, targeted towards clients with small sensors and mobile devices.  Please refer to [MQTT client guide](https://github.com/mqtt/mqtt.github.io/wiki/libraries) for client APIs and device-specific examples.

# About RoboMQ
[RoboMQ](https://www.robomq.io) is an IoT & SaaS integration platform that can connect any device, sensor, SaaS application, enterprise system or cloud over any integration protocol.

The RoboMQ Integration platform is composed of messaging brokers, management UI, dashboards, analytics and value added components. 

