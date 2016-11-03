# Part I - AWS Guide

## Overview

Welcome to the Stark & Wayne guide to deploying Cloud Foundry on Amazon Web
Services.  This guide provides the steps to create authentication credentials,
generate a Virtual Private Cloud (VPC), then use Terraform to prepare a bastion
host.

From this bastion, we setup a special BOSH Director we call the **proto-BOSH**
server where software like Vault, Concourse, Bolo and SHIELD are setup in order
to give each of the environments created after the **proto-BOSH** key benefits of:

* Secure Credential Storage
* Pipeline Management
* Monitoring Framework
* Backup and Restore Datastores

Once the **proto-BOSH** environment is setup, the child environments will have
the added benefit of being able to update their BOSH software as a release,
rather than having to re-initialize with `bosh-init`.

This also increases the resiliency of all BOSH Directors through monitoring and
backups with software created by Stark & Wayne's engineers.

And visibility into the progress and health of each application, release, or
package is available through the power of Concourse pipelines.

![Levels of Bosh][levels_of_bosh]

In the above diagram, BOSH (1) is the **proto-BOSH**, while BOSH (2) and BOSH (3)
are the per-site BOSH Directors.

Now it's time to setup the credentials.

## Setup Credentials

So you've got an AWS account right?  Cause otherwise let me interest you in
another guide like our OpenStack, Azure or vSphere, etc.  j/k

To begin, let's login to [Amazon Web Services][aws] and prepare the necessary
credentials and resources needed.

1. Access Key ID
2. Secret Key ID
3. A Name for your VPC
4. An EC2 Key Pair

### Generate Access Key

  The first thing you're going to need is a combination **Access Key ID** /
  **Secret Key ID**.  These are generated (for IAM users) via the IAM dashboard.

  To help keep things isolated, we're going to set up a brand new IAM user.  It's
  a good idea to name this user something like `cf` so that no one tries to
  re-purpose it later, and so that it doesn't get deleted.

1. On the AWS web console, access the IAM service, and click on `Users` in the
sidebar.  Then create a new user and select "Generate an access key for each user".

  **NOTE**: **Make sure you save the secret key somewhere secure**, like 1Password
  or a Vault instance.  Amazon will be unable to give you the **Secret Key ID**
  if you misplace it -- your only recourse at that point is to generate a new
  set of keys and start over.

2. Next, find the `cf` user and click on the username. This should bring up a
summary of the user with things like the _User ARN_, _Groups_, etc.  In the
bottom half of the Summary panel, you can see some tabs, and one of those tabs
is _Permissions_.  Click on that one.

3. Now assign the **PowerUserAccess** role to your user. This user will be able to
do any operation except IAM operations.  You can do this by clicking on the
_Permissions_ tab and then clicking on the _attach policy_ button.

4. We will also need to create a custom user policy in order to create ELBs with
SSL listeners. At the same _Permissions_ tab, expand the _Inline Policies_ and
then create one using the _Custom Policy_ editor. Name it `ServerCertificates`
and paste the following content:

    ```
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "iam:DeleteServerCertificate",
                    "iam:UploadServerCertificate",
                    "iam:ListServerCertificates",
                    "iam:GetServerCertificate"
                ],
                "Resource": "*"
            }
        ]
    }
    ```

5. Click on _Apply Policy_ and you will be all set.

### Name Your VPC

This step is really simple -- just make one up.  The VPC name will be used to
prefix certain things that Terraform creates in the AWS Virtual Private Cloud.
When managing multiple VPC's this can help you to sub-select only the ones you're
concerned about.

The VPC is configured in Terraform using the `aws_vpc_name` variable in the
`aws.tfvars` file we're going to create soon.

```
aws_vpc_name = "snw"
```

The prefix of `snw` for Stark & Wayne would show up before VPC components like
Subnets, Network ACLs and Security Groups:

| Name            | ID              |
| :-------------- | :-------------- |
| snw-dev-infra-0 | subnet-cf7812b9 |
| snw-hardened    | acl-10feff74    |
| snw-dmz         | sg-e0cfcf86     |

### Generate EC2 Key Pair

The **Access Key ID** / **Secret Key ID** are used to get access to the Amazon
Web Services themselves.  In order to properly deploy on EC2 over SSH, we'll need
to create an **EC2 Key Pair**.  This will be used as we bring up the initial NAT
and bastion host instances. And is the SSH key you'll use to connect from your
local machine to the bastion.

**NOTE**: Make sure you are in the correct region (top-right corner of the black
menu bar) when you create your **EC2 Key Pair**. Otherwise, it just plain won't
work. The region name setting can be found in `aws.tf` and the mapping to the
region in the menu bar can be found on [Amazon Region Doc][amazon-region-doc].

1. Starting from the main Amazon Web Console, go to Service > EC2, and then click
the _Key Pairs_ link under _Network & Security_. Look for the big blue
`Create Key Pair` button.

2. This downloads a file matching the name of your **EC2 Key Pair**.  Example,
a key pair named cf-deploy would produce a file named `cf-deploy.pem` and be saved
to your Downloads folder.  Also `chmod 0600` the `*.pem` file.

3. Decide where you want this file to be.  All `*.pem` files are ignored in the
codex repository.  So you can either move this file to the same folder as
`CODEX_ROOT/terraform/aws` or move it to a place you keep SSH keys and use the
full path to the `*.pem` file in your `aws.tfvars` for the `aws_key_file`
variable name.

```
aws_key_file = /Users/<username>/.ssh/cf-deploy.pem
```

## Use Terraform

Once the requirements for AWS are met, we can put it all together and build out
your shiny new Virtual Private Cloud (VPC), NAT server and bastion host. Change
to the `terraform/aws` sub-directory of this repository before we begin.

The configuration directly matches the [Network Plan][netplan] for the demo
environment.  When deploying in other environments like production, some tweaks
or rewrites may need to be made.

### Variable File

Create a `aws.tfvars` file with the following configurations (substituting your
actual values) all the other configurations have default setting in the
`CODEX_ROOT/terraform/aws/aws.tf` file.

```
aws_access_key = "..."
aws_secret_key = "..."
aws_vpc_name   = "snw"
aws_key_name   = "cf-deploy"
aws_key_file   = "/Users/<username/.ssh/cf-deploy.pem"
```

If you need to change the region or subnet, you can override the defaults
by adding:

```
aws_region     = "us-east-1"
network        = "10.42"
```

Also, be advised:  Depending on the state of your AWS account, you may also need to explicitly list the AWS Availability Zones as follows:
```
aws_az1        = "a"
aws_az2        = "c"
aws_az3        = "d"
```
Otherwise, you may get the following error:
```
 * aws_subnet.dev-cf-edge-1: Error creating subnet: InvalidParameterValue: Value (us-east-1b) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1d, us-east-1e, us-east-1a.
    status code: 400, request id:
```
You may change some default settings according to the real cases you are
working on. For example, you can change `instance_type` (default is t2.small)
in `aws.tf` to large size if the bastion would require a high workload.

### Production Considerations

When considering production availability. We recommend [a region with three availability zones][az]
for best HA results.  Vault requires at least three zones.  Please feel free to
list any other software that requires more than two zones for HA.

### Build Resources

As a quick pre-flight check, run `make manifest` to compile your Terraform plan
and suss out any issues with naming, missing variables, configuration, etc.:

```
$ make manifest
terraform get -update
terraform plan -var-file aws.tfvars -out aws.tfplan
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

Terraform will connect to AWS, using your **Access Key ID** and **Secret Key ID**,
and spin up all the things it needs.  When it finishes, you should be left with
a bunch of subnets, configured network ACLs, security groups, routing tables,
a NAT instance (for public internet connectivity) and a bastion host.

If you run into issues before this point refer to our [troubleshooting][troubleshooting]
doc for help.

### Automate Build and Teardown

When working with development environments only, there are options built into
Terraform that will allow you to configure additional variables and then run a
script that will automatically create or destroy the base Terraform environment
for you (a NAT server and a bastion host).  This allows us to help reduce runtime
cost.

Setup the variables of what time (in military time) that you'd like the script's
time range to monitor.

```
startup = "9"
shutdown = "17"
```

With the `startup` and `shutdown` variables configured in the `aws.tfvars` file,
you can then return to the `CODEX_ROOT/terraform/aws` folder and run:

* `make aws-watch`
* `make aws-stopwatch`

The first starts the background process that will be checking if it's time to
begin the teardown.  The second will shutdown the background process.

## Bastion Host

The bastion host is the server the BOSH operator connects to, in order to perform
commands that affect the **proto-BOSH** Director and the software that gets
deployed by it.

We'll be covering the configuration and deployment of each of these software
step-by-step as we go along. By the time you're done working on the bastion
server, you'll have installed each of the following in the numbered order:

![Bastion Host Overview][bastion_host_overview]

### Public IP Address

Before we can begin to install software, we need to connect to the server.  There
are a couple of ways to get the IP address.

* At the end of the Terraform `make deploy` output the bastion address is displayed.

```
box.bastion.public    = 52.43.51.197
box.nat.public        = 52.41.225.204
```

* In the AWS Console, go to Services > EC2.  In the dashboard each of the
**Resources** are listed.  Find the _Running Instances_ click on it and locate
the bastion.  The _Public IP_ is an attribute in the _Description_ tab.

### Connect to Bastion

You'll use the **EC2 Key Pair** `*.pem` file that was stored from the
[Generate EC2 Key Pair](aws.md#generate-ec2-key-pair) step before as your credential
to connect.

In forming the SSH connection command, use the `-i` flag to give SSH the path to
the `IdentityFile`.  The default user on the bastion server is `ubuntu`.  This
will change in a little bit though when we create a new user, so don't get too
comfy.

```
$ ssh -i ~/.ssh/cf-deploy.pem ubuntu@52.43.51.197
```

Problems connecting?  [Verify your SSH fingerprint][verify_ssh] in the
troubleshooting doc.

### Add User

Once on the bastion host, you'll want to use the `jumpbox` script, which has
been installed automatically by the Terraform configuration. [This script installs][jumpbox]
some useful utilities like `jq`, `spruce`, `safe`, and `genesis` all of which
will be important when we start using the bastion host to do deployments.

**NOTE**: Try not to confuse the `jumpbox` script with the jumpbox _BOSH release_.
The _BOSH release_ can be used as part of a deployment.  And the script gets
run directly on the bastion host.

Once connected to the bastion, check if the `jumpbox` utility is installed.

```
$ jumpbox -v
jumpbox v49
```

In order to have the dependencies for the `bosh_cli` we need to create a user.
Also a convenience method at the end will prompt for git configuration that will
be useful when we are generating Genesis templates later.

Also, using named accounts provides auditing (via the `sudo` logs), and
isolation (people won't step on each others toes on the filesystem) and
customization (everyone gets to set their own prompt / shell / `$EDITOR`).

Let's add a user with `jumpbox useradd`:

```
$ jumpbox useradd
Full name: Joe User
Username:  juser
Enter the public key for this user's .ssh/authorized_keys file:
You should run `jumpbox user` now, as juser:
  su - juser  
  jumpbox user
