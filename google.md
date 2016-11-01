# Part IV - Google Guide

## Overview

Welcome to the Stark & Wayne guide to deploying Cloud Foundry on [Google Cloud Platform][google]. This guide provides the steps to create authentication credentials, generate Network/Subnetworks and then use Terraform to prepare a bastion host.

From this bastion, we setup a special BOSH director we call the **proto-BOSH** server where software like Vault, Concourse, Bolo and SHIELD are setup in order to give each of the environments created after the **proto-BOSH** key benefits of:

* Secure Credential Storage
* Pipeline Management
* Monitoring Framework
* Backup and Restore Datastores

Once the **proto-BOSH** environment is setup, the child environments will have the added benefit of being able to update their BOSH software as a release, rather than having to re-initialize with `bosh-init`.

This also increases the resiliency of all BOSH directors through monitoring and backups with software created by Stark & Wayne's engineers.

And visibility into the progress and health of each application, release, or package is available through the power of Concourse pipelines.

![Levels of Bosh][bosh_levels]

In the above diagram, BOSH (1) is the **proto-BOSH**, while BOSH (2) and BOSH (3) are the per-site BOSH directors.

Now it's time to setup the credentials.

## Setup Credentials

### Signup

So you've got an Google Cloud Platform account right? No? Let's [sign up][signup] and activate Google Compute Engine.

### Setup Google Cloud SDK

[Download and install][gcloud] the Google Cloud SDK command line tool.

Set your project ID:

```
export projectid=REPLACE_WITH_YOUR_PROJECT_ID
```

And finally configure `gcloud`:

```
gcloud auth login
gcloud config set project ${projectid}
```

### Generate a Service Account and Key

The first thing you're going to need is a **Service Account** and a **Private Service Account Key**. These are generated (for IAM users) via the [IAM & Admin GCP dashboard][iam-dashboard] or via the `gcloud` tool.

To help keep things isolated, we're going to set up a brand new IAM user. It's a good idea to name this user something like `cf-account` so that no one tries to re-purpose it later, and so that it doesn't get deleted. Remember that Google Service Accounts names must be between 6 and 30 characters.

Using the `gcloud` tool, let's create a new service account and key:

```
gc_cf_account="cf-account"
$ gcloud iam service-accounts create ${gc_cf_account} \
  --display-name "CloudFoundry Service Account"
$ gcloud iam service-accounts keys create $HOME/cf-account.key.json \
  --iam-account ${gc_cf_account}@${projectid}.iam.gserviceaccount.com
```

Then make your service account's key available in an environment variable so we can use later by `terraform`:

```
export GOOGLE_CREDENTIALS=$(cat $HOME/cf-account.key.json)
```

And finally grant the new service account editor access to your project:

```
$ gcloud projects add-iam-policy-binding ${projectid} \
  --member serviceAccount:${gc_cf_account}@${projectid}.iam.gserviceaccount.com \
  --role roles/editor
```

### Name Your Network

This step is really simple -- just make one up. The Network name will be used to prefix certain things that Terraform creates in the Google Cloud Platform. When managing multiple Networks this can help you to sub-select only the ones you're concerned about.

The Network is configured in Terraform using the `google_network_name` variable in the `google.tfvars` file we're going to create soon.

```
google_network_name = "snw"
```

The prefix of `snw` for Stark & Wayne would show up before Network components like Subnetworkss and Firewalls.

## Use Terraform

Once the requirements for Gogogle are met, we can put it all together and build out your shiny new Network and bastion host. Change to the `terraform/google` sub-directory of this repository before we begin.

The configuration directly matches the [Network Plan][netplan] for the demo environment. When deploying in other environments like production, some tweaks or rewrites may need to be made.

### Variable File

Create a `google.tfvars` file with the following configurations (substituting your actual values) all the other configurations have default settings in the
`CODEX_ROOT/terraform/google/google.tf` file.

```
google_project = "..."
google_network_name = "snw"
```

You may change some default settings according to the real cases you are working on. For example, you can change `machine_type (default is n1-standard-1)` in `google.tf` to large size if the bastion would require a high workload.

### Production Considerations

When considering production availability. We recommend a [region with three zones][regions-zones] for best HA results, for example, Vault requires at least three zones.

So let's specify the region and zones we want to use for the resources to be created:

```
google_region = "europe-west1"
google_zone_1 = "b"
google_zone_2 = "c"
google_zone_3 = "d"
```

### Build Resources

As a quick pre-flight check, run `make manifest` to compile your Terraform plan and suss out any issues with naming, missing variables, configuration, etc.:

```
$ make manifest
terraform get -update
terraform plan -var-file google.tfvars -out google.tfplan
Refreshing Terraform state prior to plan...

<snip>

Plan: 60 to add, 0 to change, 0 to destroy.
```

If everything worked out you should se a summary of the plan. If this is the first time you've done this, all of your changes should be additions. The numbers may differ from the above output, and that's okay.

Now, to pull the trigger, run `make deploy`:

```
$ make deploy
```

Terraform will connect to Google Cloud Platform, using your **Service Account**, and spin up all the things it needs. When it finishes, you should be left with a bunch of subnets, firewalls and a bastion host.

If you run into issues before this point refer to our [troubleshooting][troubleshooting] doc for help.

## Bastion Host

The bastion host is the server the BOSH operator connects to, in order to perform commands that affect the **proto-BOSH** Director and the software that gets deployed by it.

We'll be covering the configuration and deployment of each of these software
step-by-step as we go along. By the time you're done working on the bastion
server, you'll have installed each of the following in the numbered order:

![Bastion Host Overview][bastion_host_overview]

### Connect to Bastion

Before we can begin to install software, we need to connect to the server. At the end of the Terraform `make deploy` output the `bastion` vm name, region, zone and public IP variables are displayed.  You can also get these variables using the following command:

```
gcloud compute instances list
```

```
box.bastion.name = bastion
box.bastion.public_ip = x.x.x.x
box.bastion.region = europe-west1
box.bastion.zone = europe-west1-b
```

Now connect to the bastion server using the `gcloud` utility:

```
$ gcloud compute ssh bastion --zone europe-west1-b
```

Your ssh key pair for the initial bastion host login account will be created on your initial login request.  The private and public keys will be stored in your $HOME/.ssh directory in the files google_compute_engine and google_compute_engine.pub respectively. The public key will be needed when you do `jumpbox useradd` later on.

### Setup User

Once on the bastion host, you'll want to use the `jumpbox` script, which has been installed automatically by the Terraform configuration. [This script installs][jumpbox] some useful utilities like `jq`, `spruce`, `safe`, and `genesis` all of which will be important when we start using the bastion host to do deployments.

**NOTE**: Try not to confuse the `jumpbox` script with the jumpbox _BOSH release_. The _BOSH release_ can be used as part of the deployment. And the script gets run directly on the bastion host.

Once connected to the bastion, check if the `jumpbox` utility is installed.

```
$ jumpbox -v
jumpbox v49
```

Then run `jumpbox user` to install all dependent packages. At the end will prompt for git configuration that will be useful when we are generating Genesis templates later.

```
$ jumpbox user
                   _.-+.
              _.-""     '.
          +:""            '.
          J \               '.
           L \             _.-+
           |  '.       _.-"   |
           J    \  _.-"       L
            L    +"          J
            +    |           |     (( jumpbox ))
             \   |          .+
              \  |       .-'
               \ |    .-'
                \| .-'
                 +

>> Installing rvm
...
Your Full Name (for git):
Your Email Address (for git):
   git is configured



   ALL DONE
```

Log out and log in again. Then run `jumpbox` and if everything returns green then everything is ready to continue.

```
$ jumpbox
...
>> Checking jumpbox installation
   jumpbox installed - jumpbox v49
   ruby installed - ruby 2.2.4p230 (2015-12-16 revision 53155) [x86_64-linux]
   rvm installed - rvm 1.27.0 (latest) by Wayne E. Seguin <wayneeseguin@gmail.com>, Michal Papis <mpapis@gmail.com> [https://rvm.io/]
   bosh installed - BOSH 1.3184.1.0
   bosh-init installed - version 0.0.81-775439c-2015-12-09T00:36:03Z
   cf installed - cf version 6.21.1+6fd3c9f-2016-08-10
   jq installed - jq-1.5
   spruce installed - spruce - Version 1.8.0
   safe installed - safe v0.0.23
   vault installed - Vault v0.6.0
   genesis installed - genesis 1.5.2 (61864a21370c)
   certstrap installed - certstrap version 1.0.1
   sipcalc installed - sipcalc 1.1.6
...
git user.name  is 'Joe User'
git user.email is 'juser@starkandwayne.com'
...
```

### Add User

In order to have the dependencies for the `bosh_cli` we need to create a user. Also a convenience method at the end will prompt for git configuration that will be useful when we are generating Genesis templates later.

