#!/usr/bin/env bash
# ------------------------------------------------------------
# 容器入口（群晖 / FlexNet）
#   1. 准备可写 Wine 前缀
#   2. 把 bin/、licenses/ 拷到 /app/run
#   3. 交给 run-lmgrd.sh 启动 lmgrd.exe -z -c -l
# ------------------------------------------------------------
set -euo pipefail

log() { printf '[入口] %s\n' "$*"; }

WINEPREFIX="${WINEPREFIX:-/wine/prefix}"
RUNTIME_DIR="${RUNTIME_DIR:-/app/run}"
BIN_DIR="${BIN_DIR:-/app/bin}"
LIC_DIR="${LIC_DIR:-/app/licenses}"

mkdir -p "$WINEPREFIX" "$RUNTIME_DIR" /tmp/.X11-unix /root
chmod 1777 /tmp/.X11-unix || true

if [[ ! -f "$WINEPREFIX/system.reg" && -f /wine/prefix.img-bak/system.reg ]]; then
  log "正在初始化 Wine 前缀（首次启动）"
  cp -a /wine/prefix.img-bak/. "$WINEPREFIX"/ || true
fi

copy_files() {
  local src="$1"
  [[ -d "$src" ]] || return 0
  find "$src" -maxdepth 1 -type f \( \
      -iname '*.exe' -o -iname '*.dll' -o -iname '*.sh' \
      -o -iname '*.dat' -o -iname '*.lic' -o -iname '*.txt' \
    \) -exec cp -f {} "$RUNTIME_DIR"/ \; 2>/dev/null || true
}

copy_files "$BIN_DIR"
copy_files "$LIC_DIR"

chmod +x "$RUNTIME_DIR"/*.sh 2>/dev/null || true

daemon_list="$(
  find "$RUNTIME_DIR" -maxdepth 1 -type f -iname '*.exe' ! -iname 'lmgrd.exe' -printf '%f ' 2>/dev/null || true
)"
log "bin 中的厂商 daemon: ${daemon_list:-（无）}"

export HOME=/root
export WINEPREFIX
export LMGRD_WORKDIR="$RUNTIME_DIR"
export LMGRD_EXE="${LMGRD_EXE:-$RUNTIME_DIR/lmgrd.exe}"

log "root 模式 | 前缀=$WINEPREFIX | 运行目录=$RUNTIME_DIR"
exec /app/scripts/run-lmgrd.sh "$@"
