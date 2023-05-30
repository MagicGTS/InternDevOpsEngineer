# InternDevOpsEngineer

This is repository for studying on Intern DevOps Engineer course in Itransition.

# Task 1.2 -Kubernetes
Because I`m already had my own infrastructure, I decided describe my experience in manual deployment 3 master nodes\ 3 work nodes cluster.

## Basic steps:
- useradd -g users -G wheel -m <USER> && passwd <USER>
- Preload some useful modules

```
cat <<EOF | sudo tee /etc/modules-load.d/kube.conf
br_netfilter
overlay
EOF
```

- Tune system vars

```
cat <<EOF | sudo tee /etc/sysctl.d/kube.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```

- Allow passwordless sudo for our user
```
cat <<EOF | sudo tee /etc/sudoers.d/<USER>
<USER> ALL=(ALL) NOPASSWD: ALL
EOF
```
- Disabling swap (mandatory), selinux (current k8s has numerius problem with it) and cgroup v1 (also has problem)
- sudo -- bash -c "swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab"
- sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
- sudo grubby --update-kernel ALL --args enforcing=0
- sudo grubby --update-kernel ALL --args systemd.unified_cgroup_hierarchy=0
- reboot

## Downloading k8s packages
- export OS=CentOS_8_Stream
- export VERSION=1.27
- sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
- sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
```
- Preparation to use calico
```
cat <<EOF | sudo tee /etc/NetworkManager/conf.d/calico.conf
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico;interface-name:wireguard.cali
EOF
```
- sudo systemctl restart NetworkManager

Because I'm don't like to use Docker, on next step we should install Docker compatible replacement - Podman (!!! this instruction compatible with Podman version prior 4)

- sudo dnf -y install cri-o containernetworking-plugins kubelet kubeadm kubectl --disableexcludes=kubernetes
- sudo mkdir -p /etc/systemd/system/kubelet.service.wants/
- sudo ln -s /usr/lib/systemd/system/crio.service /etc/systemd/system/kubelet.service.wants/crio.service
- sudo systemctl daemon-reload

```
cat <<EOF | tee ./kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: <token>
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: <some ip>
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/crio/crio.sock
  imagePullPolicy: IfNotPresent
  name: <host name>
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: <some ip\dns name>:6443
controllerManager: {}
dns:
  imageRepository: registry.k8s.io/coredns/coredns
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io
kind: ClusterConfiguration
kubernetesVersion: v1.26.1
networking:
  dnsDomain: <dns cluster name>
  podSubnet: 10.85.0.0/16
  serviceSubnet: 10.96.0.0/16
scheduler: {}
EOF
```
```
cat <<EOF | sudo tee /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS="--container-log-max-size=100M"
EOF
```
- sudo -- bash -c "sed -i 's/\#?*\s*conmon_cgroup\s*=.*/conmon_cgroup = \"kubepods.slice\"/g' /etc/crio/crio.conf"
- sudo -- bash -c "sed -i 's/\#?*\s*PMLOGGER_DAILY_PARAMS\s*=.*/PMLOGGER_DAILY_PARAMS = \"-E -k 1\"/g' /etc/sysconfig/pmlogger_timers"
- sudo systemctl disable --now rsyslog
- sudo logrotate --force /etc/logrotate.conf
- sudo find /var/log/ -type f -regextype sed -regex '.*[0-9]\{8,8\}.*' -exec rm -f {} +
- sudo systemctl enable --now crio
- sudo systemctl enable kubelet.service
- sudo firewall-cmd --zone=public --add-service=kube-control-plane --permanent
- sudo firewall-cmd --zone=public --add-service=kubelet-worker --permanent
- sudo firewall-cmd --zone=public --add-port=4789/udp --permanent
- sudo firewall-cmd --zone=public --add-port=5473/tcp --permanent
- sudo firewall-cmd --zone=public --add-port=179/tcp --permanent
- sudo firewall-cmd --permanent --zone=public --add-source=10.85.0.0/16
- sudo firewall-cmd --permanent --new-zone=k8s-cluster
- sudo firewall-cmd --permanent --zone=k8s-cluster --set-target=ACCEPT
- sudo firewall-cmd --permanent --zone=k8s-cluster --add-interface=vxlan.calico
- sudo firewall-cmd --reload
- sudo firewall-cmd --zone=public --add-service=http --permanent
- sudo firewall-cmd --zone=public --add-service=https --permanent
- sudo firewall-cmd --reload
- sudo firewall-cmd --reload
- for i in $(systemctl list-unit-files --no-legend --no-pager -l | grep --color=never -o .*.slice | grep kubepod); do systemctl stop $i; done

