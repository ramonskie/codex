And also the `properties.yml`:

```
---
properties:
  ha_proxy:
    ssl_pem:
      - (( vault meta.vault_prefix "/certs/pems:(( insert_parameter cf_beta.base_domain ))" ))
    backend_servers: [ 10.4.19.4, 10.4.19.132 ]  # Dev Cloud Foundry router_z* IPs

    tcp:
      - name: cf_app_ssh
        backend_servers: [ 10.4.20.108 ]         # Dev Cloud Foundry access_z1 IP
```

As before, we'll need to generate the haproxy cert. In this case, we have a true (( insert_parameter service.public_ip_type )) so we will be using that IP to generate the cert:

```
$ ENV_PATH=secret/dc01/dev FIP=(( insert_parameter cf_beta.public_ip )) ./bin/haproxy_cert_gen
```

As a reminder if you are using a domain with its own CA, you will generate the cert with your own internal process and upload it to Vault using `safe write`. For example, if you had a cert for `example.com` for this environment and saved it as `haproxy.pem`, you would use:

```
$ safe write secret/dc01/dev/haproxy/certs/pems example.com@haproxy.pem
```

You would then reference the secret in the manifest with `(( vault meta.vault_prefix "/certs/pems:example.com" ))`.

After configuring all the templates, and generating the certificate, make the manifest and deploy with `make manifest deploy`.

There is one final step: since Cloud Foundry was already deployed so we could use it's CA, you'll need to edit `properties.yml` haproxy (( insert_parameter service.public_ip_type )) for the base domain and directory key prefix:

```
  cf:
    base_domain: (( insert_parameter cf_beta.base_domain ))
    directory_key_prefix: (( insert_parameter cf_beta.directory_key_prefix ))
```

Once this is done remake the manifest and deploy the Beta (dev) Cloud Foundry with `make manifest deploy`. You will also need to delete the original `run` and `system` domains by listing the domains with `cf domains` and then using `cf delete-shared-domain` and `cf delete-domain`. Alternatively, if the Cloud Foundry has yet to have any apps/etc. added to it you may want to delete the deployment with `bosh delete deployment dc01-dev-cf-cloudfoundry` and then deploy normally.