Also, using named accounts provides auditing (via the `sudo` logs), and isolation (people won't step on each others toes on the filesystem) and customization (everyone gets to set their own prompt / shell / `$EDITOR`).

Let's add a user with `jumpbox useradd`:

**TBD NOTE:** The sudo is required for now since it prompts for the bastion user account password for some reason. Sudo avoided getting the extra password prompt. Should investigate the ssh setup and see if we eliminate this kludge.

```
$ sudo jumpbox useradd
Full name: Joe User
Username: juser
sudo password for ubuntu:
You should run `jumpbox user` now, as juser:
  sudo -iu juser
  jumpbox user
```

After you've added the user, use the `sudo -iu juser` command to change to the user. And run `jumpbox user` to install all dependent packages.

**TBD NOTE:** I was surprised I needed the extra sudo to avoid that extra password prompt. __The duplicate sudo is intentional__.  Maybe the issue is with the sudo setup and not with ssh. 

```
$ sudo sudo -iu juser
$ jumpbox user
```

## Proto Environment

![Global Network Diagram][global_network_diagram]

There are three layers to `genesis` templates.

* Global
* Site
* Environment

### Site Name

Sometimes the site level name can be a bit tricky because each IaaS divides things differently. With Google we suggest a default of the Google Region you're using, for example: `europe-west1`.

### Environment Name

All of the software the **proto-BOSH** will deploy will be in the `proto` environment. And by this point, you've [Setup Credentials][setup_credentials], [Used Terraform][use_terraform] to construct the IaaS components and [Configured a Bastion Host][bastion_host]. We're ready now to setup a BOSH Director on the bastion.

The first step is to create a **vault-init** process.

### vault-init

![vault-init][bastion_1]

BOSH has secrets. Lots of them. Components like NATS and the database rely on secure passwords for inter-component interaction. Ideally, we'd have a spinning Vault for storing our credentials, so that we don't have them on-disk or in a git repository somewhere.

However, we are starting from almost nothing, so we don't have the luxury of using a BOSH-deployed Vault. What we can do, however, is spin a single-threaded
Vault server instance **on the bastion host**, and then migrate the credentials to the real Vault later.

This we call a **vault-init**. Because it precedes the **proto-BOSH** and Vault
deploy we'll be setting up later.

The `jumpbox` script that we ran as part of setting up the bastion host installs the `vault` command-line utility, which includes not only the client for interacting with Vault (`safe`), but also the Vault server daemon itself.

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
...
```

A vault being unsealed sounds like a bad thing right?  But if you think about it like at a bank, you can't get to what's in a vault unless it's unsealed.

And in dev mode, `vault server` gives the user the tools needed to authenticate. We'll be using these soon when we log in.

```
The unseal key and root token are reproduced below in case you
want to seal/unseal the Vault or play with authentication.

Unseal Key: fae3029289da491db20775127cc8590f757ccb666e0d5ceb035ada5e29fe041c
Root Token: 327ce53c-3f02-c3e5-8fc4-82f24c87f655
```

**NOTE**: When you run the `vault server -dev` command, we recommend running it in the foreground using either a `tmux` session or a separate ssh tab. Also, we do need to capture the output of the `Root Token`.

#### Setup vault-init

In order to setup the **vault-init** we need to target the server and authenticate. We use `safe` as our CLI to do both commands.

The local `vault server` runs on `127.0.0.1` and on port `8200`.t:

```
$ safe target init http://127.0.0.1:8200
Now targeting init at http://127.0.0.1:8200

$ safe targets

(*) init        http://127.0.0.1:8200

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

All set!  Now we can now build our deploy for the **proto-BOSH**.

### proto-BOSH

![proto-BOSH][bastion_2]

#### Generate BOSH Deploy

When using [the Genesis framework][genesis] to manage our deploys across environments, a folder to manage each of the software we'll deploy needs to be created.

First setup a `ops` folder in your user's home directory.

```
$ mkdir -p ~/ops
$ cd ~/ops
```

Genesis has a template for BOSH deployments (including support for the **proto-BOSH**), so let's use that by passing `bosh` into the `--template` flag.

```
$ genesis new deployment --template bosh
$ cd bosh-deployments
```

Next, we'll create a site and an environment from which to deploy our **proto-BOSH**. The BOSH template comes with some site templates to help you get started quickly, including:

- `aws` for Amazon Web Services VPC deployments
- `google` for Google Cloud Platform deployments
- `openstack` for OpenStack tenant deployments
- `vsphere` for VMWare ESXi virtualization clusters

When generating a new site we'll use this command format:

```
genesis new site --template <name> <site_name>
```

The template `<name>` will be `google` because that's our IaaS we're working with and we recommend the `<site_name>` default to the Google Region, ex. `europe-west1`.

```
$ genesis new site --template google europe-west1
Created site europe-west1 (from template google):
~/ops//bosh-deployments/europe-west1
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
    │   ├── sha1
    │   ├── url
    │   └── version
    └── update.yml

2 directories, 13 files
```

Finally, let's create our new environment, and name it `proto` (that's `europe-west1/proto`, formally speaking).

```
$ genesis new env --type bosh-init europe-west1 proto
Running env setup hook: ~/ops/bosh-deployments/.env_hooks/setup

(*) init        http://127.0.0.1:8200

Use this Vault for storing deployment credentials?  [yes or no] yes
Setting up credentials in vault, under secret/europe-west1/proto/bosh
.
└── secret/europe-west1/proto/bosh
    ├── blobstore/
    │   ├── agent
    │   └── director
    ├── db
    ├── nats
    ├── registry
    ├── users/
    │   ├── admin
    │   └── hm
    └── vcap


Created environment europe-west1/:
~/ops/bosh-deployments/europe-west1/proto
├── credentials.yml
├── Makefile
├── name.yml
├── networking.yml
├── properties.yml
└── README

0 directories, 6 files
```

**NOTE** Don't forget that `--type bosh-init` flag is very important. Otherwise, you'll run into problems with your deployment.

The template helpfully generated all new credentials for us and stored them in our **vault-init**, under the `secret/europe-west1/proto/bosh` subtree. Later, we'll migrate this subtree over to our real Vault, once it is up and spinning.

#### Make Manifest

Let's head into the `proto` environment directory and see if we can create a manifest, or (a more likely case) we still have to provide some critical information:

```
$ cd europe-west1/proto/
$ make manifest
...
5 error(s) detected:
 - $.meta.google.private_key: What private key will be used for establishing the ssh_tunnel (bosh-init only)?
 - $.meta.google.project: Please supply your Google Project
 - $.meta.google.ssh_user: What username will be used for establishing the ssh_tunnel (bosh-init only)?
 - $.meta.google.zones.z1: What Zone will BOSH be in?
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Drat. Let's focus on the `$.meta.google` subtree, since that's where most parameters are defined in Genesis templates:

```
 - $.meta.google.private_key: What private key will be used for establishing the ssh_tunnel (bosh-init only)?
 - $.meta.google.project: Please supply your Google Project
 - $.meta.google.ssh_user: What username will be used for establishing the ssh_tunnel (bosh-init only)?
 - $.meta.google.zones.z1: What Zone will BOSH be in?
```

This is easy enough to supply. We'll put these properties in `properties.yml`:

```
$ cat properties.yml
---
meta:
  google:
    project: <YOUR GOOGLE PROJECT>
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
```

I use the `(( concat ... ))` operator to [DRY][DRY] up the configuration.  This way, if we need to move the BOSH Director to a different region (for whatever reason) we just change `meta.google.region` and the availability zone just tacks on "b".

Now, let's leverage our Vault to create the SSH keypair for bosh-init. `safe` has a handy builtin for doing this:

```
$ safe ssh secret/google/ssh -- set secret/google/ssh username=bosh
$ safe get secret/google/ssh
--- # secret/google/ssh
fingerprint: ff:1c:52:b2:a4:25:6a:02:a2:3f:1d:50:99:48:35:40
private: |
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----
public: |
  ssh-rsa AAAA...mjp
username: bosh
```

Copy the contents of the `private` key to a local file (ie `/tmp/bosh.pem`) and set the proper permissions to that file (`chmod 0600 /tmp/bosh.pem`).

Go to your Google Cloud project's web console and add the new Metadata SSH key by pasting the contents of `public` key and appending `bosh` at the end of the key.

Now we can put references to our Vaultified keypair in `credentials.yml`:

```
$ cat credentials.yml
---
meta:
  google:
    ssh_user: (( vault "secret/google/ssh:username" ))
    private_key: /tmp/bosh.pem
```

Let's try that `make manifest` again.

```
$ make manifest
...
1 error(s) detected:
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Excellent. We should have only a single error and it's down to networking.

Refer back to your [Network Plan][netplan], and find the `global-infra-0`
subnetwork for the **proto-BOSH** in your Google Cloud project's web console. If you're using the plan in this repository, that would be `10.4.1.0/24`, and we're allocating `10.4.1.0/28` to our BOSH Director. Our `networking.yml` file, then, should look like this:

```
$ cat networking.yml
---
networks:
  - name: default
    subnets:
      - range: 10.4.1.0/24
        gateway: 10.4.1.1
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-global-infra-0 # <- your global-infra-0 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-global-internal # <- your global-internal firewall name
        reserved:
          - 10.4.1.16 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.2
```

Our range is that of the actual subnet we are in, `10.4.1.0/24` (in reality, the `/28` allocation is merely a tool of bookkeeping that simplifies firewall configuration).

We identify our Google-specific configuration under `cloud_properties`, by calling out what Google Network and Subnetwork we want the instance to be placed in, and what tags it should be subject to (used by firewall rules).

Under the `reserved` block, we reserve the IPs that are outside of
`10.4.1.0/28` (that is, `10.4.1.16` and above).

Finally, in `static` we reserve the first usable IP (`10.4.1.2`) as static.  This will be assigned to our `bosh/0` director VM.

Now, `make manifest` should succeed (no output is a good sign), and we should have a full manifest at `manifests/manifest.yml`:

```
$ make manifest
$ ls -l manifests
total 4
-rw-rw-r-- 1 ops staff 3565 Sep 11 10:37 manifest.yml
```

Now we are ready to deploy **proto-BOSH**.

```
$ make deploy
...
No existing genesis-created bosh-init statefile detected. Please help genesis find it.
Path to existing bosh-init statefile (leave blank for new deployments):
Deployment manifest: '~/ops/bosh-deployments/europe-west1/proto/manifests/.deploy.yml'
Deployment state: '~/ops/bosh-deployments/europe-west1/proto/manifests/.deploy-state.json'

Started validating
  Downloading release 'bosh'... Finished (00:00:15)
  Validating release 'bosh'... Finished (00:00:02)
  Downloading release 'bosh-google-cpi'... Finished (00:00:09)
  Validating release 'bosh-google-cpi'... Finished (00:00:02)
  Validating cpi release... Finished (00:00:00)
  Validating deployment manifest... Finished (00:00:00)
  Downloading stemcell... Finished (00:00:00)
  Validating stemcell... Finished (00:00:00)
Finished validating (00:00:30)
...
```

(At this point, `bosh-init` starts the tedious process of compiling all the things. End-to-end, this is going to take about a half an hour, so you probably want to go play [a game][slither] or grab a cup of tea.)

...

All done? Verify the deployment by trying to `bosh target` the newly-deployed Director. First you're going to need to get the password out of our **vault-init**.

```
$ safe get secret/europe-west1/proto/bosh/users/admin
--- # secret/europe-west1/proto/bosh/users/admin
password: super-secret
```

Then, run target the director:

```
$ bosh target https://10.4.1.2:25555 proto-bosh
Target set to `europe-west1-proto-bosh'
Your username: admin
Enter password:
Logged in as `admin'

$ bosh status
Config
             ~/.bosh_config

Director
  Name       europe-west1-proto-bosh
  URL        https://10.4.1.2:25555
  Version    1.3262.9.0 (00000000)
  User       admin
  UUID       c1513b02-5b5e-44e5-b525-6da1d1a8b60a
  CPI        google_cpi
  dns        disabled
  compiled_package_cache disabled
  snapshots  disabled

Deployment
  not set
```

All set!

Before you move onto the next step, you should commit your local deployment files to version control, and push them up _somewhere_. It's ok, thanks to Vault, Spruce and Genesis, there are no credentials or anything sensitive in the template files.

### Generate Vault Deploy

We're building the infrastructure environment's vault.

![Vault][bastion_3]

Now that we have a **proto-BOSH** Director, we can use it to deploy our real Vault. We'll start with the Genesis template for Vault:

```
$ cd ~/ops
$ genesis new deployment --template vault
$ cd vault-deployments
```

As before (and as will become almost second-nature soon), let's create our `europe-west1` site using the `google` template, and then create the `proto` environment inside of that site.

```
$ genesis new site --template google europe-west1
$ genesis new env europe-west1 proto
```

Answer yes twice and then enter a name for your Vault instance when prompted for a FQDN.

Run `make manifest`:

```
$ cd europe-west1/proto
$ make manifest
...
7 error(s) detected:
 - $.meta.google.zones.z1: Define the z1 Google zone
 - $.meta.google.zones.z2: Define the z2 Google zone
 - $.meta.google.zones.z3: Define the z3 Google zone
 - $.networks.vault_z1.subnets: Specify the z1 subnetwork for vault
 - $.networks.vault_z2.subnets: Specify the z2 subnetwork for vault
 - $.networks.vault_z3.subnets: Specify the z3 subnetwork for vault
 - $.properties.vault.ha.domain: What fully-qualified domain name do you want to access your Vault at?


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Vault is pretty self-contained, and doesn't have any secrets of its own. All you have to supply is your network configuration, and any IaaS settings.

Referring back to our [Network Plan][netplan] again, we find that Vault should be striped across three zone-isolated networks:

  - **10.4.1.16/28** in zone 1 (b)
  - **10.4.2.16/28** in zone 2 (c)
  - **10.4.3.16/28** in zone 3 (d)

First, lets do our Google-specific region/zone configuration, along with our Vault HA fully-qualified domain name:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
      z2: (( concat meta.google.region "-c" ))
      z3: (( concat meta.google.region "-d" ))
properties:
  vault:
    ha:
      domain: 10.4.1.16
```

Our `/28` ranges are actually in their corresponding `/24` ranges because the `/28`'s are (again) just for bookkeeping and firewall simplification.  That leaves us with this for our `networking.yml`:

```
$ cat networking.yml
---
networks:
  - name: vault_z1
    subnets:
      - range:    10.4.1.0/24
        gateway:  10.4.1.1
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-global-infra-0 # <- your global-infra-0 subnetwork name
          tags:
            - cf-global-internal # <- your global-internal firewall name
        reserved:
          - 10.4.1.2 - 10.4.1.15   # Allocated to other deployments
            # Vault (z1) is in 10.4.1.16/28
          - 10.4.1.32 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.16 - 10.4.1.18

  - name: vault_z2
    subnets:
      - range:    10.4.2.0/24
        gateway:  10.4.2.1
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-global-infra-1 # <- your global-infra-1 subnetwork name
          tags:
            - cf-global-internal # <- your global-internal firewall name
        reserved:
          - 10.4.2.2 - 10.4.2.15   # Allocated to other deployments
            # Vault (z2) is in 10.4.2.16/28
          - 10.4.2.32 - 10.4.2.254 # Allocated to other deployments
        static:
          - 10.4.2.16 - 10.4.2.18

  - name: vault_z3
    subnets:
      - range:    10.4.3.0/24
        gateway:  10.4.3.1
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-global-infra-2 # <- your global-infra-2 subnetwork name
          tags:
            - cf-global-internal # <- your global-internal firewall name
        reserved:
          - 10.4.3.2 - 10.4.3.15   # Allocated to other deployments
            # Vault (z3) is in 10.4.3.16/28
          - 10.4.3.32 - 10.4.3.254 # Allocated to other deployments
        static:
          - 10.4.3.16 - 10.4.3.18
```

That's a ton of configuration, but when you break it down it's not all that bad. We're defining three separate networks (one for each of the three zones). Each network has a unique Google Subnetwork, but they share the same Google Firewall, since we want uniform access control across the board.

The most difficult part of this configuration is getting the reserved ranges and static ranges correct, and self-consistent with the network range / gateway settings. This is a bit easier since our network plan allocates a different `/24` to each zone network, meaning that only the third octet has to change from zone to zone (x.x.1.x for zone 1, x.x.2.x for zone 2, etc.)

Now, let's try a `make manifest` again (no output is a good sign):

```
$ make manifest
```

And then let's give the deploy a whirl:

```
$ make deploy
...
Acting as user 'admin' on 'europe-west1-proto-bosh'
Checking whether release consul/21.0.0 already exists...NO
Using remote release `https://bosh.io/d/github.com/cloudfoundry-community/consul-boshrelease?v=21.0.0'

Director task 1

```

Thanks to Genesis, we don't even have to upload the BOSH releases (or stemcells) ourselves!

### Initializing Your Global Vault

Now that the Vault software is spinning, you're going to need to initialize the Vault, which generates a root token for interacting with the Vault, and a set of 5 _seal keys_ that will be used to unseal the Vault so that you can interact with it.

First off, we need to find the IP addresses of our Vault nodes:

```
$ bosh vms europe-west1-proto-vault
Acting as user 'admin' on deployment 'europe-west1-proto-vault' on 'europe-west1-proto-bosh'

