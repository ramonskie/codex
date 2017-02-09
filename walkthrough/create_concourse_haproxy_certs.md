First, let's create the  CA Certificate:

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

Next, create the certificates for your concourse haproxy domain:

```
$ certstrap request-cert -common-name *.<your concourse haproxy domain> -domain *.<your concourse haproxy domain>

Enter passphrase (empty for no passphrase):

Enter same passphrase again:

Created out/*.<your concourse haproxy domain>.key
Created out/*.<your concourse haproxy domain>.csr
```

Next, sign the domain certificates with the CA certificate:

```
$ certstrap sign *.<your concourse haproxy domain> --CA CertAuth
Created out/*.<your concourse haproxy domain>.crt from out/*.<your concourse haproxy domain>.csr signed by out/CertAuth.key
```
And last, generate `ConcoursePemFile.pem` by concatenating the certificate in `out/*.<your concourse haproxy domain>.crt`  on the end of the key in `out/*.<your concourse haproxy domain>.key` and store it in vault, where `your_concourse_haproxy_path`  is the path you defined in `ssl_pem` in the `properties.yml`.  

```
safe write your_concourse_haproxy_path "*.<your concourse haproxy domain>@"
```
