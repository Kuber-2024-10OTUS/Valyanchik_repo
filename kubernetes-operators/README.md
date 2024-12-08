Питонячий код предложенного в ДЗ оператора:  
![files/mysql-operator.py](mysql-operator.py)

Применяем манифесты обьектов:  
<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k apply -f CRD.yaml -f RBAC.yaml  deployment.yaml 
deployment.apps/mysql-operator created
customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework created
serviceaccount/dba unchanged
clusterrole.rbac.authorization.k8s.io/dba-role unchanged
clusterrolebinding.rbac.authorization.k8s.io/dba-crb unchanged
error: resource mapping not found for name: "mysql-cr" namespace: "default" from "CR.yaml": no matches for kind "MySQL" in version "otus.homework/v1"
ensure CRDs are installed first
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k apply -f CR.yaml 
mysql.otus.homework/mysql-cr created
```
</details>

В логах пода оператора по выводу из консоли  'MySQL instance mysql-cr and its children resources created!'  видно, что процесс создания успешный:    
<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k logs -n homework mysql-operator-65c797f964-mjrf5 -f
/usr/local/lib/python3.10/site-packages/kopf/_core/reactor/running.py:179: FutureWarning: Absence of either namespaces or cluster-wide flag will become an error soon. For now, switching to the cluster-wide mode for backward compatibility.
  warnings.warn("Absence of either namespaces or cluster-wide flag will become an error soon."
[2024-12-08 13:10:47,864] kopf._core.engines.a [INFO    ] Initial authentication has been initiated.
[2024-12-08 13:10:47,866] kopf.activities.auth [INFO    ] Activity 'login_via_client' succeeded.
[2024-12-08 13:10:47,867] kopf._core.engines.a [INFO    ] Initial authentication has finished.
[2024-12-08 13:10:47,895] kopf._core.reactor.o [WARNING ] Not enough permissions to watch for resources: changes (creation/deletion/updates) will not be noticed; the resources are only refreshed on operator restarts.
[2024-12-08 13:10:47,925] kopf._cogs.clients.w [WARNING ] Receiving `too many requests` error from server, will retry after 1 seconds. Error details: ('storage is (re)initializing', {'kind': 'Status', 'apiVersion': 'v1', 'metadata': {}, 'status': 'Failure', 'message': 'storage is (re)initializing', 'reason': 'TooManyRequests', 'details': {'retryAfterSeconds': 1}, 'code': 429})
[2024-12-08 13:11:29,622] kopf.objects         [INFO    ] [default/mysql-cr] Creating pv, pvc for mysql data and svc...
[2024-12-08 13:11:29,663] kopf.objects         [INFO    ] [default/mysql-cr] Creating mysql deployment...
[2024-12-08 13:11:29,697] kopf.objects         [INFO    ] [default/mysql-cr] Waiting for mysql deployment to become ready...
[2024-12-08 13:11:39,721] kopf.objects         [INFO    ] [default/mysql-cr] MySQL instance mysql-cr and its children resources created!
[2024-12-08 13:11:39,725] kopf.objects         [INFO    ] [default/mysql-cr] Handler 'mysql_on_create' succeeded.
[2024-12-08 13:11:39,726] kopf.objects         [INFO    ] [default/mysql-cr] Creation is processed: 1 succeeded; 0 failed.
[2024-12-08 13:11:39,745] kopf.objects         [WARNING ] [default/mysql-cr] Patching failed with inconsistencies: (('remove', ('status',), {'mysql_on_create': {'message': 'MySQL instance mysql-cr and its children resources created!'}}, None),)
```
</details>

Описание манифестов обьектов:
 
<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k describe svc -n default mysql-cr 
Name:                     mysql-cr
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 app=mysql-cr
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       None
IPs:                      None
Port:                     <unset>  3306/TCP
TargetPort:               3306/TCP
Endpoints:                10.244.1.44:3306
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k describe pvc -n default mysql-cr-pvc 
Name:          mysql-cr-pvc
Namespace:     default
StorageClass:  standard
Status:        Bound
Volume:        mysql-cr-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      2Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       mysql-cr-658f4fb94b-vc4dk
Events:        <none>
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k describe pv mysql-cr-pv 
Name:            mysql-cr-pv
Labels:          pv-usage=mysql-cr
Annotations:     pv.kubernetes.io/bound-by-controller: yes
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    standard
Status:          Bound
Claim:           default/mysql-cr-pvc
Reclaim Policy:  Retain
Access Modes:    RWO
VolumeMode:      Filesystem
Capacity:        2Gi
Node Affinity:   <none>
Message:         
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /tmp/hostpath_pv/mysql-cr-pv/
    HostPathType:  
