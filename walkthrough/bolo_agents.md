### Configuring Bolo Agents

Now that you have a Bolo installation, you're going to want to
configure your other deployments to use it.  To do that, you'll
need to add the `bolo` release to the deployment (if it isn't
already there), add the `dbolo` template to all the jobs you want
monitored, and configure `dbolo` to submit metrics to your
`bolo/0` VM in the bolo deployment.

**NOTE**: This may require configuration of network ACLs, security groups, etc.
If you experience issues with this step, you might want to start looking in
those areas first.

We will use shield as an example to show you how to configure Bolo Agents.

To add the release:

```
$ cd ~/ops/shield-deployments
$ genesis add release bolo latest
$ cd ~/ops/shield-deployments/(( insert_parameter site.name ))/proto
$ genesis use release bolo
```

If you do a `make refresh manifest` at this point, you should see a new
release being added to the top-level `releases` list.

To configure dbolo, you're going to want to add a line like the
last one here to all of your job template definitions:

```
jobs:
  - name: shield
    templates:
      - { release: bolo, name: dbolo }
```

Then, to configure `dbolo` to submit to your Bolo installation,
add the `dbolo.submission.address` property either globally or
per-job (strong recommendation for global, by the way).

If you have specific monitoring requirements, above and beyond
the stock host-health checks that the `linux` collector provides,
you can change per-job (or global) properties like the dbolo.collectors properties.

You can put those configuration in the `properties.yml` as follows:

```
properties:
  dbolo:
    submission:
      address: x.x.x.x # your Bolo VM IP
    collectors:
      - { every: 20s, run: 'linux' }
      - { every: 20s, run: 'httpd' }
      - { every: 20s, run: 'process -n nginx -m nginx' }
```

Remember that you will need to supply the `linux` collector
configuration, since Bolo skips the automatic `dbolo` settings you
get for free when you specify your own configuration.

### Further Reading on Bolo

More information can be found in the [Bolo BOSH Release README][bolo]
which contains a wealth of information about available graphs,
collectors, and deployment properties.
