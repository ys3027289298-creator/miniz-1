# ZIP64 支持：验证产物

本目录存放 "归档支持超大文件与超多条目" 任务的验证产物。

## 代码改动（仓库根目录）

- `miniz_zip.c`
  - `mz_zip_writer_finalize_archive()`：归档在写入过程中超过经典 ZIP 上限
    （4GB / 65535 条目）时自动切换 ZIP64，不再报错；ZIP64 模式下中央目录
    超过 4GB 时返回 `MZ_ZIP_UNSUPPORTED_CDIR_SIZE`（原为误导性的
    `MZ_ZIP_TOO_MANY_FILES`）。
  - `mz_zip_writer_add_from_zip_reader()`：条目数达 65535、估算归档尺寸超
    4GB、或源归档为 ZIP64 时，自动将目标归档切换为 ZIP64，不再失败。
- `tests/main.cpp`：新增 catch2 用例（仓库自带测试入口 `ctest`）
  - `Zip writer automatically switches to zip64 past classic limits`
    （4GB 跨越用稀疏虚拟存储验证，内存恒定；65535/65536 条目边界）
  - `Zip reader rejects archives beyond zip64 practical limits`
    （条目数 > 2^32 → `MZ_ZIP_TOO_MANY_FILES`；中央目录 > 4GB →
    `MZ_ZIP_UNSUPPORTED_CDIR_SIZE`）
- `ChangeLog.md`：Unreleased 段落记录上述改动。

## 目录结构

- `scripts/`：7 个分段验证脚本及自制小素材生成器（`scripts/src/*.c`），
  大文件素材均为稀疏文件（`truncate` 生成，几乎不占磁盘）。
- `logs/`：各分段完整输出日志。
- `recordings/`：asciinema 分段录屏（每段开头有标题、段末有停顿），
  播放：`asciinema play recordings/seg01_build_and_ctest.cast`

## 分段内容

1. `seg01_build_and_ctest`：CMake 构建 + 仓库自带 `ctest` 全量回归。
2. `seg02_boundary_unit_tests`：临界行为单元测试（65535/65536 条目、
   跨 4GB 自动切换、超限错误码）。
3. `seg03_before_after_4g`：2GB+3GB 真实文件——修复前 finalize 报
   "too many files"，修复后自动 ZIP64；miniz 与 python zipfile 均能读回。
4. `seg04_large_file_memory`：单文件 5GB 写/读/解压往返，峰值内存约 2MB
   （`/usr/bin/time -v`），解压结果与原文件逐字节一致。
5. `seg05_many_entries`：65535（经典）/65536/70000/80000 条目，
   python zipfile 交叉验证。
6. `seg06_interop`：旧格式互通——miniz 与 python zipfile 双向读写
   经典与 ZIP64 归档，CRC 校验一致。
7. `seg07_overlimit_errors`：超出扩展上限（条目数 2^32、中央目录 4GB）
   返回明确错误码。

## 复现

```sh
bash output/record_all.sh   # 重新执行全部分段并录屏（无需键盘操作）
```
