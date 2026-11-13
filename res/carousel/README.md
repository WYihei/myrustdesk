# 旋转木马远程桌面（Windows x64）

忙的团团转已经麻木的牛马专用的远程桌面软件。

界面名称为“旋转木马远程桌面”；安装目录、Windows 服务、进程和协议标识使用 `CarouselRemote`。
源码的安装名称校验只接受 ASCII 字符，因此保留它，不扩大可用名称范围。
包内 DLL、Cargo 包名和部分第三方组件继续使用上游标识，以保持构建和加载正常。

## 内置服务器

`res/carousel/client.json` 在编译时通过 `include_str!` 嵌入 DLL，分发时不需要旁置配置。
ID 服务器为 `wochaoyuan.fun`，使用默认端口。
公钥已从用户提供的文件复制并检查为 32 字节；原始文件和路径均不进入构建产物。
中继地址留空，沿用上游从 ID 服务器获取中继的逻辑。若部署的中继不同，请填写 `relay_server`。
这些服务器设置作为覆盖配置应用；更换服务器或公钥后要重新编译。
这是公开可分发的服务器公钥；不要把 `id_ed25519` 私钥或访问密码放进这里。

## 推荐：GitHub Actions 编译

1. 将本次改动提交并推送到自己的 fork（含新增的资源 PNG、JSON、脚本和工作流）。
2. 在自己的仓库 Actions 中启用工作流，选择 **Build Carousel Windows EXE** → **Run workflow**。
3. 完成后下载 `CarouselRemote-windows-x64` artifact；解压得到 `旋转木马远程桌面.exe`。

工作流仅在手动运行时触发，只构建并上传 artifact，不发布 Release。
它复用当前仓库的桥接生成流程，以及上游 Windows x64 的依赖版本和自定义 Flutter 引擎。
无需填写官方签名服务密钥；产物未经代码签名。
首次构建依赖下载较多。当前修改尚未经过完整 CI 编译和 Windows 运行验证。

## 本地编译

先按 `.github/workflows/carousel-windows.yml` 安装和配置：

- Visual Studio C++ 工作负载及 Windows SDK、Rust MSVC 工具链。
- Flutter **3.24.5**，以及该工作流使用的 Windows x64 自定义 Flutter 引擎和 dropdown 补丁。
- LLVM **15.0.6**，设置 `LIBCLANG_PATH`。
- vcpkg 提交 `9e593bb18ea69cc5095e012465dcd675a822ed0d`，设置 `VCPKG_ROOT`，安装仓库清单中 `x64-windows-static` 依赖。
- Python，以及 `libs/portable/requirements.txt` 中的打包依赖。
- `git submodule update --init --recursive`（此次已初始化）。

桥接文件被上游 gitignore 排除；先在 Actions 运行仓库已有的桥接流程，下载 `bridge-artifact` 并按相对路径解压到仓库。
需要 `src/bridge_generated.rs`、`src/bridge_generated.io.rs`、`flutter/lib/generated_bridge.dart` 和对应的 freezed 文件。
请使用当前提交生成的桥接文件，不要混用其它版本，也不要在本地重新运行 codegen。

在仓库根目录、配置好 C++ 和上述环境变量的终端中运行：

```powershell
python res/carousel/package_windows.py --check
python build.py --portable --flutter --skip-portable-pack --hwcodec --vram
python -m pip install -r libs/portable/requirements.txt
python res/carousel/package_windows.py
```

产物为 `dist/旋转木马远程桌面.exe`。打包会先复制 Flutter 输出到 `dist/carousel-payload` 并将内部主程序命名为 `CarouselRemote.exe`。
再次打包前，将旧的 `dist/carousel-payload` 移走。脚本不会自动删除已有目录。
该 EXE 包含 Flutter 运行所需的资源和依赖，启动时解压到本地缓存；它不是不落盘的单二进制程序。

发布前用干净 Windows 机器检查名称、图标、服务器设置、主动连接、被控连接和安装后的服务。
默认不内置固定访问密码，远程控制仍沿用上游的密码或人工确认流程。

## Logo

母版：`res/carousel/logo-master.png`（内置 image_gen 工具生成，透明外背景）。
提示词：为旋转木马远程桌面设计应用图标；困倦木马、旋转箭头与鼠标指针；深海军蓝、暖琥珀与少量青绿；简洁、易辨认、无文字。
PNG 与 ICO 为母版的机械缩放/格式转换，ICO 包含 16/24/32/48/64/128/256 七档尺寸。
界面横版文字由本机微软雅黑字体排版，提供明暗两版；关于页包含用户指定的完整标语。

## 改动影响范围

- `src/carousel.rs` 与 `src/common.rs`、`src/lib.rs`：Windows 启动时设置内部品牌标识与服务器覆盖配置。
- `src/lang.rs`、`src/flutter.rs`、`src/tray.rs`、`flutter/lib/common.dart`：翻译中的品牌、窗口标题和托盘提示显示中文名；技术标识保持 ASCII。
- `src/platform/windows.rs`：安装后的应用列表使用中文显示名，安装和服务标识仍为 ASCII。
- `flutter/lib/desktop/pages/desktop_setting_page.dart`：关于页标语。
- Windows 资源、便携打包器元数据和图像资源：EXE 属性、图标、启动解压提示和应用内 Logo。
- `.gitignore`：允许新增品牌 PNG 被提交，忽略打包产物。
- 新工作流与打包脚本：增加单 EXE 构建入口；保留现有工作流和传输、鉴权实现。

保留上游 LICENSE、版权和第三方声明。分发修改版时同时提供对应源码和许可证。
