After it is deployed, you can do a quick test by hitting the HAProxy machine

```
$ bosh vms (( insert_parameter site.name ))-proto-concourse
Acting as user 'admin' on deployment '(( insert_parameter site.name ))-proto-concourse' on '(( insert_parameter site.name ))-proto-bosh'

Director task 43

Task 43 done

+--------------------------------------------------+---------+-----+---------+------------+
| VM                                               | State   | AZ  | VM Type | IPs        |
+--------------------------------------------------+---------+-----+---------+------------+
| db/0 (fdb7a556-e285-4cf0-8f35-e103b96eff46)      | running | n/a | db      | 10.4.1.61  |
| haproxy/0 (5318df47-b138-44d7-b3a9-8a2a12833919) | running | n/a | haproxy | 10.4.1.51  |
| web/0 (ecb71ebc-421d-4caa-86af-81985958578b)     | running | n/a | web     | 10.4.1.48  |
| worker/0 (c2c081e0-c1ef-4c28-8c7d-ff589d05a1aa)  | running | n/a | workers | 10.4.1.62  |
| worker/1 (12a4ae1f-02fc-4c3b-846b-ae232215c77c)  | running | n/a | workers | 10.4.1.57  |
| worker/2 (b323f3ba-ebe4-4576-ab89-1bce3bc97e65)  | running | n/a | workers | 10.4.1.58  |
+--------------------------------------------------+---------+-----+---------+------------+

VMs total: 6
```

Smoke test HAProxy IP address:

```
$ curl -i 10.4.1.51
HTTP/1.1 200 OK
Date: Thu, 07 Jul 2016 04:50:05 GMT
Content-Type: text/html; charset=utf-8
Transfer-Encoding: chunked

<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Concourse</title>
```

You can then run on a your local machine

```
$ ssh -L 8080:10.4.1.51:80 user@ci.x.x.x.x.sslip.io -i path_to_your_private_key
```

and hit http://localhost:8080 to get the Concourse UI. Be sure to replace `user`
with the `jumpbox` username on the bastion host and x.x.x.x with the IP address
of the bastion host.

### Setup Pipelines Using Concourse

TODO: Need an example to show how to setup pipeline for deployments using Concourse.
