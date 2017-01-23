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

Started		2017-01-02 19:14:31 UTC
Finished	2017-01-02 19:17:42 UTC
Duration	00:03:11

Deployed `(( insert_parameter site.name ))-alpha-bosh-lite' to `(( insert_parameter site.name ))-proto-bosh'
```
