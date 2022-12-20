# InternDevOpsEngineer

Today we continue to work with k8s and going to deploy own Gitlab.
It Is necessary to pre deploy ingress controller and Certmanager to have public approved certificate.

## Pre tasks

Please consults steps in https://github.com/MagicGTS/InternDevOpsEngineer/tree/Task-1.2 about installation ingress controller and certmanager

## Deploying gitlab

First of all we need to download default values.yaml and set your own values in values.yaml and run helm with values

- wget https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/values.yaml
- helm install gitlab gitlab/gitlab --namespace gitlab --create-namespace -f values.yaml

After few minutes we get ready to see what we have

```bash
kubectl get pods --namespace gitlab
NAME                                          READY   STATUS      RESTARTS       AGE
gitlab-gitaly-0                               1/1     Running     0              1d
gitlab-gitlab-exporter-5b8746988d-hfrsk       1/1     Running     1              1d
gitlab-gitlab-runner-67995cf87b-rqgls         1/1     Running     14 (1d ago)   1d
gitlab-gitlab-shell-759f658f-2n4p2            1/1     Running     0              1d
gitlab-gitlab-shell-759f658f-rptxg            1/1     Running     1              1d
gitlab-kas-c8d8b4cd-ccxws                     1/1     Running     1              1d
gitlab-kas-c8d8b4cd-rx8pm                     1/1     Running     0              1d
gitlab-minio-74dfc6b6c7-fhbgf                 1/1     Running     1              1d
gitlab-minio-create-buckets-15-vklcw          0/1     Completed   0              1d
gitlab-postgresql-0                           2/2     Running     0              1d
gitlab-redis-master-0                         2/2     Running     0              1d
gitlab-registry-784db54548-gr768              1/1     Running     1              1d
gitlab-registry-784db54548-l6mx6              1/1     Running     0              1d
gitlab-runner-c669f5986-6jqs4                 1/1     Running     10 (1d ago)   1d
gitlab-shared-secrets-11-n9e-lh42b            0/1     Completed   0              1d
gitlab-shared-secrets-12-emf-selfsign-gkj22   0/1     Completed   0              1d
gitlab-sidekiq-all-in-1-v2-8c596899-8jzrd     1/1     Running     1              1d
gitlab-toolbox-854bffd46-n6w5q                1/1     Running     0              1d
gitlab-webservice-default-746f897c47-pr95n    2/2     Running     2              1d
gitlab-webservice-default-746f897c47-wbzvd    2/2     Running     0              1d
```
```bash
kubectl get ingress --namespace gitlab
NAME                        CLASS   HOSTS                 ADDRESS   PORTS     AGE
gitlab-kas                  nginx   kas.miritek.ru                  80, 443   1d
gitlab-minio                nginx   minio.miritek.ru                80, 443   1d
gitlab-registry             nginx   registry.miritek.ru             80, 443   1d
gitlab-webservice-default   nginx   gitlab.miritek.ru               80, 443   1d
```
```bash
kubectl get secrets --namespace cert-manager
NAME                                 TYPE                 DATA   AGE
cert-manager-webhook-ca              Opaque               3      1d
magic-prod-tls                       Opaque               1      1d
magic-staging-tls                    Opaque               1      1d
sh.helm.release.v1.cert-manager.v1   helm.sh/release.v1   1      1d
```
it is seems look fine. Let's go to web panel and create new project.

## GitLab

Preparing namespace for test project and generate tokens for deploying into it, also setting lifetime for generated token
Before begin, you should create **Settings -> Repository -> Deploy Tokens** with capabalities (read_registry, write_registry permissions)
```bash
duration=2h
read -p "Enter docker-registry token name: " docker_username
read -p "Enter docker-registry token: " docker_token
read -p "Enter docker-registry: " docker_server
read -p "Enter docker-email: " docker_email
[ -z "$docker_server" ] && docker_server="registry.miritek.ru"
[ -z "$docker_email" ] && docker_email="magicgts@gmail.com"

for ns in stage prod; do
    kubectl create ns ${ns}
    kubectl create sa deploy --namespace ${ns}
    kubectl create rolebinding deploy --serviceaccount ${ns}:deploy --clusterrole edit --namespace ${ns}
    kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "gitlab-registry"}]}' -n ${ns}
    kubectl create secret docker-registry gitlab_registry --docker-server=${docker_server} --docker-username=${docker_username} --docker-password=${docker_token} --docker-email=${docker_email} -n ${ns}
    echo "-----BEGIN DEPLOY TOKEN FOR NS ${ns}-----"
    kubectl create token deploy -n ${ns} --duration=${duration}
    echo "-----END DEPLOY TOKEN FOR NS ${ns}-----"
done
```
Now we have two tokens which need to place in (**Settings -> CI/CD -> Variables**) and naming it as K8S_STAGE_CI_TOKEN and K8S_PROD_CI_TOKEN acordently.

## Install runner

Before hit the helm command, you should adjust variables inside value.yml

```bash
mkdir gitlab-runner
wget https://gitlab.com/gitlab-org/charts/gitlab-runner/-/raw/main/values.yaml?inline=false -O gitlab-runner/value.yml
helm install --namespace gitlab gitlab-runner -f ./gitlab-runner/values.yaml gitlab/gitlab-runner
```
## Place app invirement into k8s
```bash
for ns in stage prod; do
    kubectl apply --namespace ${ns} -f ./app/kube/deployment.yaml -f ./app/kube/service.yaml -f ./app/kube/postgres/secret.yaml -f ./app/kube/postgres/service.yaml -f ./app/kube/postgres/statefulset.yaml
    sed "s,__HOSTNAME__,${ns},g" ./app/kube/ingress.yaml | kubectl apply --namespace ${ns}
done
```

## Run pipline
All we needs to continue it is fire up pipeline or commit something into master branch to trigger it up to.
