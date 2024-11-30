Перед началом необходимо доустановить в миникуб необходимые аддоны(ingress, metrics-server ):  

<details>

```bash
valyan@valyan-pc:~$ minikube addons list
|-----------------------------|----------|--------------|--------------------------------|
|         ADDON NAME          | PROFILE  |    STATUS    |           MAINTAINER           |
|-----------------------------|----------|--------------|--------------------------------|
| ambassador                  | minikube | disabled     | 3rd party (Ambassador)         |
| auto-pause                  | minikube | disabled     | minikube                       |
| cloud-spanner               | minikube | disabled     | Google                         |
| csi-hostpath-driver         | minikube | disabled     | Kubernetes                     |
| dashboard                   | minikube | disabled     | Kubernetes                     |
| default-storageclass        | minikube | enabled ✅   | Kubernetes                     |
| efk                         | minikube | disabled     | 3rd party (Elastic)            |
| freshpod                    | minikube | disabled     | Google                         |
| gcp-auth                    | minikube | disabled     | Google                         |
| gvisor                      | minikube | disabled     | minikube                       |
| headlamp                    | minikube | disabled     | 3rd party (kinvolk.io)         |
| helm-tiller                 | minikube | disabled     | 3rd party (Helm)               |
| inaccel                     | minikube | disabled     | 3rd party (InAccel             |
|                             |          |              | [info@inaccel.com])            |
| ingress                     | minikube | enabled ✅   | Kubernetes                     |
| ingress-dns                 | minikube | disabled     | minikube                       |
| inspektor-gadget            | minikube | disabled     | 3rd party                      |
|                             |          |              | (inspektor-gadget.io)          |
| istio                       | minikube | disabled     | 3rd party (Istio)              |
| istio-provisioner           | minikube | disabled     | 3rd party (Istio)              |
| kong                        | minikube | disabled     | 3rd party (Kong HQ)            |
| kubeflow                    | minikube | disabled     | 3rd party                      |
| kubevirt                    | minikube | disabled     | 3rd party (KubeVirt)           |
| logviewer                   | minikube | disabled     | 3rd party (unknown)            |
| metallb                     | minikube | disabled     | 3rd party (MetalLB)            |
| metrics-server              | minikube | enabled ✅   | Kubernetes                     |
| nvidia-device-plugin        | minikube | disabled     | 3rd party (NVIDIA)             |
| nvidia-driver-installer     | minikube | disabled     | 3rd party (NVIDIA)             |
| nvidia-gpu-device-plugin    | minikube | disabled     | 3rd party (NVIDIA)             |
| olm                         | minikube | disabled     | 3rd party (Operator Framework) |
| pod-security-policy         | minikube | disabled     | 3rd party (unknown)            |
| portainer                   | minikube | disabled     | 3rd party (Portainer.io)       |
| registry                    | minikube | disabled     | minikube                       |
| registry-aliases            | minikube | disabled     | 3rd party (unknown)            |
| registry-creds              | minikube | disabled     | 3rd party (UPMC Enterprises)   |
| storage-provisioner         | minikube | enabled ✅   | minikube                       |
| storage-provisioner-gluster | minikube | disabled     | 3rd party (Gluster)            |
| storage-provisioner-rancher | minikube | disabled     | 3rd party (Rancher)            |
| volcano                     | minikube | disabled     | third-party (volcano)          |
| volumesnapshots             | minikube | disabled     | Kubernetes                     |
| yakd                        | minikube | disabled     | 3rd party (marcnuri.com)       |
|-----------------------------|----------|--------------|--------------------------------|

```
</details>


Создаем обьекты для домашнего задания из директории kubernetes-security при помощи kubectl apply -f ./.  
Вывод консоли ниже:  

<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-security$ k apply -f ./
configmap/test-cm-1 created
deployment.apps/test-deployment-2 created
ingress.networking.k8s.io/test-ingress-2 created
namespace/homework unchanged
configmap/nginx-cm created
persistentvolume/test-pv created
persistentvolumeclaim/test-pvc created
clusterrolebinding.rbac.authorization.k8s.io/namespace-metrics created
rolebinding.rbac.authorization.k8s.io/namespace-admin created
clusterrole.rbac.authorization.k8s.io/metrics-role created
role.rbac.authorization.k8s.io/admins-role created
serviceaccount/homework-admin unchanged
serviceaccount/homework-monitoring unchanged
service/test-service-2 created
storageclass.storage.k8s.io/storage-class-test configured
resource mapping not found for name: "" namespace: "" from "homework-admin-kubeconfig.yaml": no matches for kind "Config" in version "v1"
ensure CRDs are installed first
error validating "homework-admin-token.yaml": error validating data: invalid object to validate; if you choose to ignore these errors, turn validation off with --validate=false

