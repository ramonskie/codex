## Logging with Sawmill

Sawmill is a BOSH release that aggregates logs to assist with troubleshooting Cloud Foundry and its services that support [nxlog][nxlog]. Although Sawmill logs can be viewed using `curl`, we recommend installing `logemongo` - a CLI tool for Sawmill. If you need to store your logs for later access, we recommend using a storage bucket (e.g. S3).

Since we only have Cloud Foundries in Alpha (BOSH Lite) and Dev, we'll only be deploying Sawmill to those two environments here.

### How to deploy

To create the deployment:

```
$ genesis new deployment --template sawmill
$ cd sawmill-deployments
```

For the Beta (Dev) Environment:


```
$ genesis new site --template openstack (( insert_parameter site.name ))
$ genesis new env (( insert_parameter site.name )) dev
$ cd (( insert_parameter site.name ))/dev
$ make manifest
```

As before, we'll need to supply the information requested in the errors:
