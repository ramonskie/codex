### Initializing Your Global Vault

Now that the Vault software is spinning, you're going to need to
initialize the Vault, which generates a root token for interacting
with the Vault, and a set of 5 _seal keys_ that will be used to
unseal the Vault so that you can interact with it.

First off, we need to find the IP addresses of our Vault nodes:

```
$ bosh vms (( insert_parameter site.name ))-proto-vault
+---------------------------------------------------+---------+-----+----------+-----------+
| VM                                                | State   | AZ  | VM Type  | IPs       |
+---------------------------------------------------+---------+-----+----------+-----------+
| vault_z1/0 (9fe19a85-e9ed-4bab-ac80-0d3034c5953c) | running | n/a | small_z1 | 10.4.1.16 |
| vault_z2/0 (13a46946-cd06-46e5-8672-89c40fd62e5f) | running | n/a | small_z2 | 10.4.2.16 |
| vault_z3/0 (3b234173-04d4-4bfb-b8bc-5966592549e9) | running | n/a | small_z3 | 10.4.3.16 |
+---------------------------------------------------+---------+-----+----------+-----------+
```

(Your UUIDs may vary, but the IPs should be close.)

Let's target the vault at 10.4.1.16:

```
$ export VAULT_ADDR=https://10.4.1.16:8200
$ export VAULT_SKIP_VERIFY=1
```

We have to set `$VAULT_SKIP_VERIFY` to a non-empty value because we
used self-signed certificates when we deployed our Vault. The error message is as following if we did not do `export VAULT_SKIP_VERIFY=1`.

```
!! Get https://10.4.1.16:8200/v1/secret?list=1: x509: cannot validate certificate for 10.4.1.16 because it doesn't contain any IP SANs
```

Ideally, you'll be working with real certificates, and won't have
to perform this step.

Let's initialize the Vault:

```
$ vault init
Unseal Key 1: c146f038e3e6017807d2643fa46d03dde98a2a2070d0fceaef8217c350e973bb01
Unseal Key 2: bae9c63fe2e137f41d1894d8f41a73fc768589ab1f210b1175967942e5e648bd02
Unseal Key 3: 9fd330a62f754d904014e0551ac9c4e4e520bac42297f7480c3d651ad8516da703
Unseal Key 4: 08e4416c82f935570d1ca8d1d289df93a6a1d77449289bac0fa9dc8d832c213904
Unseal Key 5: 2ddeb7f54f6d4f335010dc5c3c5a688b3504e41b749e67f57602c0d5be9b042305
Initial Root Token: e63da83f-c98a-064f-e4c0-cce3d2e77f97

Vault initialized with 5 keys and a key threshold of 3. Please
securely distribute the above keys. When the Vault is re-sealed,
restarted, or stopped, you must provide at least 3 of these keys
to unseal it again.

Vault does not store the master key. Without at least 3 keys,
your Vault will remain permanently sealed.
```

**Store these seal keys and the root token somewhere secure!!**
(A password manager like 1Password is an excellent option here.)

Unlike the dev-mode **vault-init** we spun up at the very outset,
this Vault comes up sealed, and needs to be unsealed using three
of the five keys above, so let's do that.

```
$ vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 1

$ vault unseal
...

$ vault unseal
Key (will be hidden):
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0
```

Now, let's switch back to using `safe`:

```
$ safe target https://10.4.1.16:8200 proto
Now targeting proto at https://10.4.1.16:8200

$ safe auth token
Authenticating against proto at https://10.4.1.16:8200
Token:

$ safe set secret/handshake knock=knock
knock: knock
```

### Migrating Credentials

You should now have two `safe` targets, one for first Vault
(named 'init') and another for the real Vault (named 'proto'):

```
$ safe targets

(*) proto     https://10.4.1.16:8200
    init      http://127.0.0.1:8200

```

Our `proto` Vault should be empty; we can verify that with `safe
tree`:

```
$ safe target proto -- tree
Now targeting proto at https://10.4.1.16:8200
.
└── secret
    └── handshake

```

`safe` supports a handy import/export feature that can be used to
move credentials securely between Vaults, without touching disk,
which is exactly what we need to migrate from our dev-Vault to
our real one:

```
$ safe target init -- export secret | \
  safe target proto -- import
Now targeting proto at https://10.4.1.16:8200
Now targeting init at http://127.0.0.1:8200
wrote secret/(( insert_parameter site.name ))/proto/bosh/blobstore/director
wrote secret/(( insert_parameter site.name ))/proto/bosh/db
wrote secret/(( insert_parameter site.name ))/proto/bosh/vcap
wrote secret/(( insert_parameter site.name ))/proto/vault/tls
wrote secret/(( insert_parameter site.name ))
wrote secret/(( insert_parameter site.name ))/proto/bosh/blobstore/agent
wrote secret/(( insert_parameter site.name ))/proto/bosh/registry
wrote secret/(( insert_parameter site.name ))/proto/bosh/users/admin
wrote secret/(( insert_parameter site.name ))/proto/bosh/users/hm
wrote secret/(( insert_parameter site.name ))/proto/shield/keys/core
wrote secret/handshake
wrote secret/(( insert_parameter site.name ))/proto/bosh/nats

$ safe target proto -- tree
Now targeting proto at https://10.4.1.16:8200
.
└── secret
    ├── handshake
    ├── (( insert_parameter site.name ))
    └── (( insert_parameter site.name ))/
        └── proto/
            ├── bosh/
            │   ├── blobstore/
            │   │   ├── agent
            │   │   └── director
            │   ├── db
            │   ├── nats
            │   ├── registry
            │   ├── users/
            │   │   ├── admin
            │   │   └── hm
            │   └── vcap
            ├── shield/
            │   └── keys/
            │       └── core
            └── vault/
                └── tls
```

Voila!  We now have all of our credentials in our real Vault, and
we can kill the **vault-init** server process!

```
$ sudo pkill vault
```