+---------------------------------------------------+---------+-----+----------+-----------+
| VM                                                | State   | AZ  | VM Type  | IPs       |
+---------------------------------------------------+---------+-----+----------+-----------+
| vault_z1/0 (d6bada70-e04b-4b79-8da2-9922cb80a426) | running | n/a | small_z1 | 10.4.1.16 |
| vault_z2/0 (9036987d-688f-466b-b206-9070c28145b2) | running | n/a | small_z2 | 10.4.2.16 |
| vault_z3/0 (37481de3-60de-4feb-944f-e5b7b124fec3) | running | n/a | small_z3 | 10.4.3.16 |
+---------------------------------------------------+---------+-----+----------+-----------+

VMs total: 3
```

(Your UUIDs may vary, but the IPs should be close.)

Let's target the vault at 10.4.1.16:

```
$ export VAULT_ADDR=https://10.4.1.16:8200
$ export VAULT_SKIP_VERIFY=1
```

We have to set `$VAULT_SKIP_VERIFY` to a non-empty value because we used self-signed certificates when we deployed our Vault. The error message is as following if we did not do `export VAULT_SKIP_VERIFY=1`.

```
!! Get https://10.4.1.16:8200/v1/secret?list=1: x509: cannot validate certificate for 10.4.1.16 because it doesn't contain any IP SANs
```

Ideally, you'll be working with real certificates, and won't have to perform this step.

Let's initialize the Vault:

```
$ vault init
Unseal Key 1: 7ee8cda5d9b95a36bd69116cb86cf7146aa8ac3572e5ee9fc250e08bfc9e8ba001
Unseal Key 2: b8cc834aa229443b64fb7fe7959e2ad08fc487a2749b12ef6fe3cd6bf0d7610202
Unseal Key 3: 68b0f208e2016f6e78be26eee452822834342a024ca2686e357ef9dd70e24db603
Unseal Key 4: 00929b0235778c36e9f6040cbf1e4de5a1fc27501586506a7aad3915150b7eb704
Unseal Key 5: d0eeea40755fa763f5b35d05ced2e51d1a0c8af02dbf2aeb20300da3953e520305
Initial Root Token: 1611faf0-9f89-3b93-8ae6-3a8bd8fb9509

Vault initialized with 5 keys and a key threshold of 3. Please
securely distribute the above keys. When the Vault is re-sealed,
restarted, or stopped, you must provide at least 3 of these keys
to unseal it again.

Vault does not store the master key. Without at least 3 keys,
your Vault will remain permanently sealed.
```

**Store these seal keys and the root token somewhere secure!!** (A password manager like 1Password is an excellent option here.)

Unlike the dev-mode **vault-init** we spun up at the very outset, this Vault comes up sealed, and needs to be unsealed using three of the five keys above, so let's do that.

```
$ vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 1

$ vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 2

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

You should now have two `safe` targets, one for first Vault (named 'init') and another for the real Vault (named 'proto'):

```
$ safe targets

    init        http://127.0.0.1:8200
(*) proto       https://10.4.1.16:8200

```

Our `proto` Vault should be empty; we can verify that with `safe tree`:

```
$ safe target proto -- tree
Now targeting proto at https://10.4.1.16:8200
.
└── secret
    └── handshake

```

`safe` supports a handy import/export feature that can be used to move credentials securely between Vaults, without touching disk, which is exactly what we need to migrate from our dev-Vault to our real one:

```
$ safe target init -- export secret | \
  safe target proto -- import
Now targeting init at http://127.0.0.1:8200
Now targeting proto at https://10.4.1.16:8200
wrote secret/europe-west1/proto/bosh/nats
wrote secret/europe-west1/proto/bosh/registry
wrote secret/europe-west1/proto/bosh/users/admin
wrote secret/europe-west1/proto/bosh/users/hm
wrote secret/google/ssh
wrote secret/handshake
wrote secret/europe-west1/proto/bosh/blobstore/agent
wrote secret/europe-west1/proto/bosh/db
wrote secret/europe-west1/proto/bosh/vcap
wrote secret/europe-west1/proto/vault/tls
wrote secret/europe-west1/proto/bosh/blobstore/director

$ safe target proto -- tree
Now targeting proto at https://10.4.1.16:8200
.
└── secret
    ├── europe-west1/
    │   └── proto/
    │       ├── bosh/
    │       │   ├── blobstore/
    │       │   │   ├── agent
    │       │   │   └── director
    │       │   ├── db
    │       │   ├── nats
    │       │   ├── registry
    │       │   ├── users/
    │       │   │   ├── admin
    │       │   │   └── hm
    │       │   └── vcap
    │       └── vault/
    │           └── tls
    ├── google/
    │   └── ssh
    └── handshake
```

Voila!  We now have all of our credentials in our real Vault, and we can kill the **vault-init** server process!

```
$ sudo pkill vault
```

## Shield

![Shield][bastion_4]

SHIELD is our backup solution. We use it to configure and schedule regular backups of data systems that are important to our running operation, like the BOSH database, Concourse, and Cloud Foundry.

### Setting up Google Cloud Storage For Backup Archives

In order to use [Google Cloud Storage][gcs] with the AWS APIs we need to enable [interoperable access][interoperable] in our Google Cloud Storage dashboard and then generate interoperable storage access keys. Then we will store those access keys in the Vault:

```
$ safe set secret/google/gcs access_key secret_key
access_key [hidden]:
access_key [confirm]:

secret_key [hidden]:
secret_key [confirm]:
```

You're also going to want to provision a dedicated Google Cloud Storage bucket to store archives in, and name it something descriptive, like `codex-backups`. You'll specify also the location (`asia`, `eu`, `us`) and the storage class (`nearline` as we do not expect to access it frequently):

```
$ gsutil mb -c nearline -l eu gs://codex-backups
```

### Deploying SHIELD

We'll start out with the Genesis template for SHIELD:

```
$ cd ~/ops
$ genesis new deployment --template shield
$ cd shield-deployments
```

Now we can set up our `europe-west1` site using the `google` template, with a
`proto` environment inside of it:

```
$ genesis new site --template google europe-west1
$ genesis new env europe-west1 proto
$ cd europe-west1/proto
$ make manifest
...
3 error(s) detected:
 - $.meta.google.zones.z1: What Google zone is SHIELD deployed to?
 - $.networks.shield.subnets: Specify your shield subnet
 - $.properties.shield.daemon.ssh_private_key: Specify the SSH private key that the daemon will use to talk to the agents


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

By now, this should be old hat. According to the [Network Plan][netplan], the SHIELD deployment belongs in the **10.4.1.32/28** network, in zone 1 (b).  Let's put that information into `properties.yml`:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
```

As we found with Vault, the `/28` range is actually in it's outer `/24` range, since we're just using the `/28` subdivision for convenience.

```
$ cat networking.yml
---
networks:
  - name: shield
    subnets:
      - range:    10.4.1.0/24
        gateway:  10.4.1.1
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-global-infra-0 # <- your global-infra-0 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-global-internal # <- your global-internal firewall name
        reserved:
          - 10.4.1.2 - 10.4.1.31   # Allocated to other deployments
            # SHIELD is in 10.4.1.32/28
          - 10.4.1.48 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.32 - 10.4.1.34
```

Then we need to configure our `store` and a default `schedule` and `retention` policy:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))

properties:
  shield:
    skip_ssl_verify: true
    store:
      name: "default"
      plugin: "s3"
      config:
        s3_host: "https://storage.googleapis.com"
        signature_version: 2
        access_key_id: (( vault "secret/google/gcs:access_key" ))
        secret_access_key: (( vault "secret/google/gcs:secret_key" ))
        bucket: xxxxxx # <- backup's gcs bucket
        prefix: "/"
    schedule:
      name: "default"
      when: "daily 3am"
    retention:
      name: "default"
      expires: "86400" # 24 hours
```

Now let's leverage our Vault to create the SSH key pair for Shield. `safe` has a handy builtin for doing this:

```
$ safe ssh secret/europe-west1/proto/shield/keys/core
$ safe get secret/europe-west1/proto/shield/keys/core
--- # secret/europe-west1/proto/shield/keys/core
fingerprint: f0:04:b1:a4:41:ea:30:ac:21:0e:32:4a:58:61:43:79
private: |
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----
public: |
  ssh-rsa AAAA...7PN
