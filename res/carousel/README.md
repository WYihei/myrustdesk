# carouseldesk（Windows x64）

基于 RustDesk 的自建服务器 Windows 客户端，显示名称为 `carouseldesk`，使用木马 Logo 和黄色主题（`#FFBF24`）。
不显示额外的中文品牌横幅；黄色按钮配深蓝色文字，浅色主题的文字按钮使用深琥珀色保证可读性。
安装目录、Windows 服务和协议标识仍为 `CarouselRemote`，兼容已安装版本的配置与服务标识。
内部 DLL、Cargo 包名及第三方组件保留上游标识。保留上游版权和许可证声明。

## 内置服务器

`res/carousel/client.json` 通过 `include_str!` 在编译时嵌入，分发时无需旁置配置。
ID 服务器为 `wochaoyuan.fun`，使用默认端口。
公钥是从指定文件复制的 32 字节 Ed25519 公钥；原始文件路径不进入产物。
中继地址留空，沿用上游从 ID 服务器获取中继的逻辑。若中继不同，请填写 `relay_server`。
这些值作为覆盖配置应用；修改服务器或公钥后需要重新编译。
公钥可以随客户端公开；不要将服务器私钥或访问密码放入配置。

## GitHub Actions 构建

向 `master` 推送代码会触发 **Carousel Windows CI**，调用专用 Windows 构建工作流。
也可选择 **Build carouseldesk Windows EXE** → **Run workflow** 手动构建。
完成后下载 `CarouselRemote-windows-x64` artifact，解压得到 **carouseldesk.exe**。
流程使用 `contents: read` 权限，只上传 artifact，不发布 Release。
它复用当前仓库的桥接生成流程、Windows x64 依赖和自定义 Flutter 引擎。
首次依赖下载较多；没有代码签名。当前品牌和主题更新仍需 CI 完整编译与 Windows 界面运行验证。

## 本地构建

按 `.github/workflows/carousel-windows.yml` 配置：

- Visual Studio C++ 工作负载、Windows SDK 和 Rust MSVC 工具链。
- Flutter **3.24.5**，以及工作流中的 Windows x64 自定义 Flutter 引擎和 dropdown 补丁。
- LLVM **15.0.6**，设置 `LIBCLANG_PATH`。
- vcpkg 提交 `9e593bb18ea69cc5095e012465dcd675a822ed0d`，设置 `VCPKG_ROOT`，安装仓库清单的 `x64-windows-static` 依赖。
- Python、`libs/portable/requirements.txt` 中的依赖。
- 运行 `git submodule update --init --recursive`。

桥接文件被 gitignore 排除。先用仓库 Actions 的桥接流程生成当前提交的 `bridge-artifact`，按相对路径解压到仓库。
需要 `src/bridge_generated.rs`、`src/bridge_generated.io.rs`、`flutter/lib/generated_bridge.dart` 和对应 freezed 文件。
不要混用其它版本的桥接文件，也不要在本地重新运行 codegen。

在仓库根目录、配置好上述环境的终端运行：

```powershell
python res/carousel/package_windows.py --check
python build.py --portable --flutter --skip-portable-pack --hwcodec --vram
python -m pip install -r libs/portable/requirements.txt
python res/carousel/package_windows.py
./res/carousel/verify_windows_icon.ps1 -Executable @('dist/carouseldesk.exe', 'dist/carousel-payload/carouseldesk.exe')
```

单 EXE 产物位于 `dist/carouseldesk.exe`。打包器将 Flutter 输出复制到 `dist/carousel-payload`，内部主程序名为 `carouseldesk.exe`。
再次打包前将旧的 `dist/carousel-payload` 移走；脚本不会自动删除已有目录。
单 EXE 内含资源和依赖，启动时解压到本地缓存。
发布前用干净 Windows 机器验证主动连接、被控连接、安装后的服务、主题和快捷方式图标。
不内置固定访问密码；继续使用上游密码或人工确认流程。

## 图标与验证

Logo 母版是 `res/carousel/logo-master.png`（内置 image_gen 生成，透明外背景）。
提示词：困倦木马、旋转箭头与鼠标指针；海军蓝、暖琥珀与少量青绿；简洁、易辨认、无文字。
ICO 使用母版的机械缩放和格式转换，包含 16/24/32/48/64/128 档 32 位 DIB 及 256 档 PNG。
EXE 图标、托盘图标、Flutter 原生窗口图标和 `flutter/assets/icon.ico` 使用相同图标。
最后一个路径也是安装器为快捷方式和应用列表查找自定义图标的位置。
便携打包器显式嵌入 ID 101 的图标组，并在图标、manifest、包元数据变化时重新编译资源，避免复用旧图标缓存。
`verify_windows_icon.ps1` 将最终外层 EXE 和内部客户端的 RT_GROUP_ICON / RT_ICON 与品牌 ICO 逐项比较；缺失或不一致即中止上传。
本机已经通过 rc.exe 编译图标进测试 EXE、逐字节验证、缺图标反例和 Windows Shell 图标提取验证。

## 本次改动影响范围

- `src/carousel.rs`、`flutter/lib/common.dart`、Windows 版本资源和打包器元数据：显示名称及打包文件名改为 `carouseldesk`。
- `flutter/lib/common.dart`、`flutter/lib/desktop/widgets/button.dart`、关于页：黄色主题及对应文字对比度，移除中文标语覆盖。
- 删除 `flutter/assets/logo*.png`：移除额外的中文横幅，保留原有布局和木马应用图标。
- 图标、解压提示图片、`libs/portable/build.rs`：补齐运行时 ICO 并更新 EXE 图标资源及重建依赖。
- 打包脚本和 Windows 工作流：新 EXE 文件名，上传前校验真实图标资源。

传输、鉴权、服务器和公钥配置保持不变。保留上游 LICENSE、版权和第三方声明，分发修改版时提供对应源码和许可证。
