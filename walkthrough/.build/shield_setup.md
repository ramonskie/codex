### Deploying SHIELD

We'll start out with the Genesis template for SHIELD:

```
$ cd ~/ops
$ genesis new deployment --template shield
$ cd shield-deployments
```

Now we can set up our `(( insert_parameter site.name ))` site using the `(( insert_parameter template_name ))` template, with a
`proto` environment inside of it:

```
$ genesis new site --template (( insert_parameter template_name )) (( insert_parameter site.name ))
$ genesis new env (( insert_parameter site.name )) proto
$ cd (( insert_parameter site.name ))/proto
```
