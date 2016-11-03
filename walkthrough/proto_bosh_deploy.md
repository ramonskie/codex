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
Deployment manifest: '~/ops/bosh-deployments/(( insert_parameter site.name ))/proto/manifests/.deploy.yml'
Deployment state: '~/ops/bosh-deployments/(( insert_parameter site.name ))/proto/manifests/.deploy-state.json'

Started validating
  Downloading release 'bosh'... Finished (00:00:09)
  Validating release 'bosh'... Finished (00:00:03)
  Downloading release 'bosh-(( insert_parameter cpi_name ))-cpi'... Finished (00:00:02)
  Validating release 'bosh-(( insert_parameter cpi_name ))-cpi'... Finished (00:00:00)
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
$ safe get secret/(( insert_parameter site.name ))/proto/bosh/users/admin
--- # secret/(( insert_parameter site.name ))/proto/bosh/users/admin
password: super-secret
```

Then, run target the director:

```
$ bosh target https://10.4.1.4:25555 proto-bosh
Target set to `(( insert_parameter site.name ))-proto-bosh'
Your username: admin
Enter password:
Logged in as `admin'

$ bosh status
Config
             ~/.bosh_config

Director
  Name       (( insert_parameter site.name ))-proto-bosh
  URL        https://10.4.1.4:25555
  Version    1.3232.2.0 (00000000)
  User       admin
  UUID       a43bfe93-d916-4164-9f51-c411ee2110b2
  CPI        (( insert_parameter cpi_name ))_cpi
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
