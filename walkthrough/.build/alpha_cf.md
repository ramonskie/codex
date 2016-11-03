#### Alpha Cloud Foundry

To deploy CF to our alpha environment, we will need to first ensure we're targeting the right
Vault/BOSH:

```
$ cd ~/ops
$ safe target proto

(*) proto	https://10.4.1.16:8200

$ bosh target alpha
Target set to `(( insert_parameter site.name ))-alpha-bosh-lite'
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
Acting as user 'admin' on '(( insert_parameter site.name ))-try-anything-bosh-lite'
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

Deployed `bosh-lite-alpha-cf' to `(( insert_parameter site.name ))-try-anything-bosh-lite'
```

And once complete, run the smoke tests for good measure:

```
$ genesis bosh run errand smoke_tests
Acting as user 'admin' on deployment 'bosh-lite-alpha-cf' on '(( insert_parameter site.name ))-alpha-bosh-lite'

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
