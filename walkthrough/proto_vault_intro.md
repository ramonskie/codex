### Generate Vault Deploy

We're building the infrastructure environment's vault.

![Vault][bastion_3]

Now that we have a **proto-BOSH** Director, we can use it to deploy
our real Vault.  We'll start with the Genesis template for Vault:

```
$ cd ~/ops
$ genesis new deployment --template vault
$ cd ~/ops/vault-deployments
```

**NOTE**: What is the "ops" environment? Short for operations, it's the
environment we're deploying the **proto-BOSH** and all the extra software that
monitors each of the child environments that will deployed later by the
**proto-BOSH** Director.

As before (and as will become almost second-nature soon), let's
create our `(( insert_parameter site.name ))` site using the `(( insert_parameter template_name ))` template, and then create
the `ops` environment inside of that site.

```
$ genesis new site --template (( insert_parameter template_name )) (( insert_parameter site.name ))
$ genesis new env (( insert_parameter site.name )) proto
```

Answer yes twice and then enter a name for your Vault instance when prompted for a FQDN.
