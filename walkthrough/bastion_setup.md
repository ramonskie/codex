### Add User

Once on the bastion host, you'll want to use the `jumpbox` script, which has
been installed automatically by the Terraform configuration. [This script installs][jumpbox]
some useful utilities like `jq`, `spruce`, `safe`, and `genesis` all of which
will be important when we start using the bastion host to do deployments.

**NOTE**: Try not to confuse the `jumpbox` script with the jumpbox _BOSH release_.
The _BOSH release_ can be used as part of a deployment.  And the script gets
run directly on the bastion host.

Once connected to the bastion, check if the `jumpbox` utility is installed.

```
$ jumpbox -v
jumpbox v49
```

In order to have the dependencies for the `bosh_cli` we need to create a user.
Also a convenience method at the end will prompt for git configuration that will
be useful when we are generating Genesis templates later.

Also, using named accounts provides auditing (via the `sudo` logs), and
isolation (people won't step on each others toes on the filesystem) and
customization (everyone gets to set their own prompt / shell / `$EDITOR`).

Let's add a user with `jumpbox useradd`:

```
$ jumpbox useradd
Full name: Joe User
Username:  juser
Enter the public key for this user's .ssh/authorized_keys file:
You should run `jumpbox user` now, as juser:
  su - juser  
  jumpbox user
```

### Setup User

After you've added the user, **be sure you follow up and setup the user** before
going any further.

Use the `su - juser` command to switch to the user.  And run `jumpbox user`
to install all dependent packages.

```
$ su - juser
$ jumpbox user
```

The following warning may show up when you run `jumpbox user`:
```
 * WARNING: You have '~/.profile' file, you might want to load it,
    to do that add the following line to '/home/XJ/.bash_profile':

      source ~/.profile
```

In this case, please follow the `WARNING` message, otherwise you may see the following message when you run `jumpbox` command even if you already installed everything when you run `jumpbox user`.

```
ruby not installed
rvm not installed
bosh not installed
```

### SSH Config

On your local computer, setup an entry in the `~/.ssh/config` file for your
bastion host.  Substituting the correct IP.

```
Host bastion
  Hostname 52.43.51.197
  User juser
```

### Test Login

After you've logged in as `ubuntu` once, created your user, logged out and
configured your SSH config, you'll be ready to try to connect via the `Host`
alias.

```
$ ssh bastion
```

If you can login and run `jumpbox` and everything returns green, everything's
ready to continue.

```
$ jumpbox

<snip>

>> Checking jumpbox installation
jumpbox installed - jumpbox v49
ruby installed - ruby 2.2.4p230 (2015-12-16 revision 53155) [x86_64-linux]
rvm installed - rvm 1.27.0 (latest) by Wayne E. Seguin <wayneeseguin@gmail.com>, Michal Papis <mpapis@gmail.com> [https://rvm.io/]
bosh installed - BOSH 1.3184.1.0
bosh-init installed - version 0.0.81-775439c-2015-12-09T00:36:03Z
jq installed - jq-1.5
spruce installed - spruce - Version 1.7.0
safe installed - safe v0.0.23
vault installed - Vault v0.6.0
genesis installed - genesis 1.5.2 (61864a21370c)

git user.name  is 'Joe User'
git user.email is 'juser@starkandwayne.com'
```
