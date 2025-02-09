Для основного задания понадобятся 4 ноды: 1 мастер и 3 воркера, поднимаем набор нод при помощи terraform и получаем их список:   


<details>

```bash

valyan@valyan-pc:~$ yc compute instance list
+----------------------+---------------------+---------------+---------+----------------+---------------+
|          ID          |        NAME         |    ZONE ID    | STATUS  |  EXTERNAL IP   |  INTERNAL IP  |
+----------------------+---------------------+---------------+---------+----------------+---------------+
| fhm3af3hqr97oo3dlta4 | kubernetes-worker-3 | ru-central1-a | RUNNING | 158.160.55.217 | 192.168.10.15 |
| fhm50bl02guutk8n67dg | kubernetes-worker-2 | ru-central1-a | RUNNING | 158.160.32.106 | 192.168.10.10 |
| fhmot3jhtnfija046682 | kubernetes-master-1 | ru-central1-a | RUNNING | 51.250.15.138  | 192.168.10.30 |
| fhmti6og834epbh47kqg | kubernetes-worker-1 | ru-central1-a | RUNNING | 158.160.50.243 | 192.168.10.23 |
+----------------------+---------------------+---------------+---------+----------------+---------------+

```
</details>

Подключаемся на мастер-ноду и поэтапно по гайду настраиваем используя следующий набор команд: 

<details>

```bash

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay

sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

sudo mkdir -m 755 /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo apt update

sudo apt install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

sudo apt install -y kubelet kubeadm kubectl containerd

sudo apt-mark hold kubelet kubeadm kubectl

sudo mkdir -p /etc/containerd/
##здесь не дает из-за пермишенов сгенерить конфиг напрямую в целевую папку, нужен костыль через копирование
sudo containerd config default > config.toml

sudo cp config.toml > /etc/containerd/config.toml

CONFIG_FILE="/etc/containerd/config.toml"

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' "$CONFIG_FILE"

systemctl restart containerd

sudo kubeadm init --pod-network-cidr=172.16.0.0/16

sudo mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

```
</details>

По итогам получаем настроенную мастер-ноду с версией кубера 1.29, среди всего прочего нас интересует строка для подключения ноды к кластеру:  

<details>

```bash

[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.10.32:6443 --token uuic62.vwzs73yhruiiib9l \
	--discovery-token-ca-cert-hash sha256:a51fe0399695e95851f8a2b003898437b09356d342f7b56ca64c30a41019d9f4 

  Your Kubernetes control-plane has initialized successfully!


```
</details>

По итогам в кластере отображается одна нода:  

<details>

```bash
NAME                   STATUS   ROLES           AGE    VERSION
fhmi85a431g07s0k3bpr   Ready    control-plane   4m2s   v1.29.13

```
</details>

Забираем строчку подключения и идем настраивать и поочередно добавлять к кластеру наши воркеры, набор команд для каждого воркера примерно следудющий:  

<details>

```bash

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay

sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

sudo mkdir -m 755 /etc/apt/keyrings

sudo apt update

sudo apt install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

sudo apt install -y kubelet kubeadm kubectl containerd

sudo apt-mark hold kubelet kubeadm kubectl

sudo mkdir -p $HOME/.kube

sudo mkdir -p /etc/containerd/

##здесь не дает из-за пермишенов сгенерить конфиг напрямую в целевую папку, нужен костыль через копирование
sudo containerd config default > config.toml

sudo cp config.toml > /etc/containerd/config.toml

CONFIG_FILE="/etc/containerd/config.toml"

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' "$CONFIG_FILE"

systemctl restart containerd

```
</details>

Воркер нода настроена, добавляем ее в кластер:    

<details>

```bash 

valyan@fhmp6b09umjs10bd78q2:~$ sudo kubeadm join 192.168.10.32:6443 --token uuic62.vwzs73yhruiiib9l     --discovery-token-ca-cert-hash sha256:a51fe0399695e95851f8a2b003898437b09356d342f7b56ca64c30a41019d9f4
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.
Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

```
</details>

Нода добавлена, теперь на мастере ее можно увидеть в списке:  

<details>

```bash 

valyan@fhmi85a431g07s0k3bpr:~$ kubectl get nodes
NAME                   STATUS   ROLES           AGE     VERSION
fhmi85a431g07s0k3bpr   Ready    control-plane   12m     v1.29.13
fhmp6b09umjs10bd78q2   Ready    <none>          4m57s   v1.29.13
```
</details>

навешиваем на ноду лейбл воркера:  

<details>

```bash 
valyan@fhmi85a431g07s0k3bpr:~$ kubectl label node fhmp6b09umjs10bd78q2 node-role.kubernetes.io/worker=worker
node/fhmp6b09umjs10bd78q2 labeled
valyan@fhmi85a431g07s0k3bpr:~$ kubectl get nodes
NAME                   STATUS   ROLES           AGE     VERSION
fhmi85a431g07s0k3bpr   Ready    control-plane   12m     v1.29.13
fhmp6b09umjs10bd78q2   Ready    worker          5m12s   v1.29.13
```
</details>


Проделываем аналогичные операции с остальными воркерами и получаем по итогам кластер из 4 нод (1 мастер  и 3 воркера):   

<details>

```bash  
valyan@fhmi85a431g07s0k3bpr:~$ kubectl get nodes -o wide
NAME                   STATUS   ROLES           AGE     VERSION    INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
fhm8nmid64llpl2rc1on   Ready    worker          4m49s   v1.29.13   192.168.10.3    <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://1.7.24
fhmi85a431g07s0k3bpr   Ready    control-plane   21m     v1.29.13   192.168.10.32   <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://1.7.24
fhmp6b09umjs10bd78q2   Ready    worker          13m     v1.29.13   192.168.10.33   <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://1.7.24
fhmudb7sp2f99ib31eoj   Ready    worker          56s     v1.29.13   192.168.10.8    <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://1.7.24
```
</details> 


При обновлении кластера для начала обновим мастер-ноду на версию 1.30 следующим набором команд:  

<details>

```bash  
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

sudo apt-cache madison kubeadm

kubeadm version

sudo apt-mark unhold kubeadm kubelet kubectl

sudo apt install -y kubeadm

sudo apt install -y kubelet kubectl

sudo apt-mark hold kubelet kubectl

sudo kubeadm upgrade node

kubectl uncordon k8s-master

```
</details> 

Версия 1.30 установлена на мастер-ноду:  

<details>

```bash 
valyan@fhmi85a431g07s0k3bpr:~$ kubectl get nodes
NAME                   STATUS   ROLES           AGE     VERSION
fhm8nmid64llpl2rc1on   Ready    worker          8m45s   v1.29.13
fhmi85a431g07s0k3bpr   Ready    control-plane   25m     v1.30.9
fhmp6b09umjs10bd78q2   Ready    worker          17m     v1.29.13
fhmudb7sp2f99ib31eoj   Ready    worker          4m52s   v1.29.13

```
</details> 

Далее поочередно обновляем каждую воркер-ноду следующим набором команд:  

<details>

```bash

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

sudo apt install -y kubelet kubeadm kubectl containerd

sudo apt-mark hold kubelet kubeadm kubectl

sudo mkdir -p $HOME/.kube

sudo mkdir -p /etc/containerd/

sudo sh -c "containerd config default > /etc/containerd/config.toml"

sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd.service

sudo apt install -y kubeadm

sudo apt install -y kubelet kubectl

sudo apt-mark hold kubelet kubectl kubeadm

sudo systemctl daemon-reload

sudo systemctl restart kubelet

```
</details> 

После чего делаем uncordon воркер-ноды и проделываем аналогичные операции на оставшихся воркерах, по итогам получаем список обновленных на версию 1.30 нод:      

<details>

```bash
valyan@fhmi85a431g07s0k3bpr:~$ kubectl get nodes -o wide
NAME                   STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
fhm8nmid64llpl2rc1on   Ready    worker          39m   v1.30.9   192.168.10.3    <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://1.7.24
fhmi85a431g07s0k3bpr   Ready    control-plane   55m   v1.30.9   192.168.10.32   <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://1.7.24
fhmp6b09umjs10bd78q2   Ready    worker          48m   v1.30.9   192.168.10.33   <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://1.7.24
fhmudb7sp2f99ib31eoj   Ready    worker          35m   v1.30.9   192.168.10.8    <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://1.7.24

```
</details> 

При создании кластера при помощи kubespray понадобится обновленный состав нод:
- 3 мастера  
- 3 воркера  
- 1 управляющая машина для ансибла  

Создаем их так же при помощи terraform:  

<details>

