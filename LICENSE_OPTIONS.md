# License Decision / 许可证决定

(final for this export / 本次发布最终版)

## Selected policy / 选定策略

Open-source libraries under `libs/` are released under:
`libs/` 目录下的开源库基于以下许可证发布：

- GNU LGPL v2.1+ with Lazarus modified linking exception.
  GNU LGPL v2.1+，附带 Lazarus 修改版链接例外条款。

Reference texts / 参考文本：
- `licenses/COPYING.LGPL.txt`
- `licenses/COPYING.modifiedLGPL.txt`

## Rationale / 选择理由

- Compatible with Lazarus/LCL ecosystem expectations.
  与 Lazarus/LCL 生态系统的惯例兼容。
- Keeps integration path straightforward for FPC/Lazarus users.
  为 FPC/Lazarus 用户保持简洁的集成路径。
- Avoids introducing additional custom licensing in this public package.
  避免在本公开发布包中引入额外的自定义许可证。

## Scope boundary / 适用范围

- This decision applies to the source published under `libs/`.
  本许可证决定仅适用于 `libs/` 目录下发布的源代码。
- It does not automatically apply to all code outside `libs/`.
  它不会自动适用于 `libs/` 目录以外的任何代码。
