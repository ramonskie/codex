That should be it, finally. Let's deploy!

```
$ make deploy
RSA 1024 bit CA certificates are loaded due to old openssl compatibility
Acting as user 'admin' on '(( insert_parameter site.name ))-staging-bosh'
Checking whether release cf/250 already exists...NO
Using remote release 'https://bosh.io/d/github.com/cloudfoundry/cf-release?v=250'

Director task 6
  Started downloading remote release > Downloading remote release
...
Deploying
---------
Are you sure you want to deploy? (type 'yes' to continue): yes
...

Started		2017-01-02 17:23:47 UTC
Finished	2017-01-02 17:34:46 UTC
Duration	00:10:59

Deployed '(( insert_parameter site.name ))-staging-cf' to '(( insert_parameter site.name ))-staging-bosh'

```

If you want to scale your deployment in the current environment (here it is staging), you can modify `scaling.yml` in your `cf-deployments/(( insert_parameter site.name ))/staging` directory. In the following example, you scale runners in both AZ to 2. Afterwards you can run `make manifest` and `make deploy`, but always remember to verify your changes in the manifest before you type `yes`.

```
jobs:

- name: runner_z1
  instances: 2

- name: runner_z2
  instances: 2

```
To make the manifest and deploy the changes run `make manifest deploy`. Always make sure to verify the detected changes match what you intended in the manifest before entering `yes` to kickoff the deploy.

After a long while of compiling and deploying VMs, your Cloud Foundry should now be up, and accessible! You can check the sanity by running the smoke tests with `genesis bosh run errand smoke_tests`. 

To target your Cloud Foundry to start making orgs, spaces, and pushing apps use:

```
cf login -a https://api.system.(( insert_parameter cf_beta.base_domain ))
```

The admin user's password can be retrieved from Vault with `safe get secret/dc01/dev/cf-cloudfoundry/creds/users/admin:password`. If you run into any trouble, make sure that your DNS is pointing properly to the correct Load Balancer for this environment and that the Load Balancer has the correct SSL certificate for your site.
