
## **网络拓扑结构**

### **主机1 (组织 -1)**

1. 证书颁发机构 (CA)
2. 2 个peer（peer0.org1.exampl.com、peer1.org1.example.com）
3. 2 个orderer（orderer0.example.com、orderer1.example.com）
4. cli

### **主机2 (组织-2)**

1. 证书颁发机构 (CA)
2. 2 个peer（peer0.org2.exampl.com、peer1.org2.example.com）
3. 3 个orderer (orderer2.example.com)

### **整体流程**

1. 启动两台包含先决条件的主机。
2. 形成一个覆盖网络并使所有两个主机加入。
3. 准备主机 1 上的所有内容，包括配置文件、证书、每个节点的 docker-compose 文件。然后将整个结构复制到所有其他主机。
4. 使用 docker-compose 启动所有节点。
5. 创建一个通道并将所有节点加入 *mychannel*。
6. 安装并实例化 Fabcar 链码。
7. 调用和查询链码函数。

### **第 1 步：启动主机**

请注意，出于演示目的，我为所有内容（所有 UDP、TCP 和 ICMP）打开了一个安全组。对于生产，请确保您只打开所需的端口。

> 注意：Docker-swarm 必须打开以下端口
> \1. 2377 (TCP) — 集群管理
> \2. 7946 (TCP and UDP) — 节点通信
> \3. 4789 (TCP and UDP) — 覆盖网络流量

### **第 2 步：使用 DOCKER SWARM 形成一个 OVERLAY 网络**

现在我们可以打开四个终端。

```
ssh duck@140.123.179.50
```

**从主机1**，

```
docker swarm init --advertise-addr 140.123.179.50 
docker swarm join-token manager
```

使用最后一个输出，将其他主机作为管理器添加到这个群。

**从主机2**

```
<output from join-token manager> --advertise-addr 140.123.179.23
```

**从主机1，**

```
docker network create --attachable --driver overlay fabric-network_test
docker network ls
```

**从主机2，**

```
docker network ls
```



### **第3步：在主机1中准备好FABRIC文件并复制给其他人**

```
#壓縮raft-4node-swarm資料夾
tar -cf fabric-network.tar fabric-network/
#解壓到指定裝置及路徑
scp fabric-network.tar duck-2@140.123.179.23:/home/duck-2/
tar -xvf fabric-network.tar
```

关键部分之一是确保所有组件共享相同的加密文件。我们将使用主机1创建文件并将它们复制到其他主机。

**从主机1，**

```
./create-artifacts.sh
```

### **第 4 步：在每个主机中启动容器**

我们使用 docker-compose 来启动所有节点。

```
# from PC -1,
docker-compose -f pc1.yaml up -d
# from PC -2,
docker-compose -f pc2.yaml up -d
```

### **第5步：创建通道，所有peer加入**

由于我们在主机1上只有 CLI，所有命令都是从主机1终端发出的。

```
./createChannel.sh
```

### **第 6 步：安装和实例化 FABCAR 链码**

从主机1终端，

将 Fabcar 链码安装到所有peer

```
./deployChaincode.sh
```

### **第 7 步：链码调用和查询**

为了演示，根据 Fabcar 的设计，我们首先调用 **initLedger** 函数在账本中预加载 10 条汽车记录。

```
./invoke.sh./query.sh
```

### **關閉**

```
docker-compose -f pc1.yaml down -v
sudo docker volume prune
```
## **总结**

在这个演示中，我们建立了两个具有基本网络的组织。这些容器在两台独立的主机上运行。Docker Swarm 将这两台主机结合在一起，以便运行在不同主机上的容器可以进行通信。我们不再在配置文件上指定静态 IP，所有容器都像在同一台主机上一样相互通信。

