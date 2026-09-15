#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 显示欢迎信息
echo -e "${GREEN}批量创建带静态IP的relayPool容器脚本${NC}"
echo "=========================================="

# 获取网关地址
while true; do
    read -p "请输入网关地址 (GATEWAY): " gateway_addr
    if [[ "$gateway_addr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # 从网关地址提取网络部分
        network_part=$(echo "$gateway_addr" | cut -d. -f1-3)
        break
    else
        echo -e "${RED}错误: 请输入有效的网关地址 (如 192.168.100.1)!${NC}"
    fi
done

# 获取起始主机号
while true; do
    read -p "请输入起始主机号 (如 37): " start_host
    if [[ "$start_host" =~ ^[0-9]+$ ]] && [ "$start_host" -ge 1 ] && [ "$start_host" -le 254 ]; then
        break
    else
        echo -e "${RED}错误: 请输入有效的主机号 (1-254)!${NC}"
    fi
done

# 获取容器数量
while true; do
    read -p "请输入要创建的容器数量 (最大20): " container_count
    if [[ "$container_count" =~ ^[0-9]+$ ]] && [ "$container_count" -ge 1 ]; then
        if [ "$container_count" -gt 20 ]; then
            echo -e "${YELLOW}数量超过20，将使用默认值20${NC}"
            container_count=20
        fi

        # 检查主机号范围是否有效
        end_host=$((start_host + container_count - 1))
        if [ $end_host -gt 254 ]; then
            echo -e "${RED}错误: 主机号范围超出有效范围 (1-254)!${NC}"
            echo -e "${YELLOW}最大可用数量: $((254 - start_host + 1))${NC}"
        else
            break
        fi
    else
        echo -e "${RED}错误: 请输入有效的数字!${NC}"
    fi
done

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装，请先安装 Docker${NC}"
    exit 1
fi

# 创建容器
echo -e "${BLUE}开始创建容器...${NC}"

for ((i=0; i<container_count; i++)); do
    current_host=$((start_host + i))
    container_name="relayPool${current_host}"
    container_ip="${network_part}.${current_host}"

    echo -e "${YELLOW}正在创建容器 ${container_name} (IP: ${container_ip})...${NC}"

    # 创建并启动 Docker 容器
    docker_command="docker run -d --name $container_name --restart=always --ip=$container_ip --memory=512m --memory-reservation=256m --privileged --network psyduck relaypool"

    eval $docker_command

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}容器 ${container_name} 已成功创建!${NC}"
    else
        echo -e "${RED}容器 ${container_name} 创建失败!${NC}"
        echo -e "${YELLOW}可能的原因:${NC}"
        echo "1. IP地址 ${container_ip} 已被占用"
        echo "2. 容器名称 ${container_name} 已存在"
        echo "3. 镜像 'relaypool' 不存在"
        echo "4. 网络 'psyduck' 不存在"
    fi

    echo "--------------------------"
done

echo -e "${GREEN}批量部署完成!${NC}"
echo -e "${YELLOW}共创建了 ${container_count} 个容器，IP从 ${network_part}.${start_host} 到 ${network_part}.$((start_host + container_count - 1))${NC}"

echo "-----------------------------------"   # 可选分隔线
echo "[relayPool]"
for ((i=0; i<container_count; i++)); do
    current_ip="${network_part}.$((start_host + i))"
    echo "http://$current_ip:24678"
done
