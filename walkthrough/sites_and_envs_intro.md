## Building out Sites and Environments

Now that the underlying infrastructure has been deployed, we can start deploying our alpha/beta/other sites, with Cloud Foundry, and any required services. When using Concourse to update BOSH deployments,
there are the concepts of `alpha` and `beta` sites. The alpha site is the initial place where all deployment changes are checked for sanity + deployability. Typically this is done with a `bosh-lite` VM. The `beta` sites are where site-level changes are vetted. Usually these are referred to as the sandbox or staging environments, and there will be one per site, by necessity. Once changes have passed both the alpha, and beta site, we know it is reasonable for them to be rolled out to other sites, like production.
