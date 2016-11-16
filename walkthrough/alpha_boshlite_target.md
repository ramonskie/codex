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
