<!--
# Copyright 2024 New Vector Ltd

SPDX-License-Identifier: AGPL-3.0-or-later

-->
# easy setup chart
This creates an ESS deployment in a local cluster.

## Preparation

It requires locally available on your laptop:
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/): to make the local cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/): to drive the cluster and pods
- [helm](https://helm.sh/docs/intro/install/): to install applications on the cluster



You need to be able to login against the helm repositories:
```
helm repo add ess-starter-edition-core https://element-hq.github.io/ess-starter-edition-core
```

You have to add the community helm repositories as well :

```
helm repo add jetstack https://charts.jetstack.io
helm repo add codecentric https://codecentric.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
```

## Configuration

Copy the example files provided:

```bash
cp values.ess-system.yaml.example values.ess-system.yaml
cp values.ess-stack.yaml.example values.ess-stack.yaml
```

Edit the files, changing any desired values.

You can find more variables to override in `values.ess-stack.yaml` in the `ess-stack/values.yml` file.

## Run

1. To prepare the kind cluster, run `./prepare.sh;`
2. To perform a deployment (initial or subsequent), run `./deploy.sh <component> <component2>

5. To delete the cluster: `kind delete cluster --name easy-setup`

You can find Element under https://element.ess.localhost, unless you've changed
the `global.baseUrl` configuration value.

