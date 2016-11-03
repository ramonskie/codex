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

The template `<name>` will be `(( insert_parameter template_name ))` because that's our IaaS we're working with and
we recommend the `<site_name>` default to the (( insert_parameter site.description )), ex. `(( insert_parameter site.name ))`.

```
$ genesis new site --template (( insert_parameter template_name )) (( insert_parameter site.name ))
Created site (( insert_parameter site.name )) (from template (( insert_parameter template_name ))):
~/ops/bosh-deployments/(( insert_parameter template_name ))
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
(that's `(( insert_parameter site.name ))/proto`, formally speaking).

```
$ genesis new env --type bosh-init (( insert_parameter site.name )) proto
Running env setup hook: ~/ops/bosh-deployments/.env_hooks/setup

 init  http://127.0.0.1:8200

Use this Vault for storing deployment credentials?  [yes or no]
yes
Setting up credentials in vault, under secret/(( insert_parameter site.name ))/proto/bosh
.
└── secret/(( insert_parameter site.name ))/proto/bosh
    ├── blobstore/
    │   ├── agent
    │   └── director
    ├── db
    ├── nats
    ├── users/
    │   ├── admin
    │   └── hm
    └── vcap


Created environment (( insert_parameter site.name ))/:
~/ops/bosh-deployments/(( insert_parameter site.name ))/proto
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
our **vault-init**, under the `secret/(( insert_parameter site.name ))/proto/bosh` subtree.  Later, we'll
migrate this subtree over to our real Vault, once it is up and spinning.
