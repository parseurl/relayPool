FROM alpine:latest
RUN sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
RUN apk add --no-cache iproute2 ca-certificates bash curl
COPY relayPool /usr/local/bin/relayPool
RUN chmod +x /usr/local/bin/relayPool
EXPOSE 24678
CMD ["/usr/local/bin/relayPool"]
