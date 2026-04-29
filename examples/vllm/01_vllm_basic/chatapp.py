import gradio as gr
from openai import OpenAI
import base64
import io
import requests
import re
from PIL import Image as PILImage

# 1. 連接到 vLLM 服務
client = OpenAI(
    api_key="EMPTY",
    base_url="http://example.com:8000/v1"
)

# 模型配置
MODELS = {
    "純文字模型": {
        "name": "RedHatAI/Qwen3-8B-FP8-dynamic",
        "is_multimodal": False
    },
    "多模態模型": {
        "name": "RedHatAI/gemma-3-12b-it-FP8-dynamic",
        "is_multimodal": True
    }
}

SYSTEM_PROMPT = """請遵守以下規則：
1. 始終使用繁體中文回覆
2. 每次回答的結尾都加上 "還有什麼需要我幫助的嗎?"
3. 不許串改內容
"""

def encode_image_to_base64(image):
    """將 PIL Image 轉換為 base64 編碼"""
    if image is None:
        return None
    buffered = io.BytesIO()
    image.save(buffered, format="PNG")
    return base64.b64encode(buffered.getvalue()).decode('utf-8')

def load_image_from_url(url):
    """從網址載入圖片"""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        image = PILImage.open(io.BytesIO(response.content))
        return image
    except Exception as e:
        raise Exception(f"無法從網址載入圖片: {str(e)}")

def remove_think_tags(text):
    """移除 <think> 標籤內的內容（需求1）"""
    # 使用正則表達式移除 <think>...</think> 及其內容
    pattern = r'<think>.*?</think>'
    cleaned_text = re.sub(pattern, '', text, flags=re.DOTALL)
    # 清理可能產生的多餘換行
    cleaned_text = re.sub(r'\n\s*\n', '\n', cleaned_text)
    return cleaned_text.strip()

def predict(message, history, selected_model, uploaded_image=None, image_url=None):
    """
    message: 用戶當前輸入的問題
    history: 之前的聊天記錄
    selected_model: 選擇的模型名稱
    uploaded_image: 上傳的本地圖片
    image_url: 圖片的網址
    """
    # 獲取模型配置
    model_config = MODELS[selected_model]
    model_name = model_config["name"]
    is_multimodal = model_config["is_multimodal"]
    
    # 處理圖片來源：優先使用上傳的本地圖片，其次使用圖片網址
    final_image = uploaded_image
    if final_image is None and image_url:
        try:
            final_image = load_image_from_url(image_url)
        except Exception as e:
            yield f"圖片載入錯誤: {str(e)}"
            return
    # 構建 messages
    messages = []

    messages.append({"role": "system", "content": SYSTEM_PROMPT})
    
    # 添加歷史對話 - 修正格式處理
    if history and isinstance(history, list):
        for msg_obj in history:
            # 確保每個消息都是正確的 OpenAI 格式
            if isinstance(msg_obj, dict) and "role" in msg_obj and "content" in msg_obj:
                messages.append({
                    "role": msg_obj["role"],
                    "content": msg_obj["content"]
                })
    
    # 處理當前用戶輸入（可能包含圖片）
    if is_multimodal and final_image is not None:
        # 多模態模型且有圖片
        image_base64 = encode_image_to_base64(final_image)
        current_content = [
            {
                "type": "image_url",
                "image_url": {"url": f"data:image/png;base64,{image_base64}"}
            },
            {"type": "text", "text": message if message else "請描述這張圖片"}
        ]
        messages.append({"role": "user", "content": current_content})
    else:
        # 純文字模型或無圖片
        messages.append({"role": "user", "content": message if message else "你好"})
    
    try:
        # 調用 vLLM 服務
        stream = client.chat.completions.create(
            model=model_name,
            messages=messages,
            temperature=0.8,
            stream=True,
            max_tokens=2048
        )
        
        # 處理流式響應
        partial_message = ""
        for chunk in stream:
            if chunk.choices[0].delta.content is not None:
                partial_message += chunk.choices[0].delta.content
                yield partial_message
    except Exception as e:
        error_msg = f"錯誤：無法連接到模型。請確認：\n1. vLLM 服務是否正常運行\n2. 模型名稱 '{model_name}' 是否正確\n3. 詳細錯誤：{str(e)}"
        yield error_msg

