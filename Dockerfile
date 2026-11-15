# ============================================================
# 群晖 Wine 容器：跑 FlexNet License Manager（lmgrd.exe）
# 典型命令：lmgrd.exe -z -c <许可文件> -l <日志文件>
#   -z  前台运行（容器必需，否则进程一 fork 容器就退出）
#   -c  指定 license 文件
#   -l  指定日志文件
#
# 设计要点（群晖）：
#   - 容器内 root 跑，不用填 PUID/UID
#   - Wine 前缀用 Docker 卷，避开共享文件夹 ACL
#   - 启动时把 exe / lic 拷到容器内可写目录再跑
# ============================================================
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    WINEARCH=win32 \
    WINEPREFIX=/wine/prefix \
    WINEDEBUG=-all \
    WINEDLLOVERRIDES="mscoree,mshtml=" \
    DISPLAY=:99 \
    HOME=/root

# 启用 i386，安装 32 位 Wine（多数 FlexNet 工具是 win32）
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        wine \
        wine32 \
        wine64 \
        xvfb \
        ca-certificates \
        procps \
        net-tools \
        iproute2 \
        tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /wine/prefix /app/bin /app/run /app/scripts /app/licenses /app/logs

# 预初始化 Wine 前缀模板；运行时卷会盖住 /wine/prefix，故另存备份
RUN xvfb-run -a wineboot --init \
    && wineserver -w \
    && cp -a /wine/prefix /wine/prefix.img-bak \
    && rm -rf /tmp/.X*-lock /tmp/.X11-unix 2>/dev/null || true

COPY scripts/entrypoint.sh /app/scripts/entrypoint.sh
COPY scripts/run-lmgrd.sh /app/scripts/run-lmgrd.sh
COPY bin/ /app/bin/
COPY licenses/ /app/licenses/
RUN chmod 755 /app/scripts/entrypoint.sh /app/scripts/run-lmgrd.sh

WORKDIR /app/run

# 与许可文件一致：SERVER 25734、VENDOR FF_D 25735（均为 TCP）
EXPOSE 25734/tcp 25735/tcp

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD []
