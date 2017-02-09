### How to Use SHIELD

Backup jobs for SHIELD are created and maintained in the SHIELD UI:

![SHIELD UI][shield_ui]

To access the SHIELD UI, go to https://(( insert_parameter openstack.shield_fip )).
The user name is `shield` and the password can be accessed in Vault by running
`safe get secret/(( insert_parameter site.name ))/proto/shield/webui:password`. We recommend also storing this
password in a password manager for convenience.

In the SHIELD deployment, we defined a default schedule and retention policy as
well as provided access to the blobstore. We can add additional policies in the
SHIELD UI.

To create a backup schedule, click on the **Schedules** tab and then **Create New
Schedule**. Since schedule times are given in UT, it is helpful to include your local
time in the schedule name and/or summary field. For example, if you were in Brisbane,
Australia you might name your backup job "Daily at 2 AM" and then provide the
schedule as "daily 4 pm" or "daily 16:00". You can even use "daily at 16:05" if
desired.

There are actually quite a few keywords available allowing you to create backups
that are `hourly`, `daily`, `weekly`, or `monthly` using those keywords. Here
are some additional backup schedules to show their behaviors: "hourly at 45 after",
"thursdays at 23:35", "3rd Tuesday at 2:05", and "monthly at 2:05 on 14th".  Once
you have provided the name, schedule, and optional summary click **Create** to finish.

Now that you have some additional backup schedules, we're going to create more
**retention policies** as well. Click on **Retention** and **Create New Retention Policy**.
Similar to the schedules, it is helpful to include the duration in the policy name.
The duration is given in days, so if you wanted to keep a given backup for a year
you'd use `365` and perhaps name the policy "1 year retention".

Something to consider: people usually like comparing "this time, last period" backups.
By that we mean "I wonder what X looked like this time last year" or "I wonder what last
Monday looked like", so you might want to consider making your 1 year backups actually
13 months or your weekly backups 8 days. (And so on.)

For the **storage** you _can_ create additional storage configurations in the SHIELD
UI by clicking on **Storage** and **Create New Store**. Currently SHIELD has an s3
plugin for storage, so your blobstore must be either S3 or S3-compatible. This said,
due to credential management, we strongly encourage you to put the storage configurations
in the SHIELD deployment itself and allow Vault to manage the credentials of the new
blobstores. To create a new store in the UI you will need to supply the configuration
as a JSON object, e.g.:

```
{
  "access_key_id": "ACCESS_KEY",
  "bucket": "(( insert_parameter cf_beta.directory_key_prefix ))-shield",
  "prefix": "/DESIRED_PREFIX",
  "s3_host": "s3.(( insert_parameter cf_beta.base_domain ))",
  "s3_port": "8080",
  "secret_access_key": "SECRET_ACCESS_KEY",
  "signature_version": "2",
  "skip_ssl_validation": true
}
```

Now that we have the where, when, and how long we need the "what". In SHIELD parlance
this is the **target**. In a minimal configuration, you'll want to back up the BOSH(es)
and Cloud Foundry(-ies). To add these as targets, go to **Targets** and **Create New Target**.

In the configuration we are using here, BOSH and Cloud Foundry are both using postgres
so the plugin name in this case will be "postgres". For BOSH the only database that
needs to be backed up is the bosh database, but for Cloud Foundry we'll need to back up
all of its databases.

To backup BOSH, use the postgres plugin and the BOSH director's IP and port `5444` for the
**Remote IP:Port**. The JSON configuration for a sample BOSH backup is:

```
{
  "pg_user": "boshdb",
  "pg_password": "",
  "pg_host": "127.0.0.1",
  "pg_port": "5432",
  "pg_bindir": "/var/vcap/packages/postgres-9.4/bin",
  "pg_dump_args": "",
  "pg_database": "bosh"
}
```

To backup Cloud Foundry, again use the postgres plugin, the IP address of the `postgres_z1` VM,
and port `5444`. The JSON configuration for a sample Cloud Foundry backup is:

```
{
  "pg_user": "vcap",
  "pg_password": "",
  "pg_host": "127.0.0.1",
  "pg_port": "5432",
  "pg_bindir": "/var/vcap/packages/postgres-9.4.9/bin",
  "pg_dump_args": ""
}
```

Notice that the only difference between these configurations is the `pg_database` field,
used in the BOSH case to back up only the BOSH database itself.

SHIELD currently has plugins for Redis, Mongo, Elasticsearch, and others. To see
more information about the plugin list and relevant documentation, please check out
the [SHIELD README][shield].

In order to back up BOSH, Cloud Foundry, and your services you will need to use the
schedules, retention policies, targets, and storage definitions and create a **backup job**.
To create the job, go to **Jobs** and **Create A New Job**. This is actually the easiest
part to configure - aside from providing the name and optional summary, everything else is a
drop down menu. This is where good naming really comes in handy! Once you have selected your
target, storage, schedule, and retention policy click **Create** to create the job.

In addition to running at the scheduled time, you can run a job at any time by clicking the
circular arrow icon for the desired job. Jobs can also be paused by clicking the adjacent
pause icon. This means that the job will not run at its scheduled time(s) until it is unpaused.

In order to **restore** a given backup, go to **Restore**. You can filter your backup jobs
by date and/or target name. The **Dashboard** gives a list of the most recent tasks and
their durations. Initially, most tasks are expected to have a very short duration but
as time goes on and your environment grows you will notice the time required for the various
backups will increase.
