#!/usr/bin/env bash
# ------------------------------------------------------------
# 启动 FlexNet：wine lmgrd.exe -z -c <许可> -l <日志>
# -z 必须有，否则 lmgrd 后台 fork 后容器主进程结束
# 日志默认写入 LOG_DIR，文件名带本次启动时间戳
# ------------------------------------------------------------
set -euo pipefail

LMGRD_EXE="${LMGRD_EXE:-/app/run/lmgrd.exe}"
LMGRD_WORKDIR="${LMGRD_WORKDIR:-/app/run}"
LICENSE_FILE="${LICENSE_FILE:-license.lic}"
LOG_DIR="${LOG_DIR:-/app/logs}"
LOG_FILE="${LOG_FILE:-auto}"
CUSTOM_ARGS="${CUSTOM_ARGS:-}"
EXTRA_ARGS="${EXTRA_ARGS:-}"
USE_XVFB="${USE_XVFB:-1}"
WINEPREFIX="${WINEPREFIX:-/wine/prefix}"

log() { printf '[启动] %s\n' "$*"; }

start_xvfb() {
  if [[ "$USE_XVFB" != "1" ]]; then
    return 0
  fi
  if pgrep -x Xvfb >/dev/null 2>&1; then
    return 0
  fi
  Xvfb "${DISPLAY:-:99}" -screen 0 1024x768x24 -ac +extension GLX +render -noreset >/tmp/xvfb.log 2>&1 &
  XVFB_PID=$!
  sleep 0.5
  if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    log "警告：Xvfb 启动失败，继续尝试（见 /tmp/xvfb.log）"
  else
    log "Xvfb 已就绪（$DISPLAY）"
  fi
}

cleanup() {
  wineserver -k 2>/dev/null || true
  if [[ -n "${XVFB_PID:-}" ]]; then
    kill "$XVFB_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

if [[ ! -f "$WINEPREFIX/system.reg" ]]; then
  log "正在执行 wineboot 初始化..."
  wineboot --init || true
  wineserver -w || true
fi

start_xvfb
cd "$LMGRD_WORKDIR"

if [[ ! -f "$LMGRD_EXE" ]]; then
  log "错误：找不到 $LMGRD_EXE"
  log "请把 lmgrd.exe 和厂商 daemon 放到项目 bin/ 目录"
  exit 1
fi

# 许可路径
if [[ "$LICENSE_FILE" = /* ]]; then
  LIC_PATH="$LICENSE_FILE"
else
  LIC_PATH="$LMGRD_WORKDIR/$LICENSE_FILE"
fi

if [[ ! -f "$LIC_PATH" ]]; then
  log "错误：找不到许可文件 $LIC_PATH"
  log "请放到项目 licenses/ 目录"
  exit 1
fi

# ---------- 按本次运行时间生成日志路径 ----------
mkdir -p "$LOG_DIR"
# 优先用 TZ（compose 里 Asia/Shanghai）；无 tzdata 时退回 UTC 并在文件名标明
STAMP="$(date +%Y%m%d-%H%M%S)"

if [[ -z "$LOG_FILE" || "$LOG_FILE" = "auto" ]]; then
  LOG_PATH="$LOG_DIR/lmgrd-${STAMP}.log"
elif [[ "$LOG_FILE" = /* ]]; then
  LOG_PATH="$LOG_FILE"
elif [[ "$LOG_FILE" = */* ]]; then
  # 相对路径：相对 LOG_DIR
  LOG_PATH="$LOG_DIR/$LOG_FILE"
else
  LOG_PATH="$LOG_DIR/$LOG_FILE"
fi

mkdir -p "$(dirname "$LOG_PATH")"
# 方便查看「当前这次」：软链到最新日志
ln -sfn "$(basename "$LOG_PATH")" "$LOG_DIR/lmgrd-latest.log" 2>/dev/null || true

# 写一行启动头，便于区分各次运行
{
  echo "======== lmgrd start ========"
  echo "time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "license: $LIC_PATH"
  echo "log: $LOG_PATH"
  echo "============================="
} >>"$LOG_PATH"

# 组装参数：默认 -z -c -l ；CUSTOM_ARGS 可整段覆盖
if [[ -n "$CUSTOM_ARGS" ]]; then
  read -r -a ARGS <<< "$CUSTOM_ARGS"
else
  ARGS=(-z -c "$LIC_PATH" -l "$LOG_PATH")
  if [[ -n "$EXTRA_ARGS" ]]; then
    # shellcheck disable=SC2206
    EXTRA=( $EXTRA_ARGS )
    ARGS+=("${EXTRA[@]}")
  fi
fi
if [[ "$#" -gt 0 ]]; then
  ARGS+=("$@")
fi

log "工作目录: $LMGRD_WORKDIR"
log "许可文件: $LIC_PATH"
log "本次日志: $LOG_PATH"
log "最新软链: $LOG_DIR/lmgrd-latest.log"
log "执行: wine $LMGRD_EXE ${ARGS[*]}"
log "请确认 compose 端口与许可 TCP 端口一致，并已在群晖防火墙放行"

exec wine "$LMGRD_EXE" "${ARGS[@]}"
