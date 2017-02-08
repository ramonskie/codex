# The Network Plan

> This document is used throughout the rest of this documentation
> as a guideline for how networks are laid out, to provide the
> most flexibility in deployment, while mapping to common notions
> of fault zones.  You are strongly encouraged to make your own
> _Network Plan_, one for each site you build.  Doing so clarifies
> the intent of your deployments, and provides a single source of
> truth for things like BOSH `networks` stanzas, BOSH cloud
> config, firewalling and access control, and more.

## Supernet

All deployments in this site live under the `10.4.0.0/16` subnet:

```
-[ipv4 : 10.4.0.0/16] - 0

[CIDR]
Host address            - 10.4.0.0
Host address (decimal)  - 168034304
Host address (hex)      - A040000
Network address         - 10.4.0.0
Network mask            - 255.255.0.0
Network mask (bits)     - 16
Network mask (hex)      - FFFF0000
Broadcast address       - 10.4.255.255
Cisco wildcard          - 0.0.255.255
Addresses in network    - 65536
Network range           - 10.4.0.0 - 10.4.255.255
Usable range            - 10.4.0.1 - 10.4.255.254

-
```

That provides **65534** usable hosts across *255* `/24` subnets.

## Network Subdivision

> In general, we will use either `/24`, `/23` or `/22` subnet
> divisions of our supernet.  If the IaaS supports it, these should
> be real networks, with their own dedicated gateways and subnet
> masks.

To support the global infrastructure and several different
(isolated) environments (i.e. dev, staging, prod, etc.), we divide
the supernet up into 16 `/20` site networks.  Each of these can be
further sub-divided into even smaller, deployment-specific
networks (i.e. cf-edge-0, cf-edge-1, cf-0, cf-1, etc.).

