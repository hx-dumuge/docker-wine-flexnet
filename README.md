# wine-flexnet

群晖（或任意 Docker）上用 Wine 跑 FlexNet `lmgrd.exe`。

## 目录

| 目录 | 内容 |
|------|------|
| `bin/` | `lmgrd.exe`、厂商 daemon（如 `FF_D.exe`）、dll；可选 `lmutil.exe` |
| `licenses/` | 放入你的 `license.lic` |
| `logs/` | 每次启动按时间戳生成的日志，如 `lmgrd-20261115-104700.log` |

## 许可端口（示例）

```
SERVER this_host ANY 25734    → TCP 25734（lmgrd）
VENDOR FF_D PORT=25735        → TCP 25735（厂商 daemon）
```

只需 **TCP**。客户端：`LM_LICENSE_FILE=25734@群晖IP`

## 部署（群晖）

1. 解压项目到任意目录  
2. `bin/` 放入 `lmgrd.exe` + 厂商 `.exe`  
3. `licenses/` 放入你的 `license.lic`（可参考 `licenses/license.lic.example`）  
4. Container Manager 用本目录 `docker-compose.yml` 建项目并启动  
5. 防火墙放行 TCP `25734`、`25735`

容器内实际命令：

```bash
wine lmgrd.exe -z -c /app/run/license.lic -l /app/logs/lmgrd-时间戳.log
```

## 用 lmutil 测试

把 `lmutil.exe` 放到 `bin/`（或在 Windows 客户端使用）。将下面的 `群晖IP` 换成实际地址；本机容器内可用 `127.0.0.1`。

### 查看服务与全部 feature

```bash
lmutil lmstat -a -c 25734@群晖IP
```

### 只看某个 feature（示例 feature 名为 app）

```bash
lmutil lmstat -f app -c 25734@群晖IP
```

### 诊断连通 / 许可问题

```bash
lmutil lmdiag -c 25734@群晖IP
```

### 在本容器里用 Wine 测

```bash
wine lmutil.exe lmstat -a -c 25734@127.0.0.1
```

正常时 `lmstat -a` 应能看到 `lmgrd`（25734）、厂商 daemon（25735）以及 feature 的总数/在用数。

也可直接看日志：

```text
logs/lmgrd-latest.log
```

## 环境变量（compose）

| 变量 | 说明 |
|------|------|
| `LICENSE_FILE` | 许可文件名，默认 `license.lic` |
| `LOG_FILE` | `auto`=每次按时间戳命名；也可固定文件名 |
| `LOG_DIR` | 日志目录，默认 `/app/logs` |
| `TZ` | 默认 `Asia/Shanghai` |
