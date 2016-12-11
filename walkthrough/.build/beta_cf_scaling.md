Another thing we may want to do is scale the VM size to save some cost when we are deploying in non-production environment, for example, we can configure the `scaling.yml` as follows:

```
resource_pools:

- name: runner_z2
  cloud_properties:
    instance_type: t2.medium

- name: runner_z1
  cloud_properties:
    instance_type: t2.medium

- name: runner_z3
  cloud_properties:
    instance_type: t2.medium
```
