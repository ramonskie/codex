Now that that's handled, let's deploy for real:

```
$ make deploy
RSA 1024 bit CA certificates are loaded due to old openssl compatibility
Acting as user 'admin' on '(( insert_parameter template_name ))-proto-bosh-microboshen-(( insert_parameter template_name ))'
Checking whether release bosh/256.2 already exists...YES
Acting as user 'admin' on '(( insert_parameter template_name ))-proto-bosh-microboshen-(( insert_parameter template_name ))'
Checking whether release bosh-(( insert_parameter template_name ))-cpi/53 already exists...YES
Acting as user 'admin' on '(( insert_parameter template_name ))-proto-bosh-microboshen-(( insert_parameter template_name ))'
Checking whether release shield/6.2.1 already exists...YES
Acting as user 'admin' on '(( insert_parameter template_name ))-proto-bosh-microboshen-(( insert_parameter template_name ))'
Checking if stemcell already exists...
Yes
Acting as user 'admin' on deployment '(( insert_parameter site.name ))-staging-bosh' on '(( insert_parameter template_name ))-proto-bosh-microboshen-(( insert_parameter template_name ))'
Getting deployment properties from director...

Detecting deployment changes
----------------------------
resource_pools:
- cloud_properties:
    availability_zone: us-east-1b
    ephemeral_disk:
      size: 25000
      type: gp2
    instance_type: m3.xlarge
  env:
    bosh:
      password: "<redacted>"
  name: bosh
  network: default
  stemcell:
    name: (( insert_parameter stemcell.name ))
    sha1: 971e869bd825eb0a7bee36a02fe2f61e930aaf29
    url: https://bosh.io/d/stemcells/(( insert_parameter stemcell.name ))?v=3232.6
...
Deploying
---------
Are you sure you want to deploy? (type 'yes' to continue): yes

Director task 144
  Started preparing deployment > Preparing deployment. Done (00:00:00)

  Started preparing package compilation > Finding packages to compile. Done (00:00:00)
...
Task 144 done

Started		2016-07-08 17:23:47 UTC
Finished	2016-07-08 17:34:46 UTC
Duration	00:10:59

Deployed '(( insert_parameter site.name ))-staging-bosh' to '(( insert_parameter site.name ))-proto-bosh'
```

This will take a little less time than **proto-BOSH** did (some packages were already compiled), and the next time you deploy, it go by much quicker, as all the packages should have been compiled by now (unless upgrading BOSH or the stemcell).

Once the deployment finishes, target the new BOSH Director to verify it works:

```
$ safe get secret/(( insert_parameter site.name ))/staging/bosh/users/admin # grab the admin user's password for bosh
$ bosh target https://10.4.32.4:25555 (( insert_parameter site.name ))-staging
Target set to '(( insert_parameter site.name ))-staging-bosh'
Your username: admin
Enter password:
Logged in as 'admin'
```

Again, since our creds are already in the long-term vault, we can skip the credential migration that was done in the proto-bosh deployment and go straight to committing our new deployment to the repo, and pushing it upstream.

Now it's time to move on to deploying our `beta` (staging) Cloud Foundry!
