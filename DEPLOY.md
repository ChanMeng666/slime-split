# Slime Split - 部署指南

## 构建产物总览

```
build/
├── slime-split.love          # 跨平台 LÖVE 包 (~21KB)
├── slime-split-win64/        # Windows 独立可执行文件
│   ├── slime-split.exe
│   └── *.dll
└── web/                      # Web 版文件
    ├── index.html
    └── slime-split.love
```

---

## 方案 A：itch.io 发布（推荐）

### 为什么选 itch.io？
- 独立游戏最大平台，自带社区和曝光
- 同时支持 **Web 在线玩** 和 **下载包**
- 完全免费（可选付费/捐赠模式）
- 支持嵌入式 HTML5 播放器

### 步骤

#### 1. 注册 itch.io 账号
前往 https://itch.io/register

#### 2. 创建新项目
- Dashboard → Create new project
- **Title**: Slime Split
- **Kind of project**: Game
- **Pricing**: Free / Donation
- **Classification**: Game
- **Genre**: Puzzle
- **Tags**: physics, puzzle, retro, pixel-art, love2d

#### 3. 上传构建包

**Web 版（让玩家直接在浏览器玩）：**

方法 A - 使用 LÖVE Web Builder（最简单）：
1. 打开 https://schellingb.github.io/LoveWebBuilder/package.html
2. 上传 `build/slime-split.love`
3. 设置：Title = "Slime Split", Resolution = 640x480
4. 选择 "Two files (HTML+JS) with loading progress bar"
5. 点击 Build，下载生成的 HTML + JS 文件
6. 将这两个文件打成 zip
7. 在 itch.io 上传该 zip，勾选 **"This file will be played in the browser"**
8. 设置 Viewport: 640 x 480

方法 B - 使用 2dengine/love.js（支持 11.4）：
1. 从 https://github.com/2dengine/love.js/ 下载 release
2. 将 `player.js` 和版本目录（11.4/）与 `slime-split.love` 一起打包
3. 使用 `build/web/index.html` 作为入口
4. 整体打成 zip 上传 itch.io

**Windows 下载包：**
1. 将 `build/slime-split-win64/` 整个目录打成 zip
2. 上传到 itch.io，标记平台为 Windows

**跨平台 .love 包：**
1. 上传 `build/slime-split.love`
2. 标记为 "Other" 平台，说明需要安装 LÖVE 运行时

#### 4. 配置页面
- 上传封面图 (630x500 推荐)
- 写描述（中英双语）
- 设置为 Public
- 点击 Publish

---

## 方案 B：GitHub Pages（免费托管）

### 步骤

#### 1. 创建 GitHub 仓库
```bash
cd slime-split
git init
git add .
git commit -m "Initial release: Slime Split v1.0"
git remote add origin https://github.com/YOUR_USERNAME/slime-split.git
git push -u origin main
```

#### 2. 构建 Web 版
使用 LÖVE Web Builder 生成 HTML+JS 文件，放入 `docs/` 目录：
```
docs/
├── index.html      # 生成的 HTML
├── game.js         # 生成的 JS（包含游戏数据）
```

#### 3. 启用 GitHub Pages
- Settings → Pages → Source: Deploy from branch
- Branch: main, Folder: /docs
- 保存后等待几分钟
- 访问: `https://YOUR_USERNAME.github.io/slime-split/`

---

## 方案 C：Netlify / Vercel（一键部署）

将 Web 构建文件放入仓库，连接 Netlify/Vercel 即自动部署：
- Netlify: https://netlify.com → Import project → 选择仓库 → Publish directory: `build/web`
- Vercel: https://vercel.com → Import → Root directory: `build/web`

注意：需要配置 HTTP Headers（COOP/COEP）才能使 SharedArrayBuffer 生效。

---

## 方案 D：打包原生桌面应用

### Windows
已通过 `build.bat` 自动构建。

### macOS
1. 下载 macOS 版 LÖVE: https://love2d.org/
2. 右键 love.app → Show Package Contents
3. 将 `slime-split.love` 复制到 `Contents/Resources/`
4. 修改 `Contents/Info.plist` 中的 bundle identifier

### Linux
```bash
# AppImage 方式
# 或直接提供 .love 文件，用户安装 love 后即可运行：
love slime-split.love
```

---

## 快速命令参考

```bash
# 构建 .love 文件
cd slime-split
powershell Compress-Archive -Path main.lua,conf.lua,src -DestinationPath build/slime-split.zip
ren build\slime-split.zip slime-split.love

# 本地测试
"C:\Program Files\LOVE\love.exe" build/slime-split.love

# 构建 Windows exe
copy /b "C:\Program Files\LOVE\love.exe"+build\slime-split.love build\slime-split.exe
```

---

## 推荐发布流程

1. ✅ 先用 LÖVE Web Builder 生成 Web 版，上传 itch.io 测试
2. ✅ 确认 Web 版可玩后，补充 Windows 下载包
3. ✅ 在 itch.io 页面配置好描述、截图、标签
4. ✅ 点击 Publish 发布
5. ✅ （可选）同步部署到 GitHub Pages 作为备用入口