Next step slightly tricky, we start first node installation and while preparation process we need to stop kubepods-burstable.slice immediately after it start:
- sudo kubeadm init --config kubeadm-config.yaml
- watch systemctl status kubepods-burstable.slice
Command to stopping process (https://github.com/kubernetes/kubernetes/issues/43856):
- sudo systemctl stop kubepods-burstable.slice
Preparing admin keys:
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get pods -A
```
For pods workload scheduling, we could make it by zones and region labels:
```
kubectl label node kube-master-0.<domain> topology.kubernetes.io/region=msk
kubectl label node kube-master-0.<doamin> topology.kubernetes.io/zone=msk.psh
etc
```
## Installing calico

- kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml
- curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/custom-resources.yaml -O
```
cat <<EOF | sudo tee /etc/sysconfig/kubelet
# This section includes base Calico installation configuration.
# For more information, see: https://projectcalico.docs.tigera.io/master/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    mtu: 1376
    ipPools:
    - blockSize: 26
      cidr: 10.85.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()

---

# This section configures the Calico API server.
# For more information, see: https://projectcalico.docs.tigera.io/master/reference/installation/api#operator.tigera.io/v1.APIServer
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF
```
- kubectl create -f custom-resources.yaml
- kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
- kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
- --kubelet-insecure-tls
# Creating dashboard service account and role

```
cat <<EOF | tee ./admin-user.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```
- kubectl apply -f admin-user.yaml

To access dashboard we should use token and start proxy:
- kubectl -n kubernetes-dashboard create token admin-user
- kubectl proxy
[DashBoard](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)

To add additional node to cluster we should use command like it:
```
kubeadm join kube-master-cp.<domain>:6443 --token <token> \
        --discovery-token-ca-cert-hash sha256:<token> \
        --control-plane
```
And pack auto generated certs by command like this and transfer it to target node:
tar -cvf pki.tar /etc/kubernetes/pki/ca.key /etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.key /etc/kubernetes/pki/front-proxy-ca.crt /etc/kubernetes/pki/front-proxy-ca.key /etc/kubernetes/pki/sa.key /etc/kubernetes/pki/sa.pub

## Ingress nginx

As nginx ingress controller we have two major distribution, the first one is https://kubernetes.github.io/ingress-nginx/ and second one is https://docs.nginx.com/nginx-ingress-controller/ known also as nginxinc/kubernetes-ingress. I`m prefered nginxinc/kubernetes-ingress.

Because I also deploy on premise k8s cluster and haven't load balancer outside cluser, except dns round robin, it is more convinient deploy ingress controller throught kubernetes manifests file as daemon-set insted of helm chart.

- git clone https://github.com/nginxinc/kubernetes-ingress.git --branch v2.4.1
- cd kubernetes-ingress/deployments
- kubectl apply -f common/ns-and-sa.yaml
- kubectl apply -f rbac/rbac.yaml
Major notice, this secret contain pre generated certificates, for security reason it is good to generate yours own.
- kubectl apply -f common/default-server-secret.yaml
- kubectl apply -f common/nginx-config.yaml
- kubectl apply -f common/ingress-class.yaml
- kubectl apply -f common/crds/k8s.nginx.org_virtualservers.yaml
- kubectl apply -f common/crds/k8s.nginx.org_virtualserverroutes.yaml
- kubectl apply -f common/crds/k8s.nginx.org_transportservers.yaml
- kubectl apply -f common/crds/k8s.nginx.org_policies.yaml
- kubectl apply -f kubernetes-ingress/deployments/daemon-set/nginx-ingress.yaml

This is quite straightforward, in addition we must allow incoming traffic to standards web ports 80 and 443 on every working nodes.

## ZFS as volume subsystem

Helpfuly that Kubernetes support a bunch of storage solutions. one of them is openbs zfs
- kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
- kubectl apply -f https://openebs.github.io/charts/zfs-operator.yaml

Inside StorageClass folder you can find some StorageClass definition and persistent volume claim for postgres.

## Install Cert-Manager
To have global validity ssl certificate we can by it from appropriate pki provider or use Let's Encrypt with Cert-Manager. Because it is not quite easy to do it by k8s manifest, just do it by helm:
- helm repo add jetstack https://charts.jetstack.io
- helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.0 --set installCRDs=true
## Zabbix inside kubernetes

We can deploy zabbix by single simple action, but it isn't simple inside:
- kubectl apply -f zabbix.yaml