```bash
valyan@valyan-pc:~/proj/kubespray$ yc compute instance list
+----------------------+---------------------+---------------+---------+----------------+---------------+
|          ID          |        NAME         |    ZONE ID    | STATUS  |  EXTERNAL IP   |  INTERNAL IP  |
+----------------------+---------------------+---------------+---------+----------------+---------------+
| fhmi364jn9c0i8g188lt | kubernetes-worker-3 | ru-central1-a | RUNNING | 158.160.39.220 | 192.168.10.29 |
| fhmi3udd69hfjhr95fqq | kubernetes-master-3 | ru-central1-a | RUNNING | 158.160.61.149 | 192.168.10.37 |
| fhmkc2br2b1hfgrm3p0q | kubernetes-master-2 | ru-central1-a | RUNNING | 130.193.48.12  | 192.168.10.30 |
| fhmo2fb95rjphskh0234 | kubernetes-master-1 | ru-central1-a | RUNNING | 51.250.65.158  | 192.168.10.10 |
| fhmrf3q7lp93rd8p4t2b | kubernetes-worker-1 | ru-central1-a | RUNNING | 158.160.49.49  | 192.168.10.4  |
| fhmsgt0b3lqob0879b7o | kubernetes-worker-2 | ru-central1-a | RUNNING | 89.169.142.203 | 192.168.10.9  |
| fhmtrub6t5aipann0duq | kubernetes-control1 | ru-central1-a | RUNNING | 158.160.50.216 | 192.168.10.8  |
+----------------------+---------------------+---------------+---------+----------------+---------------+

```
</details> 

Просто так плейбук кубспрея запустить не получится, нужно предварительно подготовить управляющую ноду, а именно:  

<details>

```bash
##Качаем плейбук на управляющую ноду
git clone https://github.com/kubernetes-sigs/kubespray.git
##устанавливаем pipx, т.к из deb-репозитория подтянется версия ансибла 2.16.3, минимально необходимая для куб-спрея 2.16.4, ставим ее при помощи pipx
sudo apt install pipx
pipx install ansible-core==2.16.4
##Доустанавливаем зависимости
pipx runpip ansible-core install -r requirements.txt
##Создаем инвентарный файл, добавляем туда локальные ip тачек 192.168.10.*, т.к по глобальным ip плейбук упадет на одной из тасок
nano ./inventory/inventory.ini
```
</details> 


После чего на управляющей ноде можно запускать установку плейбука при помощи  "ansible-playbook -i inventory/inventory.ini cluster.yml -b -v" , предварительно набросав файл-инвентаря:
![inventory.ini](inventory.ini)       


<details>

```bash

PLAY RECAP ***********************************************************************************************************************************************************************************
master-1                   : ok=626  changed=138  unreachable=0    failed=0    skipped=1065 rescued=0    ignored=6   
master-2                   : ok=538  changed=125  unreachable=0    failed=0    skipped=966  rescued=0    ignored=3   
master-3                   : ok=540  changed=126  unreachable=0    failed=0    skipped=964  rescued=0    ignored=3   
worker-1                   : ok=432  changed=86   unreachable=0    failed=0    skipped=669  rescued=0    ignored=1   
worker-2                   : ok=432  changed=86   unreachable=0    failed=0    skipped=667  rescued=0    ignored=1   
worker-3                   : ok=432  changed=86   unreachable=0    failed=0    skipped=667  rescued=0    ignored=1   

Sunday 09 February 2025  08:37:44 +0000 (0:00:00.150)       0:24:50.024 ******* 
=============================================================================== 

```
</details> 

По итогам установку плейбук развернет кластер из 6 нод:  

<details>

```bash
valyan@master-1:/etc/kubernetes$ sudo mkdir -p $HOME/.kube
valyan@master-1:/etc/kubernetes$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
valyan@master-1:/etc/kubernetes$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
valyan@master-1:/etc/kubernetes$ export KUBECONFIG=$HOME/.kube/config
valyan@master-1:/etc/kubernetes$ kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
master-1   Ready    control-plane   17m   v1.32.0   192.168.10.10   <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://2.0.2
master-2   Ready    control-plane   16m   v1.32.0   192.168.10.30   <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://2.0.2
master-3   Ready    control-plane   16m   v1.32.0   192.168.10.37   <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://2.0.2
worker-1   Ready    <none>          16m   v1.32.0   192.168.10.4    <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://2.0.2
worker-2   Ready    <none>          16m   v1.32.0   192.168.10.9    <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://2.0.2
worker-3   Ready    <none>          16m   v1.32.0   192.168.10.29   <none>        Ubuntu 24.04.1 LTS   6.8.0-51-generic   containerd://2.0.2
```
</details> 

Не забываем почистить после себя облако при помощи terraform destroy, иначе все денюшки гранта быстро растают (за +-1 час времени 7 виртуалок сожрали почти 100 рублей).  