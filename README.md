# 特殊说明

> ## ⚠️ 使用须知

> **本代理工具仅供合法的技术学习、网络调试及授权测试使用。**

> **严禁用于** 侵犯他人隐私、破坏系统安全、非法爬取数据、绕过国家网络监管等违法违规行为。

> 使用者须自行承担因违规使用所引发的一切法律责任，作者及本项目不承担任何连带责任。请务必遵守当地法律法规，合法合规使用。

> 🚫 请勿使用 AI 工具逆向破解或绕过授权，由此产生的一切后果自负。

---

## 一、快速开始

- **未经授权无法使用。**
- 网络必须开启 IPv6，否则无需继续操作。
- 请勿在主路由或旁路由系统内创建容器。
- 虚拟机环境可能不适合安装，如要折腾，请自行解决问题。
- **N1 盒子、玩客云**：刷 Armbian 即可使用。
- **飞牛 NAS**：可直接使用。
- 若以上设备均无，花几十元左右购买一台玩客云，转发流量足够满足需求。
- 安装和使用过程中出现任何问题，请自行解决，这边没有相关设备能帮你解决问题

---

## 二、配置详解

### 1. 创建镜像

```
chmod +x build.sh && ./build.sh
```

### 2. 创建网络

```
docker network create -d macvlan 
  --subnet=192.168.100.0/24 
  --gateway=192.168.100.1 
  --ipv6 
  --subnet=fdfa:5a35:6fce::/64 
  -o parent=eth0 psyduck
```

> 网关：192.168.100.1 — 请按实际网关填写（例如 192.168.2.1、10.0.0.1、192.168.3.1）

> 网段：192.168.100.0 — 请按实际网段填写（例如 192.168.2.0、10.0.0.0、192.168.3.0）

> 父网卡：eth0 — 一般为 eth0；飞牛 NAS 通常为 enp4s0，可通过 ip -6 a 命令查看

### 3. 创建容器

| 环境变量 | 说明（需授权使用） | 默认值 |
|---|---|---|
| `PORT` | 代理服务监听端口 | 24678 |
| `USER_EXPIRE_SECONDS` | 用户 IPv6 地址有效期（秒） | 10800 |
| `POOL_TARGET` | IPv6 地址池目标数量 | 80 |
| `CHECK_INTERVAL_SECONDS` | `/checkPrefix` 定时请求间隔（秒） | 300 |

```
docker run -d 
  --name relayPool31 
  --restart=always 
  --ip=192.168.100.31 
  --privileged 
  --memory=512m  
  --memory-reservation=256m  
  --network psyduck 
  relaypool
```

> 容器 IP：192.168.100.31 — 需要为容器分配一个内网 IP，注意不要冲突（例如 192.168.2.22、10.0.0.33、192.168.3.44）

### 4. 快捷批量创建

```
chmod +x p.sh && ./p.sh
```

> 脚本交互提示：

> 请输入网关地址 (GATEWAY):

> 请输入起始主机号 (如 37):

> 请输入要创建的容器数量 (最大20):

---

## 三、使用方法

### 1. 基础接口

| 接口 | 方法 | 说明 |
|---|---|---|
| `/ipv6List` | GET | 返回 IPv6 地址列表、池状态、UUID、授权信息 |
| `/userList` | GET | 返回用户映射、UUID、授权信息；支持查询单个用户和刷新 |
| `/authorization` | GET | 返回授权页面（HTML 表单） |
| `/authorization` | POST | 提交授权码 |
| `/ipv6Prefix` | POST | 被动接收前缀变动，触发重启 |
| `/checkPrefix` | GET | 查看或配置 check API URL | 
| `/info` | GET | 返回授权状态、UUID、版本信息 |

#### `/ipv6List`

**方法：** `GET`

**说明：** 返回当前 IPv6 地址列表、池状态、UUID 及授权信息。

响应示例：

```json
{
  "version": "1.1.1",
  "code": 0,
  "addresses": ["240e:..."],
  "total": 100,
  "free": 50,
  "uuid": "02ca334ae6de97efff780b80abc17",
  "license_type": "partial",
  "license_expire": 1804821373,
  "expire": "2027-03-12 11:16:13"
}
```

#### `/userList`

**方法：** `GET`

**说明：** 查询用户映射，或刷新指定用户的 IPv6 地址。

请求参数：

| 参数 | 说明 |
|---|---|
| `user` | 查询指定用户 |
| `refresh` | 刷新指定用户的 IPv6；若只传 refresh 无 user，refresh 的值即作为用户名 |

示例：

```bash
# 查询全部用户
curl http://proxy:24678/userList

# 查询单个用户
curl "http://proxy:24678/userList?user=abc"

# 刷新指定用户
curl "http://proxy:24678/userList?user=abc&refresh=1"

# 只传 refresh（refresh 的值即为用户名并刷新）
curl "http://proxy:24678/userList?refresh=abc"
```

响应示例（单个用户）：

