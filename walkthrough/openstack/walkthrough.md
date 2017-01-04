# Openstack Codex Walkthrough

(( insert_file overview.md ))
## Setup Credentials

To start deploying the infrastructure, the first thing you need to do is create
an Openstack user and give it admin access to a new tenant.

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

### Generate Openstack Key Pair

The **User Name**, **Password**, and **Tenant Name** (same as **Project Name**) are
used to get access to the Openstack Services by BOSH.  Next, we'll need to create a
**Key Pair**.  This will be used as we bring up the initial bastion host instances,
and is the SSH key you'll use to connect from your local machine to the bastion.

**NOTE**: Make sure you are in the correct project (top-left corner of the Horizon
UI) when you create your **EC2 Key Pair**. Otherwise, it just plain won't
work.

1. Log into Horizon as the user that has admin access to the project in question.

2. Under **Project --> Compute --> Access & Security**, head to the **Key Pairs**
   tab.

3. When creating the Key Pair in Kilo or earlier, you can simply use the
   **Create Key Pair** functionality.  In Liberty and later, you MUST separately
   create an RSA keypair using `ssh-keygen` and import the public key using the
   **Import Key Pair** function.  This is a known problem between BOSH and versions
   of Openstack starting with Mitaka onward.

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

Once the requirements for Openstack are met, we can put it all together and build out
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

Terraform will connect to Openstack, using your **User Name**, **Password**, and
**Tenant Name**, and spin up all the things it needs.  When it finishes, you should
be left with a bunch of subnets, security groups, and a bastion host.

If you run into issues before this point refer to our [troubleshooting][troubleshooting_openstack]
doc for help.

### Connect to Bastion

