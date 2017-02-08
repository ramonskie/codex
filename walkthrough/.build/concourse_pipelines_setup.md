After the Concourse deployment is working, it is time to setup pipelines for deployments. Once a single pipeline is set up, other pipelines are set up using a similar workflow.

### Run Genesis CI Basics

Genesis CI requires us to have at least three deployed environments: alpha, beta and manual (/auto). Alpha is usually a bosh-lite environment. In this model, once the changes are applied to the alpha deployment and pass the tests, the changes will then be pushed further down the pipeline automatically to the beta deployment, which is usually in a sandbox/development environment. Once the tests pass the beta environment, we can choose whether changes either manually or automatically trigger your production deployment and tests. If manual, then human intervention is required to trigger the production deployment, by clicking the plus button in the Concourse UI. If automatic, the pipeline itself will deploy to production environment once beta deployment passes the tests.

In the deployments repo, run the following commands:

```
genesis ci alpha site/env
genesis ci beta  site/env
genesis ci manual(or auto) site/env
```
Then simply run `genesis ci check` to see if everything is setup correctly and use `genesis ci flow` to review that if the pipeline flows are correct.

For the pipelines, you may recall in the beginning of the document that the proto-BOSH
is responsible for deploying SHIELD, Vault, etc. as well as the other BOSHes. The
other BOSHes are used to test deployment upgrades for each environment until reaching
the final environment. In the current configuration upgrades are initially deployed
to BOSH Lite (`(( insert_parameter site.name ))-alpha-bosh-lite`) and then once they are passing are automatically
deployed to the staging (`(( insert_parameter site.name ))-staging-bosh`) environment:

![pipelines][pipelines]

Currently the pipelines are production-ready, meaning they only need the director
information if/when a production environment is added. Typically, we recommend
making production deployments manual to prevent unintended and unscheduled changes
to production.

For a manual deployment, simply click on `(( insert_parameter site.name ))-prod` and then the `+` in the upper
right corner:

![manual-deploy][manual_deploy]

By the necessity of its design, the BOSH pipeline differs from the other pipelines.
It will deploy to `(( insert_parameter site.name ))-alpha-bosh-lite` first and once that passes it will use `(( insert_parameter site.name ))-proto-openvdc`
to deploy `(( insert_parameter site.name ))-staging-bosh`:

![bosh-pipeline][bosh_pipeline]

Both `(( insert_parameter site.name ))-alpha-bosh-lite` and `(( insert_parameter site.name ))-proto-openvdc` will need to be manually
updated using either `make manifest deploy` or `make refresh manifest deploy` (`make refresh`
will update the deployment with site and/or global changes that have been added).


### Set Up Vault

#### Create read-only policies

To limit the Vault access given to the Concourse workers, read-only policies should be created for the pipelines. The number of policies created depends on the required level of isolation.  For lower security development environments, one policy for all the pipelines which can access all the credentials under `secret/*` can be configured.  For higher security production environments, one policy per pipeline can be set up so each pipeline only has access to its own deployment secrets. It is not good for the workers to authenticate with Vault using root, since the root has full access to all secrets in all backends.

In order to create a read-only policy, run `vault auth` to log into Vault as root. Run `vault policies` to show all the policies which are already defined. In this example, we will only create one `read-only` policy for all of the pipelines. Run `vault policy-write read-only acl.hcl` to create a read-only policy which has read-only rights to the `secret/*` path, where `acl.hcl` is configured as follows:

```
path "secret/*" {
  policy = "read"
}
```
To confirm, run `vault policies` to see the `read-only` policy we created. Save the token for this policy and you can `vault auth` to try it out later.

#### Set up AppID Authentication

NOTE: If the CLI to set up the app-id method does not work for you, please check if you are using the right Vault CLI version.

Let’s take a look what type of auth methods are enabled:
```
$ vault auth -methods
Path    Type   Default TTL  Max TTL  Description
token/  token  system       system   token based credentials
```

First, we need to enable the `app-id` auth method by running `vault auth-enable app-id`.

```
$ vault auth -methods
Path     Type    Default TTL  Max TTL  Description
app-id/  app-id  system       system
token/   token   system       system   token based credentials
```
Next we need to configure an `app-id` token and `user-id` token, by writing to the correct backend paths.

```
vault write auth/app-id/map/app-id/your_app_id \
              value=read-only\
              display_name="Deployments pipeline"

vault write auth/app-id/map/user-id/your_user_id \
        value=your_app_id \
        cidr_block= your_concourse_network_block
```
Keep in mind that `genesis` v1.6.0 has a default name for `app-id` and `user-id` for each deployment. Make sure you replace `your_app_id` and `your_user_id` using those default names accordingly.

In future, we will switch to AppRole from AppId when `genesis` is ready for AppRole. For more details, please visit:  https://www.vaultproject.io/docs/auth/app-id.html

### Use FLY to Configure Pipelines

The `fly` CLI is downloaded from the web UI page in your Concourse environment
its version that is in sync with the version of Concourse that is deployed.

Set the fly target as `concourse`. If we do not use `concourse` as target name, we will need to specify it in the `ci/settings.yml` file.

`fly -t concourse login -c concourse_url`

You will be prompted for the user and password. The user name is `concourse` and the password is saved in `secret/(( insert_parameter site.name ))/proto/concourse/web_ui` in vault.  If you do not specify a team name, the CLI will log you into the default `main` team.

