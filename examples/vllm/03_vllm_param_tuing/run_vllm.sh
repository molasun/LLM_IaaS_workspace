#!/bin/bash

# 設定基本變數
IMAGE="registry.redhat.io/rhaiis/vllm-cuda-rhel9:3.2.3"
MODEL="RedHatAI/Qwen3-4B-FP8-dynamic"
NAME="qwen3-4b"

# 共用選項（不變的部分）
BASE_OPTS=(
    --rm
    -it
    --name "$NAME"
    --device nvidia.com/gpu=all
    --security-opt=label=disable
    --shm-size=4g
    -p 8000:8000
    --userns=keep-id:uid=1001
    --env "HF_HUB_OFFLINE=0"
    --env "VLLM_NO_USAGE_STATS=1"
    -v "./hf-cache:/root/.cache/huggingface:Z"
)

# 顯示使用說明
usage() {
    cat << EOF
使用方法: $0 [選項1] [選項2] ... [選項N]

可用選項（可自由組合）:
  --gpu-memory-utilization <值>   設定 GPU 記憶體使用率（例如 0.5）
  --max-model-len <值>            設定最大上下文長度（例如 40000）
  --enforce-eager                 強制使用 eager 模式
  --max-num-seqs <值>             最大序列數量（例如 256）
  --no-enable-prefix-caching      禁用前綴快取
  --max-num-batched-tokens <值>   最大批處理 token 數量（例如 8192）

範例:
  $0 --gpu-memory-utilization 0.5
  $0 --max-model-len 40000 --enforce-eager
  $0 --max-model-len 40000 --enforce-eager --max-num-seqs 128
  $0 --gpu-memory-utilization 0.7 --max-model-len 50000 --max-num-batched-tokens 4096
  $0 --max-model-len 30000 --enforce-eager --no-enable-prefix-caching --max-num-seqs 200

EOF
    exit 1
}

# 儲存額外參數的陣列
EXTRA_ARGS=()

# 解析參數
while [ $# -gt 0 ]; do
    case "$1" in
        --gpu-memory-utilization)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --gpu-memory-utilization 需要提供數值"
                usage
            fi
            EXTRA_ARGS+=(--gpu-memory-utilization "$2")
            shift 2
            ;;
        --max-model-len)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --max-model-len 需要提供數值"
                usage
            fi
            EXTRA_ARGS+=(--max-model-len "$2")
            shift 2
            ;;
        --max-num-seqs)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --max-num-seqs 需要提供數值"
                usage
            fi
            EXTRA_ARGS+=(--max-num-seqs "$2")
            shift 2
            ;;
        --max-num-batched-tokens)
            if [ -z "$2" ] || [[ "$2" =~ ^-- ]]; then
                echo "錯誤: --max-num-batched-tokens 需要提供數值"
                usage
            fi
            EXTRA_ARGS+=(--max-num-batched-tokens "$2")
            shift 2
            ;;
        --enforce-eager)
            EXTRA_ARGS+=(--enforce-eager)
            shift
            ;;
        --no-enable-prefix-caching)
            EXTRA_ARGS+=(--no-enable-prefix-caching)
            shift
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

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  📦 Podman 執行命令${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}▶${NC} podman run \\"
for opt in "${BASE_OPTS[@]}"; do
    echo -e "      ${YELLOW}$opt${NC} \\"
done
echo -e "      ${YELLOW}$IMAGE${NC} \\"
echo -e "      ${YELLOW}--model $MODEL${NC} \\"
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
[[ ! $REPLY =~ ^[Yy]$ ]] && { echo "已取消"; exit 0; }

# 執行 podman
podman run "${BASE_OPTS[@]}" "$IMAGE" \
    --model "$MODEL" \
    "${EXTRA_ARGS[@]}"