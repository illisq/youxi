from openai import OpenAI
client = OpenAI(
    base_url='https://xiaoai.plus/v1',
    api_key='sk-t42cuTxpubfUMnw0jeQHud5h0RhBd7QqfpHfimcImI7n2pVr'
)
completion = client.chat.completions.create(
  model="gpt-4o",
  messages=[
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
  ]
)
print(completion.choices[0].message)