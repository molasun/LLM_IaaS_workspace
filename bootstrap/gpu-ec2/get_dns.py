import json
import subprocess

def get_public_dns_from_terraform():
    try:
        # 執行 terraform show -json 命令
        result = subprocess.run(
            ['terraform', 'show', '-json'],
            capture_output=True,
            text=True,
            check=True
        )
        
        # 解析 JSON 輸出
        data = json.loads(result.stdout)
        
        # 擷取 public_dns 的值
        public_dns = data.get('values', {}).get('outputs', {}).get('public_dns', {}).get('value', [])
        
        if public_dns and len(public_dns) > 0:
            return public_dns
        else:
            print("找不到 public_dns")
            return None
            
    except subprocess.CalledProcessError as e:
        print(f"執行 terraform 命令失敗: {e}")
        print(f"錯誤輸出: {e.stderr}")
        return None
    except json.JSONDecodeError as e:
        print(f"解析 JSON 失敗: {e}")
        return None
    except FileNotFoundError:
        print("找不到 terraform 命令，請確保安裝了 Terraform 並在 PATH 中")
        return None

# 入口函數
if __name__ == "__main__":
    dns_list = get_public_dns_from_terraform()
    if dns_list:
        # 輸出 Markdown 表格
        print("| # | Public DNS |")
        print("|---|------------|")
        for i, dns in enumerate(dns_list, 1):
            print(f"| {i} | {dns} |")