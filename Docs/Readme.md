# Supported tags and respective **DockerFile** links
 * latest, 3.6.12 ([3.6/Dockerfile](https://github.com/robomq/broker-docker/blob/master/3.6/Dockerfile))


# Quick reference

* **Where to get help:**
[Contact RoboMQ](https://robomq.io/about/about.html#contact), [Documentation](https://robomq.readthedocs.io/en/latest/), [Videos](https://www.youtube.com/channel/UCbgGrNg27jzB1z2uuT1FzKw/feed), [Blogs](https://robomq.io/vision/vision.html)

* **Where to file issues:**
[https://github.com/robomq/broker-docker/issues](https://github.com/robomq/broker-docker/issues)

* **Maintained by:**
[RoboMQ](https://www.robomq.io/)

* **Published image artifact details:**
 [repo-info](https://github.com/robomq/broker-docker)  `robomq/broker-docker`
*  **Supported Docker versions:**
Only Docker 17.03.0 CE and above

# What is RoboMQ

[RoboMQ](https://www.robomq.io)  is [Hybrid Integration Platform](https://robomq.io/solutions/hip.html) (HIP) that is built to integrate IoT, SaaS applications, cloud and on premise systems in a truly distributed and highly scalable business workflows across networks and clouds. RoboMQ is built with Docker and microservices architecture for the enterprise applications and businesses of today. Key differentiation of RoboMQ are :

1. [Any-to-Any Integration](https://robomq.io/products/product.html#IoT&SaaSMiddleware)
2. [Microservices architecture](https://robomq.io/solutions/microservices.html)
3. [Hybrid Messaging Cloud](https://robomq.io/products/product.html#HybridMessagingCloud)

[RoboMQ](https://www.robomq.io)  provides added components on the top of core AMQP 0-9-1 broker based built on the strengths of [rabbitmq](https://www.r.io). RoboMQ offers added components that are built with message oriented middleware and microservices architecture. The core broker and all the value added components are packaged as docker containers.  The value added components provide capabilities like Messaging dashboard, Quboid smart container, API gateway, API layer, Error Analytics and exception handlers, Event Logging, and health checks and on demand diagnostics, Mission Control. 


> [www.robomq.io](https://www.robomq.io)

![](https://robomq.io/solutions/images/Product%20illustrations%20-%20Pluggable%20transport.png "")

# How to use this image

RoboMQ broker is a pre-configured messaging broker image built upon [RabbitMQ](https://www.rabbitmq.com/) 3.6.12, ready for deployment in production environment with support for cluster, federation, and management capabilities.

**The RoboMQ broker can be deployed standalone or as a cluster. This setup guide is organized along four sections:**
1. **Prerequisites** - Needed for both standalone and clustered broker
2. **Run Standalone Broker **
3. **Common management tasks** - Applicable to both standalone and clustered broker**
4. **Run Clustered Broker**



# 1. Prerequisites

Ensure the following ports are open on the network for the AMQP client or microservices access.  These ports are used by clients or microservices to access or manage broker services and use messaging transport.  If the broker runs behind a firewall which blocks these ports, you will need to either change firewall rules to unblock the ports, or switch to an available port permitted by firewall:

* AMQP: 5672
* MQTT: 1883
* Management UI: 15672

For cluster setup, open following additional ports to allow communication among the clustered hosts, not applicable for standalone setup:

* Peer discovery: 4369
* Inter-node communication: 25672

Please refer to [Rabbitmq Clustering Guide - Firewalled nodes](https://www.rabbitmq.com/clustering.html#firewall) and [Rabbitmq Networking Guide](https://www.rabbitmq.com/networking.html) for more details.

# 2. Run Standalone Broker
Standalone setup runs a single docker instance of RoboMQ broker. It is suitable for development or prototyping. For the production deployments, **clustered setup** should be used.

##### 2.1 Run the broker

```bash
$ docker run -d --name mybroker -p 5672:5672 -p 1883:1883 -p 15672:15672 --restart always robomq/broker
```
               
 
You can choose a different container name by changing the --name option


# 3. Common management tasks

These are the common management tasks that apply to the broker setup both in the standalone as well as clustered setup. 

##### 3.1 Show status of the running broker container:

```bash
$ docker ps -f name=<container name> ```

##### 3.2 Restart, stop, or remove broker

```bash
$ docker restart <container name> 
$ docker stop <container name> 
$ docker rm -v <container name> 
```

##### 3.3 View the broker container logs

```bash
$ docker logs <container name> 
```

You will see logs similar to:

```bash
==========================================================================
Broker rabbit@8823c6d94248 is running. Supports AMQP/MQTT by default.

    Default User     : admin
    Default Password : 942b020d5962
    Default Vhost    : /
    ERLANG_COOKIE    : QAYBCTIFOSOIYVMABAED
```


##### 3.4 Update system generated default password for admin user
Use this command executing through a shell in the broker container:

```bash
$ docker exec <container name> rabbitmqctl change_password admin <password>
```

##### 3.5 Access the web Management UI

Web Management UI can now be accessed with admin user credential, admin:<password> through URL:
http://<broker-host>:15672/

You will see web interface similar to:

![Broker Web Management UI](https://www.robomq.io/images/management_ui.png)

***Access the HTTP API***
You can also connect to the broker HTTP API.  Try running the following command to list virtual hosts, after replacing <user>:<password> with values given in broker logs:

```bash
 $ curl -u <user>:<password> http://<broker-host>:15672/api/vhosts
```

You should see outputs like [{"name":"/","tracing":false}], indicating you have correct login credentials to access broker's HTTP API.

***How to use web management UI***

Please refer to [Rabbitmq Management Plugin Guide](https://www.rabbitmq.com/management.html) for how to manage your broker via web UI or HTTP API, for example, to create and manage virtual hosts and users.


##### 3.6 Set container hostname (Recommended)

It is a good practice to use --hostname or -h option to choose a container hostname for the broker:

```bash
$ docker run -d --name <container name> -p 5672:5672 -p 1883:1883 -p 15672:15672 -h myhost --restart always robomq/broker
```


#####  3.7 Set default user/password/vhost (Recommended)
For better security, set default non-admin user, default password, and default vhost, or any combination of these to your own choice:

```bash
$ docker run -d --name <container name> \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 -h myhost \
    -e DEFAULT_USER=myuser -e DEFAULT_PASSWORD=mypass \
    -e DEFAULT_VHOST=myvhost \ 
    --restart always robomq/broker
```

If you do not choose a password for default user at first run, system will automatically generate a random password for the default  user. You can either change that default user and password combination from the web management UI or run this command:

```bash
$ docker exec <container name> rabbitmqctl change_password <user> <password>
```

##### 3.8 Persist broker data (Recommended)

To persist your broker data and configurations, you should mount a volume to the host server or VM that will map to the container volume /var/lib/rabbitmq using the -v option. All the configurations will then be saved to the host volume and can be used after the container has been deleted or terminated.

If you run the image without volume mount and your container is deleted or removed, the broker database will be reinitialized and your data will be lost, when you run the container next time.

***Standalone***

```bash
$ docker run –d --name <container name> \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 -h myhost \
    -v /path-to-host:/var/lib/rabbitmq \
    --restart always robomq/broker
```

***Clustered***

To persist broker cluster data and configurations, as in the Standalone Broker section, you should mount a volume for each broker node (Below example is in line with instructions in section `4.3 Start brokers in clustered mode`):

```bash
$ docker run -d --name broker01 -h host1 \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    -v /path-to-host:/var/lib/rabbitmq \
    --restart always robomq/broker

$ docker run -d --name broker02 -h host2 \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    -v /path-to-host:/var/lib/rabbitmq \
    -e HEAD_NODE=host1 \
    --restart always robomq/broker

$ docker run -d --name broker03 -h host3 \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    -v /path-to-host:/var/lib/rabbitmq \
    -e HEAD_NODE=host1 \
    --restart always robomq/broker
```

Please change "path-to-host" to a designated folder on your host or VM disk to store the broker configuration data.  

**Recovering deleted broker container with last known state:** In case the broker is removed or deleted, run the same command to recreate it; the new broker will recover its data and configurations from the last known state saved on the mapped volume.

After removing a broker with persisted data, if you want to recreate broker with a clean state, you need to either delete the contents of the host directory, or mount a different host directory.

**Important Reminder:**  *When making broker configuration persistent, you should always use --hostname or -h option.  When you recreate a new broker from the last known state, you should reuse the same hostname of the removed container and not change it to a new one. The persisted broker configuration is linked to the hostname.*


##### 3.9 Mount startup config files (For advanced users)

For fine tuning your broker, you can also mount one or both following startup configuration files externally:
/etc/rabbitmq/rabbitmq.config
/etc/rabbitmq/enabled_plugins

```bash
$ docker run -d --name <container name> \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 -h myhost \
    -v "/path-to-host"/rabbitmq.config:/etc/rabbitmq/rabbitmq.config \
    -v "/path-to-host"/enabled_plugins:/etc/rabbitmq/enabled_plugins \
    --restart always robomq/broker
```

Please change `path-to-host` to the full path of the host directory where you placed these config files.  When using the mounted config, those settings override the default rabbitmq configuration:
* When `rabbitmq.config` file is mounted, `DEFAULT_USER`, `DEFAULT_PASSWORD` and `DEFAULT_VHOST` are ignored.
* When `enabled_plugins` file is mounted, `WEB_MANAGE_UI`  (setting to enable disable web management UI) is ignored.


##### 3.10 Enable/disable web management UI
By default web management UI is enabled on all nodes in a cluster. You can keep the management UI up on few nodes on the cluster and disable it on others to conserve resources. For example, to start broker03 with web management UI disabled, use the following command with flag `WEB_MANAGE_UI=false `:

```bash
$ docker run –d --name <container name> \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 -h broker \
    -e WEB_MANAGE_UI=false \
    --restart always robomq/broker
```
##### 3.11 Set log level

Connection related events are logged to console, with default verbosity level of info. The supported options are `debug|info|warning|error|none`:

```bash
$ docker run -d --name <container name> \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 -h myhost \
    -e BROKER_LOG_LEVEL=error \
    --restart always robomq/broker
```

##### 3.12 Use rabbitmqctl CLI tool
Rabbitmq provides a CLI tool, rabbitmqctl, to manage broker. It can be used for example, to query status, users, and vhosts of the running broker:

```bash
$ docker exec -it mybroker rabbitmqctl status
$ docker exec -it mybroker rabbitmqctl list_users
$ docker exec -it mybroker rabbitmqctl list_vhosts
```


Please refer to [rabbitmqctl manual page](https://www.rabbitmq.com/man/rabbitmqctl.1.man.html) for how to use this CLI tool to manage your broker.

##### 3.13 Tune performance (For advanced users)
The default memory threshold at which memory alarm and [flow control](https://www.rabbitmq.com/memory.html) are triggered is 0.8, or 80% of installed RAM or available virtual memory address space. The advanced user can tune it to desired value. For example the below script sets the threshold to 40% or 0.4:

```bash
$ docker run -d --name <container name> \
    -e RABBITMQ_VM_MEMORY_HIGH_WATERMARK=0.4 \
    --restart always robomq/broker
```


You can also precompile parts of RabbitMQ with HiPE (High Performance Erlang Engine):

```bash
$ docker run -d --name <container name> \
    -e RABBITMQ_HIPE_COMPILE=true \
    --restart always robomq/broker
```

This will increase server throughput at the cost of increased startup time.  Performance varies, but you might see 20-50% improvement at the cost of a few minutes delay at startup.


# 4. Run Clustered Broker
In the clustered setup, multiple docker brokers form a cluster running on separate VM or machines.

##### 4.1 Setup hosts
You can create a cluster with any number of broker nodes.  One node in the cluster is designated as head node, which is joined by other nodes to form cluster.  Broker nodes address each other using domain names, either short or fully-qualified (FQDNs). Therefore, hostnames of all cluster members must be resolvable from all cluster nodes.  Please refer to [Rabbitmq Clustering Guide](https://www.rabbitmq.com/clustering.html#clustering).


In this example setup, each broker node runs on a separate server or VM host to avoid port conflicts. You need to find out each host's IP address/short hostname/long hostname or FQDN.  For example, on Linux system, this command prints it on separate lines:

```bash
$ hostname --ip-address; hostname --short; hostname --long; hostname --domain
```

The following sections assumes that a host "N" is configured with "hostN" for short name and "hostN.example.com" for long name or FQDN.  Please replace them in the following commands with values of your own server name setting.

##### 4.2 Choose your own shared secret (Recommended)
The broker nodes in the cluster authenticate to each other using a shared secret, called the [Erlang Cookie](https://www.rabbitmq.com/clustering.html).  This shared secret or cookie is just an alphanumeric string.  It can be of any arbitrary length.  All cluster nodes must have the same cookie.  For security reason, please choose a long string as your own cookie in production, and replace `ClusterSecret` with it in the command.

The erlang cookie is saved in cookie file, `/var/lib/rabbitmq/.erlang.cookie`.  If volume `/var/lib/rabbitmq/` is mounted (see Persist broker cluster data section), you can supply a cookie file before broker creation.  The cookie file content overrides `RABBITMQ_ERLANG_COOKIE` when both are present.  However, if the values mismatch, you will get a warning but broker will start with the ClusterSecret from the cookie file.

#### 4.3 Start brokers in clustered mode

**Note:**  *To create clustered brokers, you must assign container hostnames resolvable by all broker nodes.  In our example, broker container hostnames are set to server/VM hostnames.  Therefore, broker nodes will rely on server/VM DNS settings to resolve each other without additional DNS and network setup.*

##### 4.3.1 Clustering using long hostname or FQDN
1. Start broker node 1 with hostname "host1.example.com"as head node of the cluster:

```bash
$ docker run -d --name broker01 -h host1.example.com \
-p 5672:5672 -p 1883:1883 -p 15672:15672 \
-p 4369:4369 -p 25672:25672 \
-e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
-e RABBITMQ_USE_LONGNAME=true \
--restart always robomq/broker
```

2. From host for broker node 2 with hostname "host2.example.com", verify that head node (broker01) can be reached via ports 4369 and 25672:

```bash
$ nc -z -v host1.example.com 4369
$ nc -z -v host1.example.com 25672
```
Then start broker node 2 to join node 1:

```bash
$ docker run -d --name broker02 -h host2.example.com \
 -p 5672:5672 -p 1883:1883 -p 15672:15672 \
 -p 4369:4369 -p 25672:25672 \
 -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
 -e RABBITMQ_USE_LONGNAME=true \
 -e HEAD_NODE=host1.example.com \
 --restart always robomq/broker
```

3. You can add any number of additional nodes to join node 1 or the headnode, for example add node 3 with hostname "host3.example.com":

```bash
$ docker run -d --name broker03 -h host3.example.com \
-p 5672:5672 -p 1883:1883 -p 15672:15672 \
-p 4369:4369 -p 25672:25672 \
 -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
 -e RABBITMQ_USE_LONGNAME=true \
 -e HEAD_NODE=host1.example.com \
 --restart always robomq/broker
```

Any of the broker logs from the added broker, for example Broker03 logs should indicate successful cluster formation similar to:

```bash
Broker rabbit@host3.example.com is running. Supports AMQP/MQTT by default.
Success: Join cluster with HEAD_NODE: rabbit@host1.example.com
....
{running_nodes,['rabbit@host1.example.com','rabbit@ host2.example.com',
    'rabbit@host3.example.com']},
```
**You can also check the cluster status with following command on any node:**

```bash
$ docker exec broker01 rabbitmqctl cluster_status
```


##### 4.3.2 Clustering using short hostname
The following is a more common way to create broker cluster using short hostnames.  Before proceeding, verify that all hosts are DNS-reachable via short hostnames:

```bash
$ ping hostname
```

To set up broker cluster using short hostnames, set `RABBITMQ_USE_LONGNAME=false` or just remove it:

1. Start broker node 1 with hostname "host1"as head node of the cluster:

```bash
$ docker run -d --name broker01 -h host1 \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    --restart always robomq/broker
```

2. Then start broker node 2 with hostname "host2" to join node 1:

```bash
$ docker run -d --name broker02 -h host2 \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    -e HEAD_NODE=host1 \
    --restart always robomq/broker
```

3. You can add any number of additional nodes to join node 1, for example add node 3 with hostname "host3":

```bash
docker run -d --name broker03 -h host3 \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    -e HEAD_NODE=host1 \
    --restart always robomq/broker
```


**Note**: In some environments, only long hostnames are resolvable ((FQDNs).  Therefore, if you still want to use short hostnames, you need to add --dns-search example.com option to the commands.

##### 4.3.3 Clustering in private DNS setting (For advanced users)
In some restrictive environments, such as a private network, an internal DNS server is set up to resolve private hostnames.  For example, if a company example.com has a private subnet or zone dc1, and this zone has a broker node N with short hostname hostN, then broker node N has a private FQDN of "hostN.dc1.example.com":

```bash
$ nslookup hostN.dc1.example.com
```

Specify DNS server and DNS search domain to handle this case:

```bash
$ docker run -d --name broker01 -h host1 \
    --dns=<Private-DNS-Domain> --dns-search=dc1.example.com \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    --restart always robomq/broker

$ docker run -d --name broker02 -h host2 \
    --dns=<Private-DNS-Domain> --dns-search=dc1.example.com \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    -e HEAD_NODE=host1 \
    --restart always robomq/broker

$ docker run -d --name broker03 -h host3 \
    --dns=<Private-DNS-Domain> --dns-search=dc1.example.com \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    -e HEAD_NODE=host1 \
    --restart always robomq/broker
```


##### 4.4 Manage your broker cluster
To manage and retrieve status of running broker cluster here are some helpful command line tools and tips:

1.  Retrieve cluster status of individual nodes from the logs:

```bash
$ docker logs broker01
```

2. View the nodes currently joined in a cluster through rabbitmq cluster status command:

```bash
$ docker exec broker01 rabbitmqctl cluster_status
```

3. Access web management UI using login credentials given in head node logs when it is created.
4. Specify the `DEFAULT_USER`, `DEFAULT_PASSWORD`, `DEFAULT_VHOST` when creating the head node (recommended to achieve better security).
5. Enable/disable web management UI for any broker node (by default it is enabled for all nodes). In a large cluster it might be a better idea to save resources and enable management UI in selected nodes only. 
4. Use rabbitmqctl tool to manage your broker cluster.

*Finally, if you run broker in SWARM, Kubernetes, or similar environments, please refer to networking documents for more specific instructions.*

##### 4.5 Use RAM node (for advanced users only)
Broker nodes can be either disk node or RAM node.  By default, a broker node runs as a disk node.  In some cases, you may set broker to RAM node to get better performance. For example, to start broker03 as RAM Node:

```bash
$ docker run -d --name broker03 -h host3 \
    -p 5672:5672 -p 1883:1883 -p 15672:15672 \
    -p 4369:4369 -p 25672:25672 \
    -e RABBITMQ_ERLANG_COOKIE=ClusterSecret \
    -e HEAD_NODE=host1 \
    -e RAM_NODE=true
    --restart always robomq/broker
```

RAM node is a special case so use with care.  [See RabbitMQ Clustering Guide - Clusters with RAM nodes](https://www.rabbitmq.com/clustering.html#ram-nodes) and if in doubt, use the default disc node.


# **Get started with supported messaging protocols**

RoboMQ broker supports several messaging protocols including AMQP 0-9-1 and MQTT.
* AMQP 0-9-1: This protocol is the "core" protocol supported by the broker.  Please refer to [AMPQ client guide](https://www.rabbitmq.com/getstarted.html) for examples of client messaging scenarios in multiple languages.
* MQTT: Lightweight protocol for pub/sub messaging, targeted towards clients with small sensors and mobile devices. 
 Please refer to [MQTT client guide](https://github.com/mqtt/mqtt.github.io/wiki/libraries) for client APIs and device-specific examples.


# License
View [license](https://github.com/robomq/broker-docker/blob/master/LICENSE) information for the software contained in this image.
