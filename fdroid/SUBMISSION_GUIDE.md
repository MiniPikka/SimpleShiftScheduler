# F-Droid 上架指南

## 当前状态

- ✅ F-Droid 元数据文件已创建: `metadata/com.simpleshift.scheduler_cp.yml`
- ✅ 本地构建验证通过: APK 包含 arm64-v8a, armeabi-v7a, x86_64 的原生 Rust 库
- ✅ 所有依赖均为开源（无 Google Play Services、Firebase 等闭源组件）
- ✅ 项目使用 MIT 许可证
- ⚠️ 缺少应用截图
- ⚠️ 需要打 Git tag

## 上架前准备

### 1. 添加应用截图

F-Droid 要求至少 2 张应用截图。将截图放到:
```
fastlane/metadata/android/en-US/images/phoneScreenshots/
```

**要求:**
- PNG 格式, 推荐尺寸 1080x1920 (竖屏)
- 至少 2 张, 推荐 4-6 张
- 展示主要功能: 排班日历、月度统计、拼假、小组件

**如何截图:**
```bash
# 在连接的 Android 设备上运行
cd flutter && flutter run --release
# 然后使用 Android Studio Device Explorer 截图
# 或使用 adb screenshot
```

### 2. 创建 Git Tag

```bash
git tag -a app-v1.0.0 -m "app-v1.0.0: Flutter Android — F-Droid initial release"
git push origin app-v1.0.0
```

### 3. 更新版本号 (可选, 推荐)

如果之前发布过其他版本, 建议升级版本号:
- 编辑 `flutter/pubspec.yaml`: 修改 `version: 1.0.0+1` → `version: 1.0.1+2`
- 同步更新 tag: `v1.0.1`

## 提交到 F-Droid

### 步骤 1: Fork fdroiddata 仓库

1. 访问 https://gitlab.com/fdroid/fdroiddata
2. 点击 Fork 按钮
3. 克隆你的 fork:
```bash
git clone https://gitlab.com/YOUR_GITLAB_USERNAME/fdroiddata.git
cd fdroiddata
```

### 步骤 2: 添加元数据文件

```bash
# 复制元数据文件到 fdroiddata
cp /path/to/SimpleShiftScheduler/metadata/com.simpleshift.scheduler_cp.yml \
   fdroiddata/metadata/
```

### 步骤 3: 提交并创建 Merge Request

```bash
cd fdroiddata
git checkout -b add-shiftmate
git add metadata/com.simpleshift.scheduler_cp.yml
git commit -m "Add 班伴 (ShiftMate) - shift scheduling app"
git push origin add-shiftmate
```

然后在 GitLab 上创建 Merge Request:
- 标题: `Add 班伴 (ShiftMate)` 
- 描述: 简要介绍应用功能和技术栈 (Flutter + Rust FFI)
- 目标分支: `fdroid/fdroiddata -> master`

### 步骤 4: 等待审核

F-Droid 维护者会:
1. 审核元数据格式是否正确
2. 尝试在构建服务器上构建 APK
3. 如果有构建问题, 会在 MR 中评论

**预期审核时间: 1-4 周**

## F-Droid 元数据文件说明

当前的 `metadata/com.simpleshift.scheduler_cp.yml` 包含:

### 构建流程
```yaml
Builds:
  - versionName: 1.0.0
    versionCode: 1
    commit: v1.0.0          # Git tag, F-Droid 此检出此 commit
    subdir: flutter          # 源码子目录
    submodules: true         # Rust shift-core 是 workspace 成员, 不是 submodule
    
    sudo:                    # 在 build VM 中以 root 运行
      - apt-get install rustc cargo
    
    init:                    # 初始化构建环境
      - curl ... | sh        # 安装 rustup
      - rustup target add ... # 添加 Android 交叉编译目标
      - cargo install cargo-ndk
    
    prebuild:                # 主构建前的准备
      - cargo ndk ... build  # 编译 Rust → .so
    
    build:                   # 主构建
      - flutter pub get
      - flutter build apk --release
    
    srclibs:
      - flutter@3.44.0       # F-Droid 内置的 Flutter SDK
```

### 注意事项

1. **Rust 需要网络**: rustup 和 cargo-ndk 安装需要网络访问。F-Droid 构建服务器有网络, 但可能有防火墙限制。如果 rustup 方式失败, 可能需要改用 `sudo: apt-get install rustc cargo`。

2. **Flutter SDK 版本**: 当前指定 `flutter@3.44.0`, 但 F-Droid 的 `srclibs` 可能没有这个版本。如果构建失败, 尝试改为 `flutter@stable` 或与 F-Droid 维护者沟通支持的版本。

3. **x86 32-bit 不支持**: Rust 1.95 已不再支持 `i686-linux-android`, 因此只构建 3 个 ABI (arm64-v8a, armeabi-v7a, x86_64)。

4. **Chrome 镜像**: `settings.gradle.kts` 中的腾讯/阿里云 Maven 镜像对 F-Droid 构建无害 (它们是公共镜像的镜像), 但可能稍慢。

5. **签名**: F-Droid 使用自己的签名密钥重新签名 APK, 与 GitHub Release 的签名不同。用户从 F-Droid 安装的版本与从 GitHub 安装的版本不兼容 (无法覆盖安装)。

## 后续维护

### 发布新版本

每次发布新版本时:
1. 更新 `flutter/pubspec.yaml` 版本号
2. 打新的 Git tag: `git tag v1.x.x`
3. 更新 `metadata/com.simpleshift.scheduler_cp.yml`:
   - 添加新的 `Builds:` 条目
   - 或更新 `AutoUpdateMode: Version` + `UpdateCheckMode: Tags`
4. 提交 MR 到 fdroiddata

### 自动更新 (推荐)

当前配置使用自动更新模式:
```yaml
AutoUpdateMode: Version
UpdateCheckMode: Tags
```

这样 F-Droid 会自动检测新的 Git tag 并尝试构建。只需确保:
- 每个新版本都打正确的 Git tag (格式如 `v1.0.1`)
- `pubspec.yaml` 中的 version 与 tag 对应

## 常见问题

### Q: 构建失败怎么办?
A: F-Droid 维护者会在 MR 中提供构建日志。常见的 Flutter + Rust 构建问题:
- Rust 工具链安装失败 → 改用 `sudo: apt-get install rustc cargo`
- cargo-ndk 安装失败 → 检查 NDK 版本兼容性
- Flutter SDK 版本不存在 → 联系维护者确认可用版本

### Q: 多久能在 F-Droid 上看到我的应用?
A: 通常 MR 合并后, 应用会在 2-7 天内出现在 F-Droid 客户端中。

### Q: 需要提供 arm64-v8a 以外的 ABI 吗?
A: F-Droid 要求至少 arm64-v8a。armeabi-v7a 和 x86_64 是可选的但推荐提供以覆盖更多设备。
