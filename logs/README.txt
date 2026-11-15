lmgrd 运行日志目录（compose 挂载为可写卷）。

每次容器启动会生成带时间戳的文件，例如：
  lmgrd-20261115-104700.log

同时更新软链：
  lmgrd-latest.log  → 指向本次最新日志

时区由环境变量 TZ 控制（默认 Asia/Shanghai）。
不要手动删掉本目录；旧日志可自行清理。
