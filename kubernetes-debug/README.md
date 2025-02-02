
Запускаем отладочный эфемерный контейнер для созданного пода (обязательная опция --profile='sysadmin', без нее не будет доступа к мастер-процессу целевого пода).
После чего можно получить доступ к корневой директории мастер-процесса целевого пода:   

<details>

```bash

valyan@valyan-pc:~$ kubectl debug nginx-distroless -it --profile='sysadmin' --image=busybox --target=nginx
Targeting container "nginx". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
Defaulting debug container name to debugger-46kdq.
If you don't see a command prompt, try pressing enter.
/ # ps -a
PID   USER     TIME  COMMAND
    1 root      0:00 nginx: master process nginx -g daemon off;
    7 101       0:00 nginx: worker process
    8 root      0:00 sh
   14 root      0:00 ps -a
/ # ls -lah /proc/1/root/etc/nginx
total 48K    
drwxr-xr-x    3 root     root        4.0K Oct  5  2020 .
drwxr-xr-x    1 root     root        4.0K Feb  2 10:49 ..
drwxr-xr-x    2 root     root        4.0K Oct  5  2020 conf.d
-rw-r--r--    1 root     root        1007 Apr 21  2020 fastcgi_params
-rw-r--r--    1 root     root        2.8K Apr 21  2020 koi-utf
-rw-r--r--    1 root     root        2.2K Apr 21  2020 koi-win
-rw-r--r--    1 root     root        5.1K Apr 21  2020 mime.types
lrwxrwxrwx    1 root     root          22 Apr 21  2020 modules -> /usr/lib/nginx/modules
-rw-r--r--    1 root     root         643 Apr 21  2020 nginx.conf
-rw-r--r--    1 root     root         636 Apr 21  2020 scgi_params
-rw-r--r--    1 root     root         664 Apr 21  2020 uwsgi_params
-rw-r--r--    1 root     root        3.5K Apr 21  2020 win-utf
```
</details>

Для возможности получения дампа необходимо запустить отладочный контейнер с необходимым набором утилит (первый попавшийся в гугле --image=hmarr/debug-tools подойдет):  
<details>

```bash
valyan@valyan-pc:~$ kubectl debug nginx-distroless -it --profile='sysadmin' --image=hmarr/debug-tools  --target=nginx
Targeting container "nginx". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
Defaulting debug container name to debugger-6n965.
If you don't see a command prompt, try pressing enter.
debug-nginx-:/# ss -tulpn
Netid  State      Recv-Q Send-Q                                               Local Address:Port                                                              Peer Address:Port              
tcp    LISTEN     0      511                                                              *:80                                                                           *:*                   users:(("nginx",pid=7,fd=6),("nginx",pid=1,fd=6))
debug-nginx-:/# curl localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
</details>

Как видно в выводе выше, запрос curl localhost возвращает дефолтную страничку nginx, которую отдает мастер-процесс целевого пода, дамп этого запроса можно просмотреть создав еще один отладочный контейнер рядом с образом, содержащим tcpdump утилиту(--image=corfr/tcpdump ):      

<details>

```bash
valyan@valyan-pc:~$ kubectl debug nginx-distroless -it --profile='sysadmin' --image=corfr/tcpdump  --target=nginx -- sh
Targeting container "nginx". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
Defaulting debug container name to debugger-6j6nw.
If you don't see a command prompt, try pressing enter.
/ # ps -a
PID   USER     TIME   COMMAND
    1 root       0:00 nginx: master process nginx -g daemon off;
    7 101        0:00 nginx: worker process
  110 root       0:00 sh
  116 root       0:00 ps -a
/ # ss -tulpn
sh: ss: not found
/ # tcpdump -nn -i any -e port 80
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on any, link-type LINUX_SLL (Linux cooked), capture size 262144 bytes
10:59:02.732229  In 00:00:00:00:00:00 ethertype IPv6 (0x86dd), length 96: ::1.33116 > ::1.80: Flags [S], seq 4122746108, win 65476, options [mss 65476,sackOK,TS val 2624042016 ecr 0,nop,wscale 7], length 0
10:59:02.732240  In 00:00:00:00:00:00 ethertype IPv6 (0x86dd), length 76: ::1.80 > ::1.33116: Flags [R.], seq 0, ack 4122746109, win 0, length 0
10:59:02.732293  In 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 76: 127.0.0.1.54796 > 127.0.0.1.80: Flags [S], seq 2788393255, win 65495, options [mss 65495,sackOK,TS val 2582569443 ecr 0,nop,wscale 7], length 0
10:59:02.732305  In 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 76: 127.0.0.1.80 > 127.0.0.1.54796: Flags [S.], seq 3047205174, ack 2788393256, win 65483, options [mss 65495,sackOK,TS val 2582569443 ecr 2582569443,nop,wscale 7], length 0
10:59:02.733680  In 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 306: 127.0.0.1.80 > 127.0.0.1.54796: Flags [P.], seq 1:239, ack 74, win 512, options [nop,nop,TS val 2582569444 ecr 2582569443], length 238: HTTP: HTTP/1.1 200 OK
10:59:02.733694  In 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 68: 127.0.0.1.54796 > 127.0.0.1.80: Flags [.], ack 239, win 511, options [nop,nop,TS val 2582569444 ecr 2582569444], length 0
10:59:02.733842  In 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 680: 127.0.0.1.80 > 127.0.0.1.54796: Flags [P.], seq 239:851, ack 74, win 512, options [nop,nop,TS val 2582569444 ecr 2582569444], length 612: HTTP
10:59:02.733852  In 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 68: 127.0.0.1.54796 > 127.0.0.1.80: Flags [.], ack 851, win 507, options [nop,nop,TS val 2582569444 ecr 2582569444], length 0
10:59:02.733961  In 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 68: 127.0.0.1.54796 > 127.0.0.1.80: Flags [F.], seq 74, ack 851, win 507, options [nop,nop,TS val 2582569444 ecr 2582569444], length 0
10:59:02.734000  In 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 68: 127.0.0.1.80 > 127.0.0.1.54796: Flags [F.], seq 851, ack 75, win 512, options [nop,nop,TS val 2582569444 ecr 2582569444], length 0
10:59:02.734021  In 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 68: 127.0.0.1.54796 > 127.0.0.1.80: Flags [.], ack 852, win 507, options [nop,nop,TS val 2582569444 ecr 2582569444], length 0

```
</details>

В данном дампе видны запросы из нашего отладочного контейнера с --image=hmarr/debug-tools

Процесс отладки ноды схож с отладкой пода, запускаем kubectl debug node/minikube -it --image=busybox --profile='sysadmin' и копаемся внутри файловой системы целевой ноды:  

<details>

```bash
/ # cd host
/host # ls
CHANGELOG     boot          docker.key    kic.txt       lib32         media         proc          sbin          tmp           version.json
Release.key   data          etc           kind          lib64         mnt           root          srv           usr
bin           dev           home          lib           libx32        opt           run           sys           var
/host # cd var/log
/host/var/log # ls -lah
total 28K    
drwxr-xr-x    4 root     root        4.0K Nov  9 13:11 .
drwxr-xr-x   14 root     root        4.0K Nov  9 13:11 ..
-rw-r--r--    1 root     root        3.3K Feb  2 09:45 alternatives.log
drwxr-xr-x    2 root     root       12.0K Feb  2 11:02 containers
drwxr-x---   16 root     root        4.0K Feb  2 11:01 pods
/host/var/log # cd pods
/host/var/log/pods # ls -lah
total 64K    
drwxr-x---   16 root     root        4.0K Feb  2 11:01 .
drwxr-xr-x    4 root     root        4.0K Nov  9 13:11 ..
drwxr-xr-x   12 root     root        4.0K Feb  2 10:58 default_nginx-distroless_7af96470-b98b-49d7-84cd-492e35757837
drwxr-xr-x    3 root     root        4.0K Feb  2 11:01 default_node-debugger-minikube-mnrgz_f4803b40-d2eb-4d13-b627-4fc2ee64b9a2
drwxr-xr-x    3 root     root        4.0K Feb  2 11:01 default_node-debugger-minikube-w6hcz_4db0d324-d5f4-4f91-9077-11ed1c6d9852
drwxr-xr-x    3 root     root        4.0K Nov 17 19:14 ingress-nginx_ingress-nginx-admission-create-wmthq_90fdc574-dc8e-4bca-b465-f5b27f868a51
drwxr-xr-x    3 root     root        4.0K Nov 17 19:14 ingress-nginx_ingress-nginx-admission-patch-w49q6_202ea396-e7b4-424a-a2df-befc3f55b10c
drwxr-xr-x    3 root     root        4.0K Nov 17 19:14 ingress-nginx_ingress-nginx-controller-bc57996ff-48q6v_5d961073-4633-4610-aeab-84eb2a7d1ba1
drwxr-xr-x    3 root     root        4.0K Nov  9 13:11 kube-system_coredns-6f6b679f8f-smbjs_f453c87a-e86b-4341-be31-87e141e87e5b
drwxr-xr-x    3 root     root        4.0K Nov  9 13:11 kube-system_etcd-minikube_a5363f4f31e043bdae3c93aca4991903
drwxr-xr-x    3 root     root        4.0K Nov  9 13:11 kube-system_kube-apiserver-minikube_9e315b3a91fa9f6f7463439d9dac1a56
drwxr-xr-x    3 root     root        4.0K Nov  9 13:11 kube-system_kube-controller-manager-minikube_40f5f661ab65f2e4bfe41ac2993c01de
drwxr-xr-x    3 root     root        4.0K Nov  9 13:11 kube-system_kube-proxy-qv7d8_db4e5e28-f2ff-46bd-9b08-509cc06daac8
drwxr-xr-x    3 root     root        4.0K Nov  9 13:11 kube-system_kube-scheduler-minikube_e039200acb850c82bb901653cc38ff6e
drwxr-xr-x    3 root     root        4.0K Nov 24 17:41 kube-system_metrics-server-84c5f94fbc-fxtc4_260dedaf-e4f0-417e-8463-5c0c84893521
drwxr-xr-x    3 root     root        4.0K Nov  9 13:11 kube-system_storage-provisioner_d5ffba7e-f8e1-43dd-8dfa-ab8d844e9f3a
```
</details>

Здесь нам нужен единственный не системный под default_nginx-distroless_7af96470-b98b-49d7-84cd-492e35757837 и основной контейнер nginx внутри него:     
<details>

```bash

/host/var/log/pods # cd default_nginx-distroless_7af96470-b98b-49d7-84cd-492e35757837
/host/var/log/pods/default_nginx-distroless_7af96470-b98b-49d7-84cd-492e35757837 # ls
debugger-46kdq  debugger-6j6nw  debugger-6n965  debugger-96n82  debugger-ftmbw  debugger-nbrrm  debugger-ps9fb  debugger-rm89j  debugger-sxvr4  nginx
/host/var/log/pods/default_nginx-distroless_7af96470-b98b-49d7-84cd-492e35757837 # cd nginx
/host/var/log/pods/default_nginx-distroless_7af96470-b98b-49d7-84cd-492e35757837/nginx # ls -lah
total 12K    
drwxr-xr-x    2 root     root        4.0K Feb  2 10:49 .
drwxr-xr-x   12 root     root        4.0K Feb  2 10:58 ..
lrwxrwxrwx    1 root     root         165 Feb  2 10:49 0.log -> /var/lib/docker/containers/29ed024c8c8986fd5512e5ac0e8cd5a6430cafa3fa89b6c0dd0432b57f9ff119/29ed024c8c8986fd5512e5ac0e8cd5a6430cafa3fa89b6c0dd0432b57f9ff119-json.log
```
</details>

Судя по выводу выше логи необходимого контейнера находятся на ноде по пути /var/lib/docker/containers/29ed024c8c8986fd5512e5ac0e8cd5a6430cafa3fa89b6c0dd0432b57f9ff119/29ed024c8c8986fd5512e5ac0e8cd5a6430cafa3fa89b6c0dd0432b57f9ff119-json.log.
Сделаем несколько curl-ов из соседнего отладочного контейнера и выведем содержимое файла с логами после:  

<details>

```bash
/host/var/log/pods/default_nginx-distroless_7af96470-b98b-49d7-84cd-492e35757837/nginx # cat /host/var/lib/docker/containers/29ed024c8c8986fd5512e5ac0e8cd5a6430cafa3fa89b6c0dd0432b57f9ff119/
29ed024c8c8986fd5512e5ac0e8cd5a6430cafa3fa89b6c0dd0432b57f9ff119-json.log 
{"log":"127.0.0.1 - - [02/Feb/2025:18:59:02 +0800] \"GET / HTTP/1.1\" 200 612 \"-\" \"curl/7.52.1\" \"-\"\n","stream":"stdout","time":"2025-02-02T10:59:02.73422533Z"}
{"log":"127.0.0.1 - - [02/Feb/2025:19:04:52 +0800] \"GET / HTTP/1.1\" 200 612 \"-\" \"curl/7.52.1\" \"-\"\n","stream":"stdout","time":"2025-02-02T11:04:52.977046683Z"}
{"log":"127.0.0.1 - - [02/Feb/2025:19:04:54 +0800] \"GET / HTTP/1.1\" 200 612 \"-\" \"curl/7.52.1\" \"-\"\n","stream":"stdout","time":"2025-02-02T11:04:54.176095523Z"}
{"log":"127.0.0.1 - - [02/Feb/2025:19:04:54 +0800] \"GET / HTTP/1.1\" 200 612 \"-\" \"curl/7.52.1\" \"-\"\n","stream":"stdout","time":"2025-02-02T11:04:54.708414025Z"}
{"log":"127.0.0.1 - - [02/Feb/2025:19:04:55 +0800] \"GET / HTTP/1.1\" 200 612 \"-\" \"curl/7.52.1\" \"-\"\n","stream":"stdout","time":"2025-02-02T11:04:55.180516755Z"}
```
</details>

Вывод команды strace:  
<details>

```bash
debug-nginx-:/# strace -p 1
strace: Process 1 attached
rt_sigsuspend([], 8

```
</details>