```

### Setup User

After you've added the user, **be sure you follow up and setup the user** before
going any further.

Use the `su - juser` command to switch to the user.  And run `jumpbox user`
to install all dependent packages.

```
$ su - juser
$ jumpbox user
```

The following warning may show up when you run `jumpbox user`:
```
 * WARNING: You have '~/.profile' file, you might want to load it,
    to do that add the following line to '/home/XJ/.bash_profile':

      source ~/.profile
```

In this case, please follow the `WARNING` message, otherwise you may see the following message when you run `jumpbox` command even if you already installed everything when you run `jumpbox user`.

```
ruby not installed
rvm not installed
bosh not installed
```

### SSH Config

On your local computer, setup an entry in the `~/.ssh/config` file for your
bastion host.  Substituting the correct IP.

```
Host bastion
  Hostname 52.43.51.197
  User juser
```

### Test Login

After you've logged in as `ubuntu` once, created your user, logged out and
configured your SSH config, you'll be ready to try to connect via the `Host`
alias.

```
$ ssh bastion
```

If you can login and run `jumpbox` and everything returns green, everything's
ready to continue.

```
$ jumpbox

<snip>

>> Checking jumpbox installation
jumpbox installed - jumpbox v49
ruby installed - ruby 2.2.4p230 (2015-12-16 revision 53155) [x86_64-linux]
rvm installed - rvm 1.27.0 (latest) by Wayne E. Seguin <wayneeseguin@gmail.com>, Michal Papis <mpapis@gmail.com> [https://rvm.io/]
bosh installed - BOSH 1.3184.1.0
bosh-init installed - version 0.0.81-775439c-2015-12-09T00:36:03Z
jq installed - jq-1.5
spruce installed - spruce - Version 1.7.0
safe installed - safe v0.0.23
vault installed - Vault v0.6.0
genesis installed - genesis 1.5.2 (61864a21370c)

git user.name  is 'Joe User'
git user.email is 'juser@starkandwayne.com'
```

## Proto Environment

![Global Network Diagram][global_network_diagram]

There are three layers to `genesis` templates.

* Global
* Site
* Environment

### Site Name

Sometimes the site level name can be a bit tricky because each IaaS divides things
differently.  With AWS we suggest a default of the AWS Region you're using, for
example: `us-west-2`.

### Environment Name

All of the software the **proto-BOSH** will deploy will be in the `proto` environment.
And by this point, you've [Setup Credentials][setup_credentials],
[Used Terraform][use_terraform] to construct the IaaS components and
[Configured a Bastion Host][bastion_host].  We're ready now to setup a BOSH
Director on the bastion.

The first step is to create a **vault-init** process.

### vault-init

![vault-init][bastion_1]

BOSH has secrets.  Lots of them.  Components like NATS and the database rely on
secure passwords for inter-component interaction.  Ideally, we'd have a spinning
Vault for storing our credentials, so that we don't have them on-disk or in a
git repository somewhere.

However, we are starting from almost nothing, so we don't have the luxury of
using a BOSH-deployed Vault.  What we can do, however, is spin a single-threaded
Vault server instance **on the bastion host**, and then migrate the credentials to
the real Vault later.

This we call a **vault-init**.  Because it precedes the **proto-BOSH** and Vault
deploy we'll be setting up later.

The `jumpbox` script that we ran as part of setting up the bastion host installs
the `vault` command-line utility, which includes not only the client for
interacting with Vault (`safe`), but also the Vault server daemon itself.

#### Start Server

Were going to start the server and do an overview of what the output means.  To
start the **vault-init**, run the `vault server` with the `-dev` flag.

```
$ vault server -dev
==> WARNING: Dev mode is enabled!

In this mode, Vault is completely in-memory and unsealed.
Vault is configured to only have a single unseal key. The root
token has already been authenticated with the CLI, so you can
immediately begin using the Vault CLI.
```

A vault being unsealed sounds like a bad thing right?  But if you think about it
like at a bank, you can't get to what's in a vault unless it's unsealed.

And in dev mode, `vault server` gives the user the tools needed to authenticate.
We'll be using these soon when we log in.

```
The unseal key and root token are reproduced below in case you
want to seal/unseal the Vault or play with authentication.

Unseal Key:
781d77046dcbcf77d1423623550d28f152d9b419e09df0c66b553e1239843d89
Root Token: c888c5cd-bedd-d0e6-ae68-5bd2debee3b7
```

**NOTE**: When you run the `vault server -dev` command, we recommend running it
in the foreground using either a `tmux` session or a separate ssh tab.  Also, we
do need to capture the output of the `Root Token`.

#### Setup vault-init

In order to setup the **vault-init** we need to target the server and authenticate.
We use `safe` as our CLI to do both commands.

The local `vault server` runs on `127.0.0.1` and on port `8200`.

```
$ safe target init http://127.0.0.1:8200
Now targeting init at http://127.0.0.1:8200

$ safe targets

  init  http://127.0.0.1:8200
```

Authenticate with the `Root Token` from the `vault server` output.

```
$ safe auth token
Authenticating against init at http://127.0.0.1:8200
Token: <paste your Root Token here>
```

#### Test vault-init

Here's a smoke test to see if you've setup the **vault-init** correctly.

```
$ safe set secret/handshake knock=knock
knock: knock

$ safe read secret/handshake
--- # secret/handshake
knock: knock
```

**NOTE**: If you receive `API 400 Bad Request` when attempting `safe set`, you may have incorrectly copied and entered your Root Key.  Try `safe auth token` again.

All set!  Now we can now build our deploy for the **proto-BOSH**.

### proto-BOSH

![proto-BOSH][bastion_2]

#### Generate BOSH Deploy

When using [the Genesis framework][genesis] to manage our deploys across
environments, a folder to manage each of the software we'll deploy needs to
be created.

First setup a `ops` folder in your user's home directory.

```
$ mkdir -p ~/ops
$ cd ~/ops
```

Genesis has a template for BOSH deployments (including support for the
**proto-BOSH**), so let's use that by passing `bosh` into the `--template` flag.

```
$ genesis new deployment --template bosh
$ cd ~/ops/bosh-deployments
```

Next, we'll create a site and an environment from which to deploy our **proto-BOSH**.
The BOSH template comes with some site templates to help you get started
quickly, including:

- `aws` for Amazon Web Services VPC deployments
- `vsphere` for VMWare ESXi virtualization clusters
- `openstack` for OpenStack tenant deployments

When generating a new site we'll use this command format:

```
genesis new site --template <name> <site_name>
```

The template `<name>` will be `aws` because that's our IaaS we're working with and
we recommend the `<site_name>` default to the AWS Region, ex. `us-west-2`.

```
$ genesis new site --template aws us-west-2
Created site us-west-2 (from template aws):
~/ops/bosh-deployments/aws
├── README
└── site
    ├── README
    ├── disk-pools.yml
    ├── jobs.yml
    ├── networks.yml
    ├── properties.yml
    ├── releases
    ├── resource-pools.yml
    ├── stemcell
    │   ├── name
    │   ├── sha1
    │   ├── url
    │   └── version
    └── update.yml

2 directories, 13 files
```

Finally, let's create our new environment, and name it `proto`
(that's `us-west-2/proto`, formally speaking).

```
$ genesis new env --type bosh-init us-west-2 proto
Running env setup hook: ~/ops/bosh-deployments/.env_hooks/setup

 init  http://127.0.0.1:8200

Use this Vault for storing deployment credentials?  [yes or no]
yes
Setting up credentials in vault, under secret/us-west-2/proto/bosh
.
└── secret/us-west-2/proto/bosh
    ├── blobstore/
    │   ├── agent
    │   └── director
    ├── db
    ├── nats
    ├── users/
    │   ├── admin
    │   └── hm
    └── vcap


Created environment us-west-2/:
~/ops/bosh-deployments/us-west-2/proto
├── credentials.yml
├── Makefile
├── name.yml
├── networking.yml
├── properties.yml
└── README

0 directories, 6 files
```

**NOTE** Don't forget that `--type bosh-init` flag is very important. Otherwise,
you'll run into problems with your deployment.

The template helpfully generated all new credentials for us and stored them in
our **vault-init**, under the `secret/us-west-2/proto/bosh` subtree.  Later, we'll
migrate this subtree over to our real Vault, once it is up and spinning.

#### Make Manifest

Let's head into the `proto/` environment directory and see if we
can create a manifest, or (a more likely case) we still have to
provide some critical information:

```
$ cd ~/ops/bosh-deployments/us-west-2/proto
$ make manifest
9 error(s) detected:
 - $.meta.aws.access_key: Please supply an AWS Access Key
 - $.meta.aws.azs.z1: What Availability Zone will BOSH be in?
 - $.meta.aws.region: What AWS region are you going to use?
 - $.meta.aws.secret_key: Please supply an AWS Secret Key
 - $.meta.aws.ssh_key_name: What is your full key name?
 - $.meta.aws.default_sgs: What Security Groups?
 - $.meta.aws.private_key: What is the local path to the Amazon Private Key for this deployment?
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network
 - $.meta.shield_public_key: Specify the SSH public key from this environment's SHIELD daemon
Availability Zone will BOSH be in?


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Drat. Let's focus on the `$.meta` subtree, since that's where most parameters are defined in
Genesis templates:

```
- $.meta.aws.access_key: Please supply an AWS Access Key
- $.meta.aws.azs.z1: What Availability Zone will BOSH be in?
- $.meta.aws.region: What AWS region are you going to use?
- $.meta.aws.secret_key: Please supply an AWS Secret Key
```

This is easy enough to supply.  We'll put these properties in
`properties.yml`:

```
$ cat properties.yml
---
meta:
  aws:
    region: us-west-2
    azs:
      z1: (( concat meta.aws.region "a" ))
    access_key: (( vault "secret/us-west-2:access_key" ))
    secret_key: (( vault "secret/us-west-2:secret_key" ))
```

I use the `(( concat ... ))` operator to [DRY][DRY] up the
configuration.  This way, if we need to move the BOSH Director to
a different region (for whatever reason) we just change
`meta.aws.region` and the availability zone just tacks on "a".

(We use the "a" availability zone because that's where our subnet
is located.)

I also configured the AWS access and secret keys by pointing
Genesis to the Vault.  Let's go put those credentials in the
Vault:

```
$ safe set secret/us-west-2 access_key secret_key
access_key [hidden]:
access_key [confirm]:

secret_key [hidden]:
secret_key [confirm]:

```

Let's try that `make manifest` again.

```
$ make manifest`
5 error(s) detected:
 - $.meta.aws.default_sgs: What security groups should VMs be placed in, if none are specified in the deployment manifest?
 - $.meta.aws.private_key: What private key will be used for establishing the ssh_tunnel (bosh-init only)?
 - $.meta.aws.ssh_key_name: What AWS keypair should be used for the vcap user?
 - $.meta.shield_public_key: Specify the SSH public key from this environment's SHIELD daemon
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Better. Let's configure our `cloud_provider` for AWS, using our EC2 key pair.
We need copy our EC2 private key to bastion host and path to the key for
`private_key` entry in the following `properties.yml`.


On your local computer, you can copy to the clipboard with the `pbcopy` command
on a macOS machine:

```
cat ~/.ssh/cf-deploy.pem | pbcopy
<paste values to /path/to/the/ec2/key.pem>
```

Then add the following to the `properties.yml` file.

```
$ cat properties.yml
---
meta:
  aws:
    region: us-west-2
    azs:
      z1: (( concat meta.aws.region "a" ))
    access_key: (( vault "secret/us-west-2:access_key" ))
    secret_key: (( vault "secret/us-west-2:secret_key" ))
    private_key: /path/to/the/ec2/key.pem
    ssh_key_name: your-ec2-keypair-name
    default_sgs:
      - restricted
```

Once more, with feeling:

```
$ make manifest
2 error(s) detected:
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network
 - $.meta.shield_public_key: Specify the SSH public key from this environment's SHIELD daemon


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Excellent.  We're down to two issues.

We haven't deployed a SHIELD yet, so it may seem a bit odd that
we're being asked for an SSH public key.  When we deploy our
**proto-BOSH** via `bosh-init`, we're going to spend a fair chunk of
time compiling packages on the bastion host before we can actually
create and update the director VM.  `bosh-init` will delete the
director VM before it starts this compilation phase, so we will be
unable to do _anything_ while `bosh-init` is hard at work.  The
whole process takes about 30 minutes, so we want to minimize the
number of times we have to re-deploy **proto-BOSH**.  By specifying
the SHIELD agent configuration up-front, we skip a re-deploy after
SHIELD itself is up.

Let's leverage our Vault to create the SSH key pair for BOSH.
`safe` has a handy builtin for doing this:

```
$ safe ssh secret/us-west-2/proto/shield/keys/core
$ safe get secret/us-west-2/proto/shield/keys/core
--- # secret/us-west-2/proto/shield/keys/core
fingerprint: 40:9b:11:82:67:41:23:a8:c2:87:98:5d:ec:65:1d:30
private: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEowIBAAKCAQEA+hXpB5lmNgzn4Oaus8nHmyUWUmQFmyF2pa1++2WBINTIraF9
  ... etc ...
  5lm7mGwOCUP8F1cdPmpPNCkoQ/dx3T5mnsCGsb3a7FVBDDBje1hs
  -----END RSA PRIVATE KEY-----
public: |
  ssh-rsa AAAAB3NzaC...4vbnncAYZPTl4KOr
```

(output snipped for brevity and security; but mostly brevity)

Now we can put references to our Vaultified keypair in
`credentials.yml`:

```
$ cat credentials.yml
---
meta:
  shield_public_key: (( vault "secret/us-west-2/proto/shield/keys/core:public" ))
```

You may want to take this opportunity to migrate
credentials-oriented keys from `properties.yml` into this file.

Now, we should have only a single error left when we `make
manifest`:

```
$ make manifest
1 error(s) detected:
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

So it's down to networking.

Refer back to your [Network Plan][netplan], and find the `global-infra-0`
subnet for the proto-BOSH in the AWS Console.  If you're using the plan in this
repository, that would be `10.4.1.0/24`, and we're allocating
`10.4.1.0/28` to our BOSH Director.  Our `networking.yml` file,
then, should look like this:

```
$ cat networking.yml
---
networks:
  - name: default
    subnets:
      - range:    10.4.1.0/24
        gateway:  10.4.1.1
        dns:     [10.4.0.2]
        cloud_properties:
          subnet: subnet-xxxxxxxx # <-- your AWS Subnet ID
          security_groups: [wide-open]
        reserved:
          - 10.4.1.2 - 10.4.1.3    # Amazon reserves these
            # proto-BOSH is in 10.4.1.0/28
          - 10.4.1.16 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.4
```

Our range is that of the actual subnet we are in, `10.4.1.0/24`
(in reality, the `/28` allocation is merely a tool of bookkeeping
that simplifies ACLs and firewall configuration).  As such, our
Amazon-provided default gateway is 10.4.1.1 (the first available
IP) and our DNS server is 10.4.0.2.

We identify our AWS-specific configuration under
`cloud_properties`, by calling out what AWS Subnet we want the EC2
instance to be placed in, and what EC2 Security Groups it should
be subject to.

Under the `reserved` block, we reserve the IPs that Amazon
reserves for its own use (see [Amazon's documentation][aws-subnets],
specifically the "Subnet sizing" section), and everything outside of
`10.4.1.0/28` (that is, `10.4.1.16` and above).

Finally, in `static` we reserve the first usable IP (`10.4.1.4`)
as static.  This will be assigned to our `bosh/0` director VM.

Now, `make manifest` should succeed (no output is a good sign),
and we should have a full manifest at `manifests/manifest.yml`:

```
$ make manifest
$ ls -l manifests/
total 8
-rw-r--r-- 1 ops staff 4572 Jun 28 14:24 manifest.yml
```

Now we are ready to deploy **proto-BOSH**.

```
$ make deploy
No existing genesis-created bosh-init statefile detected. Please
help genesis find it.
Path to existing bosh-init statefile (leave blank for new
deployments):
Deployment manifest: '~/ops/bosh-deployments/us-west-2/proto/manifests/.deploy.yml'
Deployment state: '~/ops/bosh-deployments/us-west-2/proto/manifests/.deploy-state.json'

Started validating
  Downloading release 'bosh'... Finished (00:00:09)
  Validating release 'bosh'... Finished (00:00:03)
  Downloading release 'bosh-aws-cpi'... Finished (00:00:02)
  Validating release 'bosh-aws-cpi'... Finished (00:00:00)
  Downloading release 'shield'... Finished (00:00:10)
  Validating release 'shield'... Finished (00:00:02)
  Validating cpi release... Finished (00:00:00)
  Validating deployment manifest... Finished (00:00:00)
  Downloading stemcell... Finished (00:00:01)
  Validating stemcell... Finished (00:00:00)
Finished validating (00:00:29)
...
```

(At this point, `bosh-init` starts the tedious process of
compiling all the things.  End-to-end, this is going to take about
a half an hour, so you probably want to go play [a game][slither]
or grab a cup of tea.)

...

All done?  Verify the deployment by trying to `bosh target` the
newly-deployed Director.  First you're going to need to get the
password out of our **vault-init**.

```
$ safe get secret/us-west-2/proto/bosh/users/admin
--- # secret/us-west-2/proto/bosh/users/admin
password: super-secret
```

Then, run target the director:

```
$ bosh target https://10.4.1.4:25555 proto-bosh
Target set to `us-west-2-proto-bosh'
Your username: admin
Enter password:
Logged in as `admin'

$ bosh status
Config
             ~/.bosh_config

Director
  Name       us-west-2-proto-bosh
  URL        https://10.4.1.4:25555
  Version    1.3232.2.0 (00000000)
  User       admin
  UUID       a43bfe93-d916-4164-9f51-c411ee2110b2
  CPI        aws_cpi
  dns        disabled
  compiled_package_cache disabled
  snapshots  disabled

Deployment
  not set
```

All set!

Before you move onto the next step, you should commit your local
deployment files to version control, and push them up _somewhere_.
It's ok, thanks to Vault, Spruce and Genesis, there are no credentials or
anything sensitive in the template files.

### Generate Vault Deploy

We're building the infrastructure environment's vault.

![Vault][bastion_3]

Now that we have a **proto-BOSH** Director, we can use it to deploy
our real Vault.  We'll start with the Genesis template for Vault:

```
$ cd ~/ops
$ genesis new deployment --template vault
$ cd ~/ops/vault-deployments
```

**NOTE**: What is the "ops" environment? Short for operations, it's the
environment we're deploying the **proto-BOSH** and all the extra software that
monitors each of the child environments that will deployed later by the
**proto-BOSH** Director.

As before (and as will become almost second-nature soon), let's
create our `us-west-2` site using the `aws` template, and then create
the `ops` environment inside of that site.

```
$ genesis new site --template aws us-west-2
$ genesis new env us-west-2 proto
```

Answer yes twice and then enter a name for your Vault instance when prompted for a FQDN.

```
$ cd ~/ops/vault-deployments/us-west-2/proto
$ make manifest
10 error(s) detected:
 - $.compilation.cloud_properties.availability_zone: Define the z1 AWS availability zone
 - $.meta.aws.azs.z1: Define the z1 AWS availability zone
 - $.meta.aws.azs.z2: Define the z2 AWS availability zone
 - $.meta.aws.azs.z3: Define the z3 AWS availability zone
 - $.networks.vault_z1.subnets: Specify the z1 network for vault
 - $.networks.vault_z2.subnets: Specify the z2 network for vault
 - $.networks.vault_z3.subnets: Specify the z3 network for vault
 - $.resource_pools.small_z1.cloud_properties.availability_zone: Define the z1 AWS availability zone
 - $.resource_pools.small_z2.cloud_properties.availability_zone: Define the z2 AWS availability zone
 - $.resource_pools.small_z3.cloud_properties.availability_zone: Define the z3 AWS availability zone


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

First, lets do our AWS-specific region/zone configuration, along with our Vault HA fully-qualified domain name:

```
$ cat properties.yml
---
meta:
  aws:
    region: us-west-2
    azs:
      z1: (( concat meta.aws.region "a" ))
      z2: (( concat meta.aws.region "b" ))
      z3: (( concat meta.aws.region "c" ))
properties:
  vault:
    ha:
      domain: 10.4.1.16
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
        dns:     [10.4.0.2]
        cloud_properties:
          subnet: subnet-xxxxxxxx  # <--- your AWS Subnet ID
          security_groups: [wide-open]
        reserved:
          - 10.4.1.2 - 10.4.1.3    # Amazon reserves these
          - 10.4.1.4 - 10.4.1.15   # Allocated to other deployments
            # Vault (z1) is in 10.4.1.16/28
          - 10.4.1.32 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.16 - 10.4.1.18

  - name: vault_z2
    subnets:
      - range:    10.4.2.0/24
        gateway:  10.4.2.1
        dns:     [10.4.2.2]
        cloud_properties:
          subnet: subnet-yyyyyyyy  # <--- your AWS Subnet ID
          security_groups: [wide-open]
        reserved:
          - 10.4.2.2 - 10.4.2.3    # Amazon reserves these
          - 10.4.2.4 - 10.4.2.15   # Allocated to other deployments
            # Vault (z2) is in 10.4.2.16/28
          - 10.4.2.32 - 10.4.2.254 # Allocated to other deployments
        static:
          - 10.4.2.16 - 10.4.2.18

  - name: vault_z3
    subnets:
      - range:    10.4.3.0/24
        gateway:  10.4.3.1
        dns:     [10.4.3.2]
        cloud_properties:
          subnet: subnet-zzzzzzzz  # <--- your AWS Subnet ID
          security_groups: [wide-open]
        reserved:
          - 10.4.3.2 - 10.4.3.3    # Amazon reserves these
          - 10.4.3.4 - 10.4.3.15   # Allocated to other deployments
            # Vault (z3) is in 10.4.3.16/28
          - 10.4.3.32 - 10.4.3.254 # Allocated to other deployments
        static:
          - 10.4.3.16 - 10.4.3.18
```

That's a ton of configuration, but when you break it down it's not
all that bad.  We're defining three separate networks (one for
each of the three availability zones).  Each network has a unique
AWS Subnet ID, but they share the same EC2 Security Groups, since
we want uniform access control across the board.

The most difficult part of this configuration is getting the
reserved ranges and static ranges correct, and self-consistent
with the network range / gateway / DNS settings.  This is a bit
easier since our network plan allocates a different `/24` to each
zone network, meaning that only the third octet has to change from
zone to zone (x.x.1.x for zone 1, x.x.2.x for zone 2, etc.)

Now, let's try a `make manifest` again (no output is a good sign):

```
$ make manifest
```

And then let's give the deploy a whirl:

```
$ make deploy
Acting as user 'admin' on 'us-west-2-proto-bosh'
Checking whether release consul/20 already exists...NO
Using remote release `https://bosh.io/d/github.com/cloudfoundry-community/consul-boshrelease?v=20'

Director task 1

```

Thanks to Genesis, we don't even have to upload the BOSH releases
(or stemcells) ourselves!

### Initializing Your Global Vault

Now that the Vault software is spinning, you're going to need to
initialize the Vault, which generates a root token for interacting
with the Vault, and a set of 5 _seal keys_ that will be used to
unseal the Vault so that you can interact with it.

First off, we need to find the IP addresses of our Vault nodes:

```
$ bosh vms us-west-2-proto-vault
+---------------------------------------------------+---------+-----+----------+-----------+
| VM                                                | State   | AZ  | VM Type  | IPs       |
+---------------------------------------------------+---------+-----+----------+-----------+
| vault_z1/0 (9fe19a85-e9ed-4bab-ac80-0d3034c5953c) | running | n/a | small_z1 | 10.4.1.16 |
| vault_z2/0 (13a46946-cd06-46e5-8672-89c40fd62e5f) | running | n/a | small_z2 | 10.4.2.16 |
| vault_z3/0 (3b234173-04d4-4bfb-b8bc-5966592549e9) | running | n/a | small_z3 | 10.4.3.16 |
+---------------------------------------------------+---------+-----+----------+-----------+
```

(Your UUIDs may vary, but the IPs should be close.)

Let's target the vault at 10.4.1.16:

```
$ export VAULT_ADDR=https://10.4.1.16:8200
$ export VAULT_SKIP_VERIFY=1
```

We have to set `$VAULT_SKIP_VERIFY` to a non-empty value because we
used self-signed certificates when we deployed our Vault. The error message is as following if we did not do `export VAULT_SKIP_VERIFY=1`.

```
!! Get https://10.4.1.16:8200/v1/secret?list=1: x509: cannot validate certificate for 10.4.1.16 because it doesn't contain any IP SANs
```

Ideally, you'll be working with real certificates, and won't have
to perform this step.

Let's initialize the Vault:

```
$ vault init
Unseal Key 1: c146f038e3e6017807d2643fa46d03dde98a2a2070d0fceaef8217c350e973bb01
Unseal Key 2: bae9c63fe2e137f41d1894d8f41a73fc768589ab1f210b1175967942e5e648bd02
Unseal Key 3: 9fd330a62f754d904014e0551ac9c4e4e520bac42297f7480c3d651ad8516da703
Unseal Key 4: 08e4416c82f935570d1ca8d1d289df93a6a1d77449289bac0fa9dc8d832c213904
Unseal Key 5: 2ddeb7f54f6d4f335010dc5c3c5a688b3504e41b749e67f57602c0d5be9b042305
Initial Root Token: e63da83f-c98a-064f-e4c0-cce3d2e77f97

Vault initialized with 5 keys and a key threshold of 3. Please
securely distribute the above keys. When the Vault is re-sealed,
restarted, or stopped, you must provide at least 3 of these keys
to unseal it again.

Vault does not store the master key. Without at least 3 keys,
your Vault will remain permanently sealed.
```

**Store these seal keys and the root token somewhere secure!!**
(A password manager like 1Password is an excellent option here.)

Unlike the dev-mode **vault-init** we spun up at the very outset,
this Vault comes up sealed, and needs to be unsealed using three
of the five keys above, so let's do that.

```
$ vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 1

$ vault unseal
...

$ vault unseal
Key (will be hidden):
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0
```

Now, let's switch back to using `safe`:

```
$ safe target https://10.4.1.16:8200 proto
Now targeting proto at https://10.4.1.16:8200

$ safe auth token
Authenticating against proto at https://10.4.1.16:8200
Token:

$ safe set secret/handshake knock=knock
knock: knock
```

### Migrating Credentials

You should now have two `safe` targets, one for first Vault
(named 'init') and another for the real Vault (named 'proto'):

```
$ safe targets

(*) proto     https://10.4.1.16:8200
    init      http://127.0.0.1:8200

```

Our `proto` Vault should be empty; we can verify that with `safe
tree`:

```
$ safe target proto -- tree
Now targeting proto at https://10.4.1.16:8200
.
└── secret
    └── handshake

```

`safe` supports a handy import/export feature that can be used to
move credentials securely between Vaults, without touching disk,
which is exactly what we need to migrate from our dev-Vault to
our real one:

```
$ safe target init -- export secret | \
  safe target proto -- import
Now targeting proto at https://10.4.1.16:8200
Now targeting init at http://127.0.0.1:8200
wrote secret/us-west-2/proto/bosh/blobstore/director
wrote secret/us-west-2/proto/bosh/db
wrote secret/us-west-2/proto/bosh/vcap
wrote secret/us-west-2/proto/vault/tls
wrote secret/us-west-2
wrote secret/us-west-2/proto/bosh/blobstore/agent
wrote secret/us-west-2/proto/bosh/registry
wrote secret/us-west-2/proto/bosh/users/admin
wrote secret/us-west-2/proto/bosh/users/hm
wrote secret/us-west-2/proto/shield/keys/core
wrote secret/handshake
wrote secret/us-west-2/proto/bosh/nats

$ safe target proto -- tree
Now targeting proto at https://10.4.1.16:8200
.
└── secret
    ├── handshake
    ├── us-west-2
    └── us-west-2/
        └── proto/
            ├── bosh/
            │   ├── blobstore/
            │   │   ├── agent
            │   │   └── director
            │   ├── db
            │   ├── nats
            │   ├── registry
            │   ├── users/
            │   │   ├── admin
            │   │   └── hm
            │   └── vcap
            ├── shield/
            │   └── keys/
            │       └── core
            └── vault/
                └── tls
```

Voila!  We now have all of our credentials in our real Vault, and
we can kill the **vault-init** server process!

```
$ sudo pkill vault
```

## Shield

![Shield][bastion_4]

SHIELD is our backup solution.  We use it to configure and
schedule regular backups of data systems that are important to our
running operation, like the BOSH database, Concourse, and Cloud
Foundry.

### Setting up AWS S3 For Backup Archives

To help keep things isolated, we're going to set up a brand new
IAM user just for backup archive storage.  It's a good idea to
name this user something like `backup` or `shield-backup` so that
no one tries to re-purpose it later, and so that it doesn't get
deleted. We also need to generate an access key for this user and store those credentials in the Vault:

```
$ safe set secret/us-west-2/proto/shield/aws access_key secret_key
access_key [hidden]:
access_key [confirm]:

secret_key [hidden]:
secret_key [confirm]:
```

You're also going to want to provision a dedicated S3 bucket to
store archives in, and name it something descriptive, like
`codex-backups`.

Since the generic S3 bucket policy is a little open (and we don't
want random people reading through our backups), we're going to
want to create our own policy. Go to the IAM user you just created, click
`permissions`, then click the blue button with `Create User Policy`, paste the
following policy and modify accordingly, click `Validate Policy` and apply the
policy afterwards.


```
{
  "Statement": [
    {
      "Effect"   : "Allow",
      "Action"   : "s3:ListAllMyBuckets",
      "Resource" : "arn:aws:iam:xxxxxxxxxxxx:user/zzzzz"
    },
    {
      "Effect"   : "Allow",
      "Action"   : "s3:*",
      "Resource" : [
        "arn:aws:s3:::your-bucket-name",
        "arn:aws:s3:::your-bucket-name/*"
      ]
    }
  ]
}
```

### Deploying SHIELD

We'll start out with the Genesis template for SHIELD:

```
$ cd ~/ops
$ genesis new deployment --template shield
$ cd shield-deployments
```

Now we can set up our `us-west-2` site using the `aws` template, with a
`proto` environment inside of it:

```
$ genesis new site --template aws us-west-2
$ genesis new env us-west-2 proto
$ cd us-west-2/proto
$ make manifest
5 error(s) detected:
 - $.compilation.cloud_properties.availability_zone: What availability zone is SHIELD deployed to?
 - $.meta.az: What availability zone is SHIELD deployed to?
 - $.networks.shield.subnets: Specify your shield subnet
 - $.properties.shield.daemon.ssh_private_key: Specify the SSH private key that the daemon will use to talk to the agents
 - $.resource_pools.small.cloud_properties.availability_zone: What availability zone is SHIELD deployed to?


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

By now, this should be old hat.  According to the [Network
Plan][netplan], the SHIELD deployment belongs in the
**10.4.1.32/28** network, in zone 1 (a).  Let's put that
information into `properties.yml`:

```
$ cat properties.yml
---
meta:
  az: us-west-2a
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
        dns:     [10.4.0.2]
        cloud_properties:
          subnet: subnet-xxxxxxxx  # <--- your AWS Subnet ID
          security_groups: [wide-open]
        reserved:
          - 10.4.1.2 - 10.4.1.3    # Amazon reserves these
          - 10.4.1.4 - 10.4.1.31   # Allocated to other deployments
            # SHIELD is in 10.4.1.32/28
          - 10.4.1.48 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.32 - 10.4.1.34
```

(Don't forget to change your `subnet` to match your AWS VPC
configuration.)

Then we need to configure our `store` and a default `schedule` and `retention` policy:

```
$ cat properties.yml
---
meta:
  az: us-west-2a

properties:
  shield:
    skip_ssl_verify: true
    store:
      name: "default"
      plugin: "s3"
      config:
        access_key_id: (( vault "secret/us-west-2:access_key" ))
        secret_access_key: (( vault "secret/us-west-2:secret_key" ))
        bucket: xxxxxx # <- backup's s3 bucket
        prefix: "/"
    schedule:
      name: "default"
      when: "daily 3am"
    retention:
      name: "default"
      expires: "86400" # 24 hours
```

Finally, if you recall, we already generated an SSH keypair for
SHIELD, so that we could pre-deploy the pubic key to our
**proto-BOSH**.  We stuck it in the Vault, at
`secret/us-west-2/proto/shield/keys/core`, so let's get it back out for this
deployment:

```
$ cat credentials.yml
---
properties:
  shield:
    daemon:
      ssh_private_key: (( vault meta.vault_prefix "/keys/core:private"))
```

Now, our `make manifest` should succeed (and not complain)

```
$ make manifest
```

Time to deploy!

```
$ make deploy
Acting as user 'admin' on 'us-west-2-proto-bosh'
Checking whether release shield/6.3.0 already exists...NO
Using remote release `https://bosh.io/d/github.com/starkandwayne/shield-boshrelease?v=6.3.0'

Director task 13
  Started downloading remote release > Downloading remote release

```

Once that's complete, you will be able to access your SHIELD
deployment, and start configuring your backup jobs.

### How to use SHIELD

TODO: Add how to use SHIELD to backup and restore by using an example.

## bolo

![bolo][bastion_5]

Bolo is a monitoring system that collects metrics and state data
from your BOSH deployments, aggregates it, and provides data
visualization and notification primitives.

### Deploying Bolo Monitoring

You may opt to deploy Bolo once for all of your environments, in
which case it belongs in your management network, or you may
decide to deploy per-environment Bolo installations.  What you
choose mostly only affects your network topology / configuration.

To get started, you're going to need to create a Genesis
deployments repo for your Bolo deployments:

```
$ cd ~/ops
$ genesis new deployment --template bolo
$ cd bolo-deployments
```

Next, we'll create a site for your datacenter or VPC.  The bolo
template deployment offers some site templates to make getting
things stood up quick and easy, including:

- `aws` for Amazon Web Services VPC deployments
- `vsphere` for VMWare ESXi virtualization clusters
- `bosh-lite` for deploying and testing locally

```
$ genesis new site --template aws us-west-2
Created site us-west-2 (from template aws):
~/ops/bolo-deployments/us-west-2
├── README
└── site
    ├── disk-pools.yml
    ├── jobs.yml
    ├── networks.yml
    ├── properties.yml
    ├── releases
    ├── resource-pools.yml
    ├── stemcell
    │   ├── name
    │   └── version
    └── update.yml

2 directories, 10 files
```

Now, we can create our environment.

```
$ cd ~/ops/bolo-deployments/us-west-2
$ genesis new env us-west-2 proto
Created environment us-west-2/proto:
~/ops/bolo-deployments/us-west-2/proto
├── Makefile
├── README
├── cloudfoundry.yml
├── credentials.yml
├── director.yml
├── monitoring.yml
├── name.yml
├── networking.yml
├── properties.yml
└── scaling.yml

0 directories, 10 files
```

Bolo deployments have no secrets, so there isn't much in the way
of environment hooks for setting up credentials.

Now let's make manifest.

```
$ cd ~/ops/bolo-deployments/us-west-2/proto
$ make manifest

2 error(s) detected:
 - $.meta.az: What availability zone is Bolo deployed to?
 - $.networks.bolo.subnets: Specify your bolo subnet

Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

From the error message, we need to configure the following things for an AWS deployment of
bolo:

- Availability Zone (via `meta.az`)
- Networking configuration

According to the [Network Plan][netplan], the bolo deployment belongs in the
**10.4.1.64/28** network, in zone 1 (a). Let's configure the availability zone in `properties.yml`:

```
$ cat properties.yml
---
meta:
  region: us-west-2
  az: (( concat meta.region "a" ))
```

Since `10.4.1.64/28` is subdivision of the `10.4.1.0/24` subnet, we can configure networking as follows.

```
$ cat networking.yml
---
networks:
 - name: bolo
   type: manual
   subnets:
   - range: 10.4.1.0/24
     gateway: 10.4.1.1
     cloud_properties:
       subnet: subnet-xxxxxxxx #<--- your AWS Subnet ID
       security_groups: [wide-open]
     dns: [10.4.0.2]
     reserved:
       - 10.4.1.2   - 10.4.1.3  # Amazon reserves these
       - 10.4.1.4 - 10.4.1.63  # Allocated to other deployments
        # Bolo is in 10.4.1.64/28
       - 10.4.1.80 - 10.4.1.254 # Allocated to other deployments
     static:
       - 10.4.1.65 - 10.4.1.68
```

You can validate your manifest by running `make manifest` and
ensuring that you get no errors (no output is a good sign).

Then, you can deploy to your BOSH Director via `make deploy`.

Once you've deployed, you can validate the deployment via `bosh deployments`. You should see the bolo deployment. You can find the IP of bolo vm by running `bosh vms` for bolo deployment. In order to visit the [Gnossis](https://github.com/bolo/gnossis) web interface on your `bolo/0` VM from your browser on your laptop, you need to setup port forwarding to enable it.

One way of doing it is using ngrok, go to [ngrok Downloads] [ngrok-download] page and download the right version to your `bolo/0` VM, unzip it and run `./ngrok http 80`, it will output something like this:

```
ngrok by @inconshreveable                                                                                                                                                                   (Ctrl+C to quit)

Tunnel Status                 online
Version                       2.1.3
Region                        United States (us)
Web Interface                 http://127.0.0.1:4040
Forwarding                    http://18ce4bd7.ngrok.io -> localhost:80
Forwarding                    https://18ce4bd7.ngrok.io -> localhost:80

Connections                   ttl     opn     rt1     rt5     p50     p90
                              0       0       0.00    0.00    0.00    0.00
```

Copy the http or https link for forwarding and paste it into your browser, you
will be able to visit the Gnossis web interface for bolo.

If you do not want to use ngrok, you can simply use your local built-in SSH client as follows:

```
ssh bastion -L 4040:<ip address of your bolo server>:80 -N
```

Then, go to http://127.0.0.1:4040 in your web browser.

Out of the box, the Bolo installation will begin monitoring itself
for general host health (the `linux` collector), so you should
have graphs for bolo itself.

### Configuring Bolo Agents

Now that you have a Bolo installation, you're going to want to
configure your other deployments to use it.  To do that, you'll
need to add the `bolo` release to the deployment (if it isn't
already there), add the `dbolo` template to all the jobs you want
monitored, and configure `dbolo` to submit metrics to your
`bolo/0` VM in the bolo deployment.

**NOTE**: This may require configuration of network ACLs, security groups, etc.
If you experience issues with this step, you might want to start looking in
those areas first.

We will use shield as an example to show you how to configure Bolo Agents.

To add the release:

```
$ cd ~/ops/shield-deployments
$ genesis add release bolo latest
$ cd ~/ops/shield-deployments/us-west-2/proto
$ genesis use release bolo
```

If you do a `make refresh manifest` at this point, you should see a new
release being added to the top-level `releases` list.

To configure dbolo, you're going to want to add a line like the
last one here to all of your job template definitions:

```
jobs:
  - name: shield
    templates:
      - { release: bolo, name: dbolo }
```

Then, to configure `dbolo` to submit to your Bolo installation,
add the `dbolo.submission.address` property either globally or
per-job (strong recommendation for global, by the way).

If you have specific monitoring requirements, above and beyond
the stock host-health checks that the `linux` collector provides,
you can change per-job (or global) properties like the dbolo.collectors properties.

You can put those configuration in the `properties.yml` as follows:

```
properties:
  dbolo:
    submission:
      address: x.x.x.x # your Bolo VM IP
    collectors:
      - { every: 20s, run: 'linux' }
      - { every: 20s, run: 'httpd' }
      - { every: 20s, run: 'process -n nginx -m nginx' }
```

Remember that you will need to supply the `linux` collector
configuration, since Bolo skips the automatic `dbolo` settings you
get for free when you specify your own configuration.

### Further Reading on Bolo

More information can be found in the [Bolo BOSH Release README][bolo]
which contains a wealth of information about available graphs,
collectors, and deployment properties.

## Concourse

![Concourse][bastion_6]

### Deploying Concourse

If we're not already targeting the ops vault, do so now to save frustration later.

```
$ safe target proto
Now targeting proto at https://10.4.1.16:8200
```


From the `~/ops` folder let's generate a new `concourse` deployment, using the `--template` flag.

```
$ genesis new deployment --template concourse
```

Inside the `global` deployment level goes the site level definition.  For this concourse setup we'll use an `aws` template for an `us-west-2` site.

```
$ genesis new site --template aws us-west-2
Created site us-west-2 (from template aws):
~/ops/concourse-deployments/us-west-2
├── README
└── site
    ├── disk-pools.yml
    ├── jobs.yml
    ├── networks.yml
    ├── properties.yml
    ├── releases
    ├── resource-pools.yml
    ├── stemcell
    │   ├── name
    │   └── version
    └── update.yml

2 directories, 10 files
```

Finally now, because our vault is setup and targeted correctly we can generate our `environment` level configurations.  And begin the process of setting up the specific parameters for our environment.

```
$ cd ~/ops/concourse-deployments
$ genesis new env us-west-2 proto
Running env setup hook: ~/ops/concourse-deployments/.env_hooks/00_confirm_vault

(*) proto   https://10.4.1.16:8200
    init    http://127.0.0.1:8200

Use this Vault for storing deployment credentials?  [yes or no] yes
Running env setup hook: ~/ops/concourse-deployments/.env_hooks/gen_creds
Generating credentials for Concourse CI
Created environment aws/proto:
~/ops/concourse-deployments/us-west-2/proto
├── cloudfoundry.yml
├── credentials.yml
├── director.yml
├── Makefile
├── monitoring.yml
├── name.yml
├── networking.yml
├── properties.yml
├── README
└── scaling.yml

```

Let's make the manifest:

```
$ cd ~/ops/concourse-deployments/us-west-2/proto
$ make manifest
11 error(s) detected:
 - $.compilation.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?
 - $.jobs.haproxy.templates.haproxy.properties.ha_proxy.ssl_pem: Want ssl? define a pem
 - $.jobs.web.templates.atc.properties.external_url: What is the external URL for this concourse?
 - $.meta.availability_zone: What availability zone should your concourse VMs be in?
 - $.meta.external_url: What is the external URL for this concourse?
 - $.meta.ssl_pem: Want ssl? define a pem
 - $.networks.concourse.subnets: Specify your concourse subnet
 - $.resource_pools.db.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?
 - $.resource_pools.haproxy.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?
 - $.resource_pools.web.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?
 - $.resource_pools.workers.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Again starting with Meta lines in `~/ops/concourse-deployments/us-west-2/proto`:

```
$ cat properties.yml
---
meta:
  availability_zone: "us-west-2a"   # Set this to match your first zone "aws_az1"
  external_url: "https://ci.x.x.x.x.sslip.io"  # Set as Elastic IP address of the bastion host to allow testing via SSH tunnel
  ssl_pem: ~
  #  ssl_pem: (( vault meta.vault_prefix "/web_ui:pem" ))
```

Be sure to replace the x.x.x.x in the external_url above with the Elastic IP address of the bastion host.

The `~` means we won't use SSL certs for now.  If you have proper certs or want to use self signed you can add them to vault under the `web_ui:pem` key

For networking, we put this inside `proto` environment level.

```
$ cat networking.yml
---
networks:
  - name: concourse
    subnets:
      - range: 10.4.1.0/24
        gateway: 10.4.1.1
        dns:     [10.4.1.2]
        static:
          - 10.4.1.48 - 10.4.1.56  # We use 48-64, reserving the first eight for static
        reserved:
          - 10.4.1.2 - 10.4.1.3    # Amazon reserves these
		  - 10.4.1.4 - 10.4.1.47   # Allocated to other deployments
          - 10.4.1.65 - 10.4.1.254 # Allocated to other deployments
        cloud_properties:
          subnet: subnet-nnnnnnnn # <-- your AWS Subnet ID
          security_groups: [wide-open]
```

After it is deployed, you can do a quick test by hitting the HAProxy machine

```
$ bosh vms us-west-2-proto-concourse
Acting as user 'admin' on deployment 'us-west-2-proto-concourse' on 'us-west-2-proto-bosh'

Director task 43

Task 43 done

+--------------------------------------------------+---------+-----+---------+------------+
| VM                                               | State   | AZ  | VM Type | IPs        |
+--------------------------------------------------+---------+-----+---------+------------+
| db/0 (fdb7a556-e285-4cf0-8f35-e103b96eff46)      | running | n/a | db      | 10.4.1.61  |
| haproxy/0 (5318df47-b138-44d7-b3a9-8a2a12833919) | running | n/a | haproxy | 10.4.1.51  |
| web/0 (ecb71ebc-421d-4caa-86af-81985958578b)     | running | n/a | web     | 10.4.1.48  |
| worker/0 (c2c081e0-c1ef-4c28-8c7d-ff589d05a1aa)  | running | n/a | workers | 10.4.1.62  |
| worker/1 (12a4ae1f-02fc-4c3b-846b-ae232215c77c)  | running | n/a | workers | 10.4.1.57  |
| worker/2 (b323f3ba-ebe4-4576-ab89-1bce3bc97e65)  | running | n/a | workers | 10.4.1.58  |
+--------------------------------------------------+---------+-----+---------+------------+

VMs total: 6
```

Smoke test HAProxy IP address:

```
$ curl -i 10.4.1.51
HTTP/1.1 200 OK
Date: Thu, 07 Jul 2016 04:50:05 GMT
Content-Type: text/html; charset=utf-8
Transfer-Encoding: chunked

<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Concourse</title>
```

You can then run on a your local machine

```
$ ssh -L 8080:10.4.1.51:80 user@ci.x.x.x.x.sslip.io -i path_to_your_private_key
```

and hit http://localhost:8080 to get the Concourse UI. Be sure to replace `user`
with the `jumpbox` username on the bastion host and x.x.x.x with the IP address
of the bastion host.

### Setup Pipelines Using Concourse

TODO: Need an example to show how to setup pipeline for deployments using Concourse.

## Building out Sites and Environments

Now that the underlying infrastructure has been deployed, we can start deploying our alpha/beta/other sites, with Cloud Foundry, and any required services. When using Concourse to update BOSH deployments,
there are the concepts of `alpha` and `beta` sites. The alpha site is the initial place where all deployment changes are checked for sanity + deployability. Typically this is done with a `bosh-lite` VM. The `beta` sites are where site-level changes are vetted. Usually these are referred to as the sandbox or staging environments, and there will be one per site, by necessity. Once changes have passed both the alpha, and beta site, we know it is reasonable for them to be rolled out to other sites, like production.

### Alpha

#### BOSH-Lite

Since our `alpha` site will be a bosh lite running on AWS, we will need to deploy that to our [global infrastructure network][netplan].

First, lets make sure we're in the right place, targetting the right Vault:

```
$ cd ~/ops
$ safe target proto
Now targeting proto at https://10.4.1.16:8200
```

Now we can create our repo for deploying the bosh-lite:

```
$ genesis new deployment --template bosh-lite
cloning from template https://github.com/starkandwayne/bosh-lite-deployment
Cloning into '~/ops/bosh-lite-deployments'...
remote: Counting objects: 55, done.
remote: Compressing objects: 100% (33/33), done.
remote: Total 55 (delta 7), reused 55 (delta 7), pack-reused 0
Unpacking objects: 100% (55/55), done.
Checking connectivity... done.
Embedding genesis script into repository
genesis v1.5.2 (ec9c868f8e62)
[master 5421665] Initial clone of templated bosh-lite deployment
 3 files changed, 3672 insertions(+), 67 deletions(-)
  rewrite README.md (96%)
   create mode 100755 bin/genesis
```

Next lets create our site and environment:

```
$ cd bosh-lite-deployments
$ genesis new site --template aws us-west-2
Created site us-west-2 (from template aws):
~/ops/bosh-lite-deployments/us-west-2
├── README
└── site
    ├── disk-pools.yml
    ├── jobs.yml
    ├── networks.yml
    ├── properties.yml
    ├── README
    ├── releases
    ├── resource-pools.yml
    ├── stemcell
    │   ├── name
    │   └── version
    └── update.yml

2 directories, 11 files

$ genesis new env us-west-2 alpha
Running env setup hook: ~/ops/bosh-lite-deployments/.env_hooks/setup

(*) proto	https://10.4.1.16:8200

Use this Vault for storing deployment credentials?  [yes or no]yes
Setting up credentials in vault, under secret/us-west-2/alpha/bosh-lite
.
└── secret/us-west-2/alpha/bosh-lite
    ├── blobstore/


    │   ├── agent
    │   └── director
    ├── db
    ├── nats
    ├── users/
    │   ├── admin
    │   └── hm
    └── vcap




Created environment us-west-2/alpha:
~/ops/bosh-lite-deployments/us-west-2/alpha
├── cloudfoundry.yml
├── credentials.yml
├── director.yml
├── Makefile


├── monitoring.yml
├── name.yml
├── networking.yml
├── properties.yml
├── README
└── scaling.yml

0 directories, 10 files

```

Now lets try to deploy:

```
$ cd us-west-2/alpha/
$ make deploy
  checking https://genesis.starkandwayne.com for details on latest stemcell bosh-aws-xen-hvm-ubuntu-trusty-go_agent
  checking https://genesis.starkandwayne.com for details on release bosh/256.2
  checking https://genesis.starkandwayne.com for details on release bosh-warden-cpi/29
  checking https://genesis.starkandwayne.com for details on release garden-linux/0.339.0
  checking https://genesis.starkandwayne.com for details on release port-forwarding/2
8 error(s) detected:
 - $.meta.aws.azs.z1: What Availability Zone will BOSH be in?
 - $.meta.net.dns: What is the IP of the DNS server for this BOSH-Lite?
 - $.meta.net.gateway: What is the gateway of the network the BOSH-Lite will be on?
 - $.meta.net.range: What is the network address of the subnet BOSH-Lite will be on?
 - $.meta.net.reserved: Provide a list of reserved IP ranges for the subnet that BOSH-Lite will be on
 - $.meta.net.security_groups: What security groups should be applied to the BOSH-Lite?
 - $.meta.net.static: Provide a list of static IPs/ranges in the subnet that BOSH-Lite will choose from
 - $.meta.port_forwarding_rules: Define any port forwarding rules you wish to enable on the bosh-lite, or an empty array


Failed to merge templates; bailing...


Makefile:25: recipe for target 'deploy' failed
make: *** [deploy] Error 3
```

Looks like we only have a handful of parameters to update, all related to
networking, so lets fill out our `networking.yml`, after consulting the
[Network Plan][netplan] to find our global infrastructure network and the AWS
console to find our subnet ID:

```
$ cat networking.yml
---
meta:
  net:
    subnet: subnet-xxxxx # <--- your subnet ID here
    security_groups: [wide-open]
    range: 10.4.1.0/24
    gateway: 10.4.1.1
    dns: [10.4.0.2]
```

Since there are a bunch of other deployments on the infrastructure network, we should take care
to reserve the correct static + reserved IPs, so that we don't conflict with other deployments. Fortunately
that data can be referenced in the [Global Infrastructure IP Allocation section][infra-ips] of the Network Plan:

```
$ cat networking.yml
---
meta:
  net:
    subnet: subnet-xxxxx # <--- your subnet ID here
    security_groups: [wide-open]
    range: 10.4.1.0/24
    gateway: 10.4.1.1
    static: [10.4.1.80]
    reserved: [10.4.1.2 - 10.4.1.79, 10.4.1.96 - 10.4.1.255]
    dns: [10.4.0.2]
```

Lastly, we will need to add port-forwarding rules, so that things outside the bosh-lite can talk to its services.
Since we know we will be deploying Cloud Foundry, let's add rules for it:

```
$ cat properties.yml
---
meta:
  aws:
    azs:
      z1: us-west-2a
  port_forwarding_rules:
  - internal_ip: 10.244.0.34
    internal_port: 80
    external_port: 80
  - internal_ip: 10.244.0.34
    internal_port: 443
    external_port: 443
```

And finally, we can deploy again:

```
$ make deploy
  checking https://genesis.starkandwayne.com for details on stemcell bosh-aws-xen-hvm-ubuntu-trusty-go_agent/3262.2
    checking https://genesis.starkandwayne.com for details on release bosh/256.2
  checking https://genesis.starkandwayne.com for details on release bosh-warden-cpi/29
    checking https://genesis.starkandwayne.com for details on release garden-linux/0.339.0
  checking https://genesis.starkandwayne.com for details on release port-forwarding/2
    checking https://genesis.starkandwayne.com for details on stemcell bosh-aws-xen-hvm-ubuntu-trusty-go_agent/3262.2
  checking https://genesis.starkandwayne.com for details on release bosh/256.2
    checking https://genesis.starkandwayne.com for details on release bosh-warden-cpi/29
  checking https://genesis.starkandwayne.com for details on release garden-linux/0.339.0
    checking https://genesis.starkandwayne.com for details on release port-forwarding/2
Acting as user 'admin' on 'us-west-2-proto-bosh'
Checking whether release bosh/256.2 already exists...YES
Acting as user 'admin' on 'us-west-2-proto-bosh'
Checking whether release bosh-warden-cpi/29 already exists...YES
Acting as user 'admin' on 'us-west-2-proto-bosh'
Checking whether release garden-linux/0.339.0 already exists...YES
Acting as user 'admin' on 'us-west-2-proto-bosh'
Checking whether release port-forwarding/2 already exists...YES
Acting as user 'admin' on 'us-west-2-proto-bosh'
Checking if stemcell already exists...
Yes
Acting as user 'admin' on deployment 'us-west-2-alpha-bosh-lite' on 'us-west-2-proto-bosh'
Getting deployment properties from director...
Unable to get properties list from director, trying without it...

Detecting deployment changes
...
Deploying
---------
Are you sure you want to deploy? (type 'yes' to continue): yes

Director task 58
  Started preparing deployment > Preparing deployment. Done (00:00:00)
...
Task 58 done

Started		2016-07-14 19:14:31 UTC
Finished	2016-07-14 19:17:42 UTC
Duration	00:03:11

Deployed `us-west-2-alpha-bosh-lite' to `us-west-2-proto-bosh'
```

**NOTE**: If deploying a bosh-release (BOSH in this case) fails from the proto-BOSH to a child environment (different subnet), you might be having [this issue](https://github.com/starkandwayne/codex/issues/64) with a too strict AWS Network ACL (`<vpc name>-hardened`). BOSH will fail with errors such as: `Error 450002: Timed out pinging to ... after 600 seconds`.

Now we can verify the deployment and set up our `bosh` CLI target:

```
# grab the admin password for the bosh-lite
$ safe get secret/us-west-2/alpha/bosh-lite/users/admin
--- # secret/us-west-2/alpha/bosh-lite/users/admin
password: YOUR-PASSWORD-WILL-BE-HERE


$ bosh target https://10.4.1.80:25555 alpha
Target set to `us-west-2-alpha-bosh-lite'
Your username: admin
Enter password:
Logged in as `admin'
$ bosh status
Config
             ~/.bosh_config

 Director
   Name       us-west-2-alpha-bosh-lite
     URL        https://10.4.1.80:25555
   Version    1.3232.2.0 (00000000)
     User       admin
   UUID       d0a12392-f1df-4394-99d1-2c6ce376f821
     CPI        vsphere_cpi
   dns        disabled
     compiled_package_cache disabled
   snapshots  disabled

   Deployment
     not set
```

Tadaaa! Time to commit all the changes to deployment repo, and push to where we're storing
them long-term.

#### Alpha Cloud Foundry

To deploy CF to our alpha environment, we will need to first ensure we're targeting the right
Vault/BOSH:

```
$ cd ~/ops
$ safe target proto

(*) proto	https://10.4.1.16:8200

$ bosh target alpha
Target set to `us-west-2-alpha-bosh-lite'
```

Now we'll create our deployment repo for cloudfoundry:

```
$ genesis new deployment --template cf
cloning from template https://github.com/starkandwayne/cf-deployment
Cloning into '~/ops/cf-deployments'...
remote: Counting objects: 268, done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 268 (delta 0), reused 0 (delta 0), pack-reused 265
Receiving objects: 100% (268/268), 51.57 KiB | 0 bytes/s, done.
Resolving deltas: 100% (112/112), done.
Checking connectivity... done.
Embedding genesis script into repository
genesis v1.5.2 (ec9c868f8e62)
[master 1f0c534] Initial clone of templated cf deployment
 2 files changed, 3666 insertions(+), 150 deletions(-)
 rewrite README.md (99%)
 create mode 100755 bin/genesis
```

And generate our bosh-lite based alpha environment:

```
$ cd cf-deployments
$ genesis new site --template bosh-lite bosh-lite
Created site bosh-lite (from template bosh-lite):
~/ops/cf-deployments/bosh-lite
├── README
└── site
    ├── disk-pools.yml
    ├── jobs.yml
    ├── networks.yml
    ├── properties.yml
    ├── releases
    ├── resource-pools.yml
    ├── stemcell
    │   ├── name
    │   └── version
    └── update.yml

2 directories, 10 files

$ genesis new env bosh-lite alpha
Running env setup hook: ~/ops/cf-deployments/.env_hooks/00_confirm_vault

(*) proto	https://10.4.1.16:8200

Use this Vault for storing deployment credentials?  [yes or no] yes
Running env setup hook: ~/ops/cf-deployments/.env_hooks/setup_certs
Generating Cloud Foundry internal certs
Uploading Cloud Foundry internal certs to Vault
Running env setup hook: ~/ops/cf-deployments/.env_hooks/setup_cf_secrets
Creating JWT Signing Key
Creating app_ssh host key fingerprint
Generating secrets
Created environment bosh-lite/alpha:
~/ops/cf-deployments/bosh-lite/alpha
├── cloudfoundry.yml
├── credentials.yml
├── director.yml
├── Makefile
├── monitoring.yml
├── name.yml
├── networking.yml
├── properties.yml
├── README
└── scaling.yml

0 directories, 10 files


```

Unlike all the other deployments so far, we won't use `make manifest` to vet the manifest for CF. This is because the bosh-lite CF comes out of the box ready to deploy to a Vagrant-based bosh-lite with no tweaks.  Since we are using it as the Cloud Foundry for our alpha environment, we will need to customize the Cloud Foundry base domain, with a domain resolving to the IP of our `alpha` bosh-lite VM:

```
cd bosh-lite/alpha
$ cat properties.yml
---
meta:
  cf:
    base_domain: 10.4.1.80.sslip.io
```

Now we can deploy:

```
$ make deploy
  checking https://genesis.starkandwayne.com for details on release cf/237
  checking https://genesis.starkandwayne.com for details on release toolbelt/3.2.10
  checking https://genesis.starkandwayne.com for details on release postgres/1.0.3
  checking https://genesis.starkandwayne.com for details on release cf/237
  checking https://genesis.starkandwayne.com for details on release toolbelt/3.2.10
  checking https://genesis.starkandwayne.com for details on release postgres/1.0.3
Acting as user 'admin' on 'us-west-2-try-anything-bosh-lite'
Checking whether release cf/237 already exists...NO
Using remote release `https://bosh.io/d/github.com/cloudfoundry/cf-release?v=237'

Director task 1
  Started downloading remote release > Downloading remote release
...
Deploying
---------
Are you sure you want to deploy? (type 'yes' to continue): yes

Director task 12
  Started preparing deployment > Preparing deployment. Done (00:00:01)
...
Task 12 done

Started		2016-07-15 14:47:45 UTC
Finished	2016-07-15 14:51:28 UTC
Duration	00:03:43

Deployed `bosh-lite-alpha-cf' to `us-west-2-try-anything-bosh-lite'
```

And once complete, run the smoke tests for good measure:

```
$ genesis bosh run errand smoke_tests
Acting as user 'admin' on deployment 'bosh-lite-alpha-cf' on 'us-west-2-alpha-bosh-lite'

Director task 18
  Started preparing deployment > Preparing deployment. Done (00:00:02)

  Started preparing package compilation > Finding packages to compile. Done (00:00:01)

  Started creating missing vms > smoke_tests/0 (c609e4c5-29e7-4f66-81e1-b94b9139ee7d). Done (00:00:08)

  Started updating job smoke_tests > smoke_tests/0 (c609e4c5-29e7-4f66-81e1-b94b9139ee7d) (canary). Done (00:00:23)

  Started running errand > smoke_tests/0. Done (00:02:18)

  Started fetching logs for smoke_tests/c609e4c5-29e7-4f66-81e1-b94b9139ee7d (0) > Finding and packing log files. Done (00:00:01)

  Started deleting errand instances smoke_tests > smoke_tests/0 (c609e4c5-29e7-4f66-81e1-b94b9139ee7d). Done (00:00:03)

Task 18 done

Started         2016-10-05 14:15:16 UTC
Finished        2016-10-05 14:18:12 UTC
Duration        00:02:56

[stdout]
################################################################################################################
go version go1.6.3 linux/amd64
CONFIG=/var/vcap/jobs/smoke-tests/bin/config.json
...

Errand 'smoke_tests' completed successfully (exit code 0)
```

We now have our alpha-environment's Cloud Foundry stood up!

### First Beta Environment

Now that our `alpha` environment has been deployed, we can deploy our first beta environment to AWS. To do this, we will first deploy a BOSH Director for the environment using the `bosh-deployments` repo we generated back when we built our [proto-BOSH](#proto-bosh), and then deploy Cloud Foundry on top of it.

#### BOSH
```
$ cd ~/ops/bosh-deployments
$ bosh target proto-bosh
$ ls
us-west-2  bin  global  LICENSE  README.md
```

We already have the `us-west-2` site created, so now we will just need to create our new environment, and deploy it. Different names (sandbox or staging) for Beta have been used for different customers, here we call it staging.


```
$ safe target proto
Now targeting proto at http://10.10.10.6:8200
$ genesis new env us-west-2 staging
RSA 1024 bit CA certificates are loaded due to old openssl compatibility
Running env setup hook: ~/ops/bosh-deployments/.env_hooks/setup

 proto	http://10.10.10.6:8200

Use this Vault for storing deployment credentials?  [yes or no] yes
Setting up credentials in vault, under secret/us-west-2/staging/bosh
.
└── secret/us-west-2/staging/bosh
    ├── blobstore/
    │   ├── agent
    │   └── director
    ├── db
    ├── nats
    ├── users/
    │   ├── admin
    │   └── hm
    └── vcap


Created environment us-west-2/staging:
~/ops/bosh-deployments/us-west-2/staging
├── cloudfoundry.yml
├── credentials.yml
├── director.yml
├── Makefile
├── monitoring.yml
├── name.yml
├── networking.yml
├── properties.yml
├── README
└── scaling.yml

0 directories, 10 files

```

Notice, unlike the **proto-BOSH** setup, we do not specify `--type bosh-init`. This means we will use BOSH itself (in this case the **proto-BOSH**) to deploy our sandbox BOSH. Again, the environment hook created all of our credentials for us, but this time we targeted the long-term Vault, so there will be no need for migrating credentials around.

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

Now that that's handled, let's deploy for real:

```
$ make deploy
$ make deploy
RSA 1024 bit CA certificates are loaded due to old openssl compatibility
Acting as user 'admin' on 'aws-proto-bosh-microboshen-aws'
Checking whether release bosh/256.2 already exists...YES
Acting as user 'admin' on 'aws-proto-bosh-microboshen-aws'
Checking whether release bosh-aws-cpi/53 already exists...YES
Acting as user 'admin' on 'aws-proto-bosh-microboshen-aws'
Checking whether release shield/6.2.1 already exists...YES
Acting as user 'admin' on 'aws-proto-bosh-microboshen-aws'
Checking if stemcell already exists...
Yes
Acting as user 'admin' on deployment 'us-west-2-staging-bosh' on 'aws-proto-bosh-microboshen-aws'
Getting deployment properties from director...

Detecting deployment changes
----------------------------
resource_pools:
- cloud_properties:
    availability_zone: us-east-1b
    ephemeral_disk:
      size: 25000
      type: gp2
    instance_type: m3.xlarge
  env:
    bosh:
      password: "<redacted>"
  name: bosh
  network: default
  stemcell:
    name: bosh-aws-xen-hvm-ubuntu-trusty-go_agent
    sha1: 971e869bd825eb0a7bee36a02fe2f61e930aaf29
    url: https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3232.6
...
Deploying
---------
Are you sure you want to deploy? (type 'yes' to continue): yes

Director task 144
  Started preparing deployment > Preparing deployment. Done (00:00:00)

  Started preparing package compilation > Finding packages to compile. Done (00:00:00)
...
Task 144 done

Started		2016-07-08 17:23:47 UTC
Finished	2016-07-08 17:34:46 UTC
Duration	00:10:59

Deployed 'us-west-2-staging-bosh' to 'us-west-2-proto-bosh'
```

This will take a little less time than **proto-BOSH** did (some packages were already compiled), and the next time you deploy, it go by much quicker, as all the packages should have been compiled by now (unless upgrading BOSH or the stemcell).

Once the deployment finishes, target the new BOSH Director to verify it works:

```
$ safe get secret/us-west-2/staging/bosh/users/admin # grab the admin user's password for bosh
$ bosh target https://10.4.32.4:25555 us-west-2-staging
Target set to 'us-west-2-staging-bosh'
Your username: admin
Enter password:
Logged in as 'admin'
```

Again, since our creds are already in the long-term vault, we can skip the credential migration that was done in the proto-bosh deployment and go straight to committing our new deployment to the repo, and pushing it upstream.

Now it's time to move on to deploying our `beta` (staging) Cloud Foundry!

#### Jumpboxen?

#### Beta Cloud Foundry

To deploy Cloud Foundry, we will go back into our `ops` directory, making use of
the `cf-deplyoments` repo created when we built our alpha site:

```
$ cd ~/ops/cf-deployments
```

Also, make sure that you're targeting the right Vault, for good measure:

```
$ safe target proto
```

We will now create an `us-west-2` site for CF:

```
$ genesis new site --template aws us-west-2
Created site us-west-2 (from template aws):
~/ops/cf-deployments/us-west-2
├── README
└── site
    ├── disk-pools.yml
    ├── jobs.yml
    ├── networks.yml
    ├── properties.yml
    ├── releases
    ├── resource-pools.yml
    ├── stemcell
    │   ├── name
    │   └── version
    └── update.yml

2 directories, 10 files

```

And the `staging` environment inside it:

```
$ genesis new env us-west-2 staging
RSA 1024 bit CA certificates are loaded due to old openssl compatibility
Running env setup hook: ~/ops/cf-deployments/.env_hooks/00_confirm_vault

 proto	http://10.10.10.6:8200

Use this Vault for storing deployment credentials?  [yes or no] yes
Running env setup hook: ~/ops/cf-deployments/.env_hooks/setup_certs
Generating Cloud Foundry internal certs
Uploading Cloud Foundry internal certs to Vault
Running env setup hook: ~/ops/cf-deployments/.env_hooks/setup_cf_secrets
Creating JWT Signing Key
Creating app_ssh host key fingerprint
Generating secrets
Created environment us-west-2/staging:
~/ops/cf-deployments/us-west-2/staging
├── cloudfoundry.yml
├── credentials.yml
├── director.yml
├── Makefile
├── monitoring.yml
├── name.yml
├── networking.yml
├── properties.yml
├── README
└── scaling.yml

0 directories, 10 files

```

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

Now it's time to create our Elastic Load Balancer that will be in front of the `gorouters`, but as we will need TLS termination we then need to create a SSL/TLS certificate for our domain.

Create first the CA Certificate:

```
$ mkdir -p /tmp/certs
$ cd /tmp/certs
$ certstrap init --common-name "CertAuth"
Enter passphrase (empty for no passphrase):

Enter same passphrase again:

Created out/CertAuth.key
Created out/CertAuth.crt
Created out/CertAuth.crl
```

Then create the certificates for your domain:

```
$ certstrap request-cert -common-name *.staging.<your domain> -domain *.system.staging.<your domain>,*.run.staging.<your domain>,*.login.staging.<your domain>,*.uaa.staging.<your domain>

Enter passphrase (empty for no passphrase):

Enter same passphrase again:

Created out/*.staging.<your domain>.key
Created out/*.staging.<your domain>.csr
```

And last, sign the domain certificates with the CA certificate:

```
$ certstrap sign *.staging.<your domain> --CA CertAuth
Created out/*.staging.<your domain>.crt from out/*.staging.<your domain>.csr signed by out/CertAuth.key
```

For safety, let's store the certificates in Vault:

```
$ cd out
$ safe write secret/us-west-2/staging/cf/tls/ca "csr@CertAuth.crl"
$ safe write secret/us-west-2/staging/cf/tls/ca "crt@CertAuth.crt"
$ safe write secret/us-west-2/staging/cf/tls/ca "key@CertAuth.key"
$ safe write secret/us-west-2/staging/cf/tls/domain "crt@*.staging.<your domain>.crt"
$ safe write secret/us-west-2/staging/cf/tls/domain "csr@*.staging.<your domain>.csr"
$ safe write secret/us-west-2/staging/cf/tls/domain "key@*.staging.<your domain>.key"
```

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

Lastly, let's make sure to add our Cloud Foundry domain to properties.yml:

```
---
meta:
  skip_ssl_validation: true
  cf:
    base_domain: staging.<your domain> # <- Your CF domain
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
```

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
Another thing we may want to do is scaling the VM size to save some cost when we are deploying in non-production environment, for example, we can configure the `scaling.yml` as follows:

```
resource_pools:

- name: runner_z2
  cloud_properties:
    instance_type: t2.medium

- name: runner_z1
  cloud_properties:
    instance_type: t2.medium

- name: runner_z3
  cloud_properties:
    instance_type: t2.medium
```

That should be it, finally. Let's deploy!

```
$ make deploy
RSA 1024 bit CA certificates are loaded due to old openssl compatibility
Acting as user 'admin' on 'us-west-2-staging-bosh'
Checking whether release cf/237 already exists...NO
Using remote release 'https://bosh.io/d/github.com/cloudfoundry/cf-release?v=237'

Director task 6
  Started downloading remote release > Downloading remote release
...
Deploying
---------
Are you sure you want to deploy? (type 'yes' to continue): yes
...

Started		2016-07-08 17:23:47 UTC
Finished	2016-07-08 17:34:46 UTC
Duration	00:10:59

Deployed 'us-west-2-staging-cf' to 'us-west-2-staging-bosh'

```

You may encounter the following error when you are deploying Beta CF.

```
Unknown CPI error 'Unknown' with message 'Your quota allows for 0 more running instance(s). You requested at least 1.
```

Amazon has per-region limits for different types of resources. Check what resource type your failed job is using and request to increase limits for the resource your jobs are failing at. You can log into your Amazon console, go to EC2 services, on the left column click `Limits`, you can click the blue button says `Request limit increase` on the right of each type of resource. It takes less than 30 minutes get limits increase approved through Amazon.

If you want to scale your deployment in the current environment (here it is staging), you can modify `scaling.yml` in your `cf-deployments/us-west-2/staging` directory. In the following example, you scale runners in both AZ to 2. Afterwards you can run `make manifest` and `make deploy`, please always remember to verify your changes in the manifest before you type `yes` to deploy making sure the changes are what you want.

```
jobs:

- name: runner_z1
  instances: 2

- name: runner_z2
  instances: 2

```

After a long while of compiling and deploying VMs, your CF should now be up, and accessible! You can
check the sanity of the deployment via `genesis bosh run errand smoke_tests`. Target it using
`cf login -a https://api.system.<your CF domain>`. The admin user's password can be retrieved
from Vault. If you run into any trouble, make sure that your DNS is pointing properly to the
correct ELB for this environment, and that the ELB has the correct SSL certificate for your site.

##### Push An App to Beta Cloud Foundry

After you successfully deploy the Beta CF, you can push an simple app to learn more about CF. In the CF world, every application and service is scoped to a space. A space is inside an org and provides users with access to a shared location for application development, deployment, and maintenance. An org is a development account that an individual or multiple collaborators can own and use. You can click [orgs, spaces, roles and permissions][orgs and spaces] to learn more  details.

The first step is creating and org and an space and targeting the org and space you created by running the following commands.

```
cf create-org sw-codex
cf target -o sw-codex
cf create-space test
cf target -s test

```

Once you are in the space, you can push an very simple app [cf-env][cf-env]  to the CF. Clone the [cf-env][cf-env]  repo on your bastion server, then go inside the `cf-env` directory, simply run `cf push` and it will start to upload, stage and run your app.

Your `cf push` command may fail like this:

```
Using manifest file /home/user/cf-env/manifest.yml

Updating app cf-env in org sw-codex / space test as admin...
OK

Uploading cf-env...
FAILED
Error processing app files: Error uploading application.
Server error, status code: 500, error code: 10001, message: An unknown error occurred.

```
You can try to debug this yourself for a while or find the possible solution in [Debug Unknown Error When You Push Your APP to CF][DebugUnknownError].

### Production Environment

Deploying the production environment will be much like deploying the `beta` environment above. You will need to deploy a BOSH Director, Cloud Foundry, and any services also deployed in the `beta` site. Hostnames, credentials, network information, and possibly scaling parameters will all be different, but the procedure for deploying them is the same.

### Next Steps

Lather, rinse, repeat for all additional environments (dev, prod, loadtest, whatever's applicable to the client).

[//]: # (Links, please keep in alphabetical order)

[amazon-region-doc]: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
[aws]:               https://signin.aws.amazon.com/console
[aws-subnets]:       http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html
[az]:                http://aws.amazon.com/about-aws/global-infrastructure/
[bastion_host]:      aws.md#bastion-host
[bolo]:              https://github.com/cloudfoundry-community/bolo-boshrelease
[cfconsul]:          https://docs.cloudfoundry.org/concepts/architecture/#bbs-consul
[cfetcd]:            https://docs.cloudfoundry.org/concepts/architecture/#etcd
[DRY]:               https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[genesis]:           https://github.com/starkandwayne/genesis
[jumpbox]:           https://github.com/starkandwayne/jumpbox
[netplan]:           https://github.com/starkandwayne/codex/blob/master/network.md
[ngrok-download]:    https://ngrok.com/download
[infra-ips]:         https://github.com/starkandwayne/codex/blob/master/part3/network.md#global-infrastructure-ip-allocation
[setup_credentials]: aws.md#setup-credentials
[spruce-129]:        https://github.com/geofffranks/spruce/issues/129
[slither]:           http://slither.io
[troubleshooting]:   troubleshooting.md
[use_terraform]:     aws.md#use-terraform
[verify_ssh]:        https://github.com/starkandwayne/codex/blob/master/troubleshooting.md#verify-keypair
[cf-env]:            https://github.com/cloudfoundry-community/cf-env
[orgs and spaces]:   https://docs.cloudfoundry.org/concepts/roles.html
[DebugUnknownError]: http://www.starkandwayne.com/blog/debug-unknown-error-when-you-push-your-app-to-cf/

[//]: # (Images, put in /images folder)

[levels_of_bosh]:         images/levels_of_bosh.png "Levels of Bosh"
[bastion_host_overview]:  images/bastion_host_overview.png "Bastion Host Overview"
[bastion_1]:              images/bastion_step_1.png "vault-init"
[bastion_2]:              images/bastion_step_2.png "proto-BOSH"
[bastion_3]:              images/bastion_step_3.png "Vault"
[bastion_4]:              images/bastion_step_4.png "Shield"
[bastion_5]:              images/bastion_step_5.png "Bolo"
[bastion_6]:              images/bastion_step_6.png "Concourse"
[global_network_diagram]: images/global_network_diagram.png "Global Network Diagram"
