You can validate your manifest by running `make manifest` and
ensuring that you get no errors (no output is a good sign).

Then, you can deploy to your BOSH Director via `make deploy`.

Once you've deployed, you can validate the deployment via `bosh deployments`. You should see the bolo deployment. You can find the IP of bolo vm by running `bosh vms` for bolo deployment. In order to visit the Gnossis web interface on your `bolo/0` VM from your browser on your laptop, you need to setup port forwarding to enable it.

One way of doing it is using ngrok, go to [ngrok Downloads] [ngrok-download] page and download the right version to your `bolo/0` VM, unzip it and run `./ngrok http 80`, it will output something like this:

```
ngrok by @inconshreveable                                                                                                                                                                   (Ctrl+C to quit)

Tunnel Status                 online
Version                       2.1.3
Region                        United States (us)
Web Interface                 http://127.0.0.1:4040
Forwarding                    http://18ce4bd7.ngrok.io -> localhost:80
Forwarding                    https://18ce4bd7.ngrok.io -> localhost:80

Connections                   ttl     opn     rt1     rt5     p50     p90
                              0       0       0.00    0.00    0.00    0.00
```

Copy the http or https link for forwarding and paste it into your browser, you
will be able to visit the Gnossis web interface for bolo.

If you do not want to use ngrok, you can simply use your local built-in SSH client as follows:

```
ssh bastion -L 4040:<ip address of your bolo server>:80 -N
```

Then, go to http://127.0.0.1:4040 in your web browser.

Out of the box, the Bolo installation will begin monitoring itself
for general host health (the `linux` collector), so you should
have graphs for bolo itself.
