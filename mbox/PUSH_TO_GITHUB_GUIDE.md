# MBox GitHub 推送指南

## 方法一：使用部署脚本（推荐）

### 1. 设置环境变量
```bash
export GITHUB_TOKEN=your_github_token
export GITHUB_USER=your_github_username
```

### 2. 运行部署脚本
```bash
cd /workspace/mbox
./deploy-to-github.sh
```

脚本会自动完成：
- 清空远程仓库
- 推送新代码
- 推送标签
- 构建 APK（如有 Flutter 环境）
- 创建 Release（如有 Token）
- 上传 APK 文件

---

## 方法二：手动操作

### Step 1: 清空 GitHub 仓库

由于 GitHub 不允许直接清空仓库，需要以下操作：

#### A. 创建空仓库（如果还没有）
1. 访问 https://github.com/new
2. 创建仓库 `mbox`
3. 不要勾选 "Initialize this repository with a README"

#### B. 强制推送覆盖历史
```bash
cd /workspace/mbox

# 添加 remote（替换为你的用户名）
git remote add origin https://github.com/YOUR_USERNAME/mbox.git

# 或更新已有 remote
git remote set-url origin https://github.com/YOUR_USERNAME/mbox.git

# 强制推送到 master（会清空所有历史）
git push -f origin master

# 推送所有标签
git push origin --tags --force
```

### Step 2: 构建 APK

```bash
cd /workspace/mbox

# 安装依赖
flutter pub get

# 构建分 ABI 的 APK
flutter build apk --split-per-abi --release

# 输出文件:
# - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (32 位)
# - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (64 位)
```

### Step 3: 创建 GitHub Release

1. 访问 https://github.com/YOUR_USERNAME/mbox/releases/new
2. 填写信息：
   - **Tag version**: `v1.0.0`
   - **Release title**: `MBox v1.0.0 - 首个正式版本发布`
   - **Description**: 复制 `RELEASE_v1.0.0.md` 的内容
3. 上传文件：
   - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
   - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
4. 点击 "Publish release"

---

## 获取 GitHub Token

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token (classic)"
3. 填写 Note（例如：MBox Deploy）
4. 勾选权限：
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
   - `read:org` (Read organization membership)
5. 点击 "Generate token"
6. **重要**: 复制生成的 token，保存到安全位置

---

## 验证推送

### 检查仓库
```bash
# 在 GitHub 页面查看
https://github.com/YOUR_USERNAME/mbox

# 应该看到:
# - 最新的提交记录
# - 标签 v1.0.0
# - 文件结构完整
```

### 检查 Release
```bash
# 访问 Release 页面
https://github.com/YOUR_USERNAME/mbox/releases

# 应该看到:
# - v1.0.0 Release
# - 发布说明
# - APK 附件
```

---

## 常见问题

### Q1: force push 失败？
确保你有仓库的写入权限。如果是团队仓库，联系管理员。

### Q2: Token 无效？
检查 token 是否有 `repo` 权限，以及是否已过期。

### Q3: 构建失败？
确保 Flutter 和 Android SDK 已正确配置。

### Q4: APK 太大？
使用 `--split-per-abi` 参数构建分 ABI 版本。

---

## 快速命令参考

```bash
# 设置 remote
git remote set-url origin https://github.com/YOUR_USERNAME/mbox.git

# 查看 remote
git remote -v

# 查看标签
git tag -l

# 强制推送
git push -f origin master
git push origin --tags --force

# 构建 APK
flutter build apk --split-per-abi --release

# 查看 APK 文件
ls -lh build/app/outputs/flutter-apk/
```

---

**文档版本**: 1.0  
**更新日期**: 2026-04-26
