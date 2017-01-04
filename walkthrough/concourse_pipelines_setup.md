After the Concourse deployment is working, it is time to setup pipelines for deployments. Setting up pipelines for different deployments has similar work flow. We will describe the process as follows.

### Run Genesis CI Basics 

Genesis CI requires us to have at least three level deployments: alpha, beta and manual (/auto). Alpha is usually a bosh-lite environment. Once the changes apply to the alpha deployment and pass the tests, the pipeline will automatically go to the beta deployment which is usually in a sandbox/development environment. Once it passes the tests in the beta environment, we can choose manually or automatically triggering your production deployment and tests. Manually here means that we have to click the plus button to trigger the production deployment and automatically means the pipeline itself will deploy to production environment once beta deployment passes the tests.

In the deployments repo, run the following commands:

```
genesis ci alpha site/env
genesis ci beta  site/env
genesis ci manual(or auto) site/env
```
Then simply run `genesis ci check` to see if everything is set up correctly and use `genesis ci flow` to review that if the pipeline flows are correct. 

### Set Up Vault

#### Create read-only policies

The read-only policies should be created for the pipelines. Depending on the requirements, one policy for all the pipelines which can access all the credentials under `secret/*` can be configured, or per policy per pipeline can be set up so each pipeline only has access to its own deployment secrets. It is not good to auth the vault with root for running pipeline purpose since the root has full access to all secrets in all backends.

In order to create a read only policy, run `vault auth` to log into the vault using root first. `vault policies` shows all the policies which are already defined. In this example, we will only create one `read-only` policy for all the pipelines. Run `vault policy-write read-only acl.hcl` to create a read-only policy which has read only right to the `secret/*` path, where `acl.hcl` is configured as follows:  

```
path "secret/*" {
  policy = "read"
}
```
Now `vault policies` should also show the `read-only` policy we created. Save your token for read-only policy and you can `vault auth` with the read-only policy token later.

#### Set up AppID Authentication

Notes: If the CLI to set up app-id method does not work for you, please check if you are using the right Vault CLI version.

Let’s take a look what type of auth methods are enabled:
```
$ vault auth -methods
Path    Type   Default TTL  Max TTL  Description
token/  token  system       system   token based credentials
```

First, we need to enable `app-id` auth method by running `vault auth-enable app-id`. 

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
        cidr_block= your_concoure_network_block
```
Keep in mind that `genesis v1.6.0` has default name for `app_id` and `user-id` for each deployment,make sure you replace `your_app_id` and `your_user_id` using those default names accordingly.

In future, we will switch to AppRole from AppId when genesis is ready for AppRole. For more details,please visit:  https://www.vaultproject.io/docs/auth/app-id.html

### Use FLY to Configure Pipelines

We suggest downloading the fly cli from the concourse web UI page so that the latest version will be downloaded.

Set fly target as concourse, if we do not use `concourse` as target name, we will need to specify it in the `ci/setting.yml` file.

`fly -t concourse login -c concourse_url`

It will ask for user and password and it logs in as default main team when you do not specify it. Usually we should set up oAuth or other safer authentication instead of basic auth for the main team in production environment.

### Configure and Generate Pipelines

Run `genesis ci repipe`, you will see the following errors:

```
Testing Vault authentication by retrieving secret/handshake
Key                     Value
---                     -----
refresh_interval        2592000
knock                   knock

2 error(s) detected:
 - $.aliases.target: Please define aliases for your BOSH directors (uuid -> addr)
 - $.auth: Please define your BOSH directors in ci/boshes.yml (and remove this line)

2 error(s) detected:
 - $.aliases.target: Please define aliases for your BOSH directors (uuid -> addr)
 - $.auth: Please define your BOSH directors in ci/boshes.yml (and remove this line)

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
We can tackle all the errors by configuring two files `ci/boshes.yml` and `ci/setting.yml`. Before that, lets add deployment key to the repo and write them to vault since we need it to configure our pipeline.

Generate a SSH key pair,use the following commands to write them to vault. In the github reo, add the pub key to the deploy key.

```
safe write path "private_key_name@private_key_file"
safe write path "pub_key_name@pub_key_file"

```

Finally, configure the files we mentioned earlier: 

```
boshes.yml

aliases:
  target:
    your_bosh_uuid: your_bosh_director_url
    your_bosh_uuid: your_bosh_director_url
    your_bosh_uuid: your_bosh_director_url
auth:
  https://x.x.x.x:25555:
    username: admin
    password: (( vault "path to bosh admin secret" ))
  https://x.x.x.x:25555:
    username: admin
    password: (( vault "path to bosh admin secret" ))

```

```
setting.yml
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

```
### Authentication Management for teams in pipeline

To be continued: how to manage authentication for teams. For main team ,how we use github Auth instead of basic auth.

