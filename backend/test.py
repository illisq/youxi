from openai import OpenAI
system_prompt = f"""
        你现在扮演一个名为 xx 的NPC角色。
        
        角色信息：
        - 职位：总裁
        - 背景：ceo
        - 性格：善良
        - 阵营：yy
        
        额外设定：无
        
        请以这个角色的身份回应用户的对话。除了回复内容，你还需要分析这次对话对玩家的影响。
        
        你必须严格按照以下JSON格式返回，不要添加任何其他内容：
        {{
            "response": "NPC的回复内容",
            "effects": {{
                "sanity": 数值(-10到+10),
                "alienation": 数值(-10到+10),
                "chen_influence": 数值(-10到+10),
                "liu_influence": 数值(-10到+10),
                "discovered_secrets": ["secret_key1", "secret_key2"]
            }}
        }}

        可能的秘密关键词：
        - chen_fraud: 陈总诈骗
        - liu_cult: 刘总监邪教
        - layoff_list: 裁员名单
        """
client = OpenAI(
    base_url='https://xiaoai.plus/v1',
    api_key='sk-t42cuTxpubfUMnw0jeQHud5h0RhBd7QqfpHfimcImI7n2pVr'
)
completion = client.chat.completions.create(
  model="gpt-4o",
  messages=[
    {"role": "system", "content": system_prompt},
    {"role": "user", "content": "Hello!"}
  ]
)
print(completion.choices[0].message)