#### Beta Cloud Foundry

To deploy Cloud Foundry, we will go back into our `ops` directory, making use of
the `cf-deployments` repo created when we built our alpha site:

```
$ cd ~/ops/cf-deployments
```

Also, make sure that you're targeting the right Vault, for good measure:

```
$ safe target proto
```

We will now create an `(( insert_parameter site.name ))` site for CF:

```
$ genesis new site --template (( insert_parameter template_name )) (( insert_parameter site.name ))
Created site (( insert_parameter site.name )) (from template (( insert_parameter template_name ))):
~/ops/cf-deployments/(( insert_parameter site.name ))
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
$ genesis new env (( insert_parameter site.name )) staging
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
Created environment (( insert_parameter site.name ))/staging:
~/ops/cf-deployments/(( insert_parameter site.name ))/staging
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
