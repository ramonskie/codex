That should be it, finally. Let's deploy!

```
$ make deploy
RSA 1024 bit CA certificates are loaded due to old openssl compatibility
Acting as user 'admin' on '(( insert_parameter site.name ))-staging-bosh'
Checking whether release cf/237 already exists...NO
Using remote release 'https://bosh.io/d/github.com/cloudfoundry/cf-release?v=237'

Director task 6
  Started downloading remote release > Downloading remote release
...
Deploying
---------
Are you sure you want to deploy? (type 'yes' to continue): yes
...

Started		2016-07-08 17:23:47 UTC
Finished	2016-07-08 17:34:46 UTC
Duration	00:10:59

Deployed '(( insert_parameter site.name ))-staging-cf' to '(( insert_parameter site.name ))-staging-bosh'

```

If you want to scale your deployment in the current environment (here it is staging), you can modify `scaling.yml` in your `cf-deployments/(( insert_parameter site.name ))/staging` directory. In the following example, you scale runners in both AZ to 2. Afterwards you can run `make manifest` and `make deploy`, please always remember to verify your changes in the manifest before you type `yes` to deploy making sure the changes are what you want.

```
jobs:

- name: runner_z1
  instances: 2

- name: runner_z2
  instances: 2

```

After a long while of compiling and deploying VMs, your CF should now be up, and accessible! You can
check the sanity of the deployment via `genesis bosh run errand smoke_tests`. Target it using
`cf login -a https://api.system.<your CF domain>`. The admin user's password can be retrieved
from Vault. If you run into any trouble, make sure that your DNS is pointing properly to the
correct ELB for this environment, and that the ELB has the correct SSL certificate for your site.
