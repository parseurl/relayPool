#!/bin/bash
set -e

# ============ 配置 ============
IMAGE_NAME="ipv6prefix"
CONTAINER_NAME="ipv6prefix"
NETWORK_NAME="psyduck"
HOST_PORT="24679"
CONTAINER_PORT="24679"
WORK_DIR="$(cd "$(dirname "$0")" && pwd)/ipv6prefix-build"

# 容器固定 IP（可选）：./deploy.sh 192.168.100.90
ASSIGN_IP="${1:-}"
# ==============================

echo ">>> 1. 创建构建目录: ${WORK_DIR}"
mkdir -p "${WORK_DIR}/www/cgi-bin"
cd "${WORK_DIR}"

echo ">>> 2. 生成 Dockerfile"
cat > Dockerfile <<EOF
FROM alpine:latest
RUN apk add --no-cache iproute2 busybox-extras
RUN mkdir -p /www/cgi-bin
COPY prefix.cgi /www/cgi-bin/prefix
RUN chmod +x /www/cgi-bin/prefix
EXPOSE ${CONTAINER_PORT}
CMD ["/usr/sbin/httpd", "-f", "-p", "${CONTAINER_PORT}", "-h", "/www"]
EOF

echo ">>> 3. 生成 CGI 脚本"
cat > prefix.cgi <<'EOF'
#!/bin/sh

IPV6_ADDR=$(ip -6 addr show scope global | awk '/inet6/ {print $2}' | cut -d'/' -f1 | head -n1)

if [ -z "$IPV6_ADDR" ]; then
  echo "Content-Type: application/json"
  echo ""
  echo '{"error": "No IPv6 address found"}'
  exit 0
fi

PREFIX=$(echo "$IPV6_ADDR" | sed -E 's/^(([0-9a-fA-F]{1,4}:){3}[0-9a-fA-F]{1,4}).*/\1/')
TIME=$(date +%s)
HASH_STRING="Archer${PREFIX}${TIME}"
ACCESS=$(echo -n "$HASH_STRING" | md5sum | cut -d' ' -f1)

echo "Content-Type: application/json"
echo ""
cat <<JSON
{
  "prefix": "${PREFIX}",
  "time": ${TIME},
  "access": "${ACCESS}"
}
JSON
EOF
chmod +x prefix.cgi

echo ">>> 4. 构建镜像: ${IMAGE_NAME}"
docker build --no-cache -t "${IMAGE_NAME}" .

echo ">>> 5. 检查网络: ${NETWORK_NAME}"
if ! docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
  echo "    ✗ 网络 ${NETWORK_NAME} 不存在，请先创建"
  exit 1
fi
echo "    网络 ${NETWORK_NAME} 已存在，直接使用"

echo ">>> 6. 清理旧容器"
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo ">>> 7. 启动容器"
if [ -n "${ASSIGN_IP}" ]; then
  echo "    指定容器 IP: ${ASSIGN_IP}"
  docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    --network "${NETWORK_NAME}" \
    --ip "${ASSIGN_IP}" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${IMAGE_NAME}"
else
  docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    --network "${NETWORK_NAME}" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${IMAGE_NAME}"
fi

echo ">>> 8. 等待启动..."
sleep 2

# ---- 确定访问地址 ----
if [ -n "${ASSIGN_IP}" ]; then
  ACCESS_URL="http://${ASSIGN_IP}:${CONTAINER_PORT}/cgi-bin/prefix"
else
  ACCESS_URL="http://localhost:${HOST_PORT}/cgi-bin/prefix"
fi

echo ""
echo "--- 容器状态 ---"
docker ps --filter "name=${CONTAINER_NAME}"

echo ""
echo "--- 容器 IP ---"
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "${CONTAINER_NAME}"

echo ""
echo "--- 访问测试 ---"
curl -s -m 5 "${ACCESS_URL}" || echo "（curl 失败）"

echo ""
echo "=========================================="
echo "✅ 部署完成！"
echo "   容器 IP  : ${ASSIGN_IP:-（自动分配）}"
echo "   访问地址 : ${ACCESS_URL}"
echo "   日志: docker logs -f ${CONTAINER_NAME}"
echo "=========================================="
