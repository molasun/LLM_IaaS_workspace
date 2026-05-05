#!/bin/bash

# 初始化環境腳本
# 用法: ./init_aws_env.sh "email@example.com" "YOUR_AWS_ACCESS_KEY" "YOUR_AWS_SECRET_KEY"

set -e  # 遇到錯誤時退出

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 打印消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查參數數量
if [ $# -ne 3 ]; then
    print_error "參數數量錯誤！"
    echo "用法: $0 <email> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
    exit 1
fi

EMAIL="$1"
AWS_ACCESS_KEY="$2"
AWS_SECRET_KEY="$3"

print_info "開始初始化環境..."
echo ""

# 1. 處理 SSH 公鑰
print_info "檢查 SSH 公鑰..."

SSH_DIR="$HOME/.ssh"
PUB_KEY_PATH="$SSH_DIR/id_rsa.pub"
PRIV_KEY_PATH="$SSH_DIR/id_rsa"

if [ -f "$PUB_KEY_PATH" ]; then
    print_warning "SSH 公鑰已存在: $PUB_KEY_PATH"
    print_warning "跳過 ssh-keygen 生成步驟"
else
    print_info "SSH 公鑰不存在，開始生成..."
    
    # 確保 .ssh 目錄存在
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    # 生成 SSH 密鑰對
    ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$PRIV_KEY_PATH" -N ""
    
    if [ $? -eq 0 ]; then
        print_info "SSH 密鑰對生成成功"
        chmod 600 "$PRIV_KEY_PATH"
        chmod 644 "$PUB_KEY_PATH"
    else
        print_error "SSH 密鑰對生成失敗"
        exit 1
    fi
fi

# 打印公鑰內容
echo ""
print_info "=== SSH 公鑰内容 ==="
cat "$PUB_KEY_PATH"
echo "======================"
echo ""

# 2. 處理 AWS ID/key
print_info "配置 AWS 憑證..."

# 導出當前會話環境變量
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY

print_info "AWS_ACCESS_KEY_ID 和 AWS_SECRET_ACCESS_KEY 已導出到當前會話"

# 更新 ~/.bashrc
BASHRC="$HOME/.bashrc"

# 檢查是否已经存在 AWS 配置
if grep -q "export AWS_ACCESS_KEY_ID" "$BASHRC" 2>/dev/null; then
    print_warning "~/.bashrc 中已存在 AWS_ACCESS_KEY_ID 配置，正在更新..."
    # 使用 sed 替換現有配置
    sed -i "/export AWS_ACCESS_KEY_ID=/d" "$BASHRC"
    sed -i "/export AWS_SECRET_ACCESS_KEY=/d" "$BASHRC"
fi

# 添加新的配置到 .bashrc
echo "" >> "$BASHRC"
echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY" >> "$BASHRC"
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY" >> "$BASHRC"

print_info "AWS 憑證已添加到 ~/.bashrc"

echo ""
print_info "要使 AWS 憑證在未来的終端會話中生效，请運行："
echo "  source ~/.bashrc"
echo ""
print_info "或者重新打開終端"