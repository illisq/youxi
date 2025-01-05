<template>
  <div class="module-list">
    <h1>TRPG 模组列表</h1>
    <div class="filters">
      <input 
        v-model="searchQuery" 
        type="text" 
        placeholder="搜索模组..."
        class="search-input"
      >
      <button class="add-button" @click="showAddModuleDialog">
        新增模组
      </button>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading">
      加载中...
    </div>

    <!-- 错误信息 -->
    <div v-else-if="error" class="error-message">
      {{ error }}
      <button @click="fetchModules" class="retry-button">重试</button>
    </div>

    <!-- 空状态 -->
    <div v-else-if="modules.length === 0" class="empty-state">
      暂无模组数据
    </div>

    <!-- 模组列表 -->
    <div v-else class="modules-grid">
      <div v-for="module in filteredModules" :key="module.module_id" class="module-wrapper">
        <ModuleCard
          :module="module"
          @click="goToModuleDetail(module.module_id)"
        />
        <button class="delete-button" @click.stop="deleteModule(module.module_id)">
          删除
        </button>
      </div>
    </div>

    <!-- 新增模组对话框 -->
    <div v-if="showDialog" class="dialog-overlay">
      <div class="dialog">
        <h2>新增模组</h2>
        <form @submit.prevent="addModule">
          <div class="form-group">
            <label>标题：</label>
            <input v-model="newModule.title" required>
          </div>
          <div class="form-group">
            <label>描述：</label>
            <textarea v-model="newModule.description" required></textarea>
          </div>
          <div class="dialog-buttons">
            <button type="submit">保存</button>
            <button type="button" @click="showDialog = false">取消</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import ModuleCard from '../components/ModuleCard.vue';
import api from '../services/api';

// 定义模组接口
interface Module {
  module_id: number;
  title: string;
  description: string;
}

const router = useRouter();
const modules = ref<Module[]>([]);
const searchQuery = ref('');
const loading = ref(true);
const error = ref<string | null>(null);
const showDialog = ref(false);
const newModule = ref({
  title: '',
  description: ''
});

const filteredModules = computed(() => {
  return modules.value.filter(module => 
    module.title.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    module.description.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

const fetchModules = async () => {
  try {
    loading.value = true;
    error.value = null; // 清除之前的错误
    const response = await api.get('/modules/');
    modules.value = response.data;
    console.log('Fetched modules:', response.data); // 添加日志
  } catch (err) {
    console.error('Error fetching modules:', err);
    error.value = err.response?.data?.detail || '获取模组列表失败';
  } finally {
    loading.value = false;
  }
};

const goToModuleDetail = (moduleId: number) => {
  router.push(`/modules/${moduleId}`);
};

const showAddModuleDialog = () => {
  showDialog.value = true;
  newModule.value = {
    title: '',
    description: ''
  };
};

const addModule = async () => {
  try {
    const response = await api.post('/modules/', newModule.value);
    const newModuleData = {
      module_id: response.data.module_id,
      title: response.data.title,
      description: response.data.description
    };
    modules.value.push(newModuleData);
    showDialog.value = false;
    newModule.value = {
      title: '',
      description: ''
    };
  } catch (err) {
    error.value = '添加模组失败';
    console.error('Error adding module:', err);
  }
};

const deleteModule = async (moduleId: number) => {
  if (!confirm('确定要删除这个模组吗？')) return;
  
  try {
    await api.delete(`/modules/${moduleId}`);
    modules.value = modules.value.filter(m => m.module_id !== moduleId);
  } catch (err) {
    error.value = '删除模组失败';
    console.error('Error deleting module:', err);
  }
};

onMounted(() => {
  fetchModules();
});
</script>

<style scoped>
.module-list {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
}

h1 {
  text-align: center;
  color: #333;
  margin-bottom: 32px;
}

.filters {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.search-input {
  width: 100%;
  max-width: 400px;
  padding: 8px 16px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1em;
}

.modules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}

.error-message {
  color: #c5221f;
  text-align: center;
  padding: 16px;
}

.loading {
  text-align: center;
  padding: 32px;
  color: #666;
}

.add-button {
  padding: 8px 16px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.add-button:hover {
  background-color: #45a049;
}

.module-wrapper {
  position: relative;
}

.delete-button {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 4px 8px;
  background-color: #f44336;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  z-index: 1;
}

.delete-button:hover {
  background-color: #da190b;
}

.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.dialog {
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.form-group textarea {
  height: 100px;
}

.dialog-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.dialog-buttons button {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.dialog-buttons button[type="submit"] {
  background-color: #4CAF50;
  color: white;
}

.dialog-buttons button[type="button"] {
  background-color: #f44336;
  color: white;
}

.empty-state {
  text-align: center;
  padding: 32px;
  color: #666;
  font-size: 1.1em;
}

.retry-button {
  margin-left: 8px;
  padding: 4px 8px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.retry-button:hover {
  background-color: #45a049;
}
</style> 