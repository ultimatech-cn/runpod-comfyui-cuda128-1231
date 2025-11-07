@echo off
chcp 65001 >nul
REM 设置 RunPod S3 API Key 环境变量的批处理脚本
REM 使用方法: setup_s3_env.bat

echo ========================================
echo RunPod S3 API Key 环境变量设置
echo ========================================
echo.

REM 检查是否已设置
if not "%AWS_ACCESS_KEY_ID%"=="" (
    echo 当前 AWS_ACCESS_KEY_ID: %AWS_ACCESS_KEY_ID%
) else (
    echo AWS_ACCESS_KEY_ID: 未设置
)

if not "%AWS_SECRET_ACCESS_KEY%"=="" (
    echo 当前 AWS_SECRET_ACCESS_KEY: 已设置（隐藏显示）
) else (
    echo AWS_SECRET_ACCESS_KEY: 未设置
)

echo.
echo 请输入你的 RunPod S3 API Key:
echo (可以从 https://www.console.runpod.io/user/settings 获取)
echo.

set /p ACCESS_KEY="Access Key ID (例如: user_xxx...): "
set /p SECRET_KEY="Secret Access Key (例如: rps_xxx...): "

if "%ACCESS_KEY%"=="" (
    echo 错误: Access Key ID 不能为空
    exit /b 1
)

if "%SECRET_KEY%"=="" (
    echo 错误: Secret Access Key 不能为空
    exit /b 1
)

REM 设置环境变量
set AWS_ACCESS_KEY_ID=%ACCESS_KEY%
set AWS_SECRET_ACCESS_KEY=%SECRET_KEY%

echo.
echo ========================================
echo 环境变量已设置！
echo ========================================
echo.
echo 注意: 这些环境变量只在当前 CMD 窗口中有效
echo 如果关闭窗口，需要重新运行此脚本
echo.
echo 现在可以使用 download_s3_file.bat 下载文件了
echo.