# 取得 vLLM 社區 Logo（使用線上範例圖片）
VLLM_LOGO_URL = "https://docs.vllm.ai/en/latest/assets/logos/vllm-logo-text-dark.png"

def process_with_thinking(message, history, model, uploaded_image, image_url):
    """處理回應，移除 think 標籤並顯示思考提示（保留流式效果）"""
    full_response = ""
    in_think = False
    think_tag_encountered = False
    after_think_processed = False
    remaining_buffer = ""
    
    response_generator = predict(message, history, model, uploaded_image, image_url)
    
    for chunk in response_generator:
        full_response += chunk
        
        # 情況1：還沒遇到 think 標籤
        if not think_tag_encountered:
            if '<think>' in full_response:
                think_tag_encountered = True
                in_think = True
                # 顯示思考提示
                yield "💭 思考中..."
                continue
            else:
                # 完全沒有 think 標籤，正常輸出
                yield chunk
                continue
        
        # 情況2：遇到 think 標籤，正在等待結束
        if in_think:
            if '</think>' in full_response:
                in_think = False
                # 提取 think 之後的內容
                after_think = full_response.split('</think>', 1)[-1]
                if after_think:
                    # 使用 remove_think_tags 清理
                    cleaned = remove_think_tags(after_think)
                    if cleaned:
                        yield cleaned
                        after_think_processed = True
                # 記錄剩餘緩衝
                remaining_buffer = after_think if after_think else ""
            continue
        
        # 情況3：think 已結束，輸出後續新增的內容（不重複輸出）
        if not in_think and think_tag_encountered:
            # 獲取當前完整的清理後內容
            current_cleaned = remove_think_tags(full_response)
            if current_cleaned:
                # 只輸出比之前多的部分
                if len(current_cleaned) > len(remaining_buffer):
                    new_part = current_cleaned[len(remaining_buffer):]
                    if new_part:
                        yield new_part
                        remaining_buffer = current_cleaned

# 定義回應函數
def respond(message, history, model, uploaded_image, image_url):
    """
    回應函數，維護 OpenAI 格式的對話歷史
    history: OpenAI 格式的消息列表 [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]
    """

    if not message and uploaded_image is None and not image_url:
        yield history, gr.update(value="", interactive=True), gr.update(), gr.update(value="")
        return
    
    # 清空輸入框
    yield history, gr.update(value="", interactive=False), gr.update(), gr.update(value="")

    # 確保 history 是列表
    if history is None:
        history = []

    # 呼叫 predict 獲取回應
    response_generator = process_with_thinking(message, history, model, uploaded_image, image_url)
    full_response = ""
    for response in response_generator:
        full_response = response
        # 更新聊天記錄
        new_history = history + [
            {"role": "user", "content": message},
            {"role": "assistant", "content": full_response}
        ]
        yield new_history, gr.update(value="", interactive=False), gr.update(value=None), gr.update(value="")

    # 確保結尾有空行再加上問句
    if full_response and "還有什麼需要我幫助的嗎?" not in full_response:
        full_response = full_response.rstrip() + "\n\n還有什麼需要我幫助的嗎?"
    elif full_response and "還有什麼需要我幫助的嗎?" in full_response:
        # 如果已經有問句，確保前面有空行
        full_response = full_response.replace("還有什麼需要我幫助的嗎?", "\n\n還有什麼需要我幫助的嗎?")
    
    # 最後恢復輸入框
    final_history = history + [
        {"role": "user", "content": message},
        {"role": "assistant", "content": full_response}
    ]
    yield final_history, gr.update(value="", interactive=True), gr.update(value=None), gr.update(value="")

