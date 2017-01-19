# OpenStack Codex Walkthrough

(( insert_file overview.md ))
## Setup Credentials

To start deploying the infrastructure, the first thing you need to do is create
an OpenStack user and give it admin access to a new tenant.

1. Log into Horizon as the **admin** user.
2. Under **Identity --> Projects**, create a new project and set the quotas to
   accommodate the environment(s) that will be deployed to this project.

   Keep in mind:  If setting specific quotas, you will need to ask for more than
   the total resources that you are going to end up with.  This is to account for
   transient instances, such as BOSH errands and Compilation instances.

   For a typical development environment:
   * **VCPUs** - 200
   * **Instances**  - 100
   * **Volumes**    - 25
   * **RAM (MB)**   - 512000

   For a typical staging / production environment:
   * **VCPUs** - 200
   * **Instances**  - 100
   * **Volumes**    - 25
   * **RAM (MB)**   - 512000

3. Under **Identity --> Users**, create a new user.  Give the user **admin** access
   to the new project.

### Generate OpenStack Key Pair

The **User Name**, **Password**, and **Tenant Name** (same as **Project Name**) are
used to get access to the OpenStack Services by BOSH.  Next, we'll need to create a
**Key Pair**.  This will be used as we bring up the initial bastion host instances,
and is the SSH key you'll use to connect from your local machine to the bastion.

**NOTE**: Make sure you are in the correct project (top-left corner of the Horizon
UI) when you create your **OpenStack Key Pair**. Otherwise, it just plain won't
work.

1. Log into Horizon as the user that has admin access to the project in question.

2. Under **Project --> Compute --> Access & Security**, head to the **Key Pairs**
   tab.

3. When creating the Key Pair in Kilo or earlier, you can simply use the
   **Create Key Pair** functionality.  In Liberty and later, you MUST separately
   create an RSA keypair using `ssh-keygen` and import the public key using the
   **Import Key Pair** function.  This is a known problem between BOSH and versions
   of OpenStack starting with Mitaka onward.

   Also, ensure that the private key (whether a downloaded \*.pem file or separately
   generated) has permissions of `0600`.

4. Decide where you want this file to be.  All `*.pem` files are ignored in the
codex repository.  So you can either move this file to the same folder as
`CODEX_ROOT/terraform/openstack` or move it to a place you normally keep SSH keys

## Stand Up A Public Network
Though Terraform is used to stand up most of the networking and initial infrastructure,
it does not set up the publicly facing network that is used to provide external
access to instances and floating IP addresses.  To do this, use `neutron net-create`,
`neutron subnet-create`, to create the public network and allocate the pool of publicly
facing IP addresses, some of which will be used as floating IP's.

Some sample commands are as follows (these will vary depending on the physical structure
  of your network, the configuration of neutron, and whether or not you are using a
  3rd party SDN plugin):
```
neutron net-create public --provider:network_type vlan --provider:physical_network physnet1 --provider:segmentation_id 100 --tenant-id=3c155e766d1d44718cd35765c709fae1 --shared --router:external=True
neutron subnet-create public 	172.26.75.0/24 --disable-dhcp --allocation-pool start=172.26.75.110,end=172.26.75.250 --gateway 172.26.75.1
```

Make note of the public network's UUID.  It will be needed in the next step.

## Use Terraform

Once the requirements for OpenStack are met, we can put it all together and build out
your shiny new networks, routers, security groups and bastion host. Change
to the `terraform/openstack` sub-directory of this repository before we begin.

The configuration directly matches the [Network Plan][netplan] for the demo
environment.  When deploying in other environments like production, some tweaks
or rewrites may need to be made.

### Variable File

Create an `openstack.tfvars` file with the following configurations (substituting your
actual values) all the other configurations have default setting in the
`CODEX_ROOT/terraform/openstack/openstack.tf` file.

```
tenant_name = "cf"
user_name = "cfadmin"
password = "putyourpasswordhere"
auth_url = "(( insert_parameter openstack.auth_url ))"
key_pair = "bosh"
region = "(( insert_parameter openstack.region ))"
pub_net_uuid = "09b03d93-45f8-4bea-b3b8-7ad9169f23d5"
```

If you need to change the region or subnet, you can override the defaults
by adding:

```
region     = "RegionTwo"
network    = "10.42"
```

You may change some default settings according to the real cases you are
working on. For example, you can change `flavor_id` (default is `3`, which is
m1.medium) in `openstack.tf` to something larger if the bastion would require a
high workload.

### Build Resources

As a quick pre-flight check, run `make manifest` to compile your Terraform plan
and suss out any issues with naming, missing variables, configuration, etc.:

```
$ make manifest
terraform get -update
terraform plan -var-file openstack.tfvars -out openstack.tfplan
Refreshing Terraform state prior to plan...

<snip>

Plan: 129 to add, 0 to change, 0 to destroy.
```

