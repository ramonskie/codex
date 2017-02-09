For the **Alpha** (BOSH Lite) Environment:

Repeat the above process for both alpha (BOSH Lite) and dev. Since BOSH Lite is it's own site, and not in `(( insert_parameter site.name ))`, make sure to use the `bosh-lite` template for that deployment e.g. assuming you're in the `sawmill-deployments` directory:

```
$ genesis new site --template bosh-lite bosh-lite
$ genesis new env bosh-lite alpha
$ cd bosh-lite/alpha
$ make manifest
```

In this case both `credentials.yml` and `properties.yml` will match the Dev deployment, so we only need to add `networking.yml`:

```
---
networks:
  - name: sawmill_z1
    type: manual
    subnets:
    - range: 10.244.8.0/24
      gateway: 10.244.8.1
      dns: [8.8.8.8, 8.8.4.4]
      reserved:
        - 10.244.8.2 - 10.244.8.19
        - 10.244.8.30 - 10.244.8.254
      static:
        - 10.244.8.20
```

And create the `user:password` in Vault:

```
safe gen secret/bosh-lite/alpha/sawmill/users/admin password
```

Now you can make the manifest and deploy:

```
$ make manifest deploy
```
