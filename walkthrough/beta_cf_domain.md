Lastly, let's make sure to add our Cloud Foundry domain to properties.yml:

```
---
meta:
  skip_ssl_validation: true
  cf:
    base_domain: staging.<your domain> # <- Your CF domain
    ...
```