In this case, we are using Basic Auth.  For details on how to set up oAuth for your team, see [Authentication Management for Teams](#authentication-management-for-teams)

To learn more about how to use the `fly` managing your pipelines, click [here][fly].

### Configure and Generate Pipelines

Run `genesis ci repipe`. You will see the following errors:

```
Testing Vault authentication by retrieving secret/handshake
Key                     Value
---                     -----
refresh_interval        2592000
knock                   knock

2 error(s) detected:
 - $.aliases.target: Please define aliases for your BOSH directors (uuid -> addr)
 - $.auth: Please define your BOSH directors in ci/boshes.yml (and remove this line)

6 error(s) detected:
 - $.meta.github.owner: Please specify the name of the user / organization that owns the Github repository (in ci/settings.yml)
 - $.meta.github.private_key: Please generate an SSH Deployment Key for this repo and specify it in ci/settings.yml
 - $.meta.github.repo: Please specify the name of the Github repository (in ci/settings.yml)
 - $.meta.name: Please name this deployment pipeline (in ci/settings.yml)
 - $.meta.slack.channel: Please specify the channel (#name) or user (@user) to send messages to (in ci/settings.yml)
 - $.meta.slack.webhook: Please provide a Slack Integration WebHook (in ci/settings.yml)
```
We can tackle all the errors by configuring two files: `ci/boshes.yml` and `ci/settings.yml`. Before that, lets add a deployment key to the repo and write it to Vault, since we need it to configure our pipeline.

To generate an SSH key pair, use the following commands to write it to Vault. In the git repo, add the public key to the deploy key.

```
safe write secret/(( insert_parameter site.name ))/proto/concourse/deployment_keys "private_key_name@private_key_file"
safe write secret/(( insert_parameter site.name ))/proto/concourse/deployment_keys "pub_key_name@pub_key_file"

```

Finally, configure the files we mentioned earlier:

```
boshes.yml

# The UUIDs and director URL's of all bosh directors in your pipeline go here.
# Since we are using proto-bosh to deploy bosh-lite, dev-bosh and prod-bosh, using bosh-lite to deploy a regular bosh for pipeline alpha environment purpose, when you setup pipeline for BOSH, you will need configure for all the BOSHes which are involved.

aliases:
  target:
    bosh_uuid: bosh_director_url
    bosh_uuid: bosh_director_url
    bosh_uuid: bosh_director_url

# if you are setting up pipeline for BOSH, you also need to configure BOSH deployment names and URLs
    bosh_deployment_name: bosh_director_url
    bosh_deployment_name: bosh_director_url
    bosh_deployment_name: bosh_director_url

auth:
  https://x.x.x.x:25555:
    username: admin
    password: (( vault "path to your bosh admin secret" ))
  https://x.x.x.x:25555:
    username: admin
    password: (( vault "path to your bosh admin secret" ))
  https://x.x.x.x:25555:
    username: admin
    password: (( vault "path to your bosh admin secret" ))

```

```
settings.yml

meta:
  name: your_pipeline_name
  env:
     VAULT_ADDR: YOUR_VAULT_ADDRESS
     VAULT_SKIP_VERIFY: 1

  github:
    owner: your_github_user_account
    repo: your_repo_name
    private_key: (( vault "your path to deploy key which you wrote to vault earlier" ))

  slack:
    webhook: (( vault "your path to webhook url" ))
    channel: '#your_channel name'

 # If you are setting up pipeline for BOSH, you need to configure pause_for_existing_bosh_tasks as true
  pause_for_existing_bosh_tasks: true

```
After `genesis ci repipe` succeeds, follow the instructions it prints out to unpause your pipeline.

Note: We should never modify `ci/pipeline.yml` directly. `genesis ci repipe` will take what are in `.ci.yml`,` ci/settings.yml` and ` ci/boshes.yml` to generate `ci/pipeline.yml`.

### Adding Smoke Tests to Pipeline

If the deployment you set up pipeline for has a smoke tests errand, you can add it to your existing pipeline pretty easily by following the instruction below:

* Run `genesis ci smoke-test your_smoke_tests_errand_name`
* Run `genesis ci repipe`
* Answer `y` when prompted to apply the configuration

Your pipeline configuration is now updated.

### How to Use Concourse UI

Visit [(( insert_parameter concourse.url ))]((( insert_parameter concourse.url ))) in your browser, and you will see a "no pipelines configured" message in the middle of your screen. Click the **login** button on the top right, choose the main team to login. The username and password is the same with what you used when you run `fly -t concourse login -c concourse_url`. (If needed, you can retrieve the password from vault with `safe get secret/(( insert_parameter site.name ))/proto/concourse/web_ui:password`.) After you login, you will see the pipelines listed on the left you already configured as the main team. You can click the pipeline name to look at the specific jobs in rectangle boxes of that pipeline.

Click each rectangle, you can see the builds, tasks and other details about the corresponding job. To trigger a job manually, you can click the plus button on the right corner for that job. We recommend that the jobs which deploy to the production environment should be manually triggered, and all other jobs can be triggered automatically when the changes are pushed to the git repository.

### Authentication Management for Teams

For the main team, we use Github oAuth instead of Basic Auth. It is also possible to set up authentication for additional teams. For more information, please refer to the [Concourse Authentication docs](https://concourse.ci/authentication.html).
