##### Push An App to Beta Cloud Foundry

After you successfully deploy the Beta CF, you can push an simple app to learn more about CF. In the CF world, every application and service is scoped to a space. A space is inside an org and provides users with access to a shared location for application development, deployment, and maintenance. An org is a development account that an individual or multiple collaborators can own and use. You can click [orgs, spaces, roles and permissions][orgs and spaces] to learn more  details.

The first step is creating and org and an space and targeting the org and space you created by running the following commands.

```
cf create-org sw-codex
cf target -o sw-codex
cf create-space test
cf target -s test

```

Once you are in the space, you can push an very simple app [cf-env][cf-env]  to the CF. Clone the [cf-env][cf-env]  rego on your bastion server, then go inside the `cf-env` directory, simply run `cf push` and it will start to upload, stage and run your app.

Your `cf push` command may fail like this:

```
Using manifest file /home/user/cf-env/manifest.yml

Updating app cf-env in org sw-codex / space test as admin...
OK

Uploading cf-env...
FAILED
Error processing app files: Error uploading application.
Server error, status code: 500, error code: 10001, message: An unknown error occurred.

```
You can try to debug this yourself for a while or find the possible solution in [Debug Unknown Error When You Push Your APP to CF][DebugUnknownError].
