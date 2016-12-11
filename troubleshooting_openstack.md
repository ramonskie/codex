## Troubleshooting Guide

Here we will display all common errors, the common paths that you ended up in
that position, and the ways to get around them. If you can't find the solution
in the main docs, then the answer will probably be here....ONWARDS!

## Bastion Host

### Missing Commands

If you can't find the `vault` or `genesis` commands, chances are you did not run
the `jumpbox` script, refer to [the Prepare Bastion Host section][1] and make
sure that you remain logged in as the user you creaded with `jumpbox`.  

### proto-BOSH & Shield

Error Deploying **proto-BOSH** with Shield Agent Job.

If you see the error below, then you are running the scripts and everything from
the bastion user, you MUST use the `jumpbox` scripts/users/Vault in order for it
to be nice and not throw errors at you.

```
    Command 'deploy' failed:
      Deploying:
        Building state for instance 'bosh/0':
          Rendering job templates for instance 'bosh/0':
            Rendering templates for job 'shield-agent/38e11abc09d09a2af3572c070cc9813ab640e8dd':
              Rendering template src: config/target.json.erb, dst: config/target.json:
                Rendering template src: /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/bosh-init-release368081404/extracted_jobs/shield-agent/templates/config/target.json.erb, dst: /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/rendered-jobs598042080/config/target.json:
                  Running ruby to render templates:
                    Running command: 'ruby /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-render.rb /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-context.json /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/bosh-init-release368081404/extracted_jobs/shield-agent/templates/config/target.json.erb /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/rendered-jobs598042080/config/target.json', stdout: '', stderr: '/home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-render.rb:189:in `rescue in render': Error filling in template '/home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/bosh-init-release368081404/extracted_jobs/shield-agent/templates/config/target.json.erb' for shield-agent/0 (line 2: #<TypeError: nil is not a symbol nor a string>) (RuntimeError)
        from /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-render.rb:175:in `render'
        from /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-render.rb:200:in `<main>'
    ':
                      exit status 1
    Makefile:25: recipe for target 'deploy' failed
```
