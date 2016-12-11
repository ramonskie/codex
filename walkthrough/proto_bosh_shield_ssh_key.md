We haven't deployed a SHIELD yet, so it may seem a bit odd that
we're being asked for an SSH public key.  When we deploy our
**proto-BOSH** via `bosh-init`, we're going to spend a fair chunk of
time compiling packages on the bastion host before we can actually
create and update the director VM.  `bosh-init` will delete the
director VM before it starts this compilation phase, so we will be
unable to do _anything_ while `bosh-init` is hard at work.  The
whole process takes about 30 minutes, so we want to minimize the
number of times we have to re-deploy **proto-BOSH**.  By specifying
the SHIELD agent configuration up-front, we skip a re-deploy after
SHIELD itself is up.

Let's leverage our Vault to create the SSH key pair for BOSH.
`safe` has a handy builtin for doing this:

```
$ safe ssh secret/(( insert_parameter site.name ))/proto/shield/keys/core
$ safe get secret/(( insert_parameter site.name ))/proto/shield/keys/core
--- # secret/(( insert_parameter site.name ))/proto/shield/keys/core
fingerprint: 40:9b:11:82:67:41:23:a8:c2:87:98:5d:ec:65:1d:30
private: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEowIBAAKCAQEA+hXpB5lmNgzn4Oaus8nHmyUWUmQFmyF2pa1++2WBINTIraF9
  ... etc ...
  5lm7mGwOCUP8F1cdPmpPNCkoQ/dx3T5mnsCGsb3a7FVBDDBje1hs
  -----END RSA PRIVATE KEY-----
public: |
  ssh-rsa AAAAB3NzaC...4vbnncAYZPTl4KOr
```

(output snipped for brevity and security; but mostly brevity)

Now we can put references to our Vaultified keypair in
`credentials.yml`:

```
$ cat credentials.yml
---
meta:
  shield_public_key: (( vault "secret/(( insert_parameter site.name ))/proto/shield/keys/core:public" ))
```

You may want to take this opportunity to migrate
credentials-oriented keys from `properties.yml` into this file.
