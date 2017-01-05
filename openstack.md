# Part III - Deploying on OpenStack

Welcome to the Stark & Wayne guide to deploying Cloud Foundry on OpenStack.

Before beginning with BOSH and different deployments, you need to set up your OpenStack environment. There are a few options you could use:

1. [DevStack On a VM][1] - This is a very simplified Openstack built into an Ubuntu image that gets set up and run with a single command in a VM. Note that this is for playing around with small environments only. 
2. [DevStack][2] - The full version of DevStack, fully configurable. DevStack is the developer version of OpenStack. It is what we will use for the documentation.
3. [OpenStack Marketplace][3] - If you don't mind sacrificing some low level configuration for a quicker 'up' time, then pick one of the many public clouds that are already hosted. Each has different 'flavors' and components of the main OpenStack.

Like stated, we will be using Option 2, the fully configurable DevStack. We will be running it on a single machine, but if you want a multi-node cluster, then you can follow [these documents][4].

## Deploying DevStack

#### DevStack on a Dedicated Linux Machine
So to get started, you will need a dedicated Linux machine - I have an HP laptop with 16GB of RAM which runs it fine. To begin, you will need to be connected to an ethernet cord and know the network interface name for it, and you have to configure/know your IP address on your network. Ethernet cable I can't help you out much with, but to figure out the network interface, run the following command. Chances are it will either be `eth0` or `eno1`.

```bash
# We want the first option.
$ ifconfig
eno1      Link encap:Ethernet  HWaddr 50:65:f3:b9:af:93  
          inet addr:192.168.1.16  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: fe80::b92:bc13:6620:18f2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:7751 errors:0 dropped:0 overruns:0 frame:0
          TX packets:6381 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:7913321 (7.9 MB)  TX bytes:693764 (693.7 KB)
wlo1      Link encap:Ethernet  HWaddr d0:7e:35:a0:33:d6  
          inet addr:192.168.1.3  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: fe80::6241:8b70:684d:464e/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:107 errors:0 dropped:0 overruns:0 frame:0
          TX packets:71 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:9339 (9.3 KB)  TX bytes:10114 (10.1 KB)
```

#### DevStack on a Virtual Machine 
  You can also run Devstack on a Virtual Machine. For example, we have lab workstation running Windows 10. Allocating 16GB or more of ram and a sizeable virtual disk to an instance of one of the supported plantforms (Ubuntu, Centos, etc..) dev stack will run quite happily with the bonus that it's easy to back up and move your entire lab environment. 

#### DevStack Setup
To actually get DevStack running, we will need to pull the repository. *Note that you will need a user with sudo priviledges for the process to work.*
```bash
# Install git if not already there
sudo apt-get install git -y || sudo yum install -y git
git clone https://git.openstack.org/openstack-dev/devstack
```

Switch into the new `devstack` directory, and create a file called `local.conf`. These are all the configurations for DevStack running on your machine. `local.conf` should look something like this:

```
[[local|localrc]]
FLAT_INTERFACE= < Network interface name to ethernet; ex: eth0 OR eno1 >
ADMIN_PASSWORD=supersecret
DATABASE_PASSWORD=iheartdatabases
RABBIT_PASSWORD=flopsymopsy
SERVICE_PASSWORD=iheartksl
```

After these are configured correctly to your network and you are connected via ethernet, you can simply run `./stack.sh`, give it some time - it takes 15 to 30 minutes pending your internet speed. It will install all the dependencies, download all the core features and dashboards, and automatically start it up. At the bottom it will give an address to visit the dashboard at.

```bash
$ ./stack.sh
..OUTPUT..
This is your host IP address: 192.168.1.16
This is your host IPv6 address: ::1
Horizon is now available at http://192.168.1.16/dashboard
Keystone is serving at http://192.168.1.16/identity/
The default users are: admin and demo
The password: supersecret
2016-08-11 00:16:07.106 | WARNING: 
2016-08-11 00:16:07.106 | Using lib/neutron-legacy is deprecated, and it will be removed in the future
2016-08-11 00:16:07.106 | stack.sh completed in 463 seconds.
```

The remaining is from my setup. If you visit the address given - the one ending in `/dashboard` then you should hopefully see the OpenStack dashboard.  You will need your `AUTH_URL`, and to know what that is you will need to run the openstack config and grep for the system variable.

```
$ openrc  # Run this in the devstack directory
OS_AUTH_URL=http://<SOME URL>
```

Now things always look much better than what they are, so let's run some tests just to make sure everything is set up. In the `devstack` directory, run the test scripts.

```bash
# Will run through every test and outputs the result.
$ ./exercise.sh
```

## Setting Up an OpenStack Project
In the `terraform/openstack` directory of this repo, create a file called `openstack.tfvars` and enter the above values in the following format, switching out `YOUR_NAME` and `YOUR_IP`:

```
tenant_name = "<YOUR_NAME>-cfproj"
user_name = "vcap"
password = "Cl0udC0w"
auth_url = "<YOUR OS AUTH URL>"
```


[1]: https://github.com/makelinux/devstack-install-on-iso
[2]: http://docs.openstack.org/developer/devstack/
[3]: http://www.openstack.org/marketplace/
[4]: http://docs.openstack.org/developer/devstack/guides/multinode-lab.html
