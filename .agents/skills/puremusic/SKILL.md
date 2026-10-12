---
name: puremusic
description: Pure-music 项目开发指南，覆盖 Windows Flutter/Dart 前端、Rust 后端、音频播放、歌词解析与渲染、桌面歌词、主题背景、设置、FFI、文档和测试。处理此仓库的代码理解、问题诊断、功能开发、缺陷修复、性能优化或代码审查时使用。
---

# Pure-music 开发

## 开始工作

1. 先读仓库根目录的 `AGENTS.md`，再检查 `git status --short`；把已有改动视为用户工作，不覆盖、不回退。
2. 先定位实际调用链和现有实现，再决定修改位置；代码与本 skill 不一致时，以当前代码为准，并同步修正本 skill 中的过时信息。
3. 控制修改范围，不顺手重构无关代码；不创建分支、不提交、不推送，除非用户在当前任务中明确要求。

## 受保护功能

修改下列功能前先明确告知用户将涉及哪些文件和行为：

- 原文、翻译、注音的分组管理。
- 音调调节。
- 流光背景的音频律动模式。
- 其他已经上线的特有功能；无法确定是否属于保护范围时，先询问用户。

告知后再编辑相关文件，不把相邻重构混入修改。

## 代码导航

- 功能 → 核心文件全表见 [references/features-index.md](references/features-index.md)：20 类功能（播放、音频、曲库、歌词、桌面歌词、演出模式、统计、设置、系统集成、打包测试）逐条列出实现文件。定位代码先查它，不用扫目录；下面只留索引里没有的额外约定。
- 应用内快捷键与全局热键：`lib/core/hotkeys.dart`、`lib/core/hotkey_binding.dart`、`lib/page/settings_page/hotkey_settings.dart`；设置入口在「设置 → 播放」。
- 详情页播放动作：顺序播放 `PlayAll`、随机播放 `ShufflePlay`（`lib/page/uni_page_components.dart`），开关是 `enablePlayAll` / `enableShufflePlay`。专辑、歌手、文件夹、歌单详情页都会传入这两项。
- 播放页控件常驻由 `AppSettings.alwaysShowNowPlayingControls` 控制，改动后调 `AppSettings.rebuildNotifier.rebuild()` 触发控件重建。
- 桌面歌词：主进程 `lib/play_service/desktop_lyric_service.dart`，消息协议 `packages/desktop_lyric/`；歌词窗的换行与逐词高亮组件在外部 `pure-player-lyric` 仓库维护，本仓库 `desktop_lyric/` 只有预编译产物。
- 任务栏缩略图播放按钮与 Alt+Tab 封面预览的原生实现在 `windows/runner/taskbar_thumbnail.*`。
- Dart FFI 绑定：`lib/native/rust/`；Rust API：`rust/src/api/`；Windows 平台代码：`windows/`。

- 涉及播放页样式、动画、播放进度、歌词跟随、频谱或动态背景时，编辑前完整阅读 [播放页性能规则](references/player-performance.md)。
- 负责拆任务、派给其他 agent、验收结果时，先读 [调度与做事方式](references/orchestration-playbook.md)。
- 卡顿、掉帧、CPU/内存、扫库慢、FFI 开销时，先读 [同栈优化方案备忘](references/stack-perf-sources.md)（3.44 可用）。不要打开 `references/stack-perf-impeller-3.47.md`，那份在升级到 Flutter 3.47 前禁用。播放页每帧约束仍以播放页性能规则为准。

## 既有模式

- 使用 `AppSettings.instance` 管理全局配置，使用 `AppPreference.instance` 管理播放偏好。
- 播放页显示设置通过 `AppSettings.rebuildNotifier` 通知控件重建；新增设置要同时接入读取、保存和设置页入口。
- 使用 `ThemeProvider` 下发主题；使用 `LyricRenderConfig` 和 `LyricViewController` 管理歌词视觉配置，不引入新的状态管理库。
- 封面主色和调色板由 Rust 提取，Dart 侧的 `ColorExtractionService` 只缓存提取结果，不增加重复的 Dart 取色链路。
- 使用 `Symbols.xxx` 图标；颜色透明度使用 `Color.withValues(alpha:)`。
- 不在 `build` 中启动动画、读配置或触发其他副作用；异步回调更新界面前检查 `mounted`。
- 把 `lib/native/rust/` 和 `rust/src/frb_generated.rs` 中的绑定视为生成代码；修改 Rust API 后通过项目现有生成配置更新，不手工维护生成结果。
- 桌面歌词只把歌词文件明确标出的长空白行视为过渡行；普通歌词行之间的时间间隔不自动生成插播空白。
- 演出模式的编排顺序只替换当前播放队列，不修改来源歌单；调整参数时复用已缓存的音频分析结果。

## 播放页约束

- 复用现有同步信号、共享帧驱动和缓存，不为单个视觉组件新增常驻高频订阅、短周期定时器或独立 Ticker。
- 每帧路径不做 FFI、文件读取、图片解码、调色板提取、大集合分配或整页 `setState`。
- 仅让可见且需要动画的页面、歌词行和背景执行逐帧工作；暂停、隐藏、切换模式和销毁时停止或解绑。
- 为图片、Painter、Paragraph、滤镜、频谱和调色板缓存定义上限与清理时机；保留切歌过渡需要的新旧资源，过渡后释放旧资源。
- 没有相同条件下的运行态数据时，只陈述静态检查结果，不宣称内存、CPU、GPU 或帧率已经达标。

## 修改与验证

1. 复用仓库已有写法，注释只说明做了什么和为什么做，不写来源，不增加无意义的空行。
2. 仅格式化本次修改的源文件；对改动范围执行静态分析，确保没有新增警告或错误。
3. 改了解析、编排等纯逻辑时补对应单元测试（`test/`），先跑既有相关测试确认通过；并非每处小改动都必须补测试。
4. 除非用户明确要求，不主动运行完整构建或完整测试套件；未运行的验证项目如实说明，不把静态分析写成编译或性能结论。
5. 完成后检查 `git diff --check`、相关 diff 和 `git status --short`，确认没有覆盖用户已有改动。
6. 最终回复不超过 3 句，说明改了哪些文件、做了什么，以及实际执行的验证，不粘贴 diff。

## 发布文档

- GitHub Release 正文按用户能理解的功能分组书写，优先说明可感知的变化和使用位置。
- 拟定 Release 前，以最近一次由 Action 同步的版本提交为边界核对全部用户可见提交，不能只根据最近几条提交概括。
- `page/docs/guide/changelog.md`、`page/docs/public/latest-release.json` 和版本同步文件由 GitHub Action 根据 Release 自动更新，不在常规功能提交中手工维护。
