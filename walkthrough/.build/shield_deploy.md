Then we need to configure our `store` and a default `schedule` and `retention` policy:

```
$ cat properties.yml
---
...

properties:
  shield:
    skip_ssl_verify: true
    store:
      name: "default"
      plugin: "s3"
      config:
        access_key_id: (( vault "secret/(( insert_parameter site.name )):access_key" ))
        secret_access_key: (( vault "secret/(( insert_parameter site.name )):secret_key" ))
        bucket: xxxxxx # <- backup's s3 bucket
        prefix: "/"
    schedule:
      name: "default"
      when: "daily 3am"
    retention:
      name: "default"
      expires: "86400" # 24 hours
```

Finally, if you recall, we already generated an SSH keypair for
SHIELD, so that we could pre-deploy the public key to our
**proto-BOSH**.  We stuck it in the Vault, at
`secret/(( insert_parameter site.name ))/proto/shield/keys/core`, so let's get it back out for this
deployment:

```
$ cat credentials.yml
---
properties:
  shield:
    daemon:
      ssh_private_key: (( vault meta.vault_prefix "/keys/core:private"))
```

Now, our `make manifest` should succeed (and not complain)

```
$ make manifest
```

Time to deploy!

```
$ make deploy
Acting as user 'admin' on '(( insert_parameter site.name ))-proto-bosh'
Checking whether release shield/6.3.0 already exists...NO
Using remote release `https://bosh.io/d/github.com/starkandwayne/shield-boshrelease?v=6.3.0'

Director task 13
  Started downloading remote release > Downloading remote release

```

Once that's complete, you will be able to access your SHIELD
deployment, and start configuring your backup jobs.

### How to use SHIELD

TODO: Add how to use SHIELD to backup and restore by using an example.
