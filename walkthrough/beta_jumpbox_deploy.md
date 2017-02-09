`properties.yml`:

```
---
meta:
  availability_zone: (( insert_parameter site.name ))

properties:
  shield:
    agent:
      autoprovision: https://10.4.1.32    # IP Address for SHIELD VM
```

The `credentials.yml` file is where you'll add your users:

```
---
meta:
  default_ssh_key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDjqmzJtynAdxmcODCv0dtYmQrYk3lDeb03fjaQTRMtdEYbKnXk9ji8n3CHZj68JxUwxJRtQU70goP7a9X1PVQHJPIYmSWIdWbpeQdTjxymUh+kFjsu6ydlerLpnY3BjR5uWAxoQb+FRKuQDf9+gmkq95M65Lkef0scAXuVJPjLWhYnbZk6hJ4VlZIec6YKfw2x3+8fRM1sDDSWnazIfDQLudAmGnyeaVQsM5Qp7720imRQYPEl6QhwCgNFWhe42BwV5uXqQbBNVlRsoiu9hmGxjZIKB4f4E6uXfw1CPe0ZZh/34/W6CzN+kUwkWSgWet9+kS2Tf9vg0iqQDj/iFz3Cb/kKet0m7EcbYE51Y3fIC2EZAdlp5rQwDgyDoyz+x0IAPRgfMd9DXXjft/7phFdZp1SM4aBQ/bd5oYDpOTxhFZfHSGe4ZCh6tKX2ASzuP7Z4bhGlwZ50RQZqk5iYLsl+4g3Lt4XnjCz2oHgUHM5XVFiGMr7+PBqnQuWrDYJRcRAXwFZNh1dLRcj2ibYcemLWR31RfkYsEDTm6GbdjmV+XHkuvcqnkv7ZHx1MC2FhEELKLY2/LoU+8At8Fk2YU8JAfk9PROnCsQ8GjABZtEGBywHJxUXIMOFmj+9gJeHkbZsDQe6aas1z90HUKfK3u5AU5kC0e62RMjrtwb99eRK2+Q==

properties:
  jumpbox:
    users:
    - name: juser
      shell: /bin/bash
      setup_script: /var/vcap/packages/ruby-gems/bin/installer
      ssh_keys:
      - (( grab meta.default_ssh_key ))
```

Here we have the public key for `bosh` as the default SSH key. You could optionally add it to Vault like so:

```
$ safe set secret/(( insert_parameter site.name ))/dev/jumpbox/ssh/default pubkey@/full/path/to/bosh.pub
```

This creates the entry `secret/(( insert_parameter site.name ))/dev/jumpbox/ssh/default` with `pubkey` set to the contents of the file. You can view the secret with `safe get secret/(( insert_parameter site.name ))/dev/jumpbox/ssh/default:pubkey`.

You can then modify your `credentials.yml` as follows:

```
---
properties:
  jumpbox:
    users:
    - name: juser
      shell: /bin/bash
      setup_script: /var/vcap/packages/ruby-gems/bin/installer
      ssh_keys:
      - (( vault meta.vault_prefix "/ssh/default:pubkey" ))
```

Now that all of the errors are resolved, you can deploy with `make manifest deploy`. When you need to add additional users, simply update the `credentials.yml` file to mimic the above, whichever route you have chosen for storing / not storing the public key in Vault.

Note: although you need to also create an alpha (BOSH Lite) jumpbox for `genesis ci` / Concourse for the purposes of updating stemcells and releases, you only need the proto jumpbox and dev jumpboxes to access all of your environments. The proto jumpbox is intended to access the proto BOSH and BOSH Lite directors and the beta (dev) jumpbox is intended to access the dev BOSH director.