```

Now we can put references to our Vaultified keypair in `credentials.yml`:

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
Acting as user 'admin' on 'europe-west1-proto-bosh'
Checking whether release shield/6.3.6 already exists...NO
Using remote release `https://bosh.io/d/github.com/starkandwayne/shield-boshrelease?v=6.3.6'
...
```

Once that's complete, you will be able to access your SHIELD deployment, and start configuring your backup jobs.

### How to use SHIELD

TODO: Add how to use SHIELD to backup and restore by using an example.

## bolo

![bolo][bastion_5]

Bolo is a monitoring system that collects metrics and state data from your BOSH deployments, aggregates it, and provides data visualization and notification primitives.

### Deploying Bolo Monitoring

You may opt to deploy Bolo once for all of your environments, in which case it belongs in your management network, or you may decide to deploy per-environment Bolo installations. What you choose mostly only affects your network topology / configuration.

To get started, you're going to need to create a Genesis deployments repo for your Bolo deployments:

```
$ cd ~/ops
$ genesis new deployment --template bolo
$ cd bolo-deployments
```

Now we can set up our `europe-west1` site using the `google` template, with a
`proto` environment inside of it:

```
$ genesis new site --template google europe-west1
$ genesis new env europe-west1 proto
$ cd europe-west1/proto
$ make manifest
2 error(s) detected:
 - $.meta.google.zones.z1: What Google zone is Bolo deployed to?
 - $.networks.bolo.subnets: Specify your bolo subnet


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

From the error message, we need to configure the following things for a Google deployment of bolo:

- Availability Zone (via `meta.google.zones.z1`)
- Networking configuration

According to the [Network Plan][netplan], the bolo deployment belongs in the **10.4.1.64/28** network, in zone 1 (b). Let's configure the zone in `properties.yml`:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
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
          network_name: cf # <- your network name
          subnetwork_name: cf-global-infra-0 # <- your global-infra-0 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-global-internal # <- your global-internal firewall name
            - cf-global-external # <- your global-external firewall name
     reserved:
       - 10.4.1.2 - 10.4.1.63  # Allocated to other deployments
        # Bolo is in 10.4.1.64/28
       - 10.4.1.80 - 10.4.1.254 # Allocated to other deployments
     static:
       - 10.4.1.65 - 10.4.1.68
```

You can validate your manifest by running `make manifest` and ensuring that you get no errors (no output is a good sign).

Then, you can deploy to your BOSH Director via `make deploy`.

Once you've deployed, you can validate the deployment via `bosh deployments`. You should see the bolo deployment. You can find the IP of bolo vm by running `bosh vms` for bolo deployment. In order to visit the Gnossis web interface on your `bolo/0` VM from your browser on your laptop, you need to setup port forwarding to enable it.

One way of doing it is using ngrok, go to [ngrok Downloads][ngrok-download] page and download the right version to your `bolo/0` VM, unzip it and run `./ngrok http 80`, it will output something like this:

```
ngrok by @inconshreveable                                                                                                                                                                 (Ctrl+C to quit)

Tunnel Status                 online
Version                       2.1.3
Region                        United States (us)
Web Interface                 http://127.0.0.1:4040
Forwarding                    http://362cae5d.ngrok.io -> localhost:80
Forwarding                    https://362cae5d.ngrok.io -> localhost:80

Connections                   ttl     opn     rt1     rt5     p50     p90
                              0       0       0.00    0.00    0.00    0.00
```

Copy the http or https link for forwarding and paste it into your browser, you will be able to visit the Gnossis web interface for bolo.

Out of the box, the Bolo installation will begin monitoring itself for general host health (the `linux` collector), so you should have graphs for bolo itself.

### Configuring Bolo Agents

Now that you have a Bolo installation, you're going to want to configure your other deployments to use it. To do that, you'll need to add the `bolo` release to the deployment (if it isn't already there), add the `dbolo` template to all the jobs you want monitored, and configure `dbolo` to submit metrics to your `bolo/0` VM in the bolo deployment.

**NOTE**: This may require configuration of firewalls, etc. If you experience issues with this step, you might want to start looking in those areas first.

We will use shield as an example to show you how to configure Bolo Agents.

To add the release:

```
$ cd ~/ops/shield-deployments
$ genesis add release bolo latest
$ cd europe-west1/proto
$ genesis use release bolo
```

If you do a `make refresh manifest` at this point, you should see a new release being added to the top-level `releases` list.

To configure dbolo, you're going to want to add a line like the last one here to all of your job template definitions:

```
jobs:
  - name: shield
    templates:
      - { release: bolo, name: dbolo }
```

Then, to configure `dbolo` to submit to your Bolo installation, add the `dbolo.submission.address` property either globally or per-job (strong recommendation for global, by the way).

If you have specific monitoring requirements, above and beyond the stock host-health checks that the `linux` collector provides, you can change per-job (or global) properties like the dbolo.collectors properties.

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

Remember that you will need to supply the `linux` collector configuration, since Bolo skips the automatic `dbolo` settings you get for free when you specify your own configuration.

### Further Reading on Bolo

More information can be found in the [Bolo BOSH Release README][bolo] which contains a wealth of information about available graphs, collectors, and deployment properties.

## Concourse

![Concourse][bastion_6]

From the `~/ops` folder let's generate a new `concourse` deployment, using the `--template` flag.

```
$ cd ~/ops
$ genesis new deployment --template concourse
$ cd concourse-deployments
```

Now we can set up our `europe-west1` site using the `google` template, with a
`proto` environment inside of it:

```
$ genesis new site --template google europe-west1
$ genesis new env europe-west1 proto
$ cd europe-west1/proto
$ make manifest
5 error(s) detected:
 - $.meta.external_url: What is the external URL for this concourse?
 - $.meta.google.zones.z1: What Google zone should your concourse VMs be in?
 - $.meta.shield_authorized_key: Specify the SSH public key from this environment's SHIELD daemon
 - $.meta.ssl_pem: Want ssl? define a pem
 - $.networks.concourse.subnets: Specify your concourse subnet


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

First, lets do our Google-specific region/zone configuration, along with some specific `concourse` properties:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
  external_url:  "https://ci.x.x.x.x.sslip.io" # Set as Public IP address of the bastion host to allow testing via SSH tunnel
  ssl_pem: ~
```

Be sure to replace the x.x.x.x in the external_url above with the Public IP address of the bastion host.

The `~` means we won't use SSL certs for now. If you have proper certs or want to use self signed you can add them to vault under the `web_ui:pem` key

According to the [Network Plan][netplan], the concourse deployment belongs in the **10.4.1.48/28** network. Since `10.4.1.48/28` is subdivision of the `10.4.1.0/24` subnet, we can configure networking as follows.

```
$ cat networking.yml
---
networks:
  - name: concourse
    subnets:
      - range: 10.4.1.0/24
        gateway: 10.4.1.1
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-global-infra-0 # <- your global-infra-0 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-global-internal # <- your global-internal firewall name
            - cf-global-external # <- your global-external firewall name
        reserved:
          - 10.4.1.2 - 10.4.1.47   # Allocated to other deployments
          - 10.4.1.65 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.48 - 10.4.1.56  # We use 48-64, reserving the first eight for static
```

Finally, if you recall, we already generated an SSH keypair for SHIELD. We stuck it in the Vault, at `secret/europe-west1/proto/shield/keys/core`, so let's get it back out for this deployment:

```
$ cat credentials.yml
---
meta:
  shield_authorized_key: (( vault "secret/europe-west1/proto/shield/keys/core:public" ))
```

Now we can deploy:

```
$ make manifest
$ make deploy
```

After it is deployed, you can do a quick test by hitting the HAProxy machine

```
$ bosh vms europe-west1-proto-concourse
Acting as user 'admin' on deployment 'europe-west1-proto-concourse' on 'europe-west1-proto-bosh'

+--------------------------------------------------+---------+-----+---------+-----------+
| VM                                               | State   | AZ  | VM Type | IPs       |
+--------------------------------------------------+---------+-----+---------+-----------+
| db/0 (57ba8fbf-7f1c-4b5b-8849-93e251b979a2)      | running | n/a | db      | 10.4.1.57 |
| haproxy/0 (1d6e0709-e96b-4456-8925-1557d79dcdc4) | running | n/a | haproxy | 10.4.1.51 |
| web/0 (d69faf1a-641d-4b06-a533-c60da39c3225)     | running | n/a | web     | 10.4.1.48 |
| worker/0 (2522313d-62ef-4351-a530-d6af529952d5)  | running | n/a | workers | 10.4.1.58 |
| worker/1 (31525465-a0d5-4ca4-a0c6-c42129981928)  | running | n/a | workers | 10.4.1.59 |
| worker/2 (f91ff13e-4b1e-49ac-8e30-44b820ef33bd)  | running | n/a | workers | 10.4.1.60 |
+--------------------------------------------------+---------+-----+---------+-----------+

VMs total: 6
```

Smoke test HAProxy IP address:

```
$ curl -i 10.4.1.51
HTTP/1.1 200 OK
Date: Sun, 11 Sep 2016 13:40:57 GMT
Content-Type: text/html; charset=utf-8
Transfer-Encoding: chunked