You'll use the **Key Pair** `*.pem` or `ssh-keygen` generated file that was stored from the
[Generate EC2 Key Pair](openstack.md#generate-openstack-key-pair) step before as your credential
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

Configure the Openstack credentials by pointing
Genesis to the Vault.  Let's go put those credentials in the
Vault:

```
$ export VAULT_PREFIX=secret/(( insert_parameter site.name ))/proto/(( insert_parameter openstack.bosh_name ))
$ safe set ${VAULT_PREFIX}/openstack tenant=cf username=cfadmin api_key=putyourpasswordhere
```

Let's try that `make manifest` again.

```
$ make manifest`
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

Better. Let's configure our `cloud_provider` for Openstack, using our EC2 key pair.
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
Openstack administrator.

We identify our Openstack-specific configuration under
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

First, lets do our Openstack-specific region/zone configuration, along with our Vault HA fully-qualified domain name:

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
Openstack Network UUID, but they share the same Security Groups, since
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

QUINN:  Please review and add / change as needed.

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

(Don't forget to change your `subnet` to match your Openstack Network UUID and
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

From the error message, we need to configure the following things for an Openstack deployment of
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

QUINN:  The following statement is in the AWS instructions too.  Shouldn't this be the IP of CF instead of the bastion host?

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
$ cd us-west-2/staging
$ make deploy
9 error(s) detected:
 - $.meta.aws.access_key: Please supply an AWS Access Key
 - $.meta.aws.azs.z1: What Availability Zone will BOSH be in?
 - $.meta.aws.default_sgs: What security groups should VMs be placed in, if none are specified in the deployment manifest?
 - $.meta.aws.private_key: What private key will be used for establishing the ssh_tunnel (bosh-init only)?
 - $.meta.aws.region: What AWS region are you going to use?
 - $.meta.aws.secret_key: Please supply an AWS Secret Key
 - $.meta.aws.ssh_key_name: What AWS keypair should be used for the vcap user?
 - $.meta.shield_public_key: Specify the SSH public key from this environment's SHIELD daemon
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
make: *** [deploy] Error 3
```

Looks like we need to provide the same type of data as we did for **proto-BOSH**. Lets fill in the basic properties:

```
$ cat > properties.yml <<EOF
---
meta:
  aws:
    region: us-west-2
    azs:
      z1: (( concat meta.aws.region "a" ))
    access_key: (( vault "secret/us-west-2:access_key" ))
    secret_key: (( vault "secret/us-west-2:secret_key" ))
    private_key: ~ # not needed, since not using bosh-lite
    ssh_key_name: your-ec2-keypair-name
    default_sgs: [wide-open]
  shield_public_key: (( vault "secret/us-west-2/proto/shield/keys/core:public" ))
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
      - range:    10.4.32.0/24
        gateway:  10.4.32.1
        dns:     [10.4.0.2]
        cloud_properties:
          subnet: subnet-xxxxxxxx # <-- the AWS Subnet ID for your staging-infra-0 network
          security_groups: [wide-open]
        reserved:
          - 10.4.32.2 - 10.4.32.3    # Amazon reserves these
            # BOSH is in 10.4.32.0/28
          - 10.4.32.16 - 10.4.32.254 # Allocated to other deployments
        static:
          - 10.4.32.4
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
76 error(s) detected:
 - $.meta.azs.z1: What availability zone should the *_z1 vms be placed in?
 - $.meta.azs.z2: What availability zone should the *_z2 vms be placed in?
 - $.meta.azs.z3: What availability zone should the *_z3 vms be placed in?
 - $.meta.cf.base_domain: Enter the Cloud Foundry base domain
 - $.meta.cf.blobstore_config.fog_connection.aws_access_key_id: What is the access key id for the blobstore S3 buckets?
 - $.meta.cf.blobstore_config.fog_connection.aws_secret_access_key: What is the secret key for the blobstore S3 buckets?
 - $.meta.cf.blobstore_config.fog_connection.region: Which region are the blobstore S3 buckets in?
 - $.meta.cf.ccdb.host: What hostname/IP is the ccdb available at?
 - $.meta.cf.ccdb.pass: Specify the password of the ccdb user
 - $.meta.cf.ccdb.user: Specify the user to connect to the ccdb
 - $.meta.cf.diegodb.host: What hostname/IP is the diegodb available at?
 - $.meta.cf.diegodb.pass: Specify the password of the diegodb user
 - $.meta.cf.diegodb.user: Specify the user to connect to the diegodb
 - $.meta.cf.uaadb.host: What hostname/IP is the uaadb available at?
 - $.meta.cf.uaadb.pass: Specify the password of the uaadb user
 - $.meta.cf.uaadb.user: Specify the user to connect to the uaadb
 - $.meta.dns: Enter the DNS server for your VPC
 - $.meta.elbs: What elbs will be in front of the gorouters?
 - $.meta.router_security_groups: Enter the security groups which should be applied to the gorouter VMs
 - $.meta.security_groups: Enter the security groups which should be applied to CF VMs
 - $.meta.ssh_elbs: What elbs will be in front of the ssh-proxy (access_z*) nodes?
 - $.networks.cf1.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.cf1.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.cf1.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.cf1.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.cf1.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.cf2.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.cf2.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.cf2.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.cf2.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.cf2.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.cf3.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.cf3.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.cf3.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.cf3.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.cf3.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.router1.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.router1.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.router1.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.router1.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.router1.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.router2.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.router2.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.router2.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.router2.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.router2.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.runner1.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.runner1.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.runner1.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.runner1.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.runner1.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.runner2.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.runner2.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.runner2.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.runner2.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.runner2.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.runner3.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.runner3.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.runner3.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.runner3.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.runner3.subnets.0.static: Enter the static IP ranges for this subnet
 - $.properties.cc.buildpacks.fog_connection.aws_access_key_id: What is the access key id for the blobstore S3 buckets?
 - $.properties.cc.buildpacks.fog_connection.aws_secret_access_key: What is the secret key for the blobstore S3 buckets?
 - $.properties.cc.buildpacks.fog_connection.region: Which region are the blobstore S3 buckets in?
 - $.properties.cc.droplets.fog_connection.aws_access_key_id: What is the access key id for the blobstore S3 buckets?
 - $.properties.cc.droplets.fog_connection.aws_secret_access_key: What is the secret key for the blobstore S3 buckets?
 - $.properties.cc.droplets.fog_connection.region: Which region are the blobstore S3 buckets in?
 - $.properties.cc.packages.fog_connection.aws_access_key_id: What is the access key id for the blobstore S3 buckets?
 - $.properties.cc.packages.fog_connection.aws_secret_access_key: What is the secret key for the blobstore S3 buckets?
 - $.properties.cc.packages.fog_connection.region: Which region are the blobstore S3 buckets in?
 - $.properties.cc.resource_pool.fog_connection.aws_access_key_id: What is the access key id for the blobstore S3 buckets?
 - $.properties.cc.resource_pool.fog_connection.aws_secret_access_key: What is the secret key for the blobstore S3 buckets?
 - $.properties.cc.resource_pool.fog_connection.region: Which region are the blobstore S3 buckets in?
 - $.properties.cc.security_group_definitions.load_balancer.rules: Specify the rules for allowing access for CF apps to talk to the CF Load Balancer External IPs
 - $.properties.cc.security_group_definitions.services.rules: Specify the rules for allowing access to CF services subnets
 - $.properties.cc.security_group_definitions.user_bosh_deployments.rules: Specify the rules for additional BOSH user services that apps will need to talk to


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Oh boy. That's a lot. Cloud Foundry must be complicated. Looks like a lot of the fog_connection properties are all duplicates though, so lets fill out `properties.yml` with those (no need to create the blobstore S3 buckets yourself):

```
$ cat properties.yml
---
meta:
  skip_ssl_validation: true
  cf:
    blobstore_config:
      fog_connection:
        aws_access_key_id: (( vault "secret/us-west-2:access_key" ))
        aws_secret_access_key: (( vault "secret/us-west-2:secret_key" ))
        region: us-west-2
```

##### Setup RDS Database

Next, lets tackle the database situation. We will need to create RDS instances for the `uaadb` and `ccdb`, but first we need to generate a password for the RDS instances:

```
$ safe gen 40 secret/us-west-2/staging/cf/rds password
$ safe get secret/us-west-2/staging/cf/rds
--- # secret/us-west-2/staging/rds
password: pqzTtCTz7u32Z8nVlmvPotxHsSfTOvawRjnY7jTW
```

Now let's go back to the `terraform/aws` sub-directory of this repository and add to the `aws.tfvars` file the following configurations:

```
aws_rds_staging_enabled = "1"
aws_rds_staging_master_password = "<insert the generated RDS password>"
```

As a quick pre-flight check, run `make manifest` to compile your Terraform plan, a RDS Cluster and 3 RDS Instances should be created:

```
$ make manifest
terraform get -update
terraform plan -var-file aws.tfvars -out aws.tfplan
Refreshing Terraform state in-memory prior to plan...

...

Plan: 4 to add, 0 to change, 0 to destroy.
```

If everything worked out you, deploy the changes:

```
$ make deploy
```

**TODO:** Create the `ccdb`,`uaadb` and `diegodb` databases inside the RDS Instance.

We will manually create uaadb, ccdb and diegodb for now. First, connect to your PostgreSQL database using the following command.

```
psql postgres://cfdbadmin:your_password@your_rds_instance_endpoint:5432/postgres
```

Then run `create database uaadb`, `create database ccdb` and `create database diegodb`. You also need to `create extension citext` on all of your databases.

Now that we have RDS instance and `ccdb`, `uaadb` and `diegodb` databases created inside it, lets refer to them in our `properties.yml` file:

```
cat properties.yml
---
meta:
  skip_ssl_validation: true
  cf:
    blobstore_config:
      fog_connection:
        aws_access_key_id: (( vault "secret/us-west-2:access_key" ))
        aws_secret_access_key: (( vault "secret/us-west-2:secret_key" ))
        region: us-east-1
    ccdb:
      host: "xxxxxx.rds.amazonaws.com" # <- your RDS Instance endpoint
      user: "cfdbadmin"
      pass: (( vault "secret/us-west-2/staging/cf/rds:password" ))
      scheme: postgres
      port: 5432
    uaadb:
      host: "xxxxxx.rds.amazonaws.com" # <- your RDS Instance endpoint
      user: "cfdbadmin"
      pass: (( vault "secret/us-west-2/staging/cf/rds:password" ))
      scheme: postgresql
      port: 5432
    diegodb:
      host: "xxxxxx.rds.amazonaws.com" # <- your RDS Instance endpoint
      user: "cfdbadmin"
      pass: (( vault "secret/us-west-2/staging/cf/rds:password" ))
      scheme: postgres
      port: 5432
properties:
  diego:
    bbs:
      sql:
        db_driver: postgres
        db_connection_string: (( concat "postgres://" meta.cf.diegodb.user ":" meta.cf.diegodb.pass "@" meta.cf.diegodb.host ":" meta.cf.diegodb.port "/" meta.cf.diegodb.dbname ))

```
We have to configure `db_driver` and `db_connection_string` for diego since the templates we use is MySQL and we are using PostgreSQL here.

(( insert_file beta_cf_cacert.md ))
Now let's go back to the `terraform/aws` sub-directory of this repository and add to the `aws.tfvars` file the following configurations:

```
aws_elb_staging_enabled = "1"
aws_elb_staging_cert_path = "/path/to/the/signed/domain/certificate.crt"
aws_elb_staging_private_key_path = "/path/to/the/domain/private.key"
```

As a quick pre-flight check, run `make manifest` to compile your Terraform plan. If everything worked out you, deploy the changes:

```
$ make deploy
```

From here we need to configure our domain to point to the ELB. Different clients may use different DNS servers. No matter which DNS server you are using, you will need add two CNAME records, one that maps the domain-name to the CF-ELB endpoint and one that maps the ssh.domain-name to the CF-SSH-ELB endpoint. In this project, we will set up a Route53 as the DNS server. You can log into the AWS Console, create a new _Hosted Zone_ for your domain. Then go back to the `terraform/aws` sub-directory of this repository and add to the `aws.tfvars` file the following configurations:

```
aws_route53_staging_enabled = "1"
aws_route53_staging_hosted_zone_id = "XXXXXXXXXXX"
```

As usual, run `make manifest` to compile your Terraform plan and if everything worked out you, deploy the changes:

```
$ make deploy
```

(( insert_file beta_cf_domain.md ))
And let's see what's left to fill out now:

```
$ make deploy
51 error(s) detected:
 - $.meta.azs.z1: What availability zone should the *_z1 vms be placed in?
 - $.meta.azs.z2: What availability zone should the *_z2 vms be placed in?
 - $.meta.azs.z3: What availability zone should the *_z3 vms be placed in?
 - $.meta.dns: Enter the DNS server for your VPC
 - $.meta.elbs: What elbs will be in front of the gorouters?
 - $.meta.router_security_groups: Enter the security groups which should be applied to the gorouter VMs
 - $.meta.security_groups: Enter the security groups which should be applied to CF VMs
 - $.meta.ssh_elbs: What elbs will be in front of the ssh-proxy (access_z*) nodes?
 - $.networks.cf1.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.cf1.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.cf1.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.cf1.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.cf1.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.cf2.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.cf2.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.cf2.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.cf2.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.cf2.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.cf3.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.cf3.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.cf3.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.cf3.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.cf3.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.router1.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.router1.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.router1.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.router1.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.router1.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.router2.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.router2.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.router2.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.router2.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.router2.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.runner1.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.runner1.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.runner1.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.runner1.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.runner1.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.runner2.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.runner2.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.runner2.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.runner2.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.runner2.subnets.0.static: Enter the static IP ranges for this subnet
 - $.networks.runner3.subnets.0.cloud_properties.subnet: Enter the AWS subnet ID for this subnet
 - $.networks.runner3.subnets.0.gateway: Enter the Gateway for this subnet
 - $.networks.runner3.subnets.0.range: Enter the CIDR address for this subnet
 - $.networks.runner3.subnets.0.reserved: Enter the reserved IP ranges for this subnet
 - $.networks.runner3.subnets.0.static: Enter the static IP ranges for this subnet
 - $.properties.cc.security_group_definitions.load_balancer.rules: Specify the rules for allowing access for CF apps to talk to the CF Load Balancer External IPs
 - $.properties.cc.security_group_definitions.services.rules: Specify the rules for allowing access to CF services subnets
 - $.properties.cc.security_group_definitions.user_bosh_deployments.rules: Specify the rules for additional BOSH user services that apps will need to talk to


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

All of those parameters look like they're networking related. Time to start building out the `networking.yml` file. Since our VPC is `10.4.0.0/16`, Amazon will have provided a DNS server for us at `10.4.0.2`. We can grab the AZs and ELB names from our terraform output, and define our router + cf security groups, without consulting the Network Plan:

```
$ cat networking.yml
---
meta:
  azs:
    z1: us-west-2a
    z2: us-west-2b
    z3: us-west-2c
  dns: [10.4.0.2]
  elbs: [xxxxxx-staging-cf-elb] # <- ELB name
  ssh_elbs: [xxxxxx-staging-cf-ssh-elb] # <- SSH ELB name
  router_security_groups: [wide-open]
  security_groups: [wide-open]
```

Now, we can consult our [Network Plan][netplan] for the subnet information,  cross referencing with terraform output or the AWS console to get the subnet ID:

```
$ cat networking.yml
---
meta:
  azs:
    z1: us-west-2a
    z2: us-west-2b
    z3: us-west-2c
  dns: [10.4.0.2]
  elbs: [xxxxxx-staging-cf-elb] # <- ELB name
  ssh_elbs: [xxxxxx-staging-cf-ssh-elb] # <- SSH ELB name
  router_security_groups: [wide-open]
  security_groups: [wide-open]

networks:
- name: router1
  subnets:
  - range: 10.4.35.0/25
    static: [10.4.35.4 - 10.4.35.100]
    reserved: [10.4.35.2 - 10.4.35.3] # amazon reserves these
    gateway: 10.4.35.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: router2
  subnets:
  - range: 10.4.35.128/25
    static: [10.4.35.132 - 10.4.35.227]
    reserved: [10.4.35.130 - 10.4.35.131] # amazon reserves these
    gateway: 10.4.35.129
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: cf1
  subnets:
  - range: 10.4.36.0/24
    static: [10.4.36.4 - 10.4.36.100]
    reserved: [10.4.36.2 - 10.4.36.3] # amazon reserves these
    gateway: 10.4.36.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: cf2
  subnets:
  - range: 10.4.37.0/24
    static: [10.4.37.4 - 10.4.37.100]
    reserved: [10.4.37.2 - 10.4.37.3] # amazon reserves these
    gateway: 10.4.37.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: cf3
  subnets:
  - range: 10.4.38.0/24
    static: [10.4.38.4 - 10.4.38.100]
    reserved: [10.4.38.2 - 10.4.38.3] # amazon reserves these
    gateway: 10.4.38.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: runner1
  subnets:
  - range: 10.4.39.0/24
    static: [10.4.39.4 - 10.4.39.100]
    reserved: [10.4.39.2 - 10.4.39.3] # amazon reserves these
    gateway: 10.4.39.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: runner2
  subnets:
  - range: 10.4.40.0/24
    static: [10.4.40.4 - 10.4.40.100]
    reserved: [10.4.40.2 - 10.4.40.3] # amazon reserves these
    gateway: 10.4.40.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: runner3
  subnets:
  - range: 10.4.41.0/24
    static: [10.4.41.4 - 10.4.41.100]
    reserved: [10.4.41.2 - 10.4.41.3] # amazon reserves these
    gateway: 10.4.41.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
```

Let's see what's left now:

```
$ make deploy
3 error(s) detected:
 - $.properties.cc.security_group_definitions.load_balancer.rules: Specify the rules for allowing access for CF apps to talk to the CF Load Balancer External IPs
 - $.properties.cc.security_group_definitions.services.rules: Specify the rules for allowing access to CF services subnets
 - $.properties.cc.security_group_definitions.user_bosh_deployments.rules: Specify the rules for additional BOSH user services that apps will need to talk to
```

The only bits left are the Cloud Foundry security group definitions (applied to each running app, not the SGs applied to the CF VMs). We add three sets of rules for apps to have access to by default - `load_balancer`, `services`, and `user_bosh_deployments`. The `load_balancer` group should have a rule allowing access to the public IP(s) of the Cloud Foundry installation, so that apps are able to talk to other apps. The `services` group should have rules allowing access to the internal IPs of the services networks (according to our [Network Plan][netplan], `10.4.42.0/24`, `10.4.43.0/24`, `10.4.44.0/24`). The `user_bosh_deployments` is used for any non-CF-services that the apps may need to talk to. In our case, there aren't any, so this can be an empty list.

```
$ cat networking.yml
---
meta:
  azs:
    z1: us-west-2a
    z2: us-west-2b
    z3: us-west-2c
  dns: [10.4.0.2]
  elbs: [xxxxxx-staging-cf-elb] # <- ELB name
  ssh_elbs: [xxxxxx-staging-cf-ssh-elb] # <- SSH ELB name
  router_security_groups: [wide-open]
  security_groups: [wide-open]

networks:
- name: router1
  subnets:
  - range: 10.4.35.0/25
    static: [10.4.35.4 - 10.4.35.100]
    reserved: [10.4.35.2 - 10.4.35.3] # amazon reserves these
    gateway: 10.4.35.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: router2
  subnets:
  - range: 10.4.35.128/25
    static: [10.4.35.132 - 10.4.35.227]
    reserved: [10.4.35.130 - 10.4.35.131] # amazon reserves these
    gateway: 10.4.35.129
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: cf1
  subnets:
  - range: 10.4.36.0/24
    static: [10.4.36.4 - 10.4.36.100]
    reserved: [10.4.36.2 - 10.4.36.3] # amazon reserves these
    gateway: 10.4.36.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: cf2
  subnets:
  - range: 10.4.37.0/24
    static: [10.4.37.4 - 10.4.37.100]
    reserved: [10.4.37.2 - 10.4.37.3] # amazon reserves these
    gateway: 10.4.37.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: cf3
  subnets:
  - range: 10.4.38.0/24
    static: [10.4.38.4 - 10.4.38.100]
    reserved: [10.4.38.2 - 10.4.38.3] # amazon reserves these
    gateway: 10.4.38.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: runner1
  subnets:
  - range: 10.4.39.0/24
    static: [10.4.39.4 - 10.4.39.100]
    reserved: [10.4.39.2 - 10.4.39.3] # amazon reserves these
    gateway: 10.4.39.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: runner2
  subnets:
  - range: 10.4.40.0/24
    static: [10.4.40.4 - 10.4.40.100]
    reserved: [10.4.40.2 - 10.4.40.3] # amazon reserves these
    gateway: 10.4.40.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here
- name: runner3
  subnets:
  - range: 10.4.41.0/24
    static: [10.4.41.4 - 10.4.41.100]
    reserved: [10.4.41.2 - 10.4.41.3] # amazon reserves these
    gateway: 10.4.41.1
    cloud_properties:
      subnet: subnet-XXXXXX # <--- your subnet ID here

properties:
  cc:
    security_group_definitions:
    - name: load_balancer
      rules: []
    - name: services
      rules:
      - destination: 10.4.42.0-10.4.44.255
        protocol: all
    - name: user_bosh_deployments
      rules: []
```
(( insert_file beta_cf_scaling.md ))
(( insert_file beta_cf_deploy.md ))
You may encounter the following error when you are deploying Beta CF.

```
Unknown CPI error 'Unknown' with message 'Your quota allows for 0 more running instance(s). You requested at least 1.
```

Amazon has per-region limits for different types of resources. Check what resource type your failed job is using and request to increase limits for the resource your jobs are failing at. You can log into your Amazon console, go to EC2 services, on the left column click `Limits`, you can click the blue button says `Request limit increase` on the right of each type of resource. It takes less than 30 minutes get limits increase approved through Amazon.

(( insert_file beta_cf_push_app.md ))
(( insert_file next_steps.md ))
