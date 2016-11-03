## Contributing Updates to Codex
#### Pull Requests
Please submit a Pull Request with your proposed changes.  The Codex team will review it, make suggestions for improvement if necessary, and will merge your change once it is ready to be included.

#### Walkthrough Updates
When making changes, **do not** directly change the walkthrough itself (for example, don't change `aws.md`).  Our walkthroughs are built from a set of smaller documents.  Some of these documents contain content that is universal across all infrastructures, while other documents contain specific details that are intrinsic to a given platform.  This helps ensure that no matter what Infrastructure as a Service you use, our walkthroughs tell the same story.

Within the `walkthrough` directory, each file with a `.md` extension represents a common "snippet" of prose that can be pulled into a walkthrough.  The walkthrough source files reside in the subdirectories (for example:  the `aws` subdirectory) - these are as follows:
- **walkthrough.md** determines the flow of the resulting walkthrough, and contains all instructions that are specific to the infrastructure you're writing about.
- **parameters.json** contains properties that will be referenced by both `walkthrough.md` and by the more generic snippets that are to be included.  So far, these properties include:
  - **service.short_name** - the abbreviated name of the IaaS (ex:  "AWS")
  - **service.long_name** - the long name of the IaaS (ex:  "Amazon Web Services")
  - **template_name** - the name of the Genesis template (ex:  "aws")
  - **cpi_name** - the name of the BOSH CPI (ex:  "aws")
  - **site.name** - the name of the Genesis site (ex:  "us-west-2")
  - **site.description** - what the Genesis site actually represents (ex:  "AWS Region")
  - **stemcell.name** - the long name of the stemcell used (ex: "bosh-aws-xen-hvm-ubuntu-trusty-go_agent")
  - **stemcell.version** - the version of the stemcell used (ex:  "3262.2")

Directives used within `walkthrough.md` facilitate the substitution content when generating the final file.  These directives are:
- `(( insert_file filename.md ))` is replaced by the contents of the file
- `(( insert_parameter parameter ))` is replaced by the contents of the parameter referenced in `parameters.json`.  These references can be either flat (ex:  `template_name`) or hierarchical (ex:  `service.long_name`), depending on where they are in the json.

###### Generating a Walkthrough
To generate a walkthrough file, run the `build_walkthrough.py` script as follows:

```
bin/build_walkthrough.py <infrastructure name>
```

If successful, the output should look like this and you should be ok to push your changes to your branch for your pull request:
```
$ bin/build_walkthrough.py aws
BUILDING WALKTHROUGH FOR INITIAL COMPARISON...
Extracting Parameters...
cpi_name: aws
template_name: aws
stemcell.version: 3262.2
stemcell.name: bosh-aws-xen-hvm-ubuntu-trusty-go_agent
site.name: us-west-2
site.description: AWS Region
service.long_name: Amazon Web Services
service.short_name: AWS

Merging in alpha_boshlite_deploy.md...
...
Merging in vault_init.md...

Merging in Parameters...

BUILDING FINAL WALKTHROUGH FILE...
Extracting Parameters...
cpi_name: aws
template_name: aws
stemcell.version: 3262.2
stemcell.name: bosh-aws-xen-hvm-ubuntu-trusty-go_agent
site.name: us-west-2
site.description: AWS Region
service.long_name: Amazon Web Services
service.short_name: AWS

Merging in alpha_boshlite_deploy.md...
...
Merging in vault_init.md...

Merging in Parameters...

File aws.md is generated. Well Done!
```

However, if you receive the following error message, this means that someone may have changed the generated walkthrough manually, and you might be in danger of overwriting their changes:
```
...

Merging in Parameters...
ERROR - This walkthrough may have previously been manually changed without changing the source files.
```
Caution is advised.  At this point, simply work with the Codex team to ensure that changes are properly made and the problem is resolved before you push your changes.
