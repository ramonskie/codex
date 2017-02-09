Next, we will deploy our jumpbox.

#### Beta Jumpbox

Unlike the proto jumpbox, which was initially deployed with Terraform, the beta (dev) jumpbox can be deployed via BOSH:

```
$ cd ~/ops/cf-deployments
$ genesis new deployment --template jumpbox
$ cd jumpbox-deployments
$ genesis new site --template openstack (( insert_parameter site.name ))
$ genesis new env (( insert_parameter site.name )) dev
$ cd (( insert_parameter site.name ))/dev
$ make manifest
```

Similar to our other deployments, we'll start by using the errors from `make manifest` to tell us what values need to be supplied:
