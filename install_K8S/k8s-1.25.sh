# kubernets v:1.25

## 部署前的准备工作

一、 安装容器运行时

二、 部署K8S

> 二进制方式部署
>
> 通过kubeadm部署
>
> 通过第三方软件部署
>
> 部署宿主(客户端)上（windows, mac Liunx ）  

三、 架构模式

1、 生产上的方式

2、 学习环境

环境规划：

![image-20230223115641710](/Users/abbott/Library/Application Support/typora-user-images/image-20230223115641710.png)

四、 部署要求（物理环境）

<font color=red>注意：所有节点都需要操作</font>

```shell
#修改主机名
hostnamectl set-hostname k8s-master
hostnamectl set-hostname k8s-node01
hostnamectl set-hostname k8s-node02
hostnamectl set-hostname k8s-node03
#关闭防火墙

#关闭selinux
#关闭swap分区
cat /etc/fstab
cp /etc/fstab  /etc/fstab.bak  
cat /etc/fstab.bak  | grep -v swap    >  /etc/fstab

#检查网络转发是否开启
[root@k8s-master ~]# sysctl -a | grep -w net.ipv4.ip_forward
 net.ipv4.ip_forward = 1
 #开启路由转发
[root@k8s-master ~]# cat > /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
[root@k8s-master ~]# sysctl -p /etc/sysctl.d/k8s.conf 

#配置模块
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
#加载模块
modprobe overlay
modprobe br_netfilter
#刷新内核
sysctl --system
#查看模块是否加载
lsmod | grep br_netfilter
lsmod | grep overlay

#升级内核
[root@k8s-master ~]# rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
[root@k8s-master ~]# rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
[root@k8s-master ~]# yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
[root@k8s-master ~]# yum --enablerepo=elrepo-kernel install kernel-ml
[root@k8s-master ~]# grub2-editenv list
[root@k8s-master ~]# cat /boot/grub2/grub.cfg | grep 'menuentry'
[root@k8s-master ~]# grub2-set-default 'CentOS Linux (6.2.0-1.el7.elrepo.x86_64) 7 (Core)'
```

五、安装容器运行时（所有节点） 

> https://github.com/kubernetes/kubernetes/blob/v1.25.0/CHANGELOG/CHANGELOG-1.25.md
>
> 安装前要查看k8s对应容器的版本信息

安装docker容器运行时

```shell
1. 安装yum工具
yum install -y yum-utils
2. 配置docker 源
yum-config-manager     --add-repo     https://download.docker.com/linux/centos/docker-ce.repo
3. 安装docker 引擎 （指定版本）
yum list docker-ce --showduplicates | sort -r   #列出docker版本
#安装指定版本
yum  -y install docker-ce-20.10.20-3.el7 docker-ce-cli-20.10.20-3.el7 containerd.io docker-buildx-plugin docker-compose-plugin
```

安装docker 的插件（cri-dockerd）

```shell
文档地址：
官方：https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
cri-docker 插件地址
官方地址： https://github.com/Mirantis/cri-dockerd

#安装cri-docker 
1.git golang
[root@k8s-master ~]# yum -y install git go 
2.clone 源代码
[root@k8s-master ~]# git clone https://github.com/Mirantis/cri-dockerd.git
3. 创建存放二进制文件
[root@k8s-master ~]# mkdir bin
4. 编译
[root@k8s-master ~]# go build -o bin/cri-dockerd
5 安装二进制启动脚本 
[root@k8s-node01 cri-dockerd-master]# install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
6. copy启动脚本
[root@k8s-node01 cri-dockerd-master]# cp -a packaging/systemd/* /etc/systemd/system
7. 修改启动脚本
[root@k8s-master system]# sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
6. 启动服务
[root@k8s-master system]# systemctl daemon-reload
[root@k8s-master system]# systemctl enable cri-docker.service
[root@k8s-master system]# systemctl enable --now cri-docker.socket
```

启动docker 

```shell
1. 修改配置文件
创建docker目录
[root@k8s-master ~]# mkdir /etc/docker
[root@k8s-master ~]# cat /etc/docker/daemon.json 
{
  "registry-mirrors": ["https://0pnfs8l6.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
2. 启动
[root@k8s-master ~]# systemctl daemon-reload
[root@k8s-master ~]# systemctl enable docker --now
3.同步所有节点
[root@k8s-master ~]# rsync /etc/docker/daemon.json  192.168.0.162:
[root@k8s-master ~]# rsync /etc/docker/daemon.json  192.168.0.163:
[root@k8s-master ~]# rsync /etc/docker/daemon.json  192.168.0.164:
4.启动所有节点docker
[root@k8s-master ~]# pssh  -h host  "systemctl daemon-reload && systemctl enable docker --now"
```

六、 部署K8S

> 使用kubeadm工具 来辅助部署K8S集群

1、 安装kubedm 命令

安装 kubeadm、kubelet 和 kubectl

你需要在每台机器上安装以下的软件包：

- `kubeadm`：用来初始化集群的指令。

- `kubelet`：在集群中的每个节点上用来启动 Pod 和容器等。

- `kubectl`：用来与集群通信的命令行工具。

- 安装k8s源

  > <font color=red>注意：官方源不可用，由于网络原因</font>

  ```shell
  #阿里源
  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
  [kubernetes]
  name=Kubernetes
  baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
  enabled=1
  gpgcheck=1
  repo_gpgcheck=1
  gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
  EOF
  
  #检查源是否可用
  yum repolist
  #k8s官方指定安装方法（最新版本）
  [root@k8s-master ~]# yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
  
  查看安装的版本
  [root@k8s-master ~]# yum --showduplicates list kubelet
  安装指定版本
  [root@k8s-master ~]# yum install -y --nogpgcheck kubelet-1.25.1-0  kubeadm-1.25.1-0  kubectl-1.25.1-0
  ```

2、 初始化K8S集群

> <font color=red>注意：因为网络原因：是不能拉取镜像</font>

```shell
kubeadm init --cri-socket unix:///var/run/cri-dockerd.sock
--cri-socket  #指定使用容器运行时的接口（docker）
--pod-network-cidr  #POd的网络
--kubernetes-version  #指定kubernetes版本
--image-repository   #指定仓库地址
```

2.1列出所使用的镜像版本及名称

```shell
[root@k8s-master ~]# kubeadm config images list --kubernetes-version=1.25.1
registry.k8s.io/kube-apiserver:v1.25.1
registry.k8s.io/kube-controller-manager:v1.25.1
registry.k8s.io/kube-scheduler:v1.25.1
registry.k8s.io/kube-proxy:v1.25.1
registry.k8s.io/pause:3.8
registry.k8s.io/etcd:3.5.4-0
registry.k8s.io/coredns/coredns:v1.9.3
```

2.2 拉取镜像

```shell
1. 你可以使用一台国外服务器  
2. 利用镜像仓库获取到相应镜像
- docker hub 
- 华为
- redhat
docker pull registry.aliyuncs.com/google_containers/kube-apiserver:v1.25.1
docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:v1.25.1
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:v1.25.1
docker pull registry.aliyuncs.com/google_containers/kube-proxy:v1.25.1
docker pull registry.aliyuncs.com/google_containers/pause:3.8
docker pull registry.aliyuncs.com/google_containers/etcd:3.5.4-0
docker pull registry.aliyuncs.com/google_containers/coredns:v1.9.3
docker pull registry.aliyuncs.com/google_containers/pause:3.6
```

2.2 给镜像打tag

```shell
docker tag registry.aliyuncs.com/google_containers/kube-apiserver:v1.25.1  registry.k8s.io/kube-apiserver:v1.25.1
docker tag registry.aliyuncs.com/google_containers/kube-controller-manager:v1.25.1 registry.k8s.io/kube-controller-manager:v1.25.1
docker tag registry.aliyuncs.com/google_containers/kube-scheduler:v1.25.1   registry.k8s.io/kube-scheduler:v1.25.1
docker tag registry.aliyuncs.com/google_containers/kube-proxy:v1.25.1   registry.k8s.io/kube-proxy:v1.25.1
docker tag registry.aliyuncs.com/google_containers/pause:3.8  registry.k8s.io/pause:3.8
docker tag registry.aliyuncs.com/google_containers/etcd:3.5.4-0   registry.k8s.io/etcd:3.5.4-0
docker tag registry.aliyuncs.com/google_containers/coredns:v1.9.3  registry.k8s.io/coredns/coredns:v1.9.3
docker tag registry.aliyuncs.com/google_containers/pause:3.6  registry.k8s.io/pause:3.6
```

2.3 删除原来镜像

```shell
docker rmi  registry.aliyuncs.com/google_containers/kube-apiserver:v1.25.1
docker rmi  registry.aliyuncs.com/google_containers/kube-controller-manager:v1.25.1
docker rmi  registry.aliyuncs.com/google_containers/kube-scheduler:v1.25.1
docker rmi  registry.aliyuncs.com/google_containers/kube-proxy:v1.25.1
docker rmi  registry.aliyuncs.com/google_containers/pause:3.8
docker rmi  registry.aliyuncs.com/google_containers/etcd:3.5.4-0
docker rmi  registry.aliyuncs.com/google_containers/coredns:v1.9.3
docker rmi registry.aliyuncs.com/google_containers/pause:3.6
```

2.4 最终效果：

```shell
[root@k8s-master ~]# docker images 
REPOSITORY                                TAG       IMAGE ID       CREATED        SIZE
registry.k8s.io/kube-apiserver            v1.25.1   b09a3dc327be   5 months ago   128MB
registry.k8s.io/kube-scheduler            v1.25.1   4df090352368   5 months ago   50.6MB
registry.k8s.io/kube-controller-manager   v1.25.1   4d904f9df20a   5 months ago   117MB
registry.k8s.io/kube-proxy                v1.25.1   3ed3cb68c861   5 months ago   61.7MB
registry.k8s.io/pause                     3.8       4873874c08ef   8 months ago   711kB
registry.k8s.io/etcd                      3.5.4-0   a8a176a5d5d6   8 months ago   300MB
registry.k8s.io/coredns/coredns           v1.9.3    5185b96f0bec   9 months ago   48.8MB
```

2.4 初始化集群

```shell
[root@k8s-master ~]# kubeadm  init   --cri-socket  unix:///var/run/cri-dockerd.sock --kubernetes-version=1.25.1 --pod-network-cidr 10.244.0.0/16
```

输出信息：

```shell
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

kubeadm join 192.168.0.161:6443 --token lzdfz8.064akf6yhnta91bc \
        --discovery-token-ca-cert-hash sha256:b891ebee26cbc7234033fd77ba34662a3cd9b5addb258acf1b858d8fd5720ef6
```

2.5 重置kubernetes集群

```shell
[root@k8s-master ~]# kubeadm  reset  --cri-socket unix:///var/run/cri-dockerd.sock
```

2.6 查看master节点

```shell
[root@k8s-master ~]# kubectl get nodes 
NAME         STATUS     ROLES           AGE   VERSION
k8s-master   NotReady   control-plane   12m   v1.25.1
```

2.7 加入工作节点

```shell
[root@k8s-node02 ~]# kubeadm join 192.168.0.161:6443 --token lzdfz8.064akf6yhnta91bc --discovery-token-ca-cert-hash sha256:b891ebee26cbc7234033fd77ba34662a3cd9b5addb258acf1b858d8fd5720ef6 --cri-socket unix:///var/run/cri-dockerd.sock
```

2.8 验证所有节点是否加入集群中

```shell
[root@k8s-master ~]# kubectl get nodes 
NAME         STATUS     ROLES           AGE     VERSION
k8s-master   NotReady   control-plane   26m     v1.25.1
k8s-node01   NotReady   <none>          4m34s   v1.25.1
k8s-node02   NotReady   <none>          2m22s   v1.25.1
k8s-node04   NotReady   <none>          70s     v1.25.1
```

三、 安装网络组件

> 所有网络模型：https://kubernetes.io/docs/concepts/cluster-administration/addons/
>
> 常见网络模型：[Calico](https://www.tigera.io/project-calico/) [Flannel](https://github.com/flannel-io/flannel#deploying-flannel-manually)

下载网络插件

```shell
wget https://docs.projectcalico.org/v3.25/manifests/calico.yaml
```

安装calico插件

```shell
kubectl apply -f calico.yaml
```

查看node节点

```shell
kubectl  get nodes -A 
[root@k8s-master ~]# kubectl get node -A 
NAME         STATUS   ROLES           AGE   VERSION
k8s-master   Ready    control-plane   73m   v1.25.1
k8s-node01   Ready    <none>          52m   v1.25.1
k8s-node02   Ready    <none>          49m   v1.25.1
k8s-node04   Ready    <none>          48m   v1.25.1

```



## Kubernetes 基本概念

> Kubernetes是一种由Google开发的开源容器编排调度系统，用于将容器化应用程序部署在集群上。Kubernetes可以自动运行、扩展和恢复容器化应用程序，并可以自动执行故障排除和滚动更新，从而提高应用程序的可用性和可靠性

## 架构模式

1、 单点集群

2、 高可用集群

### kubernetes 组件

```shell
Kubernetes Master、Kubernetes Node、Kubernetes etcd、Kubernetes Scheduler、Kubernetes Controller Manager、Kubernetes API、Kubernetes Kubelet 和Kubernetes CNI。
```

### master

架构图：

Kubernetes是一种分布式容器编排系统，它能够自动部署、扩展和管理容器化的应用程序。Kubernetes架构图如下所示：

> - etcd：etcd 是一个分布式键值存储，用来存储数据，以便在 Kubernetes 集群内的所有节点可以访问这些数据。
> - API Server：API 服务器提供一个 REST API，用于控制和配置集群内的各种资源。
> - Scheduler：它负责将用户的应用分配到集群中的节点上，以实现负载均衡。
> - Controller Manager：控制器管理器负责管理集群的状态，并实现自动化，例如自动扩展和节点运行状态的恢复等。
> - Kubelet：Kubelet 是 Kubernetes 节点的一个代理程序，它负责管理节点上的容器，并将其状态反馈给 Kubernetes 集群的其他组件。
> - Kube-Proxy：Kube-Proxy 是一个网络代理程序，它负责实现 Kubernetes 集群中的服务和容器之间的通信。

### node

架构图：



概述：

> KubernetesNode组件是Kubernetes的一个基础组件，它负责支持Kubernetes集群的节点管理，并确保Kubernetes集群中的所有节点都在正常工作状态。KubernetesNode组件负责监控Kubernetes集群中的节点，包括节点的CPU、内存、存储使用情况，并在发现异常情况时自动采取措施处理。此外，KubernetesNode组件还负责管理节点的镜像，以及节点上的Pod容器等

Kubernetes Node组件包括：

```shell
1.Kubelet：负责管理节点上的所有容器，并提供API供其他组件调用； 
2.Kube-Proxy：负责网络代理，提供负载均衡、服务发现和路由管理等功能； 
3.Container Runtime：负责接收Kubelet发来的指令，构建、运行容器；
4.CNI：负责网络控制，主要用于容器间的网络通信； 
5.Node Problem Detector：负责检测节点的可用性，以及收集节点的监控信息； 
6.Kubelet System Logs：收集Kubernetes节点系统日志； 
7.Kubelet Addon Manager：负责管理Kubernetes节点的插件和扩展。
```



### 工作负载

#### 1、Pod 的基本概念

官方文档：https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/

> Pod是kubernetes的最重要也最基本的概念。我们看到的每个Pod都有一个特殊的被称为”根容器“的Pause容器，Pause容器对应的镜像术语Kubernetes平台的一部分，除了Pause容器，每个Pod还包含一个或多个紧密相关的用户业务容器。

##### 什么是Pod

(1) 	Pod 是逻辑对象，能把一个或多个容器放在相同的网络名称空间与相同的IPC（Inter-Process Communication）环境下运行，

1. Pod管理

   Pod 是集群中部署应用最小单元，可以理解为一个Pod就是一个容器，但实际上，一个Pod可以使多个容器。学习Pod是为了后期编写应用时更方便、更清晰地进行配置。

   在生产环境中，很少对Pod进行直接创建和管理。通常使用Deployment控制器去管理Pod，这样就具备了调度、弹性伸缩、滚动更新等一系列特性。

2. pod 基本管理

   创建Pod对象需要先创建一个pod.yaml文件，在YAML文件中写入如下代码：

   ```yaml
   apiVersion: v1       # 指定API版本
   kind: Pod            # 创建对象
   metadata:						 # 对象元数据，标识对象资源，方便后期进行匹配查询
     name: nginx-pod    # 对象名称
     labels:            # 定义标签
       app: nginx
   
   spec:								# 描述对象具体关联容器等资源
     containers:				# 具体管理容器的配置情况
     - name: nginx     # 容器名称
       image: nginx:latest  # 定义使用的镜像
   ```

   

   有了yaml文件后，可以使用kubectl 命令进行Pod资源的创建，创建命令如下：

   ```shell
   [root@k8s-master damo]# kubectl create -f pod.yaml 
   pod/nginx-pot created
   ```

   Pod 资源创建成功后，使用 kubectl 命令可以查看刚刚创建的Pod，命令如下：

   ```SHELL
   [root@k8s-master damo]# kubectl get pods
   NAME                     READY   STATUS    RESTARTS   AGE
   nginx-pot                1/1     Running   0          8m37s
   ```


示例1. 创建一个Nginx Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
```

创建：

```shell
kubectl create -f  nginxexample.yaml 
kubectl apply -f {文件名}
```

输出结果：

```shell
pod/nginx created
```

查看Pod

```shell
kubectl get pods -A 
kubectl get pods -n default
#查看Pod详细信息
kubectl describe pod -n default
[root@k8s-master example]# kubectl get pods --namespace=default
```

> -n  名称空间
>
> -A  all

pod 的生命周期



在线更新Pod

```shell
[root@k8s-master example]# kubectl replace  -f  RS-example.yaml   --force
```

查看Pod的状态

```shell
root@k8s-master example]# kubectl get pods  -A  
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
default       frontend-5klkh                             1/1     Running   0          3m48s
default       frontend-klfqz                             1/1     Running   0          3m48s
default       frontend-sbwbz                             1/1     Running   0          3m48s
```

下面是 `phase` 可能的值：

| 取值                | 描述                                                         |
| :------------------ | :----------------------------------------------------------- |
| `Pending`（悬决）   | Pod 已被 Kubernetes 系统接受，但有一个或者多个容器尚未创建亦未运行。此阶段包括等待 Pod 被调度的时间和通过网络下载镜像的时间。 |
| `Running`（运行中） | Pod 已经绑定到了某个节点，Pod 中所有的容器都已被创建。至少有一个容器仍在运行，或者正处于启动或重启状态。 |
| `Succeeded`（成功） | Pod 中的所有容器都已成功终止，并且不会再重启。               |
| `Failed`（失败）    | Pod 中的所有容器都已终止，并且至少有一个容器是因为失败终止。也就是说，容器以非 0 状态退出或者被系统终止。 |
| `Unknown`（未知）   | 因为某些原因无法取得 Pod 的状态。这种情况通常是因为与 Pod 所在主机通信失败。 |

##### 容器状态

Kubernetes 会跟踪 Pod 中每个容器的状态，就像它跟踪 Pod 总体上的[阶段](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase)一样。 你可以使用[容器生命周期回调](https://kubernetes.io/zh-cn/docs/concepts/containers/container-lifecycle-hooks/) 来在容器生命周期中的特定时间点触发事件。

一旦[调度器](https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/kube-scheduler/)将 Pod 分派给某个节点，`kubelet` 就通过[容器运行时](https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes)开始为 Pod 创建容器。容器的状态有三种：`Waiting`（等待）、`Running`（运行中）和 `Terminated`（已终止）。

要检查 Pod 中容器的状态，你可以使用 `kubectl describe pod <pod 名称>`。 其输出中包含 Pod 中每个容器的状态。

每种状态都有特定的含义：

-  Waiting （等待）

> 如果容器并不处在 `Running` 或 `Terminated` 状态之一，它就处在 `Waiting` 状态。 处于 `Waiting` 状态的容器仍在运行它完成启动所需要的操作：例如， 从某个容器镜像仓库拉取容器镜像，或者向容器应用 [Secret](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/) 数据等等。 当你使用 `kubectl` 来查询包含 `Waiting` 状态的容器的 Pod 时，你也会看到一个 Reason 字段，其中给出了容器处于等待状态的原因。

- Running（运行中）

> `Running` 状态表明容器正在执行状态并且没有问题发生。 如果配置了 `postStart` 回调，那么该回调已经执行且已完成。 如果你使用 `kubectl` 来查询包含 `Running` 状态的容器的 Pod 时， 你也会看到关于容器进入 `Running` 状态的信息。

- Terminated（已终止）

> 处于 `Terminated` 状态的容器已经开始执行并且或者正常结束或者因为某些原因失败。 如果你使用 `kubectl` 来查询包含 `Terminated` 状态的容器的 Pod 时， 你会看到容器进入此状态的原因、退出代码以及容器执行期间的起止时间。

如果容器配置了 `preStop` 回调，则该回调会在容器进入 `Terminated` 状态之前执行。

##### 容器重启策略

> Pod 的 `spec` 中包含一个 `restartPolicy` 字段，其可能取值包括 Always、OnFailure 和 Never。默认值是 Always。
>
> `restartPolicy` 适用于 Pod 中的所有容器。`restartPolicy` 仅针对同一节点上 `kubelet` 的容器重启动作。当 Pod 中的容器退出时，`kubelet` 会按指数回退方式计算重启的延迟（10s、20s、40s、...），其最长延迟为 5 分钟。 一旦某容器执行了 10 分钟并且没有出现问题，`kubelet` 对该容器的重启回退计时器执行重置操作。



#### 2、Label  标签

概念：

```shell
标签（Labels） 是附加到 Kubernetes 对象（比如 Pod）上的键值对。 标签旨在用于指定对用户有意义且相关的对象的标识属性，但不直接对核心系统有语义含义。 标签可以用于组织和选择对象的子集。标签可以在创建时附加到对象，随后可以随时添加和修改。 每个对象都可以定义一组键/值标签。每个键对于给定对象必须是唯一的。
```

> 标签使用户能够以松散耦合的方式将他们自己的组织结构映射到系统对象，而无需客户端存储这些映射。
>
> 服务部署和批处理流水线通常是多维实体（例如，多个分区或部署、多个发行序列、多个层，每层多个微服务）。 管理通常需要交叉操作，这打破了严格的层次表示的封装，特别是由基础设施而不是用户确定的严格的层次结构。
>
> 示例标签：
>
> - **版本标签****:** "release":"stable", "release":"canary"...
> - **环境标签：** ”environment“:"tier","environment":"qa"
> - **架构标签：** ”tier“:"frontend"
> - **分区标签：**”partition“：”customerA“
> - **质量管控标签****:** ”track“:"daily"

示例：

描述： “给nginx应用打标签，定义开发环境”

```shell
[root@k8s-master example]# cat nginxexample.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:    # 标签
   environment: dev   #dev 环境
   app: nginx    # 应用nginx 
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
```

#### 3、ReplicationController

> 当 Pod 数量过多时，ReplicationController 会终止多余的 Pod。当 Pod 数量太少时，ReplicationController 将会启动新的 Pod。 与手动创建的 Pod 不同，由 ReplicationController 创建的 Pod 在失败、被删除或被终止时会被自动替换。 例如，在中断性维护（如内核升级）之后，你的 Pod 会在节点上重新创建。 因此，即使你的应用程序只需要一个 Pod，你也应该使用 ReplicationController 创建 Pod。 ReplicationController 类似于进程管理器，但是 ReplicationController 不是监控单个节点上的单个进程，而是监控跨多个节点的多个 Pod。

示例：

```shell
[root@k8s-master example]# cat rc-example.yml 
apiVersion: v1
kind: ReplicationController    #绑定RC的控制器
metadata:
  name: nginx-rc
spec:
  replicas: 4        #副本数
  selector:          #选择器
    app: nginx-rc    #选择的应用名称
  template:          #定义模版
    metadata:        #模版里的元数据
      name: nginx-rc #Pod的名称
      labels:        #标签
        app: nginx-rc  #应用： (Pod的名称)
    spec:
      containers:     #定义容器
      - name: nginx-rc
        image: nginx
        ports:
        - containerPort: 80

```

#### 4、Deployments

一个 Deployment 为 [Pod](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/) 和 [ReplicaSet](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/replicaset/) 提供声明式的更新能力。

你负责描述 Deployment 中的 **目标状态**，而 Deployment [控制器（Controller）](https://kubernetes.io/zh-cn/docs/concepts/architecture/controller/) 以受控速率更改实际状态， 使其变为期望状态。你可以定义 Deployment 以创建新的 ReplicaSet，或删除现有 Deployment， 并通过新的 Deployment 收养其资源。

用途：

> 以下是 Deployments 的典型用例：
>
> - [创建 Deployment 以将 ReplicaSet 上线](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/#creating-a-deployment)。ReplicaSet 在后台创建 Pod。 检查 ReplicaSet 的上线状态，查看其是否成功。
> - 通过更新 Deployment 的 PodTemplateSpec，[声明 Pod 的新状态](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/#updating-a-deployment) 。 新的 ReplicaSet 会被创建，Deployment 以受控速率将 Pod 从旧 ReplicaSet 迁移到新 ReplicaSet。 每个新的 ReplicaSet 都会更新 Deployment 的修订版本。
>
> - 如果 Deployment 的当前状态不稳定，[回滚到较早的 Deployment 版本](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)。 每次回滚都会更新 Deployment 的修订版本。
> - [扩大 Deployment 规模以承担更多负载](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment)。
> - [暂停 Deployment 的上线](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/#pausing-and-resuming-a-deployment) 以应用对 PodTemplateSpec 所作的多项修改， 然后恢复其执行以启动新的上线版本。
> - [使用 Deployment 状态](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/#deployment-status)来判定上线过程是否出现停滞。
> - [清理较旧的不再需要的 ReplicaSet](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/#clean-up-policy) 

示例：创建Deployments示例

```yaml
[root@k8s-master example]# cat deploy-example.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80

```

查看创建状态

```shell
1. kubectl get pods  #直接获取default名称空间下的Pod
2. kubectl get pods -A  #获取所有名称空间下的Pod
3. kubectl get  pods  -n|| --namespace={名称空间name}
4. kubectl get deployments    #可以使用控制器列出Pod
5. kubectl get  pods   -n default  -w  #实时观察default名称空间中的Pod的状态
```

在线升级

> 按照以下步骤更新 Deployment
>
> 先来更新 nginx Pod 以使用 `nginx:1.16.1` 镜像，而不是 `nginx:1.14.2` 镜像

```shell
kubectl set image deployment/nginx-deployment nginx=nginx:1.16.1
```

查看Pod images是否更新

```shell
kubectl describe pods nginx-deployment-68fc675d59-8r2xb -n default 
```

![image-20230227150055879](/Users/abbott/Library/Application Support/typora-user-images/image-20230227150055879.png)

### 服务、负载均衡和网络

#### 1、service

> Servcie 是kubernetes 的核心概念，通过创建Service 可以是一组相同功能的容器应用提供一个统一的入口地址，并且将请求负载发送到后段的各个容器应用上。

架构图：

![image-20230228112736318](/Users/abbott/Library/Application Support/typora-user-images/image-20230228112736318.png)

2、service 类型（发布服务）

以下4种类型：

> - `ClusterIP`：通过集群的内部 IP 暴露服务，选择该值时服务只能够在集群内部访问。 这也是你没有为服务显式指定 `type` 时使用的默认值。 你可以使用 [Ingress](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/) 或者 [Gateway API](https://gateway-api.sigs.k8s.io/) 向公众暴露服务。
> - [`NodePort`](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#type-nodeport)：通过每个节点上的 IP 和静态端口（`NodePort`）暴露服务。 为了让节点端口可用，Kubernetes 设置了集群 IP 地址，这等同于你请求 `type: ClusterIP` 的服务。
> - [`LoadBalancer`](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#loadbalancer)：使用云提供商的负载均衡器向外部暴露服务。 外部负载均衡器可以将流量路由到自动创建的 `NodePort` 服务和 `ClusterIP` 服务上。
> - [`ExternalName`](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#externalname)：通过返回 `CNAME` 记录和对应值，可以将服务映射到 `externalName` 字段的内容（例如，`foo.bar.example.com`）。 无需创建任何类型代理。

3、 示例1：默认代理`ClusterIP`

```yaml
[root@k8s-master svc]# cat nginx-svc.yml 
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app.kubernetes.io/name: proxy
spec:
  containers:
  - name: nginx
    image: nginx:stable
    ports:
      - containerPort: 80
        name: http-web-svc

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app.kubernetes.io/name: proxy
  ports:
  - name: name-of-service-port
    protocol: TCP
    port: 80
    targetPort: http-web-svc
 
# 创建servcie和Pod的应用
[root@k8s-master svc]# kubectl apply  -f nginx-svc.yml 
# 查看Pod,service的状态
[root@k8s-master svc]# kubectl get pods 
# 查看service 的状态
[root@k8s-master svc]# kubectl get service
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes      ClusterIP   10.96.0.1      <none>        443/TCP   3d20h
nginx-service   ClusterIP   10.105.40.79   <none>        80/TCP    47m
```

示例2: 

- 创建一个POD

  ```yaml
  [root@k8s-master example]# cat deploy-example.yaml 
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: nginx-deployment
    labels:
      app: nginx
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: nginx
    template:
      metadata:
        labels:
          app: nginx
      spec:
        containers:
        - name: nginx
          image: nginx:1.14.2
          ports:
          - containerPort: 80
  ```

- 创建service

  ```yaml
  [root@k8s-master svc]# cat svc-nginx.yaml 
  apiVersion: v1
  kind: Service
  metadata:
    name: nginx-svc
  spec:
    selector:
      app: nginx
    ports:
    - name: service-port
      protocol: TCP
      port: 80
  ```

- 创建nginx pod和service应用

  ```shell
  kubectl apply -f deploy-example.yaml 
  kubectl apply -f svc-nginx.yaml 
  ```

- 查看server，Pod 状态

  ```shell
  kubectl get pod,svc
  ```

  输出：

  ```shel
  [root@k8s-master svc]# kubectl get pod,svc
  NAME                                    READY   STATUS    RESTARTS   AGE
  pod/nginx-deployment-68fc675d59-8r2xb   1/1     Running   0          20h
  pod/nginx-deployment-68fc675d59-fc2tg   1/1     Running   0          20h
  pod/nginx-deployment-68fc675d59-w4475   1/1     Running   0          20h
  NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
  service/kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP   3d20h
  service/nginx-svc       ClusterIP   10.98.123.147   <none>        80/TCP    5m10s
  ```

  > 现在就可以在集群中通过访问 service的ClusterIP 地址访问服务

  3、NodePort 

  > 如果你将 `type` 字段设置为 `NodePort`，则 Kubernetes 控制平面将在 `--service-node-port-range` 标志指定的范围内分配端口（默认值：30000-32767）。 每个节点将那个端口（每个节点上的相同端口号）代理到你的服务中。 你的服务在其 `.spec.ports[*].nodePort` 字段中报告已分配的端口。
  >
  > 使用 NodePort 可以让你自由设置自己的负载均衡解决方案， 配置 Kubernetes 不完全支持的环境， 甚至直接暴露一个或多个节点的 IP 地址。

  示例1: 不指定端口号，随机产生端口号

  ```yaml
  [root@k8s-master svc]# vim svc-nginx.yaml 
  apiVersion: v1
  kind: Service
  metadata:
    name: nginx-svc
  spec:
    type: NodePort
    selector:
      app: nginx
    ports:
    - name: service-port
      protocol: TCP
      port: 80
  ```

  ![image-20230228145330582](/Users/abbott/Library/Application Support/typora-user-images/image-20230228145330582.png)



示例2:  指定端口号

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - name: service-port
    protocol: TCP
    port: 80
    nodePort: 31000
```

替换原来Pod 

```shell
[root@k8s-master svc]# kubectl replace -f svc-nginx.yaml --force
```

查看service 

```shell
[root@k8s-master svc]# kubectl  get  svc
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
kubernetes      ClusterIP   10.96.0.1        <none>        443/TCP        3d23h
nginx-service   ClusterIP   10.105.40.79     <none>        80/TCP         4h12m
nginx-svc       NodePort    10.102.134.112   <none>        80:31000/TCP   32s
```

### 安装dashboard

- 官方的

- 第三方

  `https://kuboard.cn`

获取官方dashboard: `https://github.com/kubernetes/dashboard`

1、 下载文件

```shell
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

2、 修改配置文件(默认是不能通外网IP访问)

```shell
[root@k8s-master dashboard]# vim recommended.yaml 
---

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  type: NodePort      #指定nodeport
  ports:
    - port: 443
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard

---
```

3、 应用文件

```shell
kubectl apply -f recommended.yaml
```

4、 查看状态

```shell
[root@k8s-master dashboard]# kubectl get pod,svc -n kubernetes-dashboard
```

> 1. 直接去相对应节点把镜像拉取
>
>    ```shell
>    在各自节点上拉取镜像（从docker hub 拉取）
>    docker pull kubernetesui/metrics-scraper:v1.0.8
>    docker pull kubernetesui/dashboard:v2.7.
>    ```
>
> 2. 修改yml文件

访问dashboard



#### 部署第三方kuboard：

官方地址：

## 部署监控

#### Promethues

官方地址：`https://prometheus.io`

部署方式： 系统层面上部署，容器形式部署

k8s 部署地址：https://github.com/prometheus-operator/prometheus-operator

部署步骤：

1. 想获取源代码

   ```shell
   git  clone  https://github.com/prometheus-operator/kube-prometheus.git
   ```

2. 修改配置文件

   1⃣️  展示UI界面

   - 修改grafana

     ```yaml
     [root@k8s-master manifests]# cat grafana-service.yaml
     apiVersion: v1
     kind: Service
     metadata:
       labels:
         app.kubernetes.io/component: grafana
         app.kubernetes.io/name: grafana
         app.kubernetes.io/part-of: kube-prometheus
         app.kubernetes.io/version: 9.3.6
       name: grafana
       namespace: monitoring
     spec:
       type: NodePort
       ports:
       - name: http
         port: 3000
         targetPort: http
         nodePort: 31500
       selector:
         app.kubernetes.io/component: grafana
         app.kubernetes.io/name: grafana
         app.kubernetes.io/part-of: kube-prometheus
     ```

   - 修改Prometheus

     ```yaml
     kind: Service
     metadata:
       labels:
         app.kubernetes.io/component: prometheus
         app.kubernetes.io/instance: k8s
         app.kubernetes.io/name: prometheus
         app.kubernetes.io/part-of: kube-prometheus
         app.kubernetes.io/version: 2.42.0
       name: prometheus-k8s
       namespace: monitoring
     spec:
       type: NodePort
       ports:
       - name: web
         port: 9090
         targetPort: web
       - name: reloader-web
         port: 8080
         targetPort: reloader-web
       selector:
         app.kubernetes.io/component: prometheus
         app.kubernetes.io/instance: k8s
         app.kubernetes.io/name: prometheus
         app.kubernetes.io/part-of: kube-prometheus
     ```

3. 创建名称空间

   ```shell
   [root@k8s-master manifests]# kubectl create  -f setup/
   customresourcedefinition.apiextensions.k8s.io/alertmanagerconfigs.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/probes.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/thanosrulers.monitoring.coreos.com created
   namespace/monitoring created
   ```

4. 查看是否已创建名称空间

   ```shell
   [root@k8s-master manifests]# kubectl get namespace -A
   NAME                   STATUS   AGE
   calico-system          Active   5d18h
   default                Active   5d19h
   kube-node-lease        Active   5d19h
   kube-public            Active   5d19h
   kube-system            Active   5d19h
   kubernetes-dashboard   Active   42h
   kuboard                Active   22h
   monitoring             Active   38s
   ```

5. 创建各种应用POD

   ```shell
   [root@k8s-master kube-prometheus]# kubectl apply -f manifests/
   alertmanager.monitoring.coreos.com/main created
   networkpolicy.networking.k8s.io/alertmanager-main created
   poddisruptionbudget.policy/alertmanager-main created
   prometheusrule.monitoring.coreos.com/alertmanager-main-rules created
   secret/alertmanager-main created
   service/alertmanager-main created
   serviceaccount/alertmanager-main created
   servicemonitor.monitoring.coreos.com/alertmanager-main created
   clusterrole.rbac.authorization.k8s.io/blackbox-exporter created
   clusterrolebinding.rbac.authorization.k8s.io/blackbox-exporter created
   configmap/blackbox-exporter-configuration created
   deployment.apps/blackbox-exporter created
   networkpolicy.networking.k8s.io/blackbox-exporter created
   service/blackbox-exporter created
   serviceaccount/blackbox-exporter created
   servicemonitor.monitoring.coreos.com/blackbox-exporter created
   secret/grafana-config created
   secret/grafana-datasources created
   configmap/grafana-dashboard-alertmanager-overview created
   configmap/grafana-dashboard-apiserver created
   configmap/grafana-dashboard-cluster-total created
   configmap/grafana-dashboard-controller-manager created
   configmap/grafana-dashboard-grafana-overview created
   configmap/grafana-dashboard-k8s-resources-cluster created
   configmap/grafana-dashboard-k8s-resources-namespace created
   configmap/grafana-dashboard-k8s-resources-node created
   configmap/grafana-dashboard-k8s-resources-pod created
   configmap/grafana-dashboard-k8s-resources-workload created
   configmap/grafana-dashboard-k8s-resources-workloads-namespace created
   configmap/grafana-dashboard-kubelet created
   configmap/grafana-dashboard-namespace-by-pod created
   configmap/grafana-dashboard-namespace-by-workload created
   configmap/grafana-dashboard-node-cluster-rsrc-use created
   configmap/grafana-dashboard-node-rsrc-use created
   configmap/grafana-dashboard-nodes-darwin created
   configmap/grafana-dashboard-nodes created
   configmap/grafana-dashboard-persistentvolumesusage created
   configmap/grafana-dashboard-pod-total created
   configmap/grafana-dashboard-prometheus-remote-write created
   configmap/grafana-dashboard-prometheus created
   configmap/grafana-dashboard-proxy created
   configmap/grafana-dashboard-scheduler created
   configmap/grafana-dashboard-workload-total created
   configmap/grafana-dashboards created
   deployment.apps/grafana created
   networkpolicy.networking.k8s.io/grafana created
   prometheusrule.monitoring.coreos.com/grafana-rules created
   service/grafana created
   serviceaccount/grafana created
   servicemonitor.monitoring.coreos.com/grafana created
   prometheusrule.monitoring.coreos.com/kube-prometheus-rules created
   clusterrole.rbac.authorization.k8s.io/kube-state-metrics created
   clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics created
   deployment.apps/kube-state-metrics created
   networkpolicy.networking.k8s.io/kube-state-metrics created
   prometheusrule.monitoring.coreos.com/kube-state-metrics-rules created
   service/kube-state-metrics created
   serviceaccount/kube-state-metrics created
   servicemonitor.monitoring.coreos.com/kube-state-metrics created
   prometheusrule.monitoring.coreos.com/kubernetes-monitoring-rules created
   servicemonitor.monitoring.coreos.com/kube-apiserver created
   servicemonitor.monitoring.coreos.com/coredns created
   servicemonitor.monitoring.coreos.com/kube-controller-manager created
   servicemonitor.monitoring.coreos.com/kube-scheduler created
   servicemonitor.monitoring.coreos.com/kubelet created
   clusterrole.rbac.authorization.k8s.io/node-exporter created
   clusterrolebinding.rbac.authorization.k8s.io/node-exporter created
   daemonset.apps/node-exporter created
   networkpolicy.networking.k8s.io/node-exporter created
   prometheusrule.monitoring.coreos.com/node-exporter-rules created
   service/node-exporter created
   serviceaccount/node-exporter created
   servicemonitor.monitoring.coreos.com/node-exporter created
   clusterrole.rbac.authorization.k8s.io/prometheus-k8s created
   clusterrolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   networkpolicy.networking.k8s.io/prometheus-k8s created
   poddisruptionbudget.policy/prometheus-k8s created
   prometheus.monitoring.coreos.com/k8s created
   prometheusrule.monitoring.coreos.com/prometheus-k8s-prometheus-rules created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s-config created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s-config created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   service/prometheus-k8s created
   serviceaccount/prometheus-k8s created
   servicemonitor.monitoring.coreos.com/prometheus-k8s created
   Warning: resource apiservices/v1beta1.metrics.k8s.io is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
   apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io configured
   clusterrole.rbac.authorization.k8s.io/prometheus-adapter created
   Warning: resource clusterroles/system:aggregated-metrics-reader is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
   clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader configured
   clusterrolebinding.rbac.authorization.k8s.io/prometheus-adapter created
   clusterrolebinding.rbac.authorization.k8s.io/resource-metrics:system:auth-delegator created
   clusterrole.rbac.authorization.k8s.io/resource-metrics-server-resources created
   configmap/adapter-config created
   deployment.apps/prometheus-adapter created
   networkpolicy.networking.k8s.io/prometheus-adapter created
   poddisruptionbudget.policy/prometheus-adapter created
   rolebinding.rbac.authorization.k8s.io/resource-metrics-auth-reader created
   service/prometheus-adapter created
   serviceaccount/prometheus-adapter created
   servicemonitor.monitoring.coreos.com/prometheus-adapter created
   clusterrole.rbac.authorization.k8s.io/prometheus-operator created
   clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator created
   deployment.apps/prometheus-operator created
   networkpolicy.networking.k8s.io/prometheus-operator created
   prometheusrule.monitoring.coreos.com/prometheus-operator-rules created
   service/prometheus-operator created
   serviceaccount/prometheus-operator created
   servicemonitor.monitoring.coreos.com/prometheus-operator created
   ```

   

6. 

# 排错

如果出现一下

![image-20230224161617524](file:///Users/abbott/Library/Application%20Support/typora-user-images/image-20230224161617524.png?lastModify=1677474724)

解决：(所有节点上安装pause proxy)

```
 docker save  registry.k8s.io/pause:3.6 -o pause.tar 
 docker save registry.k8s.io/kube-proxy:v1.25.1 -o kubeproxy.tar
 #推送到所有的节点上
 scp pause.tar {node节点上}
 scp kubeproxy.tar {node节点上}
 
 #加载镜像
 docker load -i {镜像的tar包}
 31964 31427
```

你们现在应该会的

![image-20230227160047248](/Users/abbott/Library/Application Support/typora-user-images/image-20230227160047248.png)

```shell
[root@k8s-master example]# kubectl edit,replace,describe,apply,create
```







