### vault-init

![vault-init][bastion_1]

BOSH has secrets.  Lots of them.  Components like NATS and the database rely on
secure passwords for inter-component interaction.  Ideally, we'd have a spinning
Vault for storing our credentials, so that we don't have them on-disk or in a
git repository somewhere.

However, we are starting from almost nothing, so we don't have the luxury of
using a BOSH-deployed Vault.  What we can do, however, is spin a single-threaded
Vault server instance **on the bastion host**, and then migrate the credentials to
the real Vault later.

This we call a **vault-init**.  Because it precedes the **proto-BOSH** and Vault
deploy we'll be setting up later.

The `jumpbox` script that we ran as part of setting up the bastion host installs
the `vault` command-line utility, which includes not only the client for
interacting with Vault (`safe`), but also the Vault server daemon itself.

#### Start Server

Were going to start the server and do an overview of what the output means.  To
start the **vault-init**, run the `vault server` with the `-dev` flag.

```
$ vault server -dev
==> WARNING: Dev mode is enabled!

In this mode, Vault is completely in-memory and unsealed.
Vault is configured to only have a single unseal key. The root
token has already been authenticated with the CLI, so you can
immediately begin using the Vault CLI.
```

A vault being unsealed sounds like a bad thing right?  But if you think about it
like at a bank, you can't get to what's in a vault unless it's unsealed.

And in dev mode, `vault server` gives the user the tools needed to authenticate.
We'll be using these soon when we log in.

```
The unseal key and root token are reproduced below in case you
want to seal/unseal the Vault or play with authentication.

Unseal Key:
781d77046dcbcf77d1423623550d28f152d9b419e09df0c66b553e1239843d89
Root Token: c888c5cd-bedd-d0e6-ae68-5bd2debee3b7
```

**NOTE**: When you run the `vault server -dev` command, we recommend running it
in the foreground using either a `tmux` session or a separate ssh tab.  Also, we
do need to capture the output of the `Root Token`.

#### Setup vault-init

In order to setup the **vault-init** we need to target the server and authenticate.
We use `safe` as our CLI to do both commands.

The local `vault server` runs on `127.0.0.1` and on port `8200`.

```
$ safe target init http://127.0.0.1:8200
Now targeting init at http://127.0.0.1:8200

$ safe targets

  init  http://127.0.0.1:8200
```

Authenticate with the `Root Token` from the `vault server` output.

```
$ safe auth token
Authenticating against init at http://127.0.0.1:8200
Token: <paste your Root Token here>
```

#### Test vault-init

Here's a smoke test to see if you've setup the **vault-init** correctly.

```
$ safe set secret/handshake knock=knock
knock: knock

$ safe read secret/handshake
--- # secret/handshake
knock: knock
```

**NOTE**: If you receive `API 400 Bad Request` when attempting `safe set`, you may have incorrectly copied and entered your Root Key.  Try `safe auth token` again.

All set!  Now we can now build our deploy for the **proto-BOSH**.
