from openai import OpenAI
from typing import Dict, List, Any
import os

client = OpenAI(
    base_url='https://xiaoai.plus/v1',
    api_key=os.getenv('OPENAI_API_KEY', 'sk-t42cuTxpubfUMnw0jeQHud5h0RhBd7QqfpHfimcImI7n2pVr')
)

async def get_ai_response(
    npc_prompt: Dict[str, str],
    user_message: str,
    chat_history: List[Any]
) -> str:
    # 构建系统提示
    system_prompt = f"""
    你现在扮演一个名为 {npc_prompt['name']} 的NPC角色。
    
    角色信息：
    - 职位：{npc_prompt['position']}
    - 背景：{npc_prompt['background']}
    - 性格：{npc_prompt['personality']}
    
    额外设定：{npc_prompt['chat_prompt']}
    
    请以这个角色的身份回应用户的对话，保持角色特征的一致性。
    """
    
    # 构建对话历史
    messages = [{"role": "system", "content": system_prompt}]
    
    # 添加历史对话
    for content, is_npc in chat_history:
        role = "assistant" if is_npc else "user"
        messages.append({"role": role, "content": content})
    
    # 添加用户的新消息
    messages.append({"role": "user", "content": user_message})
    
    try:
        # 调用 AI API
        completion = client.chat.completions.create(
            model="gpt-4o",  # 使用正确的模型名称
            messages=messages
        )
        
        return completion.choices[0].message.content
        
    except Exception as e:
        print(f"Error calling AI API: {str(e)}")
        return "抱歉，我现在无法正常回应，请稍后再试。" 