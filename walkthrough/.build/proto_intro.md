## Proto Environment

![Global Network Diagram][global_network_diagram]

There are three layers to `genesis` templates.

* Global
* Site
* Environment

### Site Name

Sometimes the site level name can be a bit tricky because each IaaS divides things
differently.  With (( insert_parameter service.short_name )) we suggest a default of the (( insert_parameter site.description )) you're using, for
example: `(( insert_parameter site.name ))`.

### Environment Name

All of the software the **proto-BOSH** will deploy will be in the `proto` environment.
And by this point, you've setup your credentials and used Terraform to construct
the IaaS components and configure your bastion host.  We're ready now to setup a BOSH
Director on the bastion.

The first step is to create a **vault-init** process.