<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Concourse</title>
```

You can then run on a your local machine

```
$ gcloud compute ssh bastion -- -L 8080:10.4.1.51:80
```

and hit http://localhost:8080 to get the Concourse UI.

### Setup Pipelines Using Concourse

TODO: Need an example to show how to setup pipeline for deployments using Concourse.

## Building out Sites and Environments

Now that the underlying infrastructure has been deployed, we can start deploying our alpha/beta/other sites, with Cloud Foundry, and any required services. When using Concourse to update BOSH deployments, there are the concepts of `alpha` and `beta` sites. The alpha site is the initial place where all deployment changes are checked for sanity + deployability. Typically this is done with a `bosh-lite` VM. The `beta` sites are where site-level changes are vetted. Usually these are referred to as the sandbox or staging environments, and there will be one per site, by necessity. Once changes have passed both the alpha, and beta site, we know it is reasonable for them to be rolled out to other sites, like production.

### Alpha

#### BOSH-Lite

Since our `alpha` site will be a bosh lite running on Google, we will need to deploy that to our [global infrastructure network][netplan].

First, lets make sure we're targetting the right Vault:

```
$ safe target proto
Now targeting proto at https://10.4.1.16:8200
```

Now we can create our repo for deploying the `bosh-lite`:

```
$ cd ~/ops
$ genesis new deployment --template bosh-lite
$ cd bosh-lite-deployments
```

Now we can set up our `europe-west1` site using the `google` template, with a
`alpha` environment inside of it:

```
$ genesis new site --template google europe-west1
$ genesis new env europe-west1 alpha
$ cd europe-west1/alpha
$ make manifest
3 error(s) detected:
 - $.meta.google.zones.z1: What Zone will BOSH be in?
 - $.meta.port_forwarding_rules: Define any port forwarding rules you wish to enable on the bosh-lite, or an empty array
 - $.networks.default.subnets: Specify your bosh-lite subnet


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

First, lets do our Google-specific region/zone configuration:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
```

We will also need to add port-forwarding rules, so that things outside the bosh-lite can talk to its services. Since we know we will be deploying Cloud Foundry, let's add rules for it:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
  port_forwarding_rules:
  - internal_ip: 10.244.0.34
    internal_port: 80
    external_port: 80
  - internal_ip: 10.244.0.34
    internal_port: 443
    external_port: 443
```

According to the [Network Plan][netplan], the bosh-lite deployment belongs in the **10.4.1.80/28** network. Since `10.4.1.80/28` is subdivision of the `10.4.1.0/24` subnet, we can configure networking as follows.

```
$ cat networking.yml
---
networks:
  - name: default
    subnets:
      - range: 10.4.1.0/24
        gateway: 10.4.1.1
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-global-infra-0 # <- your global-infra-0 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-global-internal # <- your global-internal firewall name
            - cf-global-external # <- your global-external firewall name
        reserved:
          - 10.4.1.2 - 10.4.1.79   # Allocated to other deployments
          - 10.4.1.96 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.80
```

And finally, we can deploy:

```
$ make manifest
$ make deploy
```

Now we can verify the deployment and set up our `bosh` CLI target:

```
# grab the admin password for the bosh-lite
$ safe get secret/europe-west1/alpha/bosh-lite/users/admin
--- # secret/europe-west1/alpha/bosh-lite/users/admin
password: YOUR-PASSWORD-WILL-BE-HERE


$ bosh target https://10.4.1.80:25555 alpha
Target set to `europe-west1-alpha-bosh-lite'
Your username: admin
Enter password:
Logged in as `admin'

$ bosh status
Config
             ~/.bosh_config

Director
  Name       europe-west1-alpha-bosh-lite
  URL        https://10.4.1.80:25555
  Version    1.3262.9.0 (00000000)
  User       admin
  UUID       ff75146a-325a-49f9-bbd1-bedeb79d9dd2
  CPI        warden_cpi
  dns        disabled
  compiled_package_cache disabled
  snapshots  disabled

Deployment
  not set
```

Tadaaa! Time to commit all the changes to deployment repo, and push to where we're storing them long-term.

#### Alpha Cloud Foundry

To deploy `Cloud Foundry` to our `alpha` environment, let's generate a new `cf` deployment, using the `--template` flag.

```
$ cd ~/ops
$ genesis new deployment --template cf
$ cd cf-deployments
```

And generate our `bosh-lite` based `alpha` environment:

```
$ genesis new site --template bosh-lite bosh-lite
$ genesis new env bosh-lite alpha
$ cd bosh-lite/alpha
```

Unlike all the other deployments so far, we won't use `make manifest` to vet the manifest for CF. This is because the bosh-lite CF comes out of the box ready to deploy to a Vagrant-based bosh-lite with no tweaks. Since we are using it as the Cloud Foundry for our alpha environment, we will need to customize the Cloud Foundry base domain, with a domain resolving to the IP of our `alpha` bosh-lite VM:

```
$ cat properties.yml
---
meta:
  cf:
    base_domain: 10.4.1.80.xip.io
```

Now we can deploy:

```
$ make deploy
```

And once complete, run the smoke tests for good measure:

```
$ genesis bosh run errand smoke_tests
```

We now have our alpha-environment's Cloud Foundry stood up!

### First Beta Environment

Now that our `alpha` environment has been deployed, we can deploy our first beta environment to GCP. To do this, we will first deploy a BOSH Director for the environment using the `bosh-deployments` repo we generated back when we built our [proto-BOSH][proto-bosh], and then deploy Cloud Foundry on top of it.

#### BOSH

Let's target first our **proto-BOSH**:

```
$ bosh target proto-bosh
```

Now check the contents of the `bosh-deployments` repo:

```
$ cd ~/ops/bosh-deployments
$ ls
bin  europe-west1  global  LICENSE  README.md
```

We already have the `europe-west1` site created, so now we will just need to create our new environment, and deploy it. Different names (sandbox or staging) for Beta have been used for different customers, here we call it staging.

```
$ genesis new env europe-west1 staging
```

Notice, unlike the **proto-BOSH** setup, we do not specify `--type bosh-init`. This means we will use BOSH itself (in this case the **proto-BOSH**) to deploy our sandbox BOSH. Again, the environment hook created all of our credentials for us, but this time we targeted the long-term Vault, so there will be no need for migrating credentials around. Let's try to deploy now, and see what information still needs to be resolved:

```
$ cd europe-west1/staging
$ make deploy
...
5 error(s) detected:
 - $.meta.google.private_key: What private key will be used for establishing the ssh_tunnel (bosh-init only)?
 - $.meta.google.project: Please supply your Google Project
 - $.meta.google.ssh_user: What username will be used for establishing the ssh_tunnel (bosh-init only)?
 - $.meta.google.zones.z1: What Zone will BOSH be in?
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Looks like we need to provide the same type of data as we did for **proto-BOSH**. Lets fill in the basic properties:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
    project: <YOUR GOOGLE PROJECT>
    ssh_user: ~ # not needed, since not using bosh-lite
    private_key: ~ # not needed, since not using bosh-lite
```

This was a bit easier than it was for **proto-BOSH**. Verifying our changes worked, we see that we only need to provide networking configuration at this point:

```
$ make manifest
...
1 error(s) detected:
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

All that remains is filling in our networking details, so lets go consult our [Network Plan][netplan]. We will place the BOSH Director in the staging site's infrastructure network, in the first AZ we have defined (subnet name `staging-infra-0`, CIDR `10.4.32.0/24`). To do that, we'll need to update `networking.yml`:

```
$ cat networking.yml
---
networks:
  - name: default
    subnets:
      - range: 10.4.32.0/24
        gateway: 10.4.32.1
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-staging-infra-0 # <- your staging-infra-0 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-global-internal # <- your global-internal firewall name
            - cf-staging-internal # <- your staging-internal firewall name
        reserved:
            # BOSH is in 10.4.32.0/28
          - 10.4.32.16 - 10.4.32.254 # Allocated to other deployments
        static:
          - 10.4.32.2
```

Now that that's handled, let's deploy for real:

```
$ make manifest
$ make deploy
```

This will take a little less time than **proto-BOSH** did (some packages were already compiled), and the next time you deploy, it go by much quicker, as all the packages should have been compiled by now (unless upgrading BOSH or the stemcell).

Once the deployment finishes, target the new BOSH Director to verify it works:

```
# grab the admin password for the bosh-lite
$ safe get secret/europe-west1/staging/bosh/users/admin
--- # secret/europe-west1/staging/bosh/users/admin
password: 5hWkJeoWdTTFGhsKe3rzj7Man4suuM


$ bosh target https://10.4.32.2:25555 staging
Target set to 'europe-west1-staging-bosh'
Your username: admin
Enter password:
Logged in as 'admin'

$ bosh status
Config
             ~/.bosh_config

