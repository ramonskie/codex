## Overview

Welcome to the Stark & Wayne guide to deploying Cloud Foundry on (( insert_parameter service.long_name )).
  This guide provides the steps to create authentication credentials,
generate the underlying cloud infrastructure, then use Terraform to prepare a bastion
host.

From this bastion, we setup a special BOSH Director we call the **proto-BOSH**
server where software like Vault, Concourse, Bolo and SHEILD are setup in order
to give each of the environments created after the **proto-BOSH** key benefits of:

* Secure Credential Storage
* Pipeline Management
* Monitoring Framework
* Backup and Restore Datastores

Once the **proto-BOSH** environment is setup, the child environments will have
the added benefit of being able to update their BOSH software as a release,
rather than having to re-initialize with `bosh-init`.

This also increases the resiliency of all BOSH Directors through monitoring and
backups with software created by Stark & Wayne's engineers.

And visibility into the progress and health of each application, release, or
package is available through the power of Concourse pipelines.

![Levels of Bosh][levels_of_bosh]

In the above diagram, BOSH (1) is the **proto-BOSH**, while BOSH (2) and BOSH (3)
are the per-site BOSH Directors.

Now it's time to setup the credentials.
