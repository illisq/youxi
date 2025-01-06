技术栈：
FastAPI + Python + PostgreSQL + OpenAI API + Vue + Node + npm

后端运行：
```
cd backend
uvicorn main:app --reload
```

数据库文件在backend/migrations/full_backup.sql

为了方便运行，我的openai api key并没有删掉，但是其内部余额较少，如果对话出现问题，请自行更换api key。

前端运行：
```
cd frontend
npm install
npm run dev
```