```
</details>

Вывод ругнулся на token.yaml и kubeconfig.yaml, их создадим вручную в конце, это не критично

Получившиеся обьекты и их спецификации:

pv и pvc:  
<details>

```bash

valyan@valyan-pc:~$ k get pv pvc -n homework
Error from server (NotFound): persistentvolumes "pvc" not found
valyan@valyan-pc:~$ k -n homework get pvc
NAME       STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS         VOLUMEATTRIBUTESCLASS   AGE
test-pvc   Bound    test-pv   2Gi        RWX            storage-class-test   <unset>                 78s
valyan@valyan-pc:~$ k -n homework get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS         VOLUMEATTRIBUTESCLASS   REASON   AGE
test-pv   2Gi        RWX            Retain           Bound    homework/test-pvc   storage-class-test   <unset>                          80s
valyan@valyan-pc:~$ k describe pv -n homework test-pv 
Name:              test-pv
Labels:            <none>
Annotations:       pv.kubernetes.io/bound-by-controller: yes
Finalizers:        [kubernetes.io/pv-protection]
StorageClass:      storage-class-test
Status:            Bound
Claim:             homework/test-pvc
Reclaim Policy:    Retain
Access Modes:      RWX
VolumeMode:        Filesystem
Capacity:          2Gi
Node Affinity:     
  Required Terms:  
    Term 0:        kubernetes.io/hostname in [minikube]
Message:           
Source:
    Type:  LocalVolume (a persistent volume backed by local storage on a node)
    Path:  /home/docker/test_dir
Events:    <none>
valyan@valyan-pc:~$ k describe pvc -n homework test-pvc 
Name:          test-pvc
Namespace:     homework
StorageClass:  storage-class-test
Status:        Bound
Volume:        test-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      2Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       test-deployment-2-86c584dcc8-5wnjc
               test-deployment-2-86c584dcc8-plnhl
               test-deployment-2-86c584dcc8-rcjb8
Events:
  Type    Reason               Age                From                         Message
  ----    ------               ----               ----                         -------
  Normal  WaitForPodScheduled  45m (x2 over 45m)  persistentvolume-controller  waiting for pods test-deployment-2-86c584dcc8-plnhl,test-deployment-2-86c584dcc8-rcjb8,test-deployment-2-86c584dcc8-5wnjc to be scheduled

```
</details>

service и ingress:    

<details>

```bash

valyan@valyan-pc:~$ k get svc -n homework 
NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
test-service-2   NodePort   10.105.138.80   <none>        80:30080/TCP   91s
valyan@valyan-pc:~$ k describe svc -n homework test-service-2 
Name:                     test-service-2
Namespace:                homework
Labels:                   <none>
Annotations:              <none>
Selector:                 homework=true
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.105.138.80
IPs:                      10.105.138.80
Port:                     <unset>  80/TCP
TargetPort:               8000/TCP
NodePort:                 <unset>  30080/TCP
Endpoints:                10.244.0.247:80,10.244.0.248:80,10.244.0.249:80
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>
valyan@valyan-pc:~$ k get ingress -n homework test-ingress-2 
NAME             CLASS   HOSTS           ADDRESS        PORTS   AGE
test-ingress-2   nginx   homework.otus   192.168.49.2   80      108s
valyan@valyan-pc:~$ k describe ingress -n homework test-ingress-2 
Name:             test-ingress-2
Labels:           <none>
Namespace:        homework
Address:          192.168.49.2
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host           Path  Backends
  ----           ----  --------
  homework.otus  
                 /homepage       test-service-2:80 (10.244.0.247:80,10.244.0.248:80,10.244.0.249:80)
                 /index.html     test-service-2:80 (10.244.0.247:80,10.244.0.248:80,10.244.0.249:80)
                 /conf/file      test-service-2:80 (10.244.0.247:80,10.244.0.248:80,10.244.0.249:80)
                 /metrics.html   test-service-2:80 (10.244.0.247:80,10.244.0.248:80,10.244.0.249:80)
Annotations:     nginx.ingress.kubernetes.io/rewrite-target: /index.html
Events:
  Type    Reason  Age                  From                      Message
  ----    ------  ----                 ----                      -------
  Normal  Sync    104s (x2 over 116s)  nginx-ingress-controller  Scheduled for sync

```
</details>

Role, clusterRole, RoleBinding, clusterRoleBinding:    

<details>

```bash

valyan@valyan-pc:~$ k get role -n homework 
NAME          CREATED AT
admins-role   2024-11-30T13:18:09Z
valyan@valyan-pc:~$ k describe role -n homework  admins-role 
Name:         admins-role
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  *.*        []                 []              [*]       
        
valyan@valyan-pc:~$ k get rolebindings.rbac.authorization.k8s.io -n homework 
NAME              ROLE               AGE
namespace-admin   Role/admins-role   3m15s
valyan@valyan-pc:~$ k describe rolebindings.rbac.authorization.k8s.io -n homework namespace-admin 
Name:         namespace-admin
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  admins-role
Subjects:
  Kind            Name            Namespace
  ----            ----            ---------
  ServiceAccount  homework-admin  homework
valyan@valyan-pc:~$ k get clusterrole -n homework | grep metrics-role
metrics-role                                                           2024-11-30T13:18:09Z
valyan@valyan-pc:~$ k describe clusterrole -n homework  metrics-role
Name:         metrics-role
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources            Non-Resource URLs  Resource Names  Verbs
  ---------            -----------------  --------------  -----
  pods.metrics.k8s.io  []                 []              [get list watch]
valyan@valyan-pc:~$ k describe clusterrolebindings.rbac.authorization.k8s.io namespace-metrics
Name:         namespace-metrics
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  metrics-role
Subjects:
  Kind            Name                 Namespace
  ----            ----                 ---------
  ServiceAccount  homework-monitoring  homework
  

```
</details>

deployment и его поды:  

<details>

```bash

