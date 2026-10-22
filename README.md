# HMPlayer · HarmonyOS 音视频播放器

![Platform](https://img.shields.io/badge/Platform-HarmonyOS%206.0%2B-black)
![Language](https://img.shields.io/badge/Language-ArkTS-3178C6)
![UI](https://img.shields.io/badge/UI-ArkUI%20Declarative-29A5E8)
![TargetSDK](https://img.shields.io/badge/Target%20SDK-API%2024-00A98F)
![Modules](https://img.shields.io/badge/Modules-1%20HAP%20%2B%205%20HAR-555555)
![Lines](https://img.shields.io/badge/ArkTS-~12k%20lines-4B8BBE)

> 一款使用 **ArkTS / ArkUI** 从零实现的 HarmonyOS 本地音视频播放器：完整的视频库与逻辑文件夹管理、系统播控中心与投播、画中画、后台播放、沉浸式音频播放与滚动歌词、隐私保险柜。
>
> 项目采用「产品层 / 特性层 / 公共能力层」的三层 HAR 模块化架构，播放内核、媒体会话、数据持久化均作为独立公共包被音视频两个特性模块复用。

---

## 目录

- [录屏演示](#录屏演示)
- [项目简介](#项目简介)
- [功能特性](#功能特性)
- [技术架构](#技术架构)
- [核心技术实现](#核心技术实现)
- [用到的系统能力](#用到的系统能力)
- [代码规模](#代码规模)
- [快速开始](#快速开始)
- [当前限制](#当前限制)
- [说明](#说明)

---

## 录屏演示

### 视频

<video height="480" controls>
    <source src="./screenshot/video_screen_cap.mp4" type="video/mp4">
</video>

### 音频

<video height="480" controls>
    <source src="./screenshot/audio_screen_cap.mp4" type="video/mp4">
</video>

---

## 项目简介

**HMPlayer** 是一款面向 HarmonyOS 手机 / 平板的本地音视频播放器应用。它不做"简单调一个播放器"的 Demo，而是把本地媒体管理这件事做完整：文件怎么进来、怎么被组织、怎么被检索、怎么被安全存放、怎么被系统级播控接管，每个环节都有对应实现。

项目覆盖两条完整业务线：

- **视频线**：以"逻辑文件夹"组织视频（新建 / 重命名 / 移动 / 级联删除），支持三种导入来源、多选批量操作、隐私保险柜，以及带手势控制、锁定、横屏、画中画、投播、后台听、定时关闭的播放器。
- **音频线**：以"歌单 / 专辑 / 艺术家"三个维度组织音频，支持收藏、歌单增删、元数据与歌词编辑、逐行滚动歌词、沉浸式播放页与横屏歌词页，并与系统播控中心（锁屏、耳机线控、蓝牙设备）打通。

技术上有两个我自己比较满意的取舍：

1. **播放能力全部沉到公共包**。`AVPlayerManager` 封装播放器状态机，`MediaSessionManager` 封装媒体会话与投播，特性模块只关心"播什么"，不关心"怎么播"。音视频两条线因此共用同一套内核，投播、后台播放、播控中心能力只需实现一次。
2. **用关系型数据库维护"虚拟媒体库"**。导入的文件副本落在文件系统，媒体组织结构（文件夹树、歌单、收藏、封面、歌词路径）存在 RDB 里。好处是重命名、移动、保险柜这些操作只改元数据、不动真实文件，且全部能在事务里保证一致性。

> 技术栈：ArkTS / ArkUI（声明式 UI）· Stage 模型 · AVPlayer · AVSession（AVCast）· PiPWindow · relationalStore · Preferences · 长时任务 · 生物认证

---

## 功能特性

### 视频

**媒体库与组织**

| 能力         | 说明                                                                                                  |
| ------------ | ----------------------------------------------------------------------------------------------------- |
| 逻辑文件夹树 | 新建 / 重命名 / 移动 / 级联删除，支持任意层级嵌套，真实文件不重排                                     |
| 视图模式     | 列表 / 宫格（`lanes` 1 或 2），偏好持久化                                                             |
| 排序         | 创建时间 / 文件名 / 文件大小，支持升降序；文件名排序经 `i18n.Transliterator` 转写，中英文混排不会乱序 |
| 多选批量     | 全选 / 取消全选、批量删除、批量移动（文件夹树选择器）、批量分享、批量存入保险柜                       |
| 隐私保险柜   | 独立目录 `/*/`，进入前需通过 `userAuth` 指纹或 PIN 认证（ATL3），支持移入 / 移出                      |

**导入**

- 三种来源：系统图库（`PhotoViewPicker`）、文件管理（`DocumentViewPicker`）、下载目录递归扫描
- 文件 **SHA256 分块摘要**判重，同名但内容不同的文件自动改名 `xxx(1).mp4`
- 导入时用 `AVMetadataExtractor` 提取元数据、用 `AVImageGenerator` 抽首帧生成缩略图并保存到沙箱

**播放**

- `XComponent` + `AVPlayer` 渲染
- 手势控制：单击显隐控制面板 · 长按 3× 倍速 · 水平滑动快进快退（100vp ≈ 10s）· 左半屏上下滑调亮度 / 右半屏上下滑调音量
- 播放器锁定、横竖屏切换、沉浸式全屏（隐藏状态栏与导航条）
- 倍速 6 档（0.5×–2.0×）、循环模式 4 种（播完暂停 / 自动连播 / 单集循环 / 列表循环）
- **画中画**：`PiPWindow`，播放中可切小窗，小窗控制面板可播放 / 暂停
- **投播**：`AVCastPicker` + `AVCastController`，支持 Cast+ 与 DLNA 协议
- **后台听视频**开关：关闭画面但保留音频后台播放
- 定时关闭：按时长（时 / 分）或"播完当前视频后停止"
- 系统分享（`systemShare`，带缩略图）

### 音频

**媒体库**

- 三个入口维度：**歌单**（全部音频 / 我的收藏 / 自建歌单）、**专辑**、**艺术家**
- 歌单：新建 / 删除、批量添加到歌单、从歌单移除（均支持多选）
- 收藏状态与系统播控中心双向同步
- 排序：标题 / 创建时间；视图：列表 / 宫格
- 导入：音频文件选择器、文件管理、下载目录递归扫描；自动抽取**专辑封面**并保存到沙箱

**编辑**

- 就地面板编辑：标题、专辑、歌手、专辑封面（替换 / 删除）、歌词（`.lrc` 导入 + 直接编辑）
- 元数据变更同步写库与列表项，无需重进页面

**播放**

- 沉浸式播放页：封面 + 歌词双 Tab 切换、进度条拖动、收藏、循环模式（单曲 / 列表 / 随机）、上一首 / 下一首、播放队列弹层
- **逐行滚动歌词**：解析 LRC 时间标签，随 `timeUpdate` 自动高亮并 `ScrollAlign.CENTER` 居中滚动；无歌词时降级为单行跑马灯
- **横屏歌词页**：大封面 + 歌词 + 完整控制条
- 播放队列（当前播放列表）快速切歌
- 倍速 6 档、定时关闭、系统分享
- **后台播放**：切后台自动申请长时任务，锁屏 / 播控中心 / 耳机线控均可控制

---

## 技术架构

### 分层与依赖

工程为一个 entry HAP + 五个 HAR 静态共享包，依赖方向严格单向：`products → features → common`。特性模块之间互不依赖，公共包不反向依赖业务。

```
┌─ products/phone（entry HAP）        应用装配层
│    EntryAbility：全屏 / 安全区 / 颜色模式
│    Index：底部 Tabs（视频、音频）+ Navigation 根路由
│    @Provide：AudioPlayerVM、VideoPlayerVM 全局单例
└──────────┬─────────────────────────────────────────────
           │  products → features
           ▼
┌─ features/video_library（HAR）      特性层（两者并列、互不依赖）
│    视频库、逻辑文件夹树、保险柜
│    视频播放页、手势控制、画中画、投播
├─ features/audio_library（HAR）
│    歌单 / 专辑 / 艺术家
│    沉浸式播放、滚动歌词、元数据编辑
└──────────┬─────────────────────────────────────────────
           │  features → common
           ▼
┌─ common/player（HAR）        AVPlayerManager、MediaSessionManager
├─ common/data_storage（HAR）  AudioLibraryStore、VideoLibraryStore、Settings
└─ common/util（HAR）          ContinuousTaskManager（长时任务）
```

### 模块职责

| 模块                                              | 类型      | 层   | 职责                                                                        | 对外导出                                             |
| ------------------------------------------------- | --------- | ---- | --------------------------------------------------------------------------- | ---------------------------------------------------- |
| [phone](products/phone/src/main/module.json5)     | entry HAP | 产品 | 应用入口、双 Tab 主导航、播放器 VM 单例注入、前后台切换分发、安全区全局下发 | `pages/Index`                                        |
| [video_library](features/video_library/Index.ets) | HAR       | 特性 | 视频库、文件夹树、保险柜、视频播放器                                        | `VideoLibraryView`、`VideoPlayerViewModel`           |
| [audio_library](features/audio_library/Index.ets) | HAR       | 特性 | 歌单 / 专辑 / 艺术家、音频播放器、歌词、元数据编辑                          | `AudioLibraryView`、`AudioPlayerViewModel`           |
| [player](common/player/Index.ets)                 | HAR       | 公共 | AVPlayer 状态机封装、AVSession 媒体会话与播控命令、投播控制                 | `AVPlayerManager`、`MediaSessionManager`             |
| [data_storage](common/data_storage/index.ets)     | HAR       | 公共 | RDB 存储（音 / 视频库、歌单、文件夹）、Preferences 设置、实体模型与枚举     | `AudioLibraryStore`、`VideoLibraryStore`、`Settings` |
| [util](common/util/Index.ets)                     | HAR       | 公共 | 后台长时任务的申请 / 释放 / 查询                                            | `ContinuousTaskManager`                              |

### 运行时数据流

1. **单向数据流**：`View（声明式 UI）` → `ViewModel（@Observed/@Track）` → `Store（RDB）` / `AVPlayerManager` → 回调 / `emitter` 事件 → 刷新 `View`。UI 层不直接操作 `AVPlayer` 与 `RDB`。
2. **播放状态单例**：两个播放器 ViewModel 在 [Index.ets](products/phone/src/main/ets/pages/Index.ets) 中创建，通过 `@Provide` / `@Consume` 以字符串 key（如 `AudioPlayerVM`）跨 `Navigation` 层级共享，避免 props 层层透传，也保证全局只有一个播放器实例。
3. **跨树通信**：列表页与播放器是兄弟组件，用 `emitter` 事件总线解耦（`ImportAudio`、`ToggleFavorite`、`MoveVideo`、`DeleteChoice` 等常量事件名约定在各自模块顶部），事件携带 `EventData` 载荷，接收方只做增量更新。
4. **系统回调回流**：播控中心的播放 / 暂停 / 上一首 / 快进快退等命令由 `MediaSessionManager` 统一接收，再分发到对应 ViewModel 方法，实现"UI 发起"与"系统发起"共用同一套业务入口。

### 目录结构

```
hm-player-main/
├── AppScope/                        # 应用级配置与图标（bundleName、versionName）
├── build-profile.json5              # 产品配置、SDK 版本、模块注册
├── oh-package.json5                 # 工程级依赖（hypium / hamock）
├── hvigor/                          # 构建参数
├── common/
│   ├── player/                      # 播放内核与媒体会话（HAR）
│   │   └── src/main/ets/
│   │       ├── player/AVPlayerManager.ets
│   │       └── media_session/MediaSession.ets
│   ├── data_storage/                # 持久化层（HAR）
│   │   └── src/main/ets/
│   │       ├── rdbms/               # Store、实体模型
│   │       └── preference/          # Settings、SettingKey/枚举/默认值
│   └── util/                        # 后台长时任务（HAR）
├── features/
│   ├── video_library/               # 视频特性（HAR）
│   │   └── src/main/ets/
│   │       ├── components/          # 库页外壳（标题栏、导入、多选、菜单）
│   │       ├── view/                # 播放器、文件夹列表、移动/重命名/定时弹窗
│   │       └── viewmodel/           # 库、列表、文件夹浏览、播放器、投播 VM
│   └── audio_library/               # 音频特性（HAR）
│       └── src/main/ets/
│           ├── components/          # 库页外壳
│           ├── view/                # 沉浸页、歌词、横屏、队列、编辑弹窗
│           ├── viewmodel/           # 库、歌单、列表、播放器、编辑 VM
│           └── model/               # LRC 歌词模型
└── products/phone/                  # 应用入口（HAP）
    └── src/main/ets/
        ├── entryability/            # 全屏、安全区、颜色模式
        └── pages/Index.ets          # 底部 Tab + Navigation 根容器
```

---

## 核心技术实现

### 1. 播放内核封装：把 AVPlayer 的状态机收进一个类

[player/AVPlayerManager.ets](common/player/src/main/ets/player/AVPlayerManager.ets) 把 `AVPlayer` 的异步状态机收敛成面向业务的 API：

- 以 `fd://${fd}` 方式加载本地文件，规避 URI 权限问题；`release()` 时统一关闭文件句柄，避免 fd 泄漏
- 在 `on('stateChange')` 内部自动完成 `initialized → prepare()`、`prepared → 设置 surfaceId → play()` 的流转，业务层不必关心状态机细节
- 进入 `prepared` 时设置 `audioInterruptMode = INDEPENDENT_MODE`，避免与其他音频应用互相打断
- `durationUpdate / timeUpdate / seekDone / stateChange / error` 五类事件通过 `Map<string, Function>` 注册回调，UI 侧按需订阅，避免全局单例被多处 `on()` 重复绑定
- `seek` 使用 `SEEK_CLOSEST` 精确跳转；`setMediaMuted` 用于投播时静音本地播放

**为什么这么设计**：音视频两条业务线共用同一份播放逻辑，投播、静音、倍速、释放策略只需在一处维护。

### 2. 媒体会话与投播：一次实现，音视频共用

[player/MediaSession.ets](common/player/src/main/ets/media_session/MediaSession.ets) 以单例封装 `AVSession`：

- **双会话类型**：音频会话与视频会话各自注册不同的控制命令集合（音频含 `playNext / playPrevious / setLoopMode / toggleFavorite`；视频含 `rewind / fastForward / outputDeviceChange`），切换类型时销毁重建，避免命令错配
- **元数据同步**：`setAVMetadata` 填充标题、歌手、时长、封面（`PixelMap`，无封面时回落到 rawfile 默认图）、歌词文本；`setAVPlaybackState` 同步播放状态、进度、循环模式、收藏、倍速
- **投播**：`setExtras({ requireAbilityList: ['url-cast'] })` 声明投播能力，`ProtocolType.CAST_PLUS_STREAM | TYPE_DLNA` 指定协议；设备选择交给 `AVCastPicker`，连接成功后由 [VideoCastViewModel.ets](features/video_library/src/main/ets/viewmodel/VideoCastViewModel.ets) 通过 `AVCastController.prepare/start` 下发媒体，播放 / 暂停 / seek 以 `AVCastControlCommand` 命令发送，同时本地 `AVPlayer` 静音
- 前端 UI 显示"远端投播中"遮罩，`outputDeviceChange` 回调断连后自动恢复本地播放

**收益**：锁屏控制、耳机线控、蓝牙设备切换、投播全部来自系统能力，无需自建控制通道。

### 3. 后台播放：长时任务与前后台协同

[util/ContinuousTaskManager.ets](common/util/src/main/ets/background_task/ContinuousTaskManager.ets) 封装 `backgroundTaskManager`：

- `startBackgroundRunning(context, ['audioPlayback'], wantAgent)` 申请长时任务，`wantAgent` 指向 `EntryAbility`，点击通知可回到应用
- `getAllContinuousTasks` 做幂等判断，避免重复申请
- 应用入口订阅 `applicationStateChange`，切后台时把 `isBackground` 下发给两个播放器：音频在播放则自动申请长时任务；视频遵循"后台听视频"开关，关闭时直接暂停
- 回到前台统一释放长时任务，避免任务泄漏被系统处罚

### 4. 媒体导入管线：去重、元数据、缩略图一次做完

导入是这类应用最容易写脏的一段，这里拆成五步流水线（[AudioLibraryViewModel.ets:233](features/audio_library/src/main/ets/viewmodel/AudioLibraryViewModel.ets#L233) / [VideoLibraryViewModel.ets:238](features/video_library/src/main/ets/viewmodel/VideoLibraryViewModel.ets#L238)）：

1. **复制到目标目录**：目标已存在同名文件时先比内容 —— 用 `cryptoFramework.createMd('SHA256')` 以 1MB 缓冲区**分块摘要**（大文件不整读进内存）；内容相同且已入库 → 判定重复导入并跳过；内容相同但未入库 → 复用已有文件；内容不同 → 自动改名为 `name(1).mp4`
2. **抽元数据**：`AVMetadataExtractor.fdSrc` + `fetchMetadata()`，拿到时长、宽高、标题、歌手、专辑等信息，序列化后存 `METADATA` 字段，供播放器与画中画读取宽高比
3. **抽封面 / 缩略图**：音频用 `fetchAlbumCover()` 取内嵌封面，视频用 `AVImageGenerator.fetchFrameByTime(0, AV_IMAGE_QUERY_NEXT_SYNC)` 抽首帧，`ImagePacker` 以 JPEG 100 质量 `packToFile` 保存到沙箱
4. **落库**：写入 RDB，返回行号
5. **增量刷新 UI**：`emitter.emit` 携带 `{ folder, rowId }`，列表页按当前排序规则把新项**插入到正确位置**（而非整表重载）

所有 `fileIo` 句柄与 `PixelMap` 均在 `finally` 中释放，避免批量导入时的资源堆积。

### 5. 数据持久化：虚拟媒体库的库表设计

[data_storage](common/data_storage/src/main/ets/rdbms) 使用两个 `RdbStore`（`VideoStore.db` / `AudioStore.db`，`SecurityLevel.S3`）：

```sql
-- 视频库
VIDEO_IMPORTED  (ID, NAME, DATE_ADD, METADATA, VIDEO_PATH UNIQUE, THUMBNAIL_PATH, FOLDER)
FOLDER_CREATED  (ID, PATH UNIQUE, PARENT, DATE_ADD)

-- 音频库
AUDIO_IMPORTED  (ID, TITLE, DATE_ADD, METADATA, ALBUM, ARTIST,
                 AUDIO_PATH UNIQUE, COVER_PATH, LYRICS_PATH, FAVORITE)
PLAYLIST_CREATED( ID, NAME UNIQUE, DATE_ADD)
PLAYLIST_AUDIO  (PLAYLIST_NAME, AUDIO_ID, PRIMARY KEY(PLAYLIST_NAME, AUDIO_ID))
```

几个设计要点：

- **树形目录用自引用**：文件夹不落真实文件系统结构，`PATH`（如 `/旅行/2024/`）+ `PARENT` 自关联；移动 / 重命名时递归遍历子树，把子视频的 `FOLDER` 与子目录的 `PARENT`、`PATH` 全量重算后在**一个事务里批量更新**
- **多表一致性用事务**：删除音频要同时清 `AUDIO_IMPORTED` 与 `PLAYLIST_AUDIO`；删除文件夹要同时清文件夹及其全部视频 —— 均通过 `createTransaction()` / `commit()` / `rollback()` 保证要么全成、要么全回滚
- **多对多用关联表**：歌单与音频通过 `PLAYLIST_AUDIO` 复合主键关联，天然去重
- **路径唯一约束**：`VIDEO_PATH` / `AUDIO_PATH` 建 UNIQUE，从库层面兜住重复导入
- **设置走 Preferences**：排序方式、排序规则、视图模式、循环模式、后台听开关共 11 个 key，[SettingsModel.ets](common/data_storage/src/main/ets/preference/SettingsModel.ets) 统一维护 `SettingKey` 枚举、默认值表与取值枚举，读写统一走 [Settings.ets](common/data_storage/src/main/ets/preference/Settings.ets)

### 6. 播放器交互：手势、亮度 / 音量、画中画

[VideoPlayerView.ets](features/video_library/src/main/ets/view/VideoPlayerView.ets) 用一个 `GestureGroup(Exclusive)` 编排三种手势，互斥避免冲突：

| 手势     | 实现                                                                                                                                                                                        |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 长按     | 临时切到 `SPEED_FORWARD_3_00_X`，抬手指恢复 1×，并显示"倍速播放中"提示                                                                                                                      |
| 水平 Pan | 按 `offsetX / 100vp × 10s` 映射 seek 目标；拖动中只更新 UI（`isSeeking`），抬手一次性 `seek`                                                                                                |
| 垂直 Pan | 按下时用 `fingerInfos[0].globalX` 与屏幕宽度比较判定左右半屏：左侧调 `window.setWindowBrightness`，右侧调系统音量（`AudioVolumeManager`，0–15 档）；同时用 `AVVolumePanel` 展示系统音量面板 |

其他细节：

- **沉浸式全屏**：[EntryAbility.ets](products/phone/src/main/ets/entryability/EntryAbility.ets) 打开 `setWindowLayoutFullScreen(true)`，监听 `avoidAreaChange` 把状态栏 / 导航条高度写入 `AppStorage`，各页面用 `@StorageProp` 读取并转为 padding，兼顾全屏与安全区
- **画中画**：`PiPWindow.create({ templateType: VIDEO_PLAY, contentWidth/Height })`，宽高从视频元数据解析；监听 `stateChange`（进入小窗前释放播放器避免黑屏）与 `controlPanelActionEvent`（小窗内播放 / 暂停）
- **资源回收**：`onBackPressed`、页面 `onWillDisappear` 统一恢复竖屏、恢复系统栏、恢复默认亮度，防止退出播放页后窗口状态残留

### 7. 状态管理与跨组件通信

- `@Observed` + `@Track` 修饰 ViewModel 与列表项，只刷新真正变化的字段（如 `isChoice`、`title`），长列表多选不卡顿
- `@Observed class VideoItemViewModelList extends Array<VideoItemViewModel>` 配合 `@ObjectLink`，让数组增删也能触发刷新
- 跨 `Navigation` 层级用 `@Provide / @Consume` + 字符串 key 注入：`AudioPlayerVM`、`VideoPlayerVM`、`CurrentFolder`、`MultiChoice`、`ChoiceCount` 等，避免长链路传参
- `emitter` 事件总线承担"列表 ↔ 播放器 ↔ 弹窗"的解耦通信，事件名与载荷类型在文件顶部以常量声明，收发两侧对齐
- `AppStorage` 只放真正全局的少量状态：顶部 / 底部安全区高度、视图模式等

### 8. 工程化

- **模块化**：entry HAP 只做装配，业务全部在 HAR；HAR 之间用 `file:` 本地依赖，不依赖远端仓库，工程可直接克隆构建
- **动态路由**：`router_map.json` 声明 + `@Builder` 导出页面，各特性模块自带路由表，宿主不用硬编码页面路径
- **资源隔离**：每个模块维护自己的 `string / color / float` 与图标资源，模块可独立抽离复用
- **异常规范**：所有系统 API 调用统一 `try/catch` 并打印 `Cause: ${JSON.stringify(error)}`，便于 hilog 定位

---

## 用到的系统能力

| 能力           | 使用的 Kit / 接口                                                             |
| -------------- | ----------------------------------------------------------------------------- |
| 音视频播放     | `@kit.MediaKit` → `media.AVPlayer`、`AVMetadataExtractor`、`AVImageGenerator` |
| 媒体会话与投播 | `@kit.AVSessionKit` → `avSession`、`AVCastController`、`AVCastPicker`         |
| 画中画         | `@kit.ArkUI` → `PiPWindow`、`XComponent`                                      |
| 后台长时任务   | `@ohos.resourceschedule.backgroundTaskManager`、`wantAgent`                   |
| 关系型数据库   | `@kit.ArkData` → `relationalStore`（事务、谓词、ResultSet）                   |
| 键值配置       | `@kit.ArkData` → `preferences`                                                |
| 文件与选择器   | `@kit.CoreFileKit` → `fileIo`、`fileUri`、`picker`                            |
| 图库选择       | `@kit.MediaLibraryKit` → `photoAccessHelper.PhotoViewPicker`                  |
| 图像处理       | `@ohos.multimedia.image` → `ImageSource`、`ImagePacker`、`PixelMap`           |
| 摘要与随机数   | `@kit.CryptoArchitectureKit` → `createMd('SHA256')`、`createRandom`           |
| 生物认证       | `@kit.UserAuthenticationKit` → `userAuth`（指纹 / PIN，ATL3）                 |
| 系统分享       | `@kit.ShareKit` → `systemShare`                                               |
| 音频路由与音量 | `@kit.AudioKit` → `audio.VolumeManager`、`AVVolumePanel`                      |
| 窗口与显示     | `@kit.ArkUI` → `window`（全屏、亮度、方向、系统栏）、`display`                |
| 文本排序       | `@kit.LocalizationKit` → `i18n.Transliterator`                                |
| 跨组件事件     | `@kit.BasicServicesKit` → `emitter`                                           |

---

## 代码规模

统计口径：`src/main` 下的 ArkTS 源码（不含 `ohosTest`、`test` 模板与构建产物）。

| 模块                     | 文件数 |          行数 |
| ------------------------ | -----: | ------------: |
| `features/audio_library` |     33 |         5,613 |
| `features/video_library` |     20 |         4,596 |
| `common/data_storage`    |     10 |           933 |
| `common/player`          |      4 |           639 |
| `products/phone`         |      4 |           189 |
| `common/util`            |      3 |            57 |
| **合计**                 | **75** | **约 12,000** |

---

## 快速开始

### 环境要求

| 项   | 要求                                                                                         |
| ---- | -------------------------------------------------------------------------------------------- |
| IDE  | DevEco Studio 6.0.0 及以上                                                                   |
| SDK  | HarmonyOS SDK，工程 `compatibleSdkVersion` 为 `6.0.0(20)`，`targetSdkVersion` 为 `6.1.1(24)` |
| 设备 | 手机 / 平板真机（推荐），部分能力模拟器不支持                                                |

### 运行步骤

1. 使用 DevEco Studio 打开工程根目录（`build-profile.json5` 所在目录），等待 hvigor 自动同步。工程内 HAR 依赖均为 `file:` 本地引用，无需配置远端 ohpm 仓库。
2. **配置签名**：`File → Project Structure → Signing Configs` 勾选自动签名（工程中 `products` 已引用 `signingConfig: "default"`，但签名配置本身未提交，首次构建需自行生成）。
3. 选择 `phone` 模块与目标设备，点击运行。
4. 首次进入「视频」或「音频」页时会弹出一次目录选择框，请选择如 `Download` 的目录：应用以此作为导入媒体的副本存放位置，并在其下创建 `videos/`、`audios/` 子目录；封面与缩略图写入应用沙箱。
5. 点击右上角 `+` 选择导入方式（系统图库 / 文件管理 / 下载目录）开始导入媒体。

### 权限说明

| 权限                                            | 用途                                |
| ----------------------------------------------- | ----------------------------------- |
| `ohos.permission.KEEP_BACKGROUND_RUNNING`       | 后台音频播放 / 后台听视频的长时任务 |
| `ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY` | 读取下载目录批量导入、写入导入副本  |
| `ohos.permission.ACCESS_BIOMETRIC`              | 视频保险柜的生物认证                |
| `ohos.permission.INTERNET`                      | 投播（Cast+ / DLNA）                |

`module.json5` 中已声明 `backgroundModes: ["audioPlayback"]`。

### 功能验证建议（真机）

以下能力在模拟器上通常不可用，建议真机验证：**保险柜指纹认证**、**投播到电视 / 音箱**、**画中画**、**后台长时任务通知**、**锁屏播控中心**。

---

## 当前限制
- 仅支持本地文件播放，未接入网络流媒体 / 在线音乐源
- 导入格式受选择器过滤限制：音频 `.mp3` / `.m4a`，视频 `.mp4`（播放内核实际支持更多格式）
- 播放进度未持久化：应用被系统回收后不记忆上次播放项与进度
- 歌词仅支持 LRC 行级时间标签，无逐字歌词、翻译与偏移校准
- 文案为中文硬编码，未做多语言；深色模式仅依赖系统色板做基础适配，未提供独立深色资源
- 首次进入页面即弹出"下载目录"选择（`DocumentViewPicker.save`），缺少首次引导与"记住目录"的设置项；若用户取消，下载目录导入与副本写入将不可用
- `ohosTest` / `test` 目录仍为 DevEco 模板桩，业务逻辑尚无单元测试覆盖

---

## 说明

本项目为个人学习与求职展示作品，用于演示 HarmonyOS 应用开发中的声明式 UI、媒体播放、系统能力集成与模块化工程实践。

如对实现细节有疑问或希望交流，欢迎通过 Issue 讨论。
