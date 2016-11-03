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

Inside the `global` deployment level goes the site level definition.  For this concourse setup we'll use an `(( insert_parameter template_name ))` template for an `(( insert_parameter site.name ))` site.

```
$ genesis new site --template (( insert_parameter template_name )) (( insert_parameter site.name ))
Created site (( insert_parameter site.name )) (from template (( insert_parameter template_name ))):
~/ops/concourse-deployments/(( insert_parameter site.name ))
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
$ genesis new env (( insert_parameter site.name )) proto
Running env setup hook: ~/ops/concourse-deployments/.env_hooks/00_confirm_vault

(*) proto   https://10.4.1.16:8200
    init    http://127.0.0.1:8200

Use this Vault for storing deployment credentials?  [yes or no] yes
Running env setup hook: ~/ops/concourse-deployments/.env_hooks/gen_creds
Generating credentials for Concource CI
Created environment (( insert_parameter template_name ))/proto:
~/ops/concourse-deployments/(( insert_parameter site.name ))/proto
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
