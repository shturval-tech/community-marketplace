# SSC examples

Apply **ShturvalRepoConfig** first (`kubectl apply -k deploy/repoconfig/base`).

`spec.reponame` must match `metadata.name` of the repo config (`community`).

`spec.version` must match published chart version (см. `version` в `Chart.yaml` чарта).