valyan@valyan-pc:~$ k describe deployments.apps -n homework test-deployment-2 
Name:                   test-deployment-2
Namespace:              homework
CreationTimestamp:      Sat, 30 Nov 2024 16:18:09 +0300
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               homework=true
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 25% max surge
Pod Template:
  Labels:           homework=true
  Service Account:  homework-monitoring
  Init Containers:
   install:
    Image:      busybox:1.28
    Port:       <none>
    Host Port:  <none>
    Command:
      wget
      -O
      /init/index.html
      http://info.cern.ch
    Limits:
      cpu:     500m
      memory:  256Mi
    Requests:
      cpu:        250m
      memory:     128Mi
    Environment:  <none>
    Mounts:
      /init from workdir (rw)
   extract-metrics:
    Image:      curlimages/curl:latest
    Port:       <none>
    Host Port:  <none>
    Command:
      sh
      -c
    Args:
      sleep 60 && curl --cacert ${CA_CERT} --header "Authorization: Bearer $(cat ${TOKEN})" -X GET ${KUBEAPI}/apis/metrics.k8s.io/v1beta1/namespaces/"$(cat ${NAMESPACE})"/pods -o /init/metrics.html
    Limits:
      cpu:     500m
      memory:  256Mi
    Requests:
      cpu:     250m
      memory:  128Mi
    Environment:
      TOKEN:      /var/run/secrets/kubernetes.io/serviceaccount/token
      CA_CERT:    /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      KUBEAPI:    https://192.168.49.2:8443
      NAMESPACE:  /var/run/secrets/kubernetes.io/serviceaccount/namespace
    Mounts:
      /init from workdir (rw)
  Containers:
   nginx:
    Image:      nginx
    Port:       80/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     1
      memory:  512Mi
    Requests:
      cpu:        500m
      memory:     256Mi
    Environment:  <none>
    Mounts:
      /etc/nginx/conf.d from nginx-config (rw)
      /homework from workdir (rw)
      /homework/conf from configfile (rw)
  Volumes:
   workdir:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  test-pvc
    ReadOnly:   false
   configfile:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      test-cm-1
    Optional:  false
   nginx-config:
    Type:          ConfigMap (a volume populated by a ConfigMap)
    Name:          nginx-cm
    Optional:      false
  Node-Selectors:  <none>
  Tolerations:     <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   test-deployment-2-86c584dcc8 (3/3 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  4m29s  deployment-controller  Scaled up replica set test-deployment-2-86c584dcc8 to 3



 valyan@valyan-pc:~$ k get po -n homework 
NAME                                 READY   STATUS    RESTARTS   AGE
test-deployment-2-86c584dcc8-5wnjc   1/1     Running   0          15m
test-deployment-2-86c584dcc8-plnhl   1/1     Running   0          15m
test-deployment-2-86c584dcc8-rcjb8   1/1     Running   0          15m
 
```
</details>

Нужные обьекты созданы, теперь нужно проверить, что init-container отработал корректно и отдал по ендпоинту файл с метриками, для этого включаем minikube tunnel:


<details>

```bash

valyan@valyan-pc:~$ minikube tunnel
[sudo] password for valyan: 
Status:	
	machine: minikube
	pid: 354865
	route: 10.96.0.0/12 -> 192.168.49.2
	minikube: Running
	services: []
    errors: 
		minikube: no errors
		router: no errors
		loadbalancer emulator: no errors

```
</details>

И переходим в адресной строке браузера по адресу http://homework.otus/metrics.html:

![img_1.png](screenshots/img_1.png)  

Содержимое файла так же можно увидеть при обращении к ендпоинту целевых подов сервиса внутри кластера используя внутренний ip сервиса в кластере:  

<details>

```bash
root@test-deployment-2-86c584dcc8-5wnjc:/# curl http://10.105.138.80:8000/metrics.html
{
  "kind": "PodMetricsList",
  "apiVersion": "metrics.k8s.io/v1beta1",
  "metadata": {},
  "items": [
    {
      "metadata": {
        "name": "test-deployment-2-86c584dcc8-plnhl",
        "namespace": "homework",
        "creationTimestamp": "2024-11-30T13:19:19Z",
        "labels": {
          "homework": "true",
          "pod-template-hash": "86c584dcc8"
        }
      },
      "timestamp": "2024-11-30T13:18:49Z",
      "window": "34.475s",
      "containers": [
        {
          "name": "extract-metrics",
          "usage": {
            "cpu": "429151n",
            "memory": "408Ki"
          }
        }
      ]
    }
  ]

```
</details>


Содержимое файла:
<details>

```bash

{ "kind": "PodMetricsList", "apiVersion": "metrics.k8s.io/v1beta1", "metadata": {}, "items": [ { "metadata": { "name": "test-deployment-2-86c584dcc8-plnhl", "namespace": "homework", "creationTimestamp": "2024-11-30T13:19:19Z", "labels": { "homework": "true", "pod-template-hash": "86c584dcc8" } }, "timestamp": "2024-11-30T13:18:49Z", "window": "34.475s", "containers": [ { "name": "extract-metrics", "usage": { "cpu": "429151n", "memory": "408Ki" } } ] } ] }
```
</details>

Для генерации токена будем использовать стандартный функционал:  

<details>

```bash
valyan@valyan-pc:~$ k create token -n homework homework-admin --duration=86400s
eyJhbGciOiJSUzI1NiIsImtpZCI6IkNvbEZXdEphYll6aUluYzFGNi1FQkdhVUZfelpkVXNWamlhNDdCV3BCb0kifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzMzMDYwMDkzLCJpYXQiOjE3MzI5NzM2OTMsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiMzQ4ZWJhYjgtYWY5Yi00NTA1LTkzYmYtNzA3YWZmOTg1M2M4Iiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJob21ld29yayIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJob21ld29yay1hZG1pbiIsInVpZCI6IjUxMGRlMTdkLTc2NjUtNDkwYS04ZGFiLWYzMTk2ZGVjOGY1MiJ9fSwibmJmIjoxNzMyOTczNjkzLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6aG9tZXdvcms6aG9tZXdvcmstYWRtaW4ifQ.kmEjtm0Co535uU6dqxDb2KwEM4nIJC9m6ehd1oWTulmA-rHFKeDlKCcQn6lreZq5r0P0deiqqyv6LdLOXgzj109B-LaMap3I9tfpNaBMKdTsIUnP5Yt1jk-TgdNY62_dBv6cjo4XmnUrTlrKO2AcKtFoeskiyD4OuMlTBotLGzrh7ZPjOrroh8f9eIVbR-ZdPxgt3nBo0s-BRO2Q37eWY63z-VX13CeHQyjf55gEXVA543IpzG9mfmCBo-Aael3Rv0kCRECwbdVZvmXChStWubli6-elHWeKNTHishKAJpxgP2zF6OWQVgD8uNvArRjgyBJ14JNnSVYmP0lGN2Rt4Q
```
</details>


В JWT.IO  в PAYLOAD:DATA можно увидеть полезное содержимое получившегося токена:  


<details>

```bash
{
  "aud": [
    "https://kubernetes.default.svc.cluster.local"
  ],
  "exp": 1733060093,
  "iat": 1732973693,
  "iss": "https://kubernetes.default.svc.cluster.local",
  "jti": "348ebab8-af9b-4505-93bf-707aff9853c8",
  "kubernetes.io": {
    "namespace": "homework",
    "serviceaccount": {
      "name": "homework-admin",
      "uid": "510de17d-7665-490a-8dab-f3196dec8f52"
    }
  },
  "nbf": 1732973693,
  "sub": "system:serviceaccount:homework:homework-admin"
}
```
</details>


Кубконфиг будем собирать вручную добавив соответствующий токен и ca сервера  в base64 формате в целевые поля    
