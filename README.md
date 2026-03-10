# FlatPaint

A lightweight raster image editor for macOS Apple Silicon, with a partial-open release of reusable public libraries.  
一款面向 macOS Apple Silicon 的轻量级位图编辑器，同时发布了部分可复用公共库的开源版本。

FlatPaint is designed for practical desktop image editing with a compact application structure and a clear separation between the end-user app and the reusable libraries behind it.  
FlatPaint 面向实际桌面图像编辑场景，强调轻量、直接和清晰的工程结构，并将终端应用与底层可复用库明确分离。

## Why FlatPaint
## 项目定位

FlatPaint focuses on the parts of raster editing that matter most in day-to-day use: layers, selections, painting tools, drawing tools, transforms, export controls, and platform-native integration on macOS.  
FlatPaint 聚焦于位图编辑中最常用、最核心的能力：图层、选区、绘画工具、绘图工具、图像变换、导出控制，以及 macOS 平台上的原生集成体验。

This repository also includes a partial-open release pack for several reusable FPC / Lazarus-related libraries extracted from the project.  
本仓库同时包含一个部分开源发布包，用于公开发布从项目中拆分出的若干 FPC / Lazarus 相关可复用库。

## Highlights
## 功能亮点

- Multi-layer raster editing with undo / redo and blend modes  
  支持多图层位图编辑，并具备撤销 / 重做与混合模式

- Selection tools including rectangle, ellipse, lasso, magic wand, move selection, and move pixels  
  提供完整选区工具，包括矩形、椭圆、套索、魔棒、移动选区与移动像素

- Paint tools including pencil, brush, eraser, fill, gradient, clone, and recolor  
  提供常用绘画工具，包括铅笔、画笔、橡皮、填充、渐变、仿制与重着色

- Drawing tools including text, line, rectangle, rounded rectangle, ellipse, and freeform drawing  
  提供绘图工具，包括文字、直线、矩形、圆角矩形、椭圆与自由绘制

- Image and layer operations such as crop, resize, rotate, flip, and general layer editing  
  支持裁剪、缩放、旋转、翻转以及常规图层操作

- Export options dialog with preview and format-specific controls  
  提供带预览的导出选项对话框，并支持按格式提供专属参数控制

- Baseline compatibility import for XCF / KRA / PDN formats (partial by design)  
  提供对 XCF / KRA / PDN 格式的基础兼容导入能力（按设计为部分支持）

- System clipboard integration and macOS-native menu / appearance bridges  
  集成系统剪贴板，并提供 macOS 原生菜单与外观桥接能力

## Platform
## 平台支持

- Target platform: macOS Apple Silicon (`arm64` / `aarch64`)  
  目标平台：macOS Apple Silicon（`arm64` / `aarch64`）

- Minimum supported macOS version: `11.0` (Big Sur)  
  最低支持的 macOS 版本：`11.0`（Big Sur）

- Main release artifact: `FlatPaint.app`  
  主发布产物：`FlatPaint.app`

## Quality
## 质量情况

- CI regression suite: 351 tests passing at packaging time  
  CI 回归测试：打包时共有 351 项测试通过

- About metadata is embedded at build time from `assets/about/*.txt`  
  About 元数据在构建时从 `assets/about/*.txt` 嵌入

## Release Package
## 发布包内容

The release payload includes:  
发布包包含：

- `release/FlatPaint.app` — macOS Apple Silicon application bundle  
  `release/FlatPaint.app` —— macOS Apple Silicon 应用程序包

- `release/APP_FEATURES.md` — feature summary  
  `release/APP_FEATURES.md` —— 功能摘要

- `release/packages/*.zip` — application and library source packages  
  `release/packages/*.zip` —— 应用程序与库源码压缩包

- `release/packages/SHA256SUMS.txt` — checksum file  
  `release/packages/SHA256SUMS.txt` —— 校验文件

## Open Libraries
## 开源库

The following reusable libraries are included in the public release:  
以下可复用库已包含在公开发布内容中：

1. `fp-raster-core` — pure FPC raster core library  
   `fp-raster-core` —— 纯 FPC 光栅核心库

2. `fp-viewport-kit` — pure FPC viewport / zoom / ruler helpers  
   `fp-viewport-kit` —— 纯 FPC 视口 / 缩放 / 标尺辅助库

3. `fp-lcl-raster-bridge` — LCL bridge between `TRasterSurface` and `TBitmap`  
   `fp-lcl-raster-bridge` —— `TRasterSurface` 与 `TBitmap` 之间的 LCL 桥接层

4. `fp-lcl-clipboard-meta` — clipboard metadata helper for LCL  
   `fp-lcl-clipboard-meta` —— 面向 LCL 的剪贴板元数据辅助库

5. `fp-macos-lcl-bridge` — macOS Cocoa bridge units for Lazarus LCL  
   `fp-macos-lcl-bridge` —— 面向 Lazarus LCL 的 macOS Cocoa 桥接单元

Each library folder includes:  
每个库目录都包含：

- `README.md` — usage and scope  
  `README.md` —— 用法与范围说明

- `LICENSE`  
  `LICENSE` —— 许可证文件

- `build.sh` — standalone smoke build script  
  `build.sh` —— 独立 smoke build 构建脚本

- `examples/smoke_test.lpr`  
  `examples/smoke_test.lpr` —— 基础冒烟测试示例

## Build
## 构建

### Build the release app
### 构建发布版应用

From the project root:  
在项目根目录执行：

```bash
bash ./scripts/build-release.sh