Events:            <none>
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k describe mss -n default mysql-cr 
Name:         mysql-cr
Namespace:    default
Labels:       <none>
Annotations:  kopf.zalando.org/last-handled-configuration:
                {"spec":{"database":"test_db1","image":"mysql:8.4.3","password":"qwer1235","storage_size":"2Gi"}}
API Version:  otus.homework/v1
Kind:         MySQL
Metadata:
  Creation Timestamp:  2024-12-08T12:47:43Z
  Finalizers:
    kopf.zalando.org/KopfFinalizerMarker
  Generation:        1
  Resource Version:  140206
  UID:               66880501-4881-4504-a84e-d92509648f72
Spec:
  Database:      test_db1
  Image:         mysql:8.4.3
  Password:      qwer1235
  storage_size:  2Gi
Events:
  Type   Reason   Age    From  Message
  ----   ------   ----   ----  -------
  Error  Logging  7m10s  kopf  Handler 'mysql_on_create' failed with an exception. Will retry.
Traceback (most recent call last):
  File "/usr/local/lib/python3.10/site-packages/kopf/_core/actions/execution.py", line 276, in execute_handler_once
    result = await invoke_handler(
  File "/usr/local/lib/python3.10/site-packages/kopf/_core/actions/execution.py", line 371, in invoke_handler
    result = await invocation.invoke(
  File "/usr/local/lib/python3.10/site-packages/kopf/_core/actions/invocation.py", line 139, in invoke
    await ...rivate', 'Content-Type': 'application/json', 'X-Kubernetes-Pf-Flowschema-Uid': 'c3c68be6-effb-4e8c-8707-1cf912d71138', 'X-Kubernetes-Pf-Prioritylevel-Uid': 'dfc12d89-4863-44c4-8dca-2a6febcabb8c', 'Date': 'Sun, 08 Dec 2024 12:47:43 GMT', 'Content-Length': '226'})
HTTP response body: {"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","message":"persistentvolumes \"mysql-cr-pv\" already exists","reason":"AlreadyExists","details":{"name":"mysql-cr-pv","kind":"persistentvolumes"},"code":409}
  Normal  Logging  7m10s  kopf  Creating pv, pvc for mysql data and svc...
  Normal  Logging  6m9s   kopf  Waiting for mysql deployment to become ready...
  Normal  Logging  6m9s   kopf  Creating pv, pvc for mysql data and svc...
  Normal  Logging  6m9s   kopf  Creating mysql deployment...
  Normal  Logging  5m59s  kopf  Waiting for mysql deployment to become ready...
  Normal  Logging  5m49s  kopf  Waiting for mysql deployment to become ready...
  Normal  Logging  5m39s  kopf  Waiting for mysql deployment to become ready...
  Normal  Logging  5m29s  kopf  Waiting for mysql deployment to become ready...
  Normal  Logging  5m19s  kopf  Waiting for mysql deployment to become ready...
  Normal  Logging  5m9s   kopf  Creation is processed: 1 succeeded; 0 failed.
  Normal  Logging  5m9s   kopf  MySQL instance mysql-cr and its children resources created!
  Normal  Logging  5m9s   kopf  Handler 'mysql_on_create' succeeded.
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k describe crd mysqls.otus.homework 
Name:         mysqls.otus.homework
Namespace:    
Labels:       <none>
Annotations:  <none>
API Version:  apiextensions.k8s.io/v1
Kind:         CustomResourceDefinition
Metadata:
  Creation Timestamp:  2024-12-08T10:57:50Z
  Generation:          1
  Resource Version:    133135
  UID:                 87862d42-1719-4c28-bcb8-0dc2d0a3947e
Spec:
  Conversion:
    Strategy:  None
  Group:       otus.homework
  Names:
    Kind:       MySQL
    List Kind:  MySQLList
    Plural:     mysqls
    Short Names:
      mss
    Singular:  mysqls
  Scope:       Namespaced
  Versions:
    Name:  v1
    Schema:
      openAPIV3Schema:
        Properties:
          Spec:
            Properties:
              Database:
                Type:  string
              Image:
                Type:  string
              Password:
                Type:  string
              storage_size:
                Type:  string
            Required:
              image
              database
              password
              storage_size
            Type:  object
        Type:      object
    Served:        true
    Storage:       true
Status:
  Accepted Names:
    Kind:       MySQL
    List Kind:  MySQLList
    Plural:     mysqls
    Short Names:
      mss
    Singular:  mysqls
  Conditions:
    Last Transition Time:  2024-12-08T10:57:50Z
    Message:               no conflicts found
    Reason:                NoConflicts
    Status:                True
    Type:                  NamesAccepted
    Last Transition Time:  2024-12-08T10:57:50Z
    Message:               the initial names have been accepted
    Reason:                InitialNamesAccepted
    Status:                True
    Type:                  Established
  Stored Versions:
    v1
Events:  <none>


```
</details>

при использовании предоставленного оператора и его шаблонов манифестов, обьекты для CR будут создаваться только в namespace default:

<details>

```bash

valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k get all -n default
NAME                            READY   STATUS    RESTARTS   AGE
pod/mysql-cr-658f4fb94b-vc4dk   1/1     Running   0          9m43s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP    28d
service/mysql-cr     ClusterIP   None         <none>        3306/TCP   9m43s

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mysql-cr   1/1     1            1           9m43s

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/mysql-cr-658f4fb94b   1         1         1       9m43s

```
</details>


При удалении mss (вновь созданного CR) оператор запускает сценарий очистки обьектов, созданных вместе с CR (PV,PVC,SVC,DEPLOYMENT):  

<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k delete mss mysql-cr 
mysql.otus.homework "mysql-cr" deleted
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k get all -n default
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   28d

[2024-12-08 12:58:32,540] kopf.objects         [INFO    ] [default/mysql-cr] MySQL instance mysql-cr and its children resources deleted!
[2024-12-08 12:58:32,544] kopf.objects         [INFO    ] [default/mysql-cr] Handler 'delete_object_make_backup' succeeded.
[2024-12-08 12:58:32,545] kopf.objects         [INFO    ] [default/mysql-cr] Deletion is processed: 1 succeeded; 0 failed.
[2024-12-08 12:58:32,566] kopf.objects         [WARNING ] [default/mysql-cr] Patching failed with inconsistencies: (('remove', ('status',), {'delete_object_make_backup': {'message': 'MySQL instance mysql-cr and its children resources deleted!'}}, None),)
```
</details>

Прав, прописанных в clusterrole хватает для работы с обьектами из ДЗ, всегда можно убрать или добавить:  
<details>

```bash
valyan@valyan-pc:~/proj/Valyanchik_repo/kubernetes-operators$ k describe clusterrole dba-role 
Name:         dba-role
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources                             Non-Resource URLs  Resource Names  Verbs
  ---------                             -----------------  --------------  -----
  mysqls.otus.homework                  []                 []              [get list create delete patch update watch]
  events                                []                 []              [get list create delete patch update]
  persistentvolumeclaims                []                 []              [get list create delete patch update]
  persistentvolumes                     []                 []              [get list create delete patch update]
  pods                                  []                 []              [get list create delete patch update]
  services                              []                 []              [get list create delete patch update]
  deployments.apps/status               []                 []              [get list create delete patch update]
  deployments.apps                      []                 []              [get list create delete patch update]
  deployments.otus.homework/status      []                 []              [get list create delete patch update]
  deployments.otus.homework             []                 []              [get list create delete patch update]
  events.otus.homework                  []                 []              [get list create delete patch update]
  persistentvolumeclaims.otus.homework  []                 []              [get list create delete patch update]
  persistentvolumes.otus.homework       []                 []              [get list create delete patch update]
  pods.otus.homework                    []                 []              [get list create delete patch update]
  services.otus.homework                []                 []              [get list create delete patch update]
  ```
</details>