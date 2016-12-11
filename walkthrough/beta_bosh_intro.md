### First Beta Environment

Now that our `alpha` environment has been deployed, we can deploy our first beta environment to (( insert_parameter service.short_name )). To do this, we will first deploy a BOSH Director for the environment using the `bosh-deployments` repo we generated back when we built our [proto-BOSH](#proto-bosh), and then deploy Cloud Foundry on top of it.

#### BOSH
```
$ cd ~/ops/bosh-deployments
$ bosh target proto-bosh
$ ls
(( insert_parameter site.name ))  bin  global  LICENSE  README.md
```

We already have the `(( insert_parameter site.name ))` site created, so now we will just need to create our new environment, and deploy it. Different names (sandbox or staging) for Beta have been used for different customers, here we call it staging.


```
$ safe target proto
Now targeting proto at http://10.10.10.6:8200
$ genesis new env (( insert_parameter site.name )) staging
RSA 1024 bit CA certificates are loaded due to old openssl compatibility
Running env setup hook: ~/ops/bosh-deployments/.env_hooks/setup

 proto	http://10.10.10.6:8200

Use this Vault for storing deployment credentials?  [yes or no] yes
Setting up credentials in vault, under secret/(( insert_parameter site.name ))/staging/bosh
.
└── secret/(( insert_parameter site.name ))/staging/bosh
    ├── blobstore/
    │   ├── agent
    │   └── director
    ├── db
    ├── nats
    ├── users/
    │   ├── admin
    │   └── hm
    └── vcap


Created environment (( insert_parameter site.name ))/staging:
~/ops/bosh-deployments/(( insert_parameter site.name ))/staging
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
