import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from openai import OpenAI
from typing import Dict, List, Any
from sqlalchemy.orm import Session
from models import PlayerStatus, GameEvent
from datetime import datetime
import json

client = OpenAI(
    base_url='https://xiaoai.plus/v1',
    api_key=os.getenv('OPENAI_API_KEY')
)

class AIService:
    def __init__(self, base_url: str, api_key: str):
        self.client = OpenAI(
            base_url=base_url,
            api_key=api_key
        )
        
    async def get_npc_response(self, system_prompt: str, user_message: str) -> Dict[str, Any]:
        try:
            print("\n=== AI Service Debug ===")
            print(f"Sending request to OpenAI API...")
            
            completion = self.client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message}
                ]
            )
            
            # 从 ChatCompletionMessage 对象中获取 content
            response_text = completion.choices[0].message.content
            print(f"\nRaw API Response:")
            print(response_text)
            
            # 解析JSON字符串
            response_data = json.loads(response_text)
            print(f"\nParsed Response Data:")
            print(json.dumps(response_data, indent=2, ensure_ascii=False))
            print("=====================\n")
            
            return {
                "response": response_data["response"],
                "effects": response_data["effects"]
            }
            
        except Exception as e:
            print(f"\nError in get_npc_response: {str(e)}")
            print(f"Error type: {type(e)}")
            import traceback
            print(f"Traceback:\n{traceback.format_exc()}")
            return {
                "response": "对不起，系统出现了一些问题。",
                "effects": {
                    "sanity": 0,
                    "alienation": 0,
                    "chen_influence": 0,
                    "liu_influence": 0,
                    "discovered_secrets": []
                }
            }

    def _update_player_status(self, session_id: int, effects: Dict):
        """根据AI分析的效果更新玩家状态"""
        status = self.db.query(PlayerStatus).filter_by(session_id=session_id).first()
        
        # 记录更新前的状态
        print("\n=== 玩家状态更新 ===")
        print(f"会话ID: {session_id}")
        print("\n更新前状态:")
        print(f"理智值: {status.sanity_value}")
        print(f"异化值: {status.alienation_value}")
        print(f"陈总影响力: {status.chen_influence}")
        print(f"刘总监影响力: {status.liu_influence}")
        print(f"已发现的秘密: {status.discovered_secrets}")
        
        # 更新基础属性
        old_values = {
            "sanity": status.sanity_value,
            "alienation": status.alienation_value,
            "chen_influence": status.chen_influence,
            "liu_influence": status.liu_influence
        }
        
        status.sanity_value = max(0, min(100, status.sanity_value + effects["sanity"]))
        status.alienation_value = max(0, min(100, status.alienation_value + effects["alienation"]))
        status.chen_influence = max(0, min(100, status.chen_influence + effects["chen_influence"]))
        status.liu_influence = max(0, min(100, status.liu_influence + effects["liu_influence"]))
        
        # 更新发现的秘密
        old_secrets = set(status.discovered_secrets or [])
        new_secrets = set(effects["discovered_secrets"])
        status.discovered_secrets = list(old_secrets.union(new_secrets))
        
        # 记录变化
        print("\n状态变化:")
        print(f"理智值: {old_values['sanity']} -> {status.sanity_value} (变化: {effects['sanity']})")
        print(f"异化值: {old_values['alienation']} -> {status.alienation_value} (变化: {effects['alienation']})")
        print(f"陈总影响力: {old_values['chen_influence']} -> {status.chen_influence} (变化: {effects['chen_influence']})")
        print(f"刘总监影响力: {old_values['liu_influence']} -> {status.liu_influence} (变化: {effects['liu_influence']})")
        
        # 记录新发现的秘密
        newly_discovered = new_secrets - old_secrets
        if newly_discovered:
            print("\n新发现的秘密:")
            for secret in newly_discovered:
                print(f"- {secret}")
        
        print("\n=== 更新完成 ===\n")
        
        # 记录事件
        self.record_event(
            session_id=session_id,
            event_type="status_update",
            event_data={
                "changes": {
                    "sanity": effects["sanity"],
                    "alienation": effects["alienation"],
                    "chen_influence": effects["chen_influence"],
                    "liu_influence": effects["liu_influence"]
                },
                "new_secrets": list(newly_discovered),
                "old_values": old_values,
                "new_values": {
                    "sanity": status.sanity_value,
                    "alienation": status.alienation_value,
                    "chen_influence": status.chen_influence,
                    "liu_influence": status.liu_influence
                }
            }
        )
        
        self.db.commit()

    def record_event(self, session_id: int, event_type: str, event_data: dict):
        """记录游戏事件"""
        event = GameEvent(
            session_id=session_id,
            event_type=event_type,
            event_data=event_data,
            created_at=datetime.utcnow()
        )
        self.db.add(event)
        self.db.commit()
        return event 