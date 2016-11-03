And finally, we can deploy again:

```
$ make deploy
  checking https://genesis.starkandwayne.com for details on stemcell (( insert_parameter stemcell.name ))/(( insert_parameter stemcell.version ))
    checking https://genesis.starkandwayne.com for details on release bosh/256.2
  checking https://genesis.starkandwayne.com for details on release bosh-warden-cpi/29
    checking https://genesis.starkandwayne.com for details on release garden-linux/0.339.0
  checking https://genesis.starkandwayne.com for details on release port-forwarding/2
    checking https://genesis.starkandwayne.com for details on stemcell (( insert_parameter stemcell.name ))/(( insert_parameter stemcell.version ))
  checking https://genesis.starkandwayne.com for details on release bosh/256.2
    checking https://genesis.starkandwayne.com for details on release bosh-warden-cpi/29
  checking https://genesis.starkandwayne.com for details on release garden-linux/0.339.0
    checking https://genesis.starkandwayne.com for details on release port-forwarding/2
Acting as user 'admin' on '(( insert_parameter site.name ))-proto-bosh'
Checking whether release bosh/256.2 already exists...YES
Acting as user 'admin' on '(( insert_parameter site.name ))-proto-bosh'
Checking whether release bosh-warden-cpi/29 already exists...YES
Acting as user 'admin' on '(( insert_parameter site.name ))-proto-bosh'
Checking whether release garden-linux/0.339.0 already exists...YES
Acting as user 'admin' on '(( insert_parameter site.name ))-proto-bosh'
Checking whether release port-forwarding/2 already exists...YES
Acting as user 'admin' on '(( insert_parameter site.name ))-proto-bosh'
Checking if stemcell already exists...
Yes
Acting as user 'admin' on deployment '(( insert_parameter site.name ))-alpha-bosh-lite' on '(( insert_parameter site.name ))-proto-bosh'
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

Deployed `(( insert_parameter site.name ))-alpha-bosh-lite' to `(( insert_parameter site.name ))-proto-bosh'
```

Now we can verify the deployment and set up our `bosh` CLI target:

```
# grab the admin password for the bosh-lite
$ safe get secret/(( insert_parameter site.name ))/alpha/bosh-lite/users/admin
--- # secret/(( insert_parameter site.name ))/alpha/bosh-lite/users/admin
password: YOUR-PASSWORD-WILL-BE-HERE


$ bosh target https://10.4.1.80:25555 alpha
Target set to `(( insert_parameter site.name ))-alpha-bosh-lite'
Your username: admin
Enter password:
Logged in as `admin'
$ bosh status
Config
             ~/.bosh_config

 Director
   Name       (( insert_parameter site.name ))-alpha-bosh-lite
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
