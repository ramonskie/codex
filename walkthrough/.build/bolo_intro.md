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

- `(( insert_parameter template_name ))` for Amazon Web Services VPC deployments
- `vsphere` for VMWare ESXi virtualization clusters
- `bosh-lite` for deploying and testing locally

```
$ genesis new site --template (( insert_parameter template_name )) (( insert_parameter site.name ))
Created site (( insert_parameter site.name )) (from template (( insert_parameter template_name ))):
~/ops/bolo-deployments/(( insert_parameter site.name ))
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
$ cd ~/ops/bolo-deployments/(( insert_parameter site.name ))
$ genesis new env (( insert_parameter site.name )) proto
Created environment (( insert_parameter site.name ))/proto:
~/ops/bolo-deployments/(( insert_parameter site.name ))/proto
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
