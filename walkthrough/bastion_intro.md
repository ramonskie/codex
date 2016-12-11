## Bastion Host

The bastion host is the server the BOSH operator connects to, in order to perform
commands that affect the **proto-BOSH** Director and the software that gets
deployed by it.

We'll be covering the configuration and deployment of each of these software
step-by-step as we go along. By the time you're done working on the bastion
server, you'll have installed each of the following in the numbered order:

![Bastion Host Overview][bastion_host_overview]

### Public IP Address

Before we can begin to install software, we need to connect to the server.  There
are a couple of ways to get the IP address.

* At the end of the Terraform `make deploy` output the bastion address is displayed.

```
box.bastion.public    = 52.43.51.197
box.nat.public        = 52.41.225.204
```
