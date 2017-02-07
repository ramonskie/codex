#### Alpha haproxy


Haproxy primarily provides SSL termination for Cloud Foundry. It is also configured to provide SSL termination for S3 since the current Openstack environment doesn't have an SSL endpoint for S3, which is needed for SHIELD. This will not be needed for environments that have SSL endpoints for S3, e.g. production.

Since haproxy has a cert and credentials that need to go in Vault, make sure you are targeting the desired Vault:

```
$ safe target proto
```
Once that is taken care of, you will create the new deployment with its site and environment:

```
$ genesis new deployment --template haproxy
$ cd haproxy-deployments
$ genesis new site --template bosh-lite bosh-lite
$ genesis new env bosh-lite alpha
$ cd bosh-lite/alpha
$ make manifest
Found stemcell bosh-warden-boshlite-ubuntu-trusty-go_agent 3312.15 on director
Found release haproxy latest on director
release toolbelt track is set to track from the index
  checking https://genesis.starkandwayne.com for details on latest release toolbelt
2 error(s) detected:
 - $.properties.ha_proxy.backend_servers: Specify your go routers IPs as backend servers
 - $.properties.ha_proxy.tcp.cf_app_ssh.backend_servers: Specify you  CF Access VMs IPs as your backend servers


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

As before, we'll resolve the errors by adding in the requested information, this time in the `properties.yml` file:

```
---
properties:
  ha_proxy:
    backend_servers: [ 10.244.0.22 ]       # Alpha Cloud Foundry router_z1 IP
    ssl_pem:
      - (( vault meta.vault_prefix "/certs/pems:*.(( insert_parameter cf_alpha.base_domain ))" ))

    tcp:
      - name: cf_app_ssh
        backend_servers: [ 10.244.0.109 ]  # Alpha Cloud Foundry access_z1 IP
```

You'll notice that we also added another field, `ssl_pem`. This stores the SSL cert that will be used by haproxy. In beta environments if you are using an `sslip.io` domain you will need to supply a floating IP to generate the cert, but since this is BOSH Lite we will simply supply the static IP assigned to the haproxy instance. To generate the cert, run the `haproxy_cert_gen` script in the `bin` directory:

