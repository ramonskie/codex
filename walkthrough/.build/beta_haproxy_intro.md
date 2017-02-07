#### Beta haproxy
For the haproxy/(-ies) in beta environments you'll need to create a (( insert_parameter service.public_ip_type )) for each environment. For this deployment, we'll be using `(( insert_parameter cf_beta.public_ip ))` as the (( insert_parameter service.public_ip_type )).

Once you have the (( insert_parameter service.public_ip_type )), create the new environment:
```
$ cd ~/ops/haproxy-deployments
$ genesis new site --template openstack dc01
$ genesis new dc01 dev 
$ cd dc01/dev
$ make manifest
```
