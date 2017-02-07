`credentials.yml`:

```
---
properties:
  sawmill:
    users:
      - name: admin
        pass: (( vault meta.vault_prefix "/users/admin:password" ))
```

`properties.yml`:

```
---
properties:
  sawmill:
    skip_ssl_verify: true
```

You will need to add the user to Vault and assign a password. The easiest way to do this is:

```
safe gen secret/(( insert_parameter site.name ))/dev/sawmill/users/admin password

```

You can view the sawmill credentials tree in Vault with `safe`:

```
safe tree secret/(( insert_parameter site.name ))/dev/sawmill
```

You can view the password with `safe get secret/(( insert_parameter site.name ))/dev/sawmill/users/admin:password`. Now you can make the manifest and deploy:

```
$ make manifest deploy
```
