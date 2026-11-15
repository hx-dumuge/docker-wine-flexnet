本目录放所有可执行文件：

  lmgrd.exe       FlexNet 主程序（必需）
  <VENDOR>.exe    厂商 daemon，文件名与许可 VENDOR 行一致（可多个）
  *.dll           若有，一并放入

例：VENDOR FF_D PORT=25735  →  本目录放 FF_D.exe

许可文件放到 ../licenses/
