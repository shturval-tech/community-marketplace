# SSC examples

Apply **ShturvalRepoConfig** first (`kubectl apply -k deploy/repoconfig/base`).

`spec.reponame` must match `metadata.name` of the repo config (`community`).

`spec.version` must match published chart version (initial wave: `0.1.0`).
