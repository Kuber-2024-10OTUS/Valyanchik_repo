
Для начала работы необходимо запустить миникуб (или подключиться к работающему кластеру)

Перейдя в директорию из корня проекта kubernetes-templating запускаем генерацию шаблона манифестов приложения из ДЗ5:  


Весь вывод  получившегося манифеста обьектов в релизе лежит в файле template.yaml:
![template.yaml](template.yaml)
Краткий вывод из консоли:  
<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating$ helm upgrade homework6   ./templating   --install --dry-run   -n homework
Release "homework6" does not exist. Installing it now.
NAME: homework6
LAST DEPLOYED: Tue Dec  3 16:10:30 2024
NAMESPACE: homework
STATUS: pending-install
REVISION: 1
TEST SUITE: None
HOOKS:
MANIFEST:

```
</details>

Т.е мы сгенерировали параметризированный манифест приложения из ДЗ5 вынеся некоторые из его параметров в переменные, разница с ДЗ5, например в том, что реплик основного пода не 3 а 2 и отключена проба проверки готовности

Помимо деплоя основного приложения в релиз так же деплоится приложение из зависимого чарта, в даном случае redis(полный вывод манифеста в файле template.yanl):

<details>

```bash
# Source: kubernetes-templating/charts/redis/templates/controller.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: homework6-redis

```
</details>

Для того, чтобы в релиз установилось приложение из зависимости, его необходимо добавить в файл Chart.yaml основного приложения:  

dependencies:  
- name: redis  
  version: 1.4.0  
  repository: https://charts.pascaliske.dev  

И на машине, с которой будет осуществляться деплой добавить репозиторий с сабчартом, обновить его и построить зависимости перед деплоем:  
<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating/templating$ helm repo add pascaliske https://charts.pascaliske.dev
"pascaliske" has been added to your repositories
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating/templating$ helm repo list
NAME      	URL                          
pascaliske	https://charts.pascaliske.dev
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating/templating$ helm dependency build
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "pascaliske" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading redis from repo https://charts.pascaliske.dev
Deleting outdated charts
```
</details>
После чего распаковать получившейся архив .tgz в директорию charts основного чарта  

В дополнении к деплою в консоль выводится информационное сообщение благодаря наличию в основном чарте механизма NOTES.txt:  

<details>

```bash
NOTES:  
1. Get the application URL by running these commands:  
echo "Visit http://homework.otus:30080/homepage to use your application"  
```
</details>

Для задания 2 необходимо установить инструмент helmfile:  
Качаем последнюю версию из:  
https://github.com/helmfile/helmfile/releases/download/v1.0.0-rc.7/helmfile_1.0.0-rc.7_linux_amd64.tar.gz  
И из распакованного архива перемещаем бинарник в /usr/local/bin (или аналоги в другитх ОС)  

Версии компонентов берем из официальных источников:  
https://github.com/helmfile/helmfile/releases    
https://hub.docker.com/r/bitnamicharts/kafka/tags    

После чего набрасываем структуру helmfile и  values под каждый релиз:   

<details>

```bash
##helmfile.yaml
releases:
  - name: kafka-prod
    chart: oci://registry-1.docker.io/bitnamicharts/kafka 
    version: 31.0.0
    namespace: prod
    values:
      - values-prod.yaml

  - name: kafka-dev
    chart: oci://registry-1.docker.io/bitnamicharts/kafka 
    version: 31.0.0
    namespace: dev
    values:
      - values-dev.yaml

##values-dev.yaml
controller:
  replicaCount: 1
image:
  tag: "3.9.0" 
auth:
  enabled: false
externalAccess:
  enabled: false
service:
  type: ClusterIP

##values-prod.yaml
controller:
  replicaCount: 5
image:
  tag: "3.5.2"
auth:
  enabled: true
  sasl:
    enabled: true
    mechanism: PLAIN
externalAccess:
  enabled: false
service:
  type: ClusterIP
readinessProbe:
  tcpSocket:
    port: 9092
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```
</details>

После чего запускаем helmfile init и helmfile apply (вывод лежит в ![stdout-helmfile.yaml](stdout-helmfile.yaml) ), по итогам получается:

<details>

```bash
UPDATED RELEASES:
NAME         NAMESPACE   CHART                                            VERSION   DURATION
kafka-prod   prod        oci://registry-1.docker.io/bitnamicharts/kafka   31.0.0          2s
kafka-dev    dev         oci://registry-1.docker.io/bitnamicharts/kafka   31.0.0          2s
```
</details>

Сам список релизов так же отображается в стандартном helm:  
<details>

```bash

valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating$ helm list -A
NAME      	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART       	APP VERSION
kafka-dev 	dev      	1       	2024-12-03 17:03:06.505025715 +0300 MSK	deployed	kafka-31.0.0	3.9.0      
kafka-prod	prod     	1       	2024-12-03 17:03:06.50596164 +0300 MSK 	deployed	kafka-31.0.0	3.9.0 
```
</details>


Сами обьекты можно посмотреть при помощи kubectl или lens:  

<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating$ k get all -n prod
NAME                          READY   STATUS    RESTARTS   AGE
pod/kafka-prod-controller-0   1/1     Running   0          3m53s
pod/kafka-prod-controller-1   1/1     Running   0          3m53s
pod/kafka-prod-controller-2   1/1     Running   0          3m53s
pod/kafka-prod-controller-3   1/1     Running   0          3m53s
pod/kafka-prod-controller-4   1/1     Running   0          3m53s

NAME                                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/kafka-prod                       ClusterIP   10.107.218.209   <none>        9092/TCP                     3m53s
service/kafka-prod-controller-headless   ClusterIP   None             <none>        9094/TCP,9092/TCP,9093/TCP   3m53s

NAME                                     READY   AGE
statefulset.apps/kafka-prod-controller   5/5     3m53s
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating$ k get all -n dev
NAME                         READY   STATUS    RESTARTS   AGE
pod/kafka-dev-controller-0   1/1     Running   0          3m57s

NAME                                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/kafka-dev                       ClusterIP   10.108.115.209   <none>        9092/TCP                     3m57s
service/kafka-dev-controller-headless   ClusterIP   None             <none>        9094/TCP,9092/TCP,9093/TCP   3m57s

NAME                                    READY   AGE
statefulset.apps/kafka-dev-controller   1/1     3m57s
```
</details>


Не забываем почистить кубер от релизов:
<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating$ helm uninstall -n dev kafka-dev
release "kafka-dev" uninstalled
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating$ helm uninstall -n prod kafka-prod
release "kafka-prod" uninstalled
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-templating$ helm list -A
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION
```
</details>


