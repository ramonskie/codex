### Alpha

#### BOSH-Lite

Since our `alpha` site will be a bosh lite running on (( insert_parameter service.short_name )), we will need to deploy that to our [global infrastructure network][netplan].

First, lets make sure we're in the right place, targeting the right Vault:

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
$ genesis new site --template (( insert_parameter template_name )) (( insert_parameter site.name ))
Created site (( insert_parameter site.name )) (from template (( insert_parameter template_name ))):
~/ops/bosh-lite-deployments/(( insert_parameter site.name ))
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

$ genesis new env (( insert_parameter site.name )) alpha
Running env setup hook: ~/ops/bosh-lite-deployments/.env_hooks/setup

(*) proto	https://10.4.1.16:8200

Use this Vault for storing deployment credentials?  [yes or no]yes
Setting up credentials in vault, under secret/(( insert_parameter site.name ))/alpha/bosh-lite
.
└── secret/(( insert_parameter site.name ))/alpha/bosh-lite
    ├── blobstore/


    │   ├── agent
    │   └── director
    ├── db
    ├── nats
    ├── users/
    │   ├── admin
    │   └── hm
    └── vcap




Created environment (( insert_parameter site.name ))/alpha:
~/ops/bosh-lite-deployments/(( insert_parameter site.name ))/alpha
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
