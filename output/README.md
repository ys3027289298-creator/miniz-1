# gzip 流式压缩容器 — 验收产物

## 背景
miniz 原本只有 zlib 包装流和 ZIP 归档格式。本次在 zlib 风格 API 上新增 gzip
(RFC 1952) 流式容器：`mz_deflateInit2()` / `mz_inflateInit2()` 的
`window_bits` 传入 `MZ_DEFAULT_WINDOW_BITS + 16` 即可读写 `.gz` 流，
解压时自动校验 CRC-32 与 ISIZE 尾，校验失败返回 `MZ_DATA_ERROR`。
既有接口签名与行为逐字节不变（gzip 为新增的可选 window_bits 取值）。

## 产物清单
- `demo.sh` — 分段演示脚本（5 段，段首标题 + 段间停顿，全程无需键盘输入）
- `demo.cast` — asciinema 录屏（`asciinema play output/demo.cast` 回放）
- `gen_material.py` / `material/` — 自造小素材（< 300KB，确定性生成）
- `logs/segment1..5_*.log` — 各分段完整日志
- `ratio_report.txt` — 压缩率对比表

## 验收结论
1. 校验错误可检出：载荷比特翻转、CRC-32 尾翻转、文件截断均被
   `mz_inflate()` 以 `MZ_DATA_ERROR` 检出（见 logs/segment4_checksum.log）。
2. 旧接口零回归：examples 1-6 标准输出与 git HEAD 基线完全一致，
   example2 的 zip 成员、example6 的 PNG、example3 的 zlib 流逐字节一致，
   miniz_tester 归档模式确定性输出一致；catch_tests 131389 断言全过
   （见 logs/segment2_regression.log）。
3. 压缩率：miniz gzip 容器 46182 字节 vs zip 归档 47590 字节（原始 240198），
   与归档模式基本持平（差异仅为容器头尾开销），见 ratio_report.txt。

## 复现
```sh
python3 output/gen_material.py   # 重新生成素材
bash output/demo.sh              # 重跑全部分段（PAUSE=0 可去掉段间停顿）
```
