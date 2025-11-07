# CMD 中使用 RunPod S3 下载文件

## 快速开始（3 步）

### 步骤 1: 设置 S3 API Key

**方法 1：使用设置脚本（推荐）**

```cmd
setup_s3_env.bat
```

然后按提示输入你的 S3 API Key。

**方法 2：手动设置**

```cmd
set AWS_ACCESS_KEY_ID=user_2ckQi5T2g512svDdVvJ5FtKxAMM
set AWS_SECRET_ACCESS_KEY=rps_你的secret密钥
```

### 步骤 2: 下载文件

使用批处理脚本（最简单）：

```cmd
download_s3_file.bat "https://s3api-eu-ro-1.runpod.io/arijswweo4/11-25/9cc0ecde-5ee6-44d8-b510-361897632673-u2/b21aea09.png"
```

### 步骤 3: 查看下载的文件

文件会下载到当前目录，文件名会自动从 URL 中提取。

## 完整示例

```cmd
REM 1. 切换到项目目录
cd "E:\Program Files\runpod-comfyui-cuda128-pure"

REM 2. 设置 S3 API Key
setup_s3_env.bat
REM 或者手动设置:
REM set AWS_ACCESS_KEY_ID=user_2ckQi5T2g512svDdVvJ5FtKxAMM
REM set AWS_SECRET_ACCESS_KEY=rps_你的secret密钥

REM 3. 下载文件
download_s3_file.bat "https://s3api-eu-ro-1.runpod.io/arijswweo4/11-25/9cc0ecde-5ee6-44d8-b510-361897632673-u2/b21aea09.png"
```

## 直接使用 AWS CLI

如果你想直接使用 AWS CLI 命令：

```cmd
REM 设置环境变量
set AWS_ACCESS_KEY_ID=user_2ckQi5T2g512svDdVvJ5FtKxAMM
set AWS_SECRET_ACCESS_KEY=rps_你的secret密钥

REM 下载文件
aws s3 cp --region eu-ro-1 --endpoint-url https://s3api-eu-ro-1.runpod.io/ s3://arijswweo4/11-25/9cc0ecde-5ee6-44d8-b510-361897632673-u2/b21aea09.png ./b21aea09.png
```

## 从 API 返回的 URL 中提取信息

API 返回的 URL 格式：
```
https://s3api-eu-ro-1.runpod.io/arijswweo4/11-25/9cc0ecde-5ee6-44d8-b510-361897632673-u2/b21aea09.png
```

对应信息：
- **Region**: `eu-ro-1`
- **Endpoint**: `https://s3api-eu-ro-1.runpod.io/`
- **Bucket**: `arijswweo4`
- **Key**: `11-25/9cc0ecde-5ee6-44d8-b510-361897632673-u2/b21aea09.png`

## 常见问题

### Q: 如何获取 S3 API Key？

1. 访问 https://www.console.runpod.io/user/settings
2. 展开 **S3 API Keys** 部分
3. 点击 **Create an S3 API key**
4. 保存显示的 **access key** 和 **secret**（只显示一次）

### Q: 环境变量设置后多久有效？

只在当前 CMD 窗口中有效。如果关闭窗口，需要重新设置。

### Q: 如何永久设置环境变量？

1. 右键"此电脑" → "属性"
2. 点击"高级系统设置"
3. 点击"环境变量"
4. 在"用户变量"中添加：
   - `AWS_ACCESS_KEY_ID` = 你的 S3 API Key access key
   - `AWS_SECRET_ACCESS_KEY` = 你的 S3 API Key secret

### Q: 下载失败怎么办？

检查以下几点：
1. 环境变量是否正确设置：`echo %AWS_ACCESS_KEY_ID%`
2. URL 是否正确（检查 bucket 名称和文件路径）
3. 文件是否存在（可能已被删除）
4. Region 是否正确（必须匹配 URL 中的 region）

