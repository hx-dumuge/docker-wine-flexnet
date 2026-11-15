#!/usr/bin/env bash
# ------------------------------------------------------------
# SSH 辅助启动：检查文件 → 构建启动 → 跟日志
# 厂商 daemon 与 lmgrd.exe 都放在 bin/
# ------------------------------------------------------------
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

missing=0
if [[ ! -f bin/lmgrd.exe ]]; then
  echo "缺少: $ROOT/bin/lmgrd.exe"
  missing=1
fi

daemon_count="$(find bin -maxdepth 1 -type f -iname '*.exe' ! -iname 'lmgrd.exe' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${daemon_count:-0}" -lt 1 ]]; then
  echo "缺少厂商 daemon：请把许可 VENDOR 对应的 .exe 放到 $ROOT/bin/"
  echo "  例：VENDOR FF_D ...  →  bin/FF_D.exe（可同时放多个）"
  missing=1
fi

if ! ls licenses/*.[lL][iI][cC] >/dev/null 2>&1 && ! ls bin/*.[lL][iI][cC] >/dev/null 2>&1; then
  echo "缺少许可文件: 请放到 $ROOT/licenses/license.lic"
  missing=1
fi
if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

docker compose up --build -d
docker compose logs -f --tail=100