```json
{
  "code": 0,
  "status": "ok",
  "user": "abc",
  "ipv6": "240e:...",
  "version": "1.1.1"
}
```

#### `/authorization`

**方法：** `GET` / `POST`

**说明：** GET 返回授权页面（HTML 表单，含本机 UUID）；POST 提交授权码。

POST 支持的 Content-Type：

- `application/json` → `{"license": "..."}`
- `application/x-www-form-urlencoded` → `license=...`
- 其他 → 纯文本 body 或 JSON

响应示例：

```json
{
  "code": 0,
  "uuid": "02ca334ae6de97efff780b80abc17",
  "type": "partial",
  "license_expire": 1804821373,
  "expire": "2027-03-12 11:16:13",
  "version": "1.1.1"
}
```
#### `/info`

**方法：** `GET`

**说明：** 返回授权状态、UUID、版本信息。

响应示例：

```json
{
  "code": 0,
  "expire": "2027-03-12 11:16:13",
  "license_expire": 1804821373,
  "type": "partial",
  "uuid": "02ca334ae6de97efff780b80abc17",
  "version": "1.1.1"
}
```

---

### 2、代理请求（需授权）

| 方式 | 说明 |
|---|---|
| `CONNECT` | HTTPS 隧道代理 |
| 普通 HTTP 代理请求 | 通过 `Proxy-Authorization: Basic` 认证 |

---

### 3. 定时重启

> 容器获取的 IPv6 前缀是固定不变的。若在此期间您的 IPv6 地址发生变动，容器将无法正常访问数据，因此建议添加定时重启机制，以确保服务稳定。

```
59 23 * * * docker restart relayPool31
```

---

### 4. Api 重启（/ipv6Prefix）

> 如果宿主机的 IPv6 前缀发生变动，你可以通过 `/ipv6Prefix` 接口重启容器。
>
> 如果 IPv6 前缀没有发生变动，容器不会重启。

```
url:  http://ip:24678/ipv6Prefix
json: {
  "prefix": "240x:xxxx:xxxx:xxxx",
  "time": 16999xxxx,
  "access": md5("Archer" + prefix + time)
}
```

> 以下脚本可保存为 prefix.sh 文件，修改 HOST、INTERFACE 这两个变量
>
> 定时任务添加：`*/2 * * * * /路径/prefix.sh`
> 
> 青龙用户可添加到task_before.sh里面

```bash
HOST="ip:24678"
INTERFACE="br-lan"
SECRET="Archer"

prefix=$(ip -6 addr show dev "$INTERFACE" | grep -E 'inet6.*global' | awk '{print $2}' | cut -d'/' -f1 | grep '^240' | head -n1 | cut -d':' -f1-4)

if [ -n "$prefix" ]; then
    time=$(date +%s)
    access=$(echo -n "${SECRET}${prefix}${time}" | md5sum | awk '{print $1}') 
    curl -s -X POST \
         -H "Content-Type: application/json" \
         -d "{\"prefix\":\"$prefix\",\"time\":$time,\"access\":\"$access\"}" \
         "http://$HOST/ipv6Prefix"
fi

```
---

### 5. 主动检查前缀变动（/checkPrefix）

> 通过 `/checkPrefix` 接口配置一个远程 API，程序会定时请求该 API，自动检测前缀变动，无需在宿主机上跑脚本。

**查看当前配置：**

```
GET http://ip:24678/checkPrefix
```

**添加/更新 API URL：**

```
GET http://ip:24678/checkPrefix?add=http://example.com:24678/ipv6Prefix
```

**删除 API URL：**

```
GET http://ip:24678/checkPrefix?delete=1
```

> 被请求的 API 返回数据结构与 `/ipv6Prefix` 一致：

```json
{
  "prefix": "240x:xxxx:xxxx:xxxx",
  "time": 16999xxxx,
  "access": "md5(Archer + prefix + time)"
}
```
> 可快速使用 checkPrefix.sh 搭建一个本地接口，需要和relaypool同宿主机，ip自行分配：
``` 
chmod +x checkPrefix.sh && ./checkPrefix.sh 192.168.100.32
```
> 定时请求间隔由环境变量 `CHECK_INTERVAL_SECONDS` 控制，默认 300 秒。

---

### 6. 授权码（不定期更新）

> 请向管理员申请，通过 `/authorization` 页面输入。
```
134108104143129074120128104104078088111066091145139141123138098097091075120070100140074132090103106105111141126096139131130122097111130111121144132141134088077106107103079129137088075076072106077108078076136074122097111138135093130108101111091103142105090072104111107138120139101076104066127121128101105112076076137142134134138079095124126066132107112106133097091101070124136108071145102075112097092137142071066129133091099143076144075077080132108098134088107066132094075107091141096122141094098072078121133113123131134113090071103074104109134111090120075099071072137107133111074092094127132107124095107132101075124100121112096073145110096090142092091120077144125066080073079075121113127099131113098125134084
```