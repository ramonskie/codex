Now it's time to create our Elastic Load Balancer that will be in front of the `gorouters`, but as we will need TLS termination we then need to create a SSL/TLS certificate for our domain.

Create first the CA Certificate:

```
$ mkdir -p /tmp/certs
$ cd /tmp/certs
$ certstrap init --common-name "CertAuth"
Enter passphrase (empty for no passphrase):

Enter same passphrase again:

Created out/CertAuth.key
Created out/CertAuth.crt
Created out/CertAuth.crl
```

Then create the certificates for your domain:

```
$ certstrap request-cert -common-name *.staging.<your domain> -domain *.system.staging.<your domain>,*.apps.staging.<your domain>,*.login.staging.<your domain>,*.uaa.staging.<your domain>

Enter passphrase (empty for no passphrase):

Enter same passphrase again:

Created out/*.staging.<your domain>.key
Created out/*.staging.<your domain>.csr
```

And last, sign the domain certificates with the CA certificate:

```
$ certstrap sign *.staging.<your domain> --CA CertAuth
Created out/*.staging.<your domain>.crt from out/*.staging.<your domain>.csr signed by out/CertAuth.key
```

For safety, let's store the certificates in Vault:

```
$ cd out
$ safe write secret/(( insert_parameter site.name ))/staging/cf/tls/ca "csr@CertAuth.crl"
$ safe write secret/(( insert_parameter site.name ))/staging/cf/tls/ca "crt@CertAuth.crt"
$ safe write secret/(( insert_parameter site.name ))/staging/cf/tls/ca "key@CertAuth.key"
$ safe write secret/(( insert_parameter site.name ))/staging/cf/tls/domain "crt@*.staging.<your domain>.crt"
$ safe write secret/(( insert_parameter site.name ))/staging/cf/tls/domain "csr@*.staging.<your domain>.csr"
$ safe write secret/(( insert_parameter site.name ))/staging/cf/tls/domain "key@*.staging.<your domain>.key"
```