Director
  Name       europe-west1-staging-bosh
  URL        https://10.4.32.2:25555
  Version    1.3262.9.0 (00000000)
  User       admin
  UUID       6c6128b4-db6f-4119-9b51-6f2efbf4cac2
  CPI        google_cpi
  dns        disabled
  compiled_package_cache disabled
  snapshots  disabled

Deployment
  not set
```

Again, since our creds are already in the long-term vault, we can skip the credential migration that was done in the proto-bosh deployment and go straight to committing our new deployment to the repo, and pushing it upstream.

Now it's time to move on to deploying our `beta` (staging) Cloud Foundry!

#### Beta Cloud Foundry

To deploy Cloud Foundry, we will go back into our `ops` directory, making use of the `cf-deployments` repo created when we built our alpha site:

```
$ cd ~/ops/cf-deployments
```

Also, make sure that you're targeting the right Vault, for good measure:

```
$ safe target proto
Now targeting proto at https://10.4.1.16:8200
```

We will now create an `europe-west1` site and the `staging` environment:

```
$ genesis new site --template google europe-west1
$ genesis new env europe-west1 staging
```

As you might have guessed, the next step will be to see what parameters we need to fill in:

```
$ cd europe-west1/staging
$ make manifest
...
27 error(s) detected:
 - $.meta.cf.base_domain: Enter the Cloud Foundry base domain
 - $.meta.cf.blobstore_config.fog_connection.google_storage_access_key_id: What is the access key id for the blobstore GCS buckets?
 - $.meta.cf.blobstore_config.fog_connection.google_storage_secret_access_key: What is the secret key for the blobstore GCS buckets?
 - $.meta.google.zones.z1: Define the z1 Google zone
 - $.meta.google.zones.z2: Define the z2 Google zone
 - $.meta.google.zones.z3: Define the z3 Google zone
 - $.meta.target_pool: What target pool will be in front of the gorouters?
 - $.meta.target_pool_ssh: What target pool will be in front of the ssh-proxy (access_z*) nodes?
 - $.networks.cf1.subnets: Specify your cf1 subnet
 - $.networks.cf2.subnets: Specify your cf2 subnet
 - $.networks.cf3.subnets: Specify your cf3 subnet
 - $.networks.router1.subnets: Specify your router1 subnet
 - $.networks.router2.subnets: Specify your router1 subnet
 - $.networks.runner1.subnets: Specify your runner1 subnet
 - $.networks.runner2.subnets: Specify your runner2 subnet
 - $.networks.runner3.subnets: Specify your runner3 subnet
 - $.properties.cc.buildpacks.fog_connection.google_storage_access_key_id: What is the access key id for the blobstore GCS buckets?
 - $.properties.cc.buildpacks.fog_connection.google_storage_secret_access_key: What is the secret key for the blobstore GCS buckets?
 - $.properties.cc.droplets.fog_connection.google_storage_access_key_id: What is the access key id for the blobstore GCS buckets?
 - $.properties.cc.droplets.fog_connection.google_storage_secret_access_key: What is the secret key for the blobstore GCS buckets?
 - $.properties.cc.packages.fog_connection.google_storage_access_key_id: What is the access key id for the blobstore GCS buckets?
 - $.properties.cc.packages.fog_connection.google_storage_secret_access_key: What is the secret key for the blobstore GCS buckets?
 - $.properties.cc.resource_pool.fog_connection.google_storage_access_key_id: What is the access key id for the blobstore GCS buckets?
 - $.properties.cc.resource_pool.fog_connection.google_storage_secret_access_key: What is the secret key for the blobstore GCS buckets?
 - $.properties.cc.security_group_definitions.load_balancer.rules: Specify the rules for allowing access for CF apps to talk to the CF Load Balancer External IPs
 - $.properties.cc.security_group_definitions.services.rules: Specify the rules for allowing access to CF services subnets
 - $.properties.cc.security_group_definitions.user_bosh_deployments.rules: Specify the rules for additional BOSH user services that apps will need to talk to


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Oh boy. That's a lot. Cloud Foundry must be complicated. Looks like a lot of the fog_connection properties are all duplicates though, so let's fill out `properties.yml` alongside our Google-specific region/zone configuration:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
      z2: (( concat meta.google.region "-c" ))
      z3: (( concat meta.google.region "-d" ))
  skip_ssl_validation: true
  cf:
    blobstore_config:
      fog_connection:
        google_storage_access_key_id: (( vault "secret/google/gcs:access_key" ))
        google_storage_secret_access_key: (( vault "secret/google/gcs:secret_key"))
```

Now it's time to create the Load Balancer that will be in front of the `gorouters`. Let's go back to the `terraform/google` sub-directory of this repository and add to the `google.tfvars` file the following configurations:

```
google_lb_staging_enabled = "1"
```

As a quick pre-flight check, run `make manifest` to compile your Terraform plan. If everything worked out you, deploy the changes:

```
$ make deploy
```

Then make sure to add our Cloud Foundry Load Balancers to `networking.yml`:

```
$ cat networking.yml
---
meta:
  target_pool: cf-staging-cf # <- your staging-cf target pool
  target_pool_ssh: cf-staging-cf-ssh # <- your staging-cf-ssh target pool
  cf:
    base_domain: x.x.x.x.xip.io # <- your staging-cf target pool IP address
```

We will also need TLS termination for our `gorouters`, so we then need to create a SSL/TLS certificate for our domain.

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

Then create the certificates for your domain (it will be `x.x.x.x.xip.io` where `x.x.x.x` is the IP address of your target pool):

```
$ certstrap request-cert -common-name *.<your domain> -domain *.system.<your domain>,*.run.<your domain>,*.login.<your domain>,*.uaa.<your domain>

Enter passphrase (empty for no passphrase):

Enter same passphrase again:

Created out/*.<your domain>.key
Created out/*.<your domain>.csr
```

And last, sign the domain certificates with the CA certificate:

```
$ certstrap sign *.<your domain> --CA CertAuth
Created out/*.<your domain>.crt from out/*.<your domain>.csr signed by out/CertAuth.key
```

For safety, let's store the certificates in Vault:

```
$ cd out
$ safe write secret/europe-west1/staging/cf/tls/ca "csr@CertAuth.crl"
$ safe write secret/europe-west1/staging/cf/tls/ca "crt@CertAuth.crt"
$ safe write secret/europe-west1/staging/cf/tls/ca "key@CertAuth.key"
$ safe write secret/europe-west1/staging/cf/tls/domain "crt@*.<your domain>.crt"
$ safe write secret/europe-west1/staging/cf/tls/domain "csr@*.<your domain>.csr"
$ safe write secret/europe-west1/staging/cf/tls/domain "key@*.<your domain>.key"
```

Then we will add those certs to the `gourouter` properties:

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
      z2: (( concat meta.google.region "-c" ))
      z3: (( concat meta.google.region "-d" ))
  skip_ssl_validation: true
  cf:
    blobstore_config:
      fog_connection:
        google_storage_access_key_id: (( vault "secret/google/gcs:access_key" ))
        google_storage_secret_access_key: (( vault "secret/google/gcs:secret_key"))

properties:
  router:
    enable_ssl: true
    ssl_cert: (( vault meta.vault_prefix "/tls/domain:crt" ))
    ssl_key: (( vault meta.vault_prefix "/tls/domain:key" ))
    ssl_skip_validation: true
```

Now, we can consult our [Network Plan][netplan] for the subnetwork information, cross referencing with terraform output or the GCP console to get the subnetwork names:

```
$ cat networking.yml
---
meta:
  target_pool: cf-staging-cf # <- your staging-cf target_pool
  target_pool_ssh: cf-staging-cf-ssh # <- your staging-cf-ssh target_pool
  cf:
    base_domain: x.x.x.x.xip.io # <- your staging-cf target pool IP address

networks:
  - name: router1
    subnets:
      - range: 10.4.35.0/25
        gateway: 10.4.35.1
        static:
          - 10.4.35.2 - 10.4.35.100
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-staging-cf-edge-0 # <- your staging-cf-edge-0 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-staging-internal # <- your staging-internal firewall name
            - cf-staging-external # <- your staging-external firewall name
  - name: router2
    subnets:
      - range: 10.4.35.128/25
        gateway: 10.4.35.129
        static:
          - 10.4.35.130 - 10.4.35.227
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-staging-cf-edge-1 # <- your staging-cf-edge-1 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-staging-internal # <- your staging-internal firewall name
            - cf-staging-external # <- your staging-external firewall name
  - name: cf1
    subnets:
      - range: 10.4.36.0/24
        gateway: 10.4.36.1
        static:
          - 10.4.36.2 - 10.4.36.100
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-staging-cf-core-0 # <- your staging-cf-core-0 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-staging-internal # <- your staging-internal firewall name
  - name: cf2
    subnets:
      - range: 10.4.37.0/24
        gateway: 10.4.37.1
        static:
          - 10.4.37.2 - 10.4.37.100
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-staging-cf-core-1 # <- your staging-cf-core-1 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-staging-internal # <- your staging-internal firewall name
  - name: cf3
    subnets:
      - range: 10.4.38.0/24
        gateway: 10.4.38.1
        static:
          - 10.4.38.2 - 10.4.38.100
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-staging-cf-core-2 # <- your staging-cf-core-2 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-staging-internal # <- your staging-internal firewall name
  - name: runner1
    subnets:
      - range: 10.4.39.0/24
        gateway: 10.4.39.1
        static:
          - 10.4.39.2 - 10.4.39.100
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-staging-cf-runtime-0 # <- your staging-cf-runtime-0 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-staging-internal # <- your staging-internal firewall name
  - name: runner2
    subnets:
      - range: 10.4.40.0/24
        gateway: 10.4.40.1
        static:
          - 10.4.40.2 - 10.4.40.100
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-staging-cf-runtime-1 # <- your staging-cf-runtime-1 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-staging-internal # <- your staging-internal firewall name
  - name: runner3
    subnets:
      - range: 10.4.41.0/24
        gateway: 10.4.41.1
        static:
          - 10.4.41.2 - 10.4.41.100
        cloud_properties:
          network_name: cf # <- your network name
          subnetwork_name: cf-staging-cf-runtime-2 # <- your staging-cf-runtime-2 subnetwork name
          ephemeral_external_ip: true
          tags:
            - cf-staging-internal # <- your staging-internal firewall name
```

Let's see what's left now:

```
$ make manifest
3 error(s) detected:
 - $.properties.cc.security_group_definitions.load_balancer.rules: Specify the rules for allowing access for CF apps to talk to the CF Load Balancer External IPs
 - $.properties.cc.security_group_definitions.services.rules: Specify the rules for allowing access to CF services subnets
 - $.properties.cc.security_group_definitions.user_bosh_deployments.rules: Specify the rules for additional BOSH user services that apps will need to talk to
```

The only bits left are the Cloud Foundry security group definitions (applied to each running app, not the SGs applied to the CF VMs). We add three sets of rules for apps to have access to by default - `load_balancer`, `services`, and `user_bosh_deployments`. The `load_balancer` group should have a rule allowing access to the public IP(s) of the Cloud Foundry installation, so that apps are able to talk to other apps. The `services` group should have rules allowing access to the internal IPs of the services networks (according to our [Network Plan][netplan], `10.4.42.0/24`, `10.4.43.0/24`, `10.4.44.0/24`). The `user_bosh_deployments` is used for any non-CF-services that the apps may need to talk to. In our case, there aren't any, so this can be an empty list.

```
$ cat properties.yml
---
meta:
  google:
    region: europe-west1
    zones:
      z1: (( concat meta.google.region "-b" ))
      z2: (( concat meta.google.region "-c" ))
      z3: (( concat meta.google.region "-d" ))
  skip_ssl_validation: true
  cf:
    blobstore_config:
      fog_connection:
        google_storage_access_key_id: (( vault "secret/google/gcs:access_key" ))
        google_storage_secret_access_key: (( vault "secret/google/gcs:secret_key"))

properties:
  router:
    enable_ssl: true
    ssl_cert: (( vault meta.vault_prefix "/tls/domain:crt" ))
    ssl_key: (( vault meta.vault_prefix "/tls/domain:key" ))
    ssl_skip_validation: true
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

That should be it, finally. Let's deploy!

```
$ make manifest
$ make deploy
```

You may encounter the following error when you are deploying Beta CF.

```
Error 100: VM failed to create: googleapi: Error 403: Quota 'CPUS' exceeded. Limit: 72.0, quotaExceeded
```

Google Cloud has per-region limits for different types of resources. Check what resource type your failed job is using and request to increase limits for the resource your jobs are failing at. You can log into your [Google Cloud console][console], go to `Compute Engine`, on the left column click `Quotas`, and then click the blue button that says `Request Increase`. It takes less than 5 minutes get limits increase approved through Google.

If you want to scale your deployment in the current environment (here it is staging), you can modify `scaling.yml` in your `cf-deployments/europe-west1/staging` directory. In the following example, you scale cells in both zones to 2 and you change the resource pool `small_z1` to use the `n1-standard-2` machine type. Afterwards you can run `make manifest` and `make deploy`, please always remember to verify your changes in the manifest before you type `yes` to deploy making sure the changes are what you want.

```
jobs:

- name: cell_z1
  instances: 2

- name: cell_z2
  instances: 2

resource_pools:

- name: small_z1
  cloud_properties:
    machine_type: n1-standard-1
```

After a long while of compiling and deploying VMs, your CF should now be up, and accessible! You can check the sanity of the deployment via `genesis bosh run errand smoke_tests`. Target it using `cf login -a https://api.system.<your CF domain>`. The admin user's password can be retrieved from Vault. If you run into any trouble, make sure that your DNS is pointing properly to the correct ELB for this environment, and that the ELB has the correct SSL certificate for your site.

##### Push An App to Beta Cloud Foundry

After you successfully deploy the Beta CF, you can push an simple app to learn more about CF. In the CF world, every application and service is scoped to a space. A space is inside an org and provides users with access to a shared location for application development, deployment, and maintenance. An org is a development account that an individual or multiple collaborators can own and use. You can click [orgs, spaces, roles and permissions][orgs and spaces] to learn more  details.

The first step is logging into your Cloud Foundry environment, but first let's grab our admin password:

```
$ safe read secret/europe-west1/staging/cf/creds/users/admin
--- # secret/europe-west1/staging/cf/creds/users/admin
password: GHLK5dS2B4goszGPAlRvwkriu3rUwCpSo4B7J1gsRLwgBczMTvfPheJUYUMPIk95
```

Then we will target our environment and we will log in:

```
$ cf api api.system.<your domain> --skip-ssl-validation
Setting api endpoint to api.system.<your domain>...
OK


API endpoint:   https://api.system.<your domain> (API version: 2.59.0)
$ cf login
API endpoint: https://api.system.<your domain>

Email> admin

Password>
Authenticating...
OK

Targeted org system



API endpoint:   https://api.system.<your domain> (API version: 2.59.0)
User:           admin
Org:            system
Space:          No space targeted, use 'cf target -s SPACE'
```

The next step is creating and org and an space and targeting the org and space you created by running the following commands.

```
$ cf create-org sw-codex
$ cf target -o sw-codex
$ cf create-space test
$ cf target -s test
```

Once you are in the space, you can push an very simple app [cf-env][cf-env] to the CF. Clone the [cf-env][cf-env] repo on your bastion server, then go inside the `cf-env` directory, simply run `cf push` and it will start to upload, stage and run your app.

Your `cf push` command may fail like this:

```
Using manifest file ~/ops/cf-env/manifest.yml

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

[bastion_host]:      google.md#bastion-host
[bolo]:              https://github.com/cloudfoundry-community/bolo-boshrelease
[cf-env]:            https://github.com/cloudfoundry-community/cf-env
[console]:           https://console.cloud.google.com
[DebugUnknownError]: http://www.starkandwayne.com/blog/debug-unknown-error-when-you-push-your-app-to-cf/
[DRY]:               https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[gcloud]:            https://cloud.google.com/sdk/
[gcs]:               https://cloud.google.com/storage/
[genesis]:           https://github.com/starkandwayne/genesis
[google]:            https://cloud.google.com/
[iam-dashboard]:     https://console.cloud.google.com/iam-admin/iam/iam-zero
[interoperable]:     https://cloud.google.com/storage/docs/migrating
[jumpbox]:           https://github.com/starkandwayne/jumpbox
[netplan]:           network.md
[ngrok-download]:    https://ngrok.com/download
[orgs and spaces]:   https://docs.cloudfoundry.org/concepts/roles.html
[proto-bosh]:        google.md#proto-bosh
[regions-zones]:     https://cloud.google.com/compute/docs/regions-zones/regions-zones
[setup_credentials]: google.md#setup-credentials
[signup]:            https://cloud.google.com/compute/docs/signup
[slither]:           http://slither.io
[troubleshooting]:   troubleshooting.md
[use_terraform]:     google.md#use-terraform

[//]: # (Images, put in /images folder)

[levels_of_bosh]:        images/levels_of_bosh.png "Levels of Bosh"
[bastion_host_overview]: images/bastion_host_overview.png "Bastion Host Overview"
[global_network_diagram]: images/global_network_diagram.png "Global Network Diagram"
[bastion_1]:              images/bastion_step_1.png "vault-init"
[bastion_2]:              images/bastion_step_2.png "proto-BOSH"
[bastion_3]:              images/bastion_step_3.png "Vault"
[bastion_4]:              images/bastion_step_4.png "Shield"
[bastion_5]:              images/bastion_step_5.png "Bolo"
[bastion_6]:              images/bastion_step_6.png "Concourse"