If everything worked out you should see a summary of the plan.  If this is the
first time you've done this, all of your changes should be additions.  The
numbers may differ from the above output, and that's okay.

Now, to pull the trigger, run `make deploy`:

```
$ make deploy
```

Terraform will connect to OpenStack, using your **User Name**, **Password**, and
**Tenant Name**, and spin up all the things it needs.  When it finishes, you should
be left with a bunch of subnets, security groups, and a bastion host.

If you run into issues before this point refer to our [troubleshooting][troubleshooting_openstack]
doc for help.

### Connect to Bastion

You'll use the **Key Pair** `*.pem` or `ssh-keygen` generated file that was stored from the
[Generate OpenStack Key Pair](openstack.md#generate-openstack-key-pair) step before as your credential
to connect.

In forming the SSH connection command, use the `-i` flag to give SSH the path to
the `IdentityFile`.  The default user on the bastion server is `ubuntu`.  This
will change in a little bit though when we create a new user, so don't get too
comfy.

```
$ ssh -i ~/.ssh/bosh ubuntu@(( insert_parameter openstack.jumpbox_ip ))
```

(( insert_file bastion_setup.md ))
(( insert_file proto_intro.md ))
(( insert_file vault_init.md ))
(( insert_file proto_bosh_intro.md ))
#### Make Manifest

Let's head into the `proto/` environment directory and see if we
can create a manifest, or (a more likely case) we still have to
provide some critical information:

```
$ cd ~/ops/bosh-deployments/(( insert_parameter site.name ))/proto
$ make manifest
9 error(s) detected:
 - $.cloud_provider.properties.openstack.default_key_name: What is your full key name?
 - $.cloud_provider.properties.openstack.default_security_groups: What Security Groups?
 - $.cloud_provider.ssh_tunnel.private_key: What is the local path to the Private Key for this deployment?  Due to a bug in Openstack Liberty and Mitaka, you need to use an SSH key generated by ssh-keygen, not one generated by Nova.
 - $.meta.openstack.api_key: Please supply an Openstack password
 - $.meta.openstack.auth_url: Please supply the authentication URL for the Openstack Identity Service
 - $.meta.openstack.tenant: Please supply an Openstack tenant name
 - $.meta.openstack.username: Please supply an Openstack user name
 - $.meta.shield_public_key: Specify the SSH public key from this environment's SHIELD daemon
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network
Availability Zone will BOSH be in?


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Drat. Let's focus on the `$.meta` subtree, since that's where most parameters are defined in
Genesis templates:

```
- $.meta.openstack.api_key: Please supply an Openstack password
- $.meta.openstack.auth_url: Please supply the authentication URL for the Openstack Identity Service
- $.meta.openstack.tenant: Please supply an Openstack tenant name
- $.meta.openstack.username: Please supply an Openstack user name
```

This is easy enough to supply.  We'll put these properties in
`properties.yml`:

```
$ cat properties.yml
---
meta:
  openstack:
    api_key:  (( vault meta.vault_prefix "/openstack:api_key" ))
    tenant:   (( vault meta.vault_prefix "/openstack:tenant" ))
    username: (( vault meta.vault_prefix "/openstack:username" ))
    auth_url: (( insert_parameter openstack.auth_url ))
    region: (( insert_parameter openstack.region ))
```

Configure the OpenStack credentials by pointing
Genesis to the Vault.  Let's go put those credentials in the
Vault:

```
$ export VAULT_PREFIX=secret/(( insert_parameter site.name ))/proto/(( insert_parameter openstack.bosh_name ))
$ safe set ${VAULT_PREFIX}/openstack tenant=cf username=cfadmin api_key=putyourpasswordhere
```

Let's try that `make manifest` again.

```
$ make manifest
5 error(s) detected:
- $.cloud_provider.properties.openstack.default_key_name: What is your full key name?
- $.cloud_provider.properties.openstack.default_security_groups: What Security Groups?
- $.cloud_provider.ssh_tunnel.private_key: What is the local path to the Private Key for this deployment?  Due to a bug in Openstack Liberty and Mitaka, you need to use an SSH key generated by ssh-keygen, not one generated by Nova.
- $.meta.shield_public_key: Specify the SSH public key from this environment's SHIELD daemon
- $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Better. Let's configure our `cloud_provider` for OpenStack, using our OpenStack key pair.
We need copy our private key to the bastion host and path to the key for the
`private_key` entry in the following `properties.yml`.

On your local computer, you can copy to the clipboard with the `pbcopy` command
on a macOS machine:

```
cat ~/.ssh/cf-deploy.pem | pbcopy
<paste values to /path/to/the/openstack/key.pem>
```

Then add the following to the `properties.yml` file.

```
$ cat properties.yml
---
meta:
...
cloud_provider:
  properties:
    openstack:
      default_key_name: bosh
      connection_options:
        connect_timeout: 600
      ignore_server_availability_zone: true
  ssh_tunnel:
    host: (( grab jobs.bosh.networks.default.static_ips.0 ))
    private_key: ~/.ssh/bosh
```

Note here the `ignore_server_availability_zone`.  This setting needs to be set to
`true` if the AZ for Cinder is not the same as the one for Nova.  Otherwise,
BOSH will have difficulty creating block storage volumes.

Once more, with feeling:

```
$ make manifest
3 error(s) detected:
 - $.cloud_provider.properties.openstack.default_security_groups: What Security Groups?
 - $.meta.shield_public_key: Specify the SSH public key from this environment's SHIELD daemon
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Excellent.  We're down to three issues.

(( insert_file proto_bosh_shield_ssh_key.md ))
Now, we should have only two errors left when we `make
manifest`:

```
$ make manifest
2 error(s) detected:
 - $.cloud_provider.properties.openstack.default_security_groups: What Security Groups?
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

So it's down to networking.

Refer back to your [Network Plan][netplan], and find the `global-infra-0`
subnet for the proto-BOSH in Horizon.  If you're using the plan in this
repository, that would be `10.4.1.0/24`, and we're allocating
`10.4.1.0/28` to our BOSH Director.  Our `networking.yml` file,
then, should look like this:

```
$ cat networking.yml
---
networks:
  - name: default
    subnets:
      - range: 10.4.1.0/24
        gateway: 10.4.1.1
        dns: [(( insert_parameter openstack.bosh_dns_ips ))]
        cloud_properties:
          net_id: b5bfe2d1-fa17-41cc-9928-89013c27e266   # <- Global-Infra-0 Network UUID
        reserved:
          - 10.4.1.2 - 10.4.1.3
          - 10.4.1.10 - 10.4.1.254
        static:
          - 10.4.1.4
jobs:
  - name: bosh
    networks:
    - name: default
      static_ips: (( static_ips(0) ))

cloud_provider:
  properties:
    openstack:
      default_security_groups: [default]
```

Our range is that of the actual subnet we are in, `10.4.1.0/24`
(in reality, the `/28` allocation is merely a tool of bookkeeping).  As such, our
neutron-provided default gateway is 10.4.1.1 (the first available
IP from the associated router).  DNS needs to be the IP's provided by your
OpenStack administrator.

We identify our OpenStack-specific configuration under
`cloud_properties`, by calling out the **Network UUID** - NOT the subnet UUID, of
the internal neutron network we wish to use.  We also define the security groups
BOSH will be bound to.

Under the `reserved` block, we reserve the first few IPs (in case they are used
  for other network services such as DNS, etc.), and everything outside of
`10.4.1.0/28` (that is, `10.4.1.16` and above).

Finally, in `static` we reserve the first usable IP (`10.4.1.4`)
as static.  This will be assigned to our `bosh/0` director VM.

(( insert_file proto_bosh_deploy.md ))
(( insert_file proto_vault_intro.md ))
```
$ cd ~/ops/vault-deployments/(( insert_parameter site.name ))/proto
$ make manifest
7 error(s) detected:
- $.meta.openstack.azs.z1: Define the z1 OpenStack availability zone
- $.meta.openstack.azs.z2: Define the z2 OpenStack availability zone
- $.meta.openstack.azs.z3: Define the z3 OpenStack availability zone
- $.networks.vault_z1.subnets: Specify the z1 network for vault
- $.networks.vault_z2.subnets: Specify the z2 network for vault
- $.networks.vault_z3.subnets: Specify the z3 network for vault
- $.properties.vault.ha.domain: What fully-qualified domain name do you want to access your Vault at?


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Vault is pretty self-contained, and doesn't have any secrets of
its own.  All you have to supply is your network configuration,
and any IaaS settings.

Referring back to our [Network Plan][netplan] again, we
find that Vault should be striped across three zone-isolated
networks:

  - **10.4.1.16/28** in zone 1 (a)
  - **10.4.2.16/28** in zone 2 (b)
  - **10.4.3.16/28** in zone 3 (c)

First, lets do our OpenStack-specific region/zone configuration, along with our Vault HA fully-qualified domain name:

```
$ cat properties.yml
---
meta:
  openstack:
    azs:
      z1: dc01
      z2: dc01
      z3: dc01

properties:
  vault:
    ha:
      domain: 10.4.1.17
```

Our `/28` ranges are actually in their corresponding `/24` ranges
because the `/28`'s are (again) just for bookkeeping and ACL
simplification.  That leaves us with this for our
`networking.yml`:

```
$ cat networking.yml
---
networks:
  - name: vault_z1
    subnets:
    - range:    10.4.1.0/24
      gateway:  10.4.1.1
      dns:     [8.8.8.8, 8.8.4.4]
      cloud_properties:
        net_id: b5bfe2d1-fa17-41cc-9928-89013c27e266   #  ID for global-infra-0
        security_groups: [wide-open]
      reserved:
        - 10.4.1.2 - 10.4.1.15
        - 10.4.1.32 - 10.4.1.254                       # Vault (z1) is in 10.4.1.16/28
      static:
        - 10.4.1.16 - 10.4.1.18

  - name: vault_z2
    subnets:
    - range:    10.4.2.0/24
      gateway:  10.4.2.1
      dns:     [8.8.8.8, 8.8.4.4]
      cloud_properties:
        net_id: 2977ae9f-88f5-4d12-ad8e-1e393731ebb7   #  ID for global-infra-1
        security_groups: [wide-open]
      reserved:
        - 10.4.2.2 - 10.4.2.15
        - 10.4.2.32 - 10.4.2.254                       # Vault (z2) is in 10.4.2.16/28
      static:
        - 10.4.2.16 - 10.4.2.18

  - name: vault_z3
    subnets:
    - range:    10.4.3.0/24
      gateway:  10.4.3.1
      dns:     [8.8.8.8, 8.8.4.4]
      cloud_properties:
        net_id: 47f76643-ee72-44a3-b47f-a43e9c6ea8d2   #  ID for global-infra-2
        security_groups: [wide-open]
      reserved:
        - 10.4.3.2 - 10.4.3.15
        - 10.4.3.32 - 10.4.3.254                       # Vault (z3) is in 10.4.3.16/28
      static:
        - 10.4.3.16 - 10.4.3.18
```

That's a ton of configuration, but when you break it down it's not
all that bad.  We're defining three separate networks (one for
each of the three availability zones).  Each network has a unique
OpenStack Network UUID, but they share the same Security Groups, since
we want uniform access control across the board.

The most difficult part of this configuration is getting the
reserved ranges and static ranges correct, and self-consistent
with the network range / gateway / DNS settings.  This is a bit
easier since our network plan allocates a different `/24` to each
zone network, meaning that only the third octet has to change from
zone to zone (x.x.1.x for zone 1, x.x.2.x for zone 2, etc.)

(( insert_file proto_vault_deploy.md ))
(( insert_file proto_vault_init.md ))
(( insert_file shield_intro.md ))
### Setting up Object Storage For Backup Archives

To help keep things isolated, we're going to set up a brand new
user just for backup archive storage.  It's a good idea to
name this user something like `backup` or `shield-backup` so that
no one tries to re-purpose it later, and so that it doesn't get
deleted.

We also need to generate an S3 access key for this user and store those credentials
in the Vault:

```
$ openstack ec2 credentials create --user shield-backup --project cf
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| access     | 453389616a724f74b5ba0c9e6874f77d |
| project_id | 4116a3a098e64ff086b21ffba9dd2b2e |
| secret     | 64206456a18946f88399103be7dc6a8f |
| trust_id   | None                             |
| user_id    | 95aaf239306f45759d0adc7f4855c12d |
+------------+----------------------------------+

$ export VAULT_PREFIX=secret/(( insert_parameter site.name ))/proto/shield
$ safe set ${VAULT_PREFIX}/s3 access_key secret_key
access_key [hidden]:
access_key [confirm]:

secret_key [hidden]:
secret_key [confirm]:
```

You're also going to want to provision a dedicated bucket to
store archives in, and name it something descriptive, like
`codex-backups`.

(( insert_file shield_setup.md ))
Next, we `make manifest` and see what we need to fill in.
```
$ make manifest
3 error(s) detected:
 - $.meta.az: What availability zone is SHIELD deployed to?
 - $.networks.shield.subnets: Specify your shield subnet
 - $.properties.shield.daemon.ssh_private_key: Specify the SSH private key that the daemon will use to talk to the agents


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

By now, this should be old hat.  According to the [Network
Plan][netplan], the SHIELD deployment belongs in the
**10.4.1.32/28** network, in (( insert_parameter site.name )).  Let's put that
information into `properties.yml`:

```
$ cat properties.yml
---
meta:
  az: (( insert_parameter site.name ))
```

As we found with Vault, the `/28` range is actually in it's outer
`/24` range, since we're just using the `/28` subdivision for
convenience.

```
$ cat networking.yml
---
networks:
  - name: shield
    subnets:
    - range:    10.4.1.0/24
      gateway:  10.4.1.1
      dns:     [8.8.8.8, 8.8.4.4]
      cloud_properties:
        net_id: b5bfe2d1-fa17-41cc-9928-89013c27e266   #  ID for global-infra-0
        security_groups: [wide-open]
      reserved:
        - 10.4.1.2 - 10.4.1.31
        - 10.4.1.48 - 10.4.1.254                       # SHIELD is in 10.4.1.32/28
      static:
        - 10.4.1.32 - 10.4.1.32
  - name: floating
    type: vip
    cloud_properties:
      net_id: 09b03d93-45f8-4bea-b3b8-7ad9169f23d5     # ID for public
      security_groups: [wide-open]
jobs:
- name: shield
  networks:
  - name: shield
    default: [dns, gateway]
  - name: floating
    static_ips:
    - (( insert_parameter openstack.shield_fip ))
```

(Don't forget to change your `subnet` to match your OpenStack Network UUID and
associated security group.)

Also, in this case (as will be seen later with things like Bolo and Cloud Foundry),
we are adding a Floating IP to this instance, so we can access the SHIELD UI.  To do
this, we have added another network called `floating`, gave it a type `vip`, and
gave it the Network UUID of the **public** network created near the beginning of
this walkthrough.  We also associate this floating IP by adding the `floating` network
directly to the `shield` job, as shown in the above manifest.

(( insert_file shield_deploy.md ))
(( insert_file bolo_intro.md ))
Now let's make the manifest.

```
$ cd ~/ops/bolo-deployments/(( insert_parameter site.name ))/proto
$ make manifest

2 error(s) detected:
 - $.meta.az: What availability zone is Bolo deployed to?
 - $.networks.bolo.subnets: Specify your bolo subnet

Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

From the error message, we need to configure the following things for an OpenStack deployment of
bolo:

- Availability Zone (via `meta.az`)
- Networking configuration

According to the [Network Plan][netplan], the bolo deployment belongs in the
**10.4.1.64/28** network, in (( insert_parameter site.name )). Let's configure the availability zone in `properties.yml`:

```
$ cat properties.yml
---
meta:
  az: (( insert_parameter site.name ))
```

Since `10.4.1.64/28` is subdivision of the `10.4.1.0/24` subnet, we can configure networking as follows.
Once again, we add a Floating IP so we can access Gnossis.

```
$ cat networking.yml
---
networks:
  - name: bolo
    subnets:
    - range: 10.4.1.0/24
      gateway: 10.4.1.1
      cloud_properties:
        net_id: b5bfe2d1-fa17-41cc-9928-89013c27e266   #  ID for global-infra-0
        security_groups: [wide-open]
      dns: [8.8.8.8, 8.8.4.4]
      reserved:
        - 10.4.1.2   - 10.4.1.3
        - 10.4.1.4 - 10.4.1.63
         # Bolo is in 10.4.1.64/28
        - 10.4.1.80 - 10.4.1.254
      static:
        - 10.4.1.65 - 10.4.1.68
  - name: floating
    type: vip
    cloud_properties:
      net_id: 09b03d93-45f8-4bea-b3b8-7ad9169f23d5
      security_groups: [wide-open]

jobs:
- name: bolo
  networks:
  - name: floating
    static_ips:
    - (( insert_parameter openstack.bolo_fip ))
```

(( insert_file bolo_test.md ))
(( insert_file bolo_agents.md ))
(( insert_file concourse_intro.md ))
Let's make the manifest:

```
$ cd ~/ops/concourse-deployments/(( insert_parameter site.name ))/proto
$ make manifest
5 error(s) detected:
  - $.meta.availability_zone: What availability zone should your concourse VMs be in?
  - $.meta.external_url: What is the external URL for this concourse?
  - $.meta.shield_authorized_key: Specify the SSH public key from this environment's SHIELD daemon
  - $.meta.ssl_pem: Want ssl? define a pem
  - $.networks.concourse.subnets: Specify your concourse subnet

Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Again starting with Meta lines in `~/ops/concourse-deployments/(( insert_parameter site.name ))/proto`:

```
$ cat properties.yml
---
meta:
  availability_zone: "dc01"   # Set this to match your first zone
  external_url: "(( insert_parameter openstack.external_concourse_url ))"  # Set as Elastic IP address of the bastion host to allow testing via SSH tunnel
  ssl_pem: ~
  #  ssl_pem: (( vault meta.vault_prefix "/web_ui:pem" ))
  shield_authorized_key: (( vault "secret/dc01/proto/shield/keys/core:public" ))
```

TODO:  The following statement is in the AWS instructions too.  Shouldn't this be the IP of CF instead of the bastion host?

Be sure to replace the x.x.x.x in the external_url above with the Floating IP address of the bastion host.

The `~` means we won't use SSL certs for now.  If you have proper certs or want to use self signed you can add them to vault under the `web_ui:pem` key

For networking, we put this inside `proto` environment level.

```
$ cat networking.yml
networks:
  - name: concourse
    subnets:
      - range: 10.4.1.0/24
        gateway: 10.4.1.1
        dns:     [8.8.8.8, 8.8.4.4]
        static:
          - 10.4.1.48 - 10.4.1.56  #Concourse uses 10.4.1.48/28
        reserved:
          - 10.4.1.2 - 10.4.1.3
          - 10.4.1.4 - 10.4.1.47
          - 10.4.1.65 - 10.4.1.254
        cloud_properties:
          net_id: b5bfe2d1-fa17-41cc-9928-89013c27e266
          security_groups: [wide-open]

  - name: floating
    type: vip
    cloud_properties:
      net_id: 09b03d93-45f8-4bea-b3b8-7ad9169f23d5
      security_groups: [wide-open]

jobs:
- name: haproxy
  networks:
  - name: concourse
    default: [dns, gateway]
  - name: floating
    static_ips:
    - (( insert_parameter openstack.concourse_fip ))
```

(( insert_file concourse_test.md ))
(( insert file concourse_pipelines_setup.md ))
(( insert_file sites_and_envs_intro.md ))
(( insert_file alpha_boshlite_intro.md ))
Now lets try to deploy:

```
$ cd (( insert_parameter site.name ))/alpha/
$ make deploy
  checking https://genesis.starkandwayne.com for details on latest stemcell bosh-openstack-kvm-ubuntu-trusty-go_agent
  checking https://genesis.starkandwayne.com for details on release bosh/260
  checking https://genesis.starkandwayne.com for details on release bosh-warden-cpi/29
  checking https://genesis.starkandwayne.com for details on release garden-linux/0.342.0
  checking https://genesis.starkandwayne.com for details on release port-forwarding/6
  3 error(s) detected:
   - $.meta.openstack.azs.z1: What Availability Zone will BOSH be in?
   - $.meta.port_forwarding_rules: Define any port forwarding rules you wish to enable on the bosh-lite, or an empty array
   - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...


Makefile:25: recipe for target 'deploy' failed
make: *** [deploy] Error 3
```

Looks like we only have a handful of parameters to update, all related to
networking, so lets fill out our `networking.yml`, after consulting the
[Network Plan][netplan] to find our global infrastructure network and Horizon
to find our Network UUID:

```
$ cat networking.yml
---
networks:
- name: default
  subnets:
  - cloud_properties:
      net_id: b5bfe2d1-fa17-41cc-9928-89013c27e266   #  ID for global-infra-0
      security_groups: [wide-open]
    dns:     [8.8.8.8]
    gateway: 10.4.1.1
    range:   10.4.1.0/24
```

Since there are a bunch of other deployments on the infrastructure network, we should take care
to reserve the correct static + reserved IPs, so that we don't conflict with other deployments. Fortunately
that data can be referenced in the [Global Infrastructure IP Allocation section][infra-ips] of the Network Plan:

```
$ cat networking.yml
---
networks:
- name: default
  subnets:
  - cloud_properties:
      net_id: b5bfe2d1-fa17-41cc-9928-89013c27e266   #  ID for global-infra-0
      security_groups: [wide-open]
    dns:     [8.8.8.8]
    gateway: 10.4.1.1
    range:   10.4.1.0/24
    reserved:
      - 10.4.1.2 - 10.4.1.79
      - 10.4.1.96 - 10.4.1.255
    static:
      - 10.4.1.80
```

As before, we will add the Floating IP so we can access Cloud Foundry when it is deployed to bosh-lite:

```
networks:
- name: default
  subnets:
  - cloud_properties:
      net_id: b5bfe2d1-fa17-41cc-9928-89013c27e266   #  ID for global-infra-0
      security_groups: [wide-open]
    dns:     [8.8.8.8]
    gateway: 10.4.1.1
    range:   10.4.1.0/24
    reserved:
      - 10.4.1.2 - 10.4.1.79
      - 10.4.1.96 - 10.4.1.255
    static:
      - 10.4.1.80
- name: floating
  type: vip
  cloud_properties:
    net_id: 09b03d93-45f8-4bea-b3b8-7ad9169f23d5
    security_groups: [wide-open]
jobs:
- name: bosh
  networks:
  - name: default
    default: [gateway, dns]
  - name: floating
    static_ips:
    - (( insert_parameter openstack.boshlite_fip ))
```

Lastly, we will need to add port-forwarding rules, so that things outside the bosh-lite can talk to its services.
Since we know we will be deploying Cloud Foundry, let's add rules for it:

```
$ cat properties.yml
---
meta:
  openstack:
    azs:
      z1: dc01
  port_forwarding_rules:
    - internal_ip:   10.244.0.34
      internal_port: 80
      external_port: 80
    - internal_ip:   10.244.0.34
      internal_port: 443
      external_port: 443
```

(( insert_file alpha_boshlite_deploy.md ))
(( insert_file alpha_boshlite_target.md ))
(( insert_file alpha_cf.md ))
(( insert_file beta_bosh_intro.md ))
Let's try to deploy now, and see what information still needs to be resolved:

```
TODO: Insert OpenStack Template key Errors Here
```

Looks like we need to provide the same type of data as we did for **proto-BOSH**. Lets fill in the basic properties:

```
$ cat > properties.yml <<EOF
---
meta:
  openstack:
    api_key:  (( vault meta.vault_prefix "/openstack:api_key" ))
    tenant:   (( vault meta.vault_prefix "/openstack:tenant" ))
    username: (( vault meta.vault_prefix "/openstack:username" ))
    auth_url: http://identity.openvdc.lab:5000/v2.0
    region: openvdc-dc01
cloud_provider:
  properties:
    openstack:
      default_key_name: bosh
      connection_options:
        connect_timeout: 600
      ignore_server_availability_zone: true
  ssh_tunnel:
    host: (( grab jobs.bosh.networks.default.static_ips.0 ))
    private_key: ~/.ssh/bosh
properties:
  bolo:
    submission:
      address: 10.4.1.65
    collectors:
      - { every: 20s, run: 'linux' }
EOF
```

This was a bit easier than it was for **proto-BOSH**, since our SHIELD public key exists now, and our
AWS keys are already in Vault.

Verifying our changes worked, we see that we only need to provide networking configuration at this point:

```
make deploy
$ make deploy
1 error(s) detected:
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
make: *** [deploy] Error 3

```

All that remains is filling in our networking details, so lets go consult our [Network Plan](https://github.com/starkandwayne/codex/blob/master/network.md). We will place the BOSH Director in the staging site's infrastructure network, in the first AZ we have defined (subnet name `staging-infra-0`, CIDR `10.4.32.0/24`). To do that, we'll need to update `networking.yml`:

```
$ cat > networking.yml <<EOF
---
networks:
  - name: default
    subnets:
      - range: 10.4.16.0/24
        gateway: 10.4.16.1
        dns: [10.4.1.77, 10.4.1.78]
        cloud_properties:
          net_id: 20c35573-3a0c-4725-95a2-b58550407fcf # <- Global-Infra-0 Network UUID
        reserved:
          - 10.4.16.2 - 10.4.16.3
          - 10.4.16.10 - 10.4.16.254
        static:
          - 10.4.16.4
  - name: floating
    type: vip
    cloud_properties:
      net_id: 09b03d93-45f8-4bea-b3b8-7ad9169f23d5
      security_groups: [wide-open]
 
jobs:
  - name: bosh
    networks:
    - name: default
      static_ips: (( static_ips(0) ))
    - name: floating
      static_ips:
      - 172.26.75.122

cloud_provider:
  properties:
    openstack:
      default_security_groups: [default]
EOF
```

(( insert_file beta_bosh_deploy.md ))
(( insert_file beta_jumpbox.md ))
(( insert_file beta_cf_intro.md ))
As you might have guessed, the next step will be to see what parameters we need to fill in:

```
$ cd us-west-2/staging
$ make manifest
```

```
TODO:  INSERT OPENSTACK ERRORS HERE
```

Oh boy. That's a lot. Cloud Foundry must be complicated. Looks like a lot of the fog_connection properties are all duplicates though, so lets fill out `properties.yml` with those (no need to create the blobstore S3 buckets yourself):

```
$ cat properties.yml
---
meta:
  type: cf
  site: (( insert_parameter site.name ))
  env: dev
  skip_ssl_validation: true

  cf:
    base_domain: (( insert_parameter cf_beta.base_domain ))
    directory_key_prefix: (( insert_parameter cf_beta.directory_key_prefix ))
    blobstore_config:
      fog_connection:
        aws_access_key_id: (( vault "secret/s3:access_key" ))
        aws_secret_access_key: (( vault "secret/s3:secret_key" ))
        scheme: http
        # host: (( get "object." + meta.openstack.domain ))
        host: 172.26.73.168
        port: 8080
        # Required
        path_style: true
        # v4 is buggy at the moment, stick with v2 for now
        aws_signature_version: 2
        provider: "AWS"
        #region: (( insert_parameter site.name ))
properties:
  bolo:
    submission:
      address: 10.4.1.65
    collectors:
      - { every: 20s, run: 'linux' }
  loggregator:
    servers:
    - 10.4.20.105
  loggregator_endpoint:
    host: 10.4.20.105 # TODO: consul/dns/LB ???
    port: 3456
```

Also, let's fill out `scaling.yml` so we can more easily scale out our Availability Zones and jobs:

```
meta:
  azs:
    z1: dc01
    z2: dc01
    z3: dc01
jobs:
 - name: access_z1
   instances: 1
 - name: access_z2
   instances: 0
 - name: api_z1
   instances: 1
 - name: api_z2
   instances: 0
 - name: brain_z1
   instances: 1
 - name: brain_z2
   instances: 0
 - name: cc_bridge_z1
   instances: 1
 - name: cc_bridge_z2
   instances: 0
 - name: cell_z1
   instances: 1
 - name: cell_z2
   instances: 0
 - name: doppler_z1
   instances: 1
 - name: doppler_z2
   instances: 0
 - name: loggregator_trafficcontroller_z1
   instances: 1
 - name: loggregator_trafficcontroller_z2
   instances: 0
 - name: route_emitter_z1
   instances: 1
 - name: route_emitter_z2
   instances: 0
 - name: router_z1
   instances: 1
 - name: router_z2
   instances: 0
 - name: stats
   instances: 1
 - name: uaa_z1
   instances: 1
 - name: uaa_z2
   instances: 0
```

In addition, let us generate our self-signed certificates for CF:
(( insert_file beta_cf_cacert.md ))
(( insert_file beta_cf_domain.md ))

And let's see what's left to fill out now:

```
$ make deploy

TODO:  INSERT OPENSTACK ERRORS HERE
```

All of those parameters look like they're networking related. Time to start building out the `networking.yml` file.

Now, we can consult our [Network Plan][netplan] for the subnet information,  cross referencing with terraform output to get the subnet IDs:

```
$ cat networking.yml
---
meta:
  azs:
    z1: (( insert_parameter site.name ))
    z2: (( insert_parameter site.name ))
    z3: (( insert_parameter site.name ))
  dns: [8.8.8.8, 8.8.4.4]
  router_security_groups: [wide-open]
  security_groups: [wide-open]

networks:
- name: router1
  subnets:
  - range: 10.4.19.0/25
    static: [10.4.19.4 - 10.4.19.10]
    reserved:
      - 10.4.19.2 - 10.4.19.3
      - 10.4.19.120 - 10.4.19.126
    gateway: 10.4.19.1
    cloud_properties:
      net_id: 262fb235-de6c-4979-832a-225c66859d26
- name: router2
  subnets:
  - range: 10.4.19.128/25
    static: [10.4.19.132 - 10.4.19.138]
    reserved:
      - 10.4.19.130 - 10.4.19.131
      - 10.4.19.248 - 10.4.19.254
    gateway: 10.4.19.129
    cloud_properties:
      net_id: 41fb3f7d-9198-49e2-84b9-d142628a666a
- name: cf1
  subnets:
  - range: 10.4.20.0/24
    static: [10.4.20.4 - 10.4.20.100]
    reserved: [10.4.20.2 - 10.4.20.3]
    gateway: 10.4.20.1
    cloud_properties:
      net_id: bbea24c9-58dc-4df5-899d-fd46e3dfbe5e
- name: cf2
  subnets:
  - range: 10.4.21.0/24
    static: [10.4.21.4 - 10.4.21.100]
    reserved: [10.4.21.2 - 10.4.21.3]
    gateway: 10.4.21.1
    cloud_properties:
      net_id: a2f1e561-2c02-4f7b-9dd9-4c5fd44c9783
- name: cf3
  subnets:
  - range: 10.4.22.0/24
    static: [10.4.22.4 - 10.4.22.100]
    reserved: [10.4.22.2 - 10.4.22.3]
    gateway: 10.4.22.1
    cloud_properties:
      net_id: 4e1df0ff-f7f9-4cf8-9c19-77afd48e7e9f
- name: runner1
  subnets:
  - range: 10.4.23.0/24
    static: [10.4.23.4 - 10.4.23.100]
    reserved: [10.4.23.2 - 10.4.23.3]
    gateway: 10.4.23.1
    cloud_properties:
      net_id: 7f4b6f05-685f-48c7-bc6d-edc8bd00b145
- name: runner2
  subnets:
  - range: 10.4.24.0/24
    static: [10.4.24.4 - 10.4.24.100]
    reserved: [10.4.24.2 - 10.4.24.3]
    gateway: 10.4.24.1
    cloud_properties:
      net_id: 631b5c2d-7948-4e77-8ca7-36417514e835
- name: runner3
  subnets:
  - range: 10.4.25.0/24
    static: [10.4.25.4 - 10.4.25.100]
    reserved: [10.4.25.2 - 10.4.25.3]
    gateway: 10.4.25.1
    cloud_properties:
      net_id: ecbf813d-77af-4919-9c80-279d9eaf10c6

- name: floating
  type: vip
  cloud_properties:
    net_id: 09b03d93-45f8-4bea-b3b8-7ad9169f23d5
    security_groups: [wide-open]
jobs:
- name: api_z1
  networks:
  - name: cf1
    default: [dns, gateway]
  - name: floating
    static_ips:
    - 172.26.75.125
- name: api_z2
  networks:
  - name: cf2
    default: [dns, gateway]

properties:
  cc:
    security_group_definitions:
    - name: load_balancer
      rules: []
    - name: services
      rules:
      - destination: 10.4.26.0-10.4.28.255
        protocol: all
    - name: user_bosh_deployments
      rules: []
```
(( insert_file beta_cf_deploy.md ))
(( insert_file beta_cf_push_app.md ))
(( insert_file next_steps.md ))
