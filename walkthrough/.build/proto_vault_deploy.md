Now, let's try a `make manifest` again (no output is a good sign):

```
$ make manifest
```

And then let's give the deploy a whirl:

```
$ make deploy
Acting as user 'admin' on '(( insert_parameter site.name ))-proto-bosh'
Checking whether release consul/20 already exists...NO
Using remote release `https://bosh.io/d/github.com/cloudfoundry-community/consul-boshrelease?v=20'

Director task 1

```

Thanks to Genesis, we don't even have to upload the BOSH releases
(or stemcells) ourselves!
