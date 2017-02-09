### Viewing Logs with Logemongo

First, log into a jumpbox that can access the private network of the environment where you want to view logs (e.g. the dev jumpbox for the dev environment). Then, grab `[logemongo](logemongo)` from Github:

```
sudo curl -o /usr/local/bin/logemongo \
  https://raw.githubusercontent.com/starkandwayne/logemongo/master/logemongo
sudo chmod 0755 /usr/local/bin/logemongo
```

Since our jumpboxes use Ubuntu, we'll need to grab a couple packages for the utility:

```
sudo apt-get install libio-socket-ssl-perl libconfig-yaml-perl
```

You can view the streaming logs from the appropriate Sawmill using the host flag and passing through the username and password. Since we're using self-signed certificates, we'll also need to disable SSL verification. e.g. to stream logs in dev:

```
$ logemongo -H 10.4.16.20 -u admin -p $(safe get secret/(( insert_parameter site.name ))/dev/sawmill/users/admin:password) --no-ssl
```

Depending on log volume, it may take a few moments for logs to begin to appear. If you wish to stream logs only from a certain source, or exclude logs only from a certain source, you can use `-i` and `-x` respectively with a regex pattern. You can also limit the number of lines of output with `-c`.
