#!/bin/bash

# 設定基本變數
TARGET_URL="http://localhost:8000"
MODEL="RedHatAI/Qwen3-4B-FP8-dynamic"

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

# 顯示使用說明
usage() {
    cat << EOF
使用方法: $0 [選項1] [選項2] ... [選項N]

可用選項（可自由組合）:
  --target <URL>                目標 API 端點（預設: http://localhost:8000）
  --model <名稱>                模型名稱（預設: RedHatAI/Qwen3-4B-FP8-dynamic）
  --data <格式>                 測試資料格式（例如: "prompt_tokens=512,output_tokens=256"）
  --profile <類型>              效能分析類型（例如: sweep）
  --max-seconds <秒數>          最大執行時間（例如: 30）
  --rate <數值>                 請求速率（例如: 128）
  --max-requests <數量>         最大請求數量（例如: 128）
  --help                        顯示此說明

範例:
  $0 
  $0 --data "prompt_tokens=512,output_tokens=256"
  $0 --profile sweep --max-seconds 30
  $0 --rate 128 --max-requests 128
  $0 --target "http://localhost:8080" --model "RedHatAI/Qwen3-4B-FP8-dynamic" --max-seconds 60

EOF
    exit 1
}

# 儲存額外參數的陣列
EXTRA_ARGS=()

# 解析參數
while [ $# -gt 0 ]; do
    case "$1" in
        --target)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --target 需要提供 URL"
                usage
            fi
            TARGET_URL="$2"
            shift 2
            ;;
        --model)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --model 需要提供模型名稱"
                usage
            fi
            MODEL="$2"
            shift 2
            ;;
        --data)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --data 需要提供格式（例如: prompt_tokens=512,output_tokens=256）"
                usage
            fi
            EXTRA_ARGS+=(--data "$2")
            shift 2
            ;;
        --profile)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --profile 需要提供類型"
                usage
            fi
            EXTRA_ARGS+=(--profile "$2")
            shift 2
            ;;
        --max-seconds)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --max-seconds 需要提供秒數"
                usage
            fi
            EXTRA_ARGS+=(--max-seconds "$2")
            shift 2
            ;;
        --rate)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --rate 需要提供數值"
                usage
            fi
            EXTRA_ARGS+=(--rate "$2")
            shift 2
            ;;
        --max-requests)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --max-requests 需要提供數量"
                usage
            fi
            EXTRA_ARGS+=(--max-requests "$2")
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo "錯誤: 未知選項 '$1'"
            usage
            ;;
    esac
done

# 漂亮的輸出格式
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  🎯 GuideLLM 效能測試${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}▶${NC} guidellm benchmark \\"
echo -e "      ${YELLOW}--target \"$TARGET_URL\"${NC} \\"
echo -e "      ${YELLOW}--model \"$MODEL\"${NC} \\"
if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
    for ((i=0; i<${#EXTRA_ARGS[@]}; i++)); do
        if [[ ${EXTRA_ARGS[$i]} == --* ]] && [[ $((i+1)) -lt ${#EXTRA_ARGS[@]} ]] && [[ ! ${EXTRA_ARGS[$((i+1))]} == --* ]]; then
            echo -e "      ${YELLOW}${EXTRA_ARGS[$i]} ${EXTRA_ARGS[$((i+1))]}${NC} \\"
            ((i++))
        else
            echo -e "      ${YELLOW}${EXTRA_ARGS[$i]}${NC} \\"
        fi
    done
fi
echo -e "      ${GREEN}# 命令結束${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "是否繼續執行？ [y/N]: " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && { echo -e "${YELLOW}已取消${NC}"; exit 0; }

# 執行 guidellm
echo -e "${GREEN}開始執行 GuideLLM 測試...${NC}"
echo ""
guidellm benchmark \
    --target "$TARGET_URL" \
    --model "$MODEL" \
    "${EXTRA_ARGS[@]}"