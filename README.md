# 概述

这是 Hyperledger Fabric 2.x多机环境。它是由两个组织和四个peer和三个使用 Docker Swarm 作为多主机容器环境的排序服务组成的设置。我们首先介绍Docker Swarm，完成了这些步骤，在两个主机网络中建立这个结构网络。

# **DOCKER SWARM**

Docker Swarm 是 Docker 环境中原生的容器编排工具。简而言之，它为跨多个主机的容器提供了一个覆盖网络。这个覆盖网络上的那些容器可以相互通信，就像它们在一台大型主机上一样。好的一面显然是，原始配置只需少量修改即可使用，并且配置中没有编码 IP 等静态信息。在本文中，我们使用 Docker Swarm。

# **先决条件**

本教程要求您从这里克隆我的 Github 代码。 https://github.com/sxguan/fabric-network

1. docker
2. docker-compose
3. fabric-network（克隆 GitHub 代码）



# **网络拓扑结构**

## **主机1 (组织 -1)**

1. 证书颁发机构 (CA)
2. 2 个peer（peer0.org1.exampl.com、peer1.org1.example.com）
3. 2 个orderer（orderer0.example.com、orderer1.example.com）
4. cli

## **主机2 (组织-2)**

1. 证书颁发机构 (CA)
2. 2 个peer（peer0.org2.exampl.com、peer1.org2.example.com）
3. 3 个orderer (orderer2.example.com)

## **整体流程**

1. 启动两台包含先决条件的主机。
2. 形成一个覆盖网络并使所有两个主机加入。
3. 准备主机 1 上的所有内容，包括配置文件、证书、每个节点的 docker-compose 文件。然后将整个结构复制到所有其他主机。
4. 使用 docker-compose 启动所有节点。
5. 创建一个通道并将所有节点加入 *mychannel*。
6. 安装并实例化 Fabcar 链码。
7. 调用和查询链码函数。

## **第 1 步：启动主机**

请注意，出于演示目的，我为所有内容（所有 UDP、TCP 和 ICMP）打开了一个安全组。对于生产，请确保您只打开所需的端口。

> 注意：Docker-swarm 必须打开以下端口
> \1. 2377 (TCP) — 集群管理
> \2. 7946 (TCP and UDP) — 节点通信
> \3. 4789 (TCP and UDP) — 覆盖网络流量

## **第 2 步：使用 DOCKER SWARM 形成一个 OVERLAY 网络**

现在我们可以打开四个终端。

```
ssh -i <key> ubuntu@<public IP>
```

**从主机1**，

```
docker swarm init --advertise-addr <pc-1 ip address>docker swarm join-token manager
```

使用最后一个输出，将其他主机作为管理器添加到这个群。

**从主机2**

```
<output from join-token manager> --advertise-addr <pc-2 ip address>
```

**从主机1，**

```
docker network create --attachable --driver overlay basic-network docker network ls
```

**从主机2，**

```
docker network ls
```



## **第3步：在主机1中准备好FABRIC文件并复制给其他人**

关键部分之一是确保所有组件共享相同的加密文件。我们将使用主机1创建文件并将它们复制到其他主机。

**从主机1，**

```
./create-artifacts.sh
```

理论上，我们只需要确保身份（证书和签名密钥）遵循所需的方案。组织（例如 org1）的证书由同一 CA (ca.org1) 颁发和签署。为简单起见，在本演示中，我们在 PC -1 中创建所有材料，然后将整个目录 **crypto-config** 复制到其他主机。

## **第 4 步：在每个主机中启动容器**

我们使用 docker-compose 来启动所有节点。

```
# from PC -1,
docker-compose -f pc1.yaml up -d# from PC -2,
docker-compose -f pc2.yaml up -d
```

## **第5步：创建通道，所有peer加入**

由于我们在主机1上只有 CLI，所有命令都是从主机1终端发出的。

```
./createChannel.sh
```

## **第 6 步：安装和实例化 FABCAR 链码**

从主机1终端，

将 Fabcar 链码安装到所有peer

```
./deployChaincode.sh
```

## **第 7 步：链码调用和查询**

为了演示，根据 Fabcar 的设计，我们首先调用 **initLedger** 函数在账本中预加载 10 条汽车记录。

```
./invoke.sh./query.sh
```

# **概括**

在这个演示中，我们建立了两个具有基本网络的组织。这些容器在两台独立的主机上运行。Docker Swarm 将这两台主机结合在一起，以便运行在不同主机上的容器可以进行通信。我们不再在配置文件上指定静态 IP，所有容器都像在同一台主机上一样相互通信。