| Site    | Subnet       | Subnet         | #    | Zone  | Name                 | Purpose                |
| ------- | ------------ | -------------- | ---- | ----- | -------------------- | ---------------------- |
| global  | 10.4.0.0/20  |                | 4096 |       |                      |                        |
|         |              | 10.4.0.0/24    |  254 |     1 | dmz                  | NAT / bastion / etc.   |
|         |              | 10.4.1.0/24    |  254 |     1 | global-infra-0       | Global Infrastructure  |
|         |              | 10.4.2.0/24    |  254 |     2 | global-infra-1       | Global Infrastructure  |
|         |              | 10.4.3.0/24    |  254 |     3 | global-infra-2       | Global Infrastructure  |
|         |              | 10.4.4.0/25    |  126 |     1 | global-openvpn-0     | Global OpenVPN         |
|         |              | 10.4.4.128/25  |  126 |     2 | global-openvpn-1     | Global OpenVPN         |
| dev     | 10.4.16.0/20 |                | 4096 |       |                      |                        |
|         |              | 10.4.16.0/24   |  254 |     1 | dev-infra-0          | Site Infrastructure    |
|         |              | 10.4.17.0/24   |  254 |     2 | dev-infra-1          | Site Infrastructure    |
|         |              | 10.4.18.0/24   |  254 |     3 | dev-infra-2          | Site Infrastructure    |
|         |              | 10.4.19.0/25   |  126 |     1 | dev-cf-edge-0        | Cloud Foundry Routers  |
|         |              | 10.4.19.128/25 |  126 |     2 | dev-cf-edge-1        | Cloud Foundry Routers  |
|         |              | 10.4.20.0/24   |  254 |     1 | dev-cf-core-0        | Cloud Foundry Core     |
|         |              | 10.4.21.0/24   |  254 |     2 | dev-cf-core-1        | Cloud Foundry Core     |
|         |              | 10.4.22.0/24   |  254 |     3 | dev-cf-core-2        | Cloud Foundry Core     |
|         |              | 10.4.23.0/24   |  254 |     1 | dev-cf-runtime-0     | Cloud Foundry Runtime  |
|         |              | 10.4.24.0/24   |  254 |     2 | dev-cf-runtime-1     | Cloud Foundry Runtime  |
|         |              | 10.4.25.0/24   |  254 |     3 | dev-cf-runtime-2     | Cloud Foundry Runtime  |
|         |              | 10.4.26.0/24   |  254 |     1 | dev-cf-svc-0         | Cloud Foundry Services |
|         |              | 10.4.27.0/24   |  254 |     2 | dev-cf-svc-1         | Cloud Foundry Services |
|         |              | 10.4.28.0/24   |  254 |     3 | dev-cf-svc-2         | Cloud Foundry Services |
|         |              | 10.4.29.0/28   |   14 |     1 | dev-cf-db-0          | Cloud Foundry Databases |
|         |              | 10.4.29.16/28  |   14 |     2 | dev-cf-db-1          | Cloud Foundry Databases |
|         |              | 10.4.29.32/28  |   14 |     3 | dev-cf-db-2          | Cloud Foundry Databases |
| staging | 10.4.32.0/20 |                | 4096 |       |                      |                        |
|         |              | 10.4.32.0/24   |  254 |     1 | staging-infra-0      | Site Infrastructure    |
|         |              | 10.4.33.0/24   |  254 |     2 | staging-infra-1      | Site Infrastructure    |
|         |              | 10.4.34.0/24   |  254 |     3 | staging-infra-2      | Site Infrastructure    |
|         |              | 10.4.35.0/25   |  126 |     1 | staging-cf-edge-0    | Cloud Foundry Routers  |
|         |              | 10.4.35.128/25 |  126 |     2 | staging-cf-edge-1    | Cloud Foundry Routers  |
|         |              | 10.4.36.0/24   |  254 |     1 | staging-cf-core-0    | Cloud Foundry Core     |
|         |              | 10.4.37.0/24   |  254 |     2 | staging-cf-core-1    | Cloud Foundry Core     |
|         |              | 10.4.38.0/24   |  254 |     3 | staging-cf-core-2    | Cloud Foundry Core     |
|         |              | 10.4.39.0/24   |  254 |     1 | staging-cf-runtime-0 | Cloud Foundry Runtime  |
|         |              | 10.4.40.0/24   |  254 |     2 | staging-cf-runtime-1 | Cloud Foundry Runtime  |
|         |              | 10.4.41.0/24   |  254 |     3 | staging-cf-runtime-2 | Cloud Foundry Runtime  |
|         |              | 10.4.42.0/24   |  254 |     1 | staging-cf-svc-0     | Cloud Foundry Services |
|         |              | 10.4.43.0/24   |  254 |     2 | staging-cf-svc-1     | Cloud Foundry Services |
|         |              | 10.4.44.0/24   |  254 |     3 | staging-cf-svc-2     | Cloud Foundry Services |
|         |              | 10.4.45.0/28   |   14 |     1 | staging-cf-db-0      | Cloud Foundry Databases |
|         |              | 10.4.45.16/28  |   14 |     2 | staging-cf-db-1      | Cloud Foundry Databases |
|         |              | 10.4.45.32/28  |   14 |     3 | staging-cf-db-2      | Cloud Foundry Databases |
| prod    | 10.4.48.0/20 |                | 4096 |       |                      |                        |
|         |              | 10.4.48.0/24   |  254 |     1 | prod-infra-0         | Site Infrastructure    |
|         |              | 10.4.49.0/24   |  254 |     2 | prod-infra-1         | Site Infrastructure    |
|         |              | 10.4.50.0/24   |  254 |     3 | prod-infra-2         | Site Infrastructure    |
|         |              | 10.4.51.0/25   |  126 |     1 | prod-cf-edge-0       | Cloud Foundry Routers  |
|         |              | 10.4.51.128/25 |  126 |     2 | prod-cf-edge-1       | Cloud Foundry Routers  |
|         |              | 10.4.52.0/24   |  254 |     1 | prod-cf-core-0       | Cloud Foundry Core     |
|         |              | 10.4.53.0/24   |  254 |     2 | prod-cf-core-1       | Cloud Foundry Core     |
|         |              | 10.4.54.0/24   |  254 |     3 | prod-cf-core-2       | Cloud Foundry Core     |
|         |              | 10.4.55.0/24   |  254 |     1 | prod-cf-runtime-0    | Cloud Foundry Runtime  |
|         |              | 10.4.56.0/24   |  254 |     2 | prod-cf-runtime-1    | Cloud Foundry Runtime  |
|         |              | 10.4.57.0/24   |  254 |     3 | prod-cf-runtime-2    | Cloud Foundry Runtime  |
|         |              | 10.4.58.0/24   |  254 |     1 | prod-cf-svc-0        | Cloud Foundry Services |
|         |              | 10.4.59.0/24   |  254 |     2 | prod-cf-svc-1        | Cloud Foundry Services |
|         |              | 10.4.60.0/24   |  254 |     3 | prod-cf-svc-2        | Cloud Foundry Services |
|         |              | 10.4.61.0/28   |   14 |     1 | prod-cf-db-0         | Cloud Foundry Databases |
|         |              | 10.4.61.16/28  |   14 |     2 | prod-cf-db-1         | Cloud Foundry Databases |
|         |              | 10.4.61.32/28  |   14 |     3 | prod-cf-db-2         | Cloud Foundry Databases |

## Global Infrastructure IP Allocation

The `global` "site" consists of three zone-isolated subnets.  Inside of those
subnets, we can further sub-divide (albeit purely for allocation's sake) for
the different infrastructural deployments.  Note that these sub-divisions
will not introduce new gateways, netmasks or broadcast addresses, rather
they merely serve to slice up the `/24` networks for fairly small
deployments.

| Deployment | "Subnet"     | #  | Zone | Purpose                         |
| ---------- | ------------ | --- | ---- | ------------------------------- |
| bosh       | 10.4.1.0/28  |  16 |    1 | proto-BOSH director             |
| vault      | 10.4.1.16/28 |  16 |    1 | Secure Vault                    |
| vault      | 10.4.2.16/28 |  16 |    2 | Secure Vault                    |
| vault      | 10.4.3.16/28 |  16 |    3 | Secure Vault                    |
| shield     | 10.4.1.32/28 |  16 |    1 | SHIELD Backup/Restore Core      |
| concourse  | 10.4.1.48/28 |  16 |    1 | Runway Concourse                |
| concourse  | 10.4.2.48/28 |  16 |    2 | Concourse overflow (if scaling exceeds the limits of the above subnet) |
| bolo       | 10.4.1.64/28 |  16 |    1 | Monitoring                      |
| alpha site | 10.4.1.80/28 |  16 |    1 | alpha site bosh-lite            |


Most infrastructural deployments are not highly available, nor even
HA-capable, so they do not need to be striped across the three zone-isolated
subnets.  Vault is the only HA deployment in the bunch, however, so it
_is_ deployed across three `/28` ranges, one per subnet.
