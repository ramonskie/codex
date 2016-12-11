### Production Environment

Deploying the production environment will be much like deploying the `beta` environment above. You will need to deploy a BOSH Director, Cloud Foundry, and any services also deployed in the `beta` site. Hostnames, credentials, network information, and possibly scaling parameters will all be different, but the procedure for deploying them is the same.

### Next Steps

Lather, rinse, repeat for all additional environments (dev, prod, loadtest, whatever's applicable to the client).

[//]: # (Links, please keep in alphabetical order)

[amazon-region-doc]: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
[aws]:               https://signin.aws.amazon.com/console
[aws-subnets]:       http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html
[az]:                http://aws.amazon.com/about-aws/global-infrastructure/
[bastion_host]:      aws.md#bastion-host
[bolo]:              https://github.com/cloudfoundry-community/bolo-boshrelease
[cfconsul]:          https://docs.cloudfoundry.org/concepts/architecture/#bbs-consul
[cfetcd]:            https://docs.cloudfoundry.org/concepts/architecture/#etcd
[DRY]:               https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[genesis]:           https://github.com/starkandwayne/genesis
[jumpbox]:           https://github.com/starkandwayne/jumpbox
[netplan]:           https://github.com/starkandwayne/codex/blob/master/network.md
[ngrok-download]:    https://ngrok.com/download
[infra-ips]:         https://github.com/starkandwayne/codex/blob/master/part3/network.md#global-infrastructure-ip-allocation
[setup_credentials]: aws.md#setup-credentials
[spruce-129]:        https://github.com/geofffranks/spruce/issues/129
[slither]:           http://slither.io
[troubleshooting]:   troubleshooting.md
[use_terraform]:     aws.md#use-terraform
[verify_ssh]:        https://github.com/starkandwayne/codex/blob/master/troubleshooting.md#verify-keypair
[cf-env]:            https://github.com/cloudfoundry-community/cf-env
[orgs and spaces]:   https://docs.cloudfoundry.org/concepts/roles.html
[DebugUnknownError]: http://www.starkandwayne.com/blog/debug-unknown-error-when-you-push-your-app-to-cf/

[//]: # (Images, put in /images folder)

[levels_of_bosh]:         images/levels_of_bosh.png "Levels of Bosh"
[bastion_host_overview]:  images/bastion_host_overview.png "Bastion Host Overview"
[bastion_1]:              images/bastion_step_1.png "vault-init"
[bastion_2]:              images/bastion_step_2.png "proto-BOSH"
[bastion_3]:              images/bastion_step_3.png "Vault"
[bastion_4]:              images/bastion_step_4.png "Shield"
[bastion_5]:              images/bastion_step_5.png "Bolo"
[bastion_6]:              images/bastion_step_6.png "Concourse"
[global_network_diagram]: images/global_network_diagram.png "Global Network Diagram"
