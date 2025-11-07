@echo off
chcp 65001 >nul
REM 从 RunPod S3 下载文件的批处理脚本
REM 使用方法: download_s3_file.bat <S3_URL> [output_filename]

if "%1"=="" (
    echo 使用方法: download_s3_file.bat ^<S3_URL^> [output_filename]
    echo.
    echo 示例:
    echo   download_s3_file.bat "https://s3api-eu-ro-1.runpod.io/bucket-name/path/to/file.png"
    echo   download_s3_file.bat "https://s3api-eu-ro-1.runpod.io/bucket-name/path/to/file.png" "my_file.png"
    echo.
    echo 注意: 请先设置环境变量:
    echo   set AWS_ACCESS_KEY_ID=your-s3-api-key-access-key
    echo   set AWS_SECRET_ACCESS_KEY=your-s3-api-key-secret
    exit /b 1
)

REM 正确处理包含特殊字符的 URL（使用延迟变量扩展）
setlocal enabledelayedexpansion
set "S3_URL=%~1"
set "OUTPUT_FILE=%~2"

REM 检查是否设置了 S3 API Key 环境变量
if "%AWS_ACCESS_KEY_ID%"=="" (
    echo 错误: 未设置 AWS_ACCESS_KEY_ID 环境变量
    echo 请先设置你的 RunPod S3 API Key:
    echo   set AWS_ACCESS_KEY_ID=your-s3-api-key-access-key
    echo   set AWS_SECRET_ACCESS_KEY=your-s3-api-key-secret
    exit /b 1
)

if "%AWS_SECRET_ACCESS_KEY%"=="" (
    echo 错误: 未设置 AWS_SECRET_ACCESS_KEY 环境变量
    echo 请先设置你的 RunPod S3 API Key:
    echo   set AWS_ACCESS_KEY_ID=your-s3-api-key-access-key
    echo   set AWS_SECRET_ACCESS_KEY=your-s3-api-key-secret
    exit /b 1
)

REM 从 URL 中提取信息（先去掉查询参数）
REM URL 格式: https://s3api-eu-ro-1.runpod.io/arijswweo4/11-25/file.png?query=...
REM 去掉查询参数
set "S3_URL_CLEAN=!S3_URL!"
if not "!S3_URL_CLEAN:?=!"=="!S3_URL_CLEAN!" (
    for /f "tokens=1 delims=?" %%a in ("!S3_URL!") do set "S3_URL_CLEAN=%%a"
)

REM 使用 PowerShell 来可靠地解析 URL（避免批处理中特殊字符的问题）
REM 将 URL 写入临时文件
echo !S3_URL_CLEAN! > "%TEMP%\s3_url_parse.txt"

REM 提取各部分信息
for /f "delims=" %%I in ('powershell -Command "$url = Get-Content '%TEMP%\s3_url_parse.txt' -Raw; $uri = [System.Uri]$url; $uri.Host"') do set "ENDPOINT_HOST=%%I"

for /f "delims=" %%I in ('powershell -Command "$url = Get-Content '%TEMP%\s3_url_parse.txt' -Raw; $uri = [System.Uri]$url; $segments = $uri.Segments; if ($segments.Length -gt 1) { $segments[1].TrimEnd('/') }"') do set "BUCKET_NAME=%%I"

for /f "delims=" %%I in ('powershell -Command "$url = Get-Content '%TEMP%\s3_url_parse.txt' -Raw; $uri = [System.Uri]$url; $segments = $uri.Segments; if ($segments.Length -gt 2) { ($segments[2..($segments.Length-1)] | ForEach-Object { $_.TrimEnd('/') }) -join '/' }"') do set "S3_KEY=%%I"

REM 提取 region (从 s3api-eu-ro-1.runpod.io 中提取 eu-ro-1)
for /f "tokens=1 delims=." %%a in ("!ENDPOINT_HOST!") do set "REGION=%%a"
set "REGION=!REGION:s3api-=!"

REM 构建 endpoint URL
set "ENDPOINT_URL=https://!ENDPOINT_HOST!/"

REM 清理临时文件
del "%TEMP%\s3_url_parse.txt" 2>nul

REM 如果没有指定输出文件名，从 URL 中提取
if "!OUTPUT_FILE!"=="" (
    for %%F in ("!S3_KEY!") do set "OUTPUT_FILE=%%~nxF"
    if "!OUTPUT_FILE!"=="" set "OUTPUT_FILE=downloaded_file"
)

echo 正在下载文件...
echo   Bucket: !BUCKET_NAME!
echo   Key: !S3_KEY!
echo   保存到: !OUTPUT_FILE!
echo.

REM 使用 AWS CLI 下载文件
aws s3 cp ^
    --region !REGION! ^
    --endpoint-url !ENDPOINT_URL! ^
    s3://!BUCKET_NAME!/!S3_KEY! ^
    "!OUTPUT_FILE!"

if !ERRORLEVEL! EQU 0 (
    echo.
    echo 下载成功！文件已保存到: !OUTPUT_FILE!
) else (
    echo.
    echo 下载失败！请检查：
    echo   1. S3 API Key 是否正确设置
    echo   2. URL 是否正确
    echo   3. 文件是否存在
)

endlocal
