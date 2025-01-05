import axios from 'axios';

const api = axios.create({
    baseURL: 'http://localhost:8000',  // 后端服务器地址
    withCredentials: true,  // 允许跨域请求携带凭证
    headers: {
        'Content-Type': 'application/json',
    }
});

export default api; 