# 清除對話記錄
def clear_conversation():
    """同時清除圖片上傳和網址輸入"""
    return [], gr.update(value=None), ""

# 建立自定義界面 - 移除 theme 參數
with gr.Blocks(title="vLLM 聊天機器人") as demo:
    # Logo 區域（需求1）
    with gr.Row():
        gr.HTML(f"""
        <div style="display: flex; align-items: center; gap: 15px; margin-bottom: 20px; padding: 10px; border-bottom: 2px solid #ddd;">
            <img src="{VLLM_LOGO_URL}" alt="vLLM Logo" style="width: 50px; height: 50px; border-radius: 10px;">
            <span style="font-size: 24px; font-weight: bold; color: #2c3e50;">vLLM 社區聊天機器人</span>
        </div>
        """)
    
    # 主要內容區域
    with gr.Row():
        # 左側控制面板
        with gr.Column(scale=1):
            gr.Markdown("### ⚙️ 設定")
            
            # 模型切換功能（需求3）
            model_selector = gr.Radio(
                choices=list(MODELS.keys()),
                value=list(MODELS.keys())[0],
                label="🤖 選擇模型"
            )

            # 添加提示文字
            gr.Markdown("""
            ### 📝 使用說明
            - **純文字模型**：只能進行文字對話
            - **多模態模型**：可以上傳圖片並詢問圖片的相關問題
            - 模型切換後，對話歷史會保留
            """)

            gr.Markdown("### 📷 圖片輸入（僅多模態模型有效）")

            # 功能1：上傳本地文件
            image_upload = gr.Image(
                type="pil",
                label="1️⃣ 上傳本地圖片",
                height=200,
                sources=["upload"]  # 只保留上傳功能，移除 webcam
            )
            
            # 功能2：上傳圖片網址
            image_url_input = gr.Textbox(
                label="2️⃣ 輸入圖片網址",
                placeholder="https://example.com/image.jpg",
                lines=1
            )

            # 添加提示文字
            gr.Markdown("""
             ### 📝 使用說明
            - 可以選擇上傳本地圖片或輸入圖片網址
            - 如果同時提供，將優先使用本地圖片
            - 僅在多模態模型下生效
            """)           
            
            clear_btn = gr.Button("🗑️ 清除對話記錄", variant="secondary")
        
        # 右側聊天區域
        with gr.Column(scale=3):
            chatbot = gr.Chatbot(
                label="對話記錄",
                height=500
            )
            
            with gr.Row():
                msg = gr.Textbox(
                    label="輸入你的訊息",
                    placeholder="請在這裡輸入你的問題...（按下 Enter 發送）",
                    scale=8,
                    lines=1,
                    interactive=True
                )
                send_btn = gr.Button("發送", variant="primary", scale=1)
    
    # 狀態變數
    state = gr.State([])
    
    # 事件處理
    send_btn.click(
        respond,
        inputs=[msg, chatbot, model_selector, image_upload, image_url_input],
        outputs=[chatbot, msg, image_upload, image_url_input]
    )
    
    msg.submit(
        respond,
        inputs=[msg, chatbot, model_selector, image_upload, image_url_input],
        outputs=[chatbot, msg, image_upload, image_url_input]
    )
   
    clear_btn.click(
        clear_conversation,
        outputs=[chatbot, image_upload, image_url_input]
    )

    # 當切換模型時顯示提示
    def on_model_change(model):
        if MODELS[model]["is_multimodal"]:
            gr.Info(f"✅ 已切換到 {model}，支援上傳圖片進行多模態對話")
        else:
            gr.Info(f"✅ 已切換到 {model}，僅支援純文字對話")
        return gr.update()
    
    model_selector.change(
        on_model_change,
        inputs=[model_selector],
        outputs=[model_selector]
    )

if __name__ == "__main__":
    demo.launch(
        server_port=7860,
        share=True,
        debug=False
    )