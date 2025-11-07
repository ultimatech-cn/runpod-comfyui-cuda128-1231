# 如何访问 RunPod S3 文件

## 快速开始

### 步骤 1: 设置 S3 API Key

首先，你需要获取 RunPod S3 API Key：

1. 访问 [RunPod Settings](https://www.console.runpod.io/user/settings)
2. 展开 **S3 API Keys** 部分
3. 创建新的 S3 API Key（如果还没有）
4. 保存 **access key** 和 **secret**（只显示一次）

然后在 PowerShell 中设置环境变量：

```powershell
# 设置 S3 API Key（替换为你的实际值）
$env:AWS_ACCESS_KEY_ID="your-s3-api-key-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-s3-api-key-secret"
```

**注意**：这些环境变量只在当前 PowerShell 会话中有效。如果关闭窗口，需要重新设置。

### 步骤 2: 下载文件

#### 方法 1: 使用批处理脚本（最简单）

```powershell
# 使用提供的批处理脚本
.\download_s3_file.bat "https://s3api-eu-ro-1.runpod.io/bucket-name/path/to/file.png"
```

#### 方法 2: 使用 AWS CLI 命令

从返回的 S3 URL 中提取信息，然后使用 `aws s3 cp` 命令：

```powershell
# 示例 URL: https://s3api-eu-ro-1.runpod.io/arijswweo4/11-25/9cc0ecde-5ee6-44d8-b510-361897632673-u2/b21aea09.png

# 提取信息：
# - Endpoint: https://s3api-eu-ro-1.runpod.io/
# - Region: eu-ro-1
# - Bucket: arijswweo4
# - Key: 11-25/9cc0ecde-5ee6-44d8-b510-361897632673-u2/b21aea09.png

aws s3 cp `
    --region eu-ro-1 `
    --endpoint-url https://s3api-eu-ro-1.runpod.io/ `
    s3://arijswweo4/11-25/9cc0ecde-5ee6-44d8-b510-361897632673-u2/b21aea09.png `
    ./b21aea09.png
```

#### 方法 3: 使用 Python 脚本

```python
# download_s3_file.py
import boto3
import os
import sys

# 从命令行参数获取 URL
if len(sys.argv) < 2:
    print("使用方法: python download_s3_file.py <S3_URL> [output_filename]")
    sys.exit(1)

s3_url = sys.argv[1]
output_file = sys.argv[2] if len(sys.argv) > 2 else None

# 从 URL 中提取信息
# URL 格式: https://s3api-eu-ro-1.runpod.io/bucket-name/path/to/file.png
url_parts = s3_url.replace("https://", "").split("/")
endpoint_host = url_parts[0]  # s3api-eu-ro-1.runpod.io
bucket_name = url_parts[1]    # bucket-name
s3_key = "/".join(url_parts[2:])  # path/to/file.png

# 提取 region
region = endpoint_host.split(".")[0].replace("s3api-", "")
endpoint_url = f"https://{endpoint_host}/"

# 如果没有指定输出文件名，从 URL 中提取
if not output_file:
    output_file = s3_key.split("/")[-1]

# 创建 S3 客户端
s3_client = boto3.client(
    's3',
    aws_access_key_id=os.environ.get('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
    region_name=region,
    endpoint_url=endpoint_url
)

# 下载文件
print(f"正在下载: {s3_key}")
print(f"保存到: {output_file}")
s3_client.download_file(bucket_name, s3_key, output_file)
print("下载完成！")
```

运行：
```powershell
pip install boto3
python download_s3_file.py "https://s3api-eu-ro-1.runpod.io/bucket-name/path/to/file.png"
```

## 常见问题

### Q: 如何永久设置环境变量？

在 Windows 中，可以通过系统设置永久设置环境变量：

1. 右键"此电脑" → "属性"
2. 点击"高级系统设置"
3. 点击"环境变量"
4. 在"用户变量"中添加：
   - `AWS_ACCESS_KEY_ID` = 你的 S3 API Key access key
   - `AWS_SECRET_ACCESS_KEY` = 你的 S3 API Key secret

### Q: 如何从 URL 中提取信息？

RunPod S3 URL 格式：
```
https://s3api-{REGION}.runpod.io/{BUCKET_NAME}/{PATH/TO/FILE}
```

示例：
```
https://s3api-eu-ro-1.runpod.io/arijswweo4/11-25/job-id/file.png
```

- **Region**: `eu-ro-1` (从 `s3api-eu-ro-1` 中提取)
- **Endpoint URL**: `https://s3api-eu-ro-1.runpod.io/`
- **Bucket**: `arijswweo4`
- **Key**: `11-25/job-id/file.png`

### Q: 下载失败怎么办？

检查以下几点：
1. S3 API Key 是否正确设置（`echo $env:AWS_ACCESS_KEY_ID`）
2. URL 是否正确（检查 bucket 名称和文件路径）
3. 文件是否存在（可能已被删除）
4. Region 是否正确（必须匹配 URL 中的 region）

