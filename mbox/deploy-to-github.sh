#!/bin/bash

# MBox v1.0.0 GitHub 部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_USER="${GITHUB_USER:-}"
REPO_NAME="mbox"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}MBox v1.0.0 GitHub 部署脚本${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

# 检查 Git Token
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}请设置 GITHUB_TOKEN 环境变量:${NC}"
    echo "  export GITHUB_TOKEN=your_github_token"
    echo ""
    echo -e "${YELLOW}或者手动输入仓库地址:${NC}"
    read -p "GitHub 仓库 URL (例如：https://github.com/yourname/mbox.git): " REPO_URL
fi

cd /workspace/mbox

# 1. 检查当前状态
echo -e "${GREEN}[1/6] 检查 Git 状态...${NC}"
git status
echo ""

# 2. 如果已有 remote，先删除
echo -e "${GREEN}[2/6] 配置远程仓库...${NC}"
if git remote | grep -q "^origin$"; then
    echo "删除现有 origin remote..."
    git remote remove origin
fi

# 3. 添加新的 remote
echo "添加新的 remote: $REPO_URL"
git remote add origin "$REPO_URL"
git remote -v
echo ""

# 4. 清空远程仓库并强制推送
echo -e "${GREEN}[3/6] 清空远程仓库并推送新代码...${NC}"
echo -e "${YELLOW}⚠️  警告：这将清空远程仓库的所有历史！${NC}"
read -p "确认继续？(y/N): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "操作已取消"
    exit 1
fi

# 获取当前分支
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "当前分支：$CURRENT_BRANCH"

# 强制推送到远程（清空历史）
echo "执行 force push..."
git push -f origin $CURRENT_BRANCH

# 推送所有标签
echo "推送标签..."
git push origin --tags --force

echo -e "${GREEN}✓ 代码推送成功！${NC}"
echo ""

# 5. 构建 APK (如果 Flutter 环境可用)
echo -e "${GREEN}[4/6] 构建 APK...${NC}"
if command -v flutter &> /dev/null; then
    echo "Flutter 已安装，开始构建..."
    flutter pub get
    flutter build apk --split-per-abi --release
    
    echo ""
    echo "APK 文件位置:"
    ls -lh build/app/outputs/flutter-apk/*.apk
else
    echo -e "${YELLOW}⚠️  Flutter 未安装，跳过构建步骤${NC}"
    echo "您可以稍后手动运行：flutter build apk --split-per-abi"
fi
echo ""

# 6. 创建 GitHub Release
echo -e "${GREEN}[5/6] 准备创建 GitHub Release...${NC}"

if [ -n "$GITHUB_TOKEN" ]; then
    echo "使用 GitHub API 创建 Release..."
    
    # 读取发布说明
    RELEASE_NOTES=$(cat RELEASE_v1.0.0.md)
    
    # 创建 Release
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/$GITHUB_USER/$REPO_NAME/releases \
        -d "{
            \"tag_name\": \"v1.0.0\",
            \"name\": \"MBox v1.0.0 - 首个正式版本发布\",
            \"body\": \"$RELEASE_NOTES\",
            \"draft\": false,
            \"prerelease\": false
        }")
    
    RELEASE_ID=$(echo $RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    
    if [ -n "$RELEASE_ID" ]; then
        echo -e "${GREEN}✓ Release 创建成功！ID: $RELEASE_ID${NC}"
        
        # 上传 APK 文件 (如果已构建)
        if [ -f "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ]; then
            echo "上传 APK 文件..."
            for apk in build/app/outputs/flutter-apk/*.apk; do
                if [ -f "$apk" ]; then
                    echo "上传：$apk"
                    curl -s -X POST \
                        -H "Authorization: token $GITHUB_TOKEN" \
                        -H "Accept: application/vnd.github.v3+json" \
                        -H "Content-Type: application/octet-stream" \
                        --data-binary @"$apk" \
                        "https://uploads.github.com/repos/$GITHUB_USER/$REPO_NAME/releases/$RELEASE_ID/assets?name=$(basename $apk)"
                fi
            done
            echo -e "${GREEN}✓ APK 文件上传完成！${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Release 创建失败，请手动创建${NC}"
        echo "访问：https://github.com/$GITHUB_USER/$REPO_NAME/releases"
    fi
else
    echo -e "${YELLOW}⚠️  未设置 GITHUB_TOKEN，跳过自动创建 Release${NC}"
    echo ""
    echo "请手动创建 Release:"
    echo "1. 访问：https://github.com/$GITHUB_USER/$REPO_NAME/releases/new"
    echo "2. 标签版本号：v1.0.0"
    echo "3. 发布标题：MBox v1.0.0 - 首个正式版本发布"
    echo "4. 发布说明：使用 RELEASE_v1.0.0.md 文件内容"
    echo "5. 上传 APK 文件：build/app/outputs/flutter-apk/*.apk"
fi
echo ""

# 7. 完成
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}🎉 部署完成！${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo "📱 仓库地址：https://github.com/$GITHUB_USER/$REPO_NAME"
echo "📄 Release 页面：https://github.com/$GITHUB_USER/$REPO_NAME/releases"
echo "📦 APK 路径：/workspace/mbox/build/app/outputs/flutter-apk/"
echo ""
echo -e "${YELLOW}下一步操作:${NC}"
echo "1. 检查 GitHub 仓库确认代码已推送"
echo "2. 如果使用了 GITHUB_TOKEN，检查 Release 和 APK 文件"
echo "3. 如果没有使用 token，手动创建 Release 并上传 APK"
echo ""
