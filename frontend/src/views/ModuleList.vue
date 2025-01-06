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
        <button 
          class="delete-button" 
          @click.stop="deleteModule(module.module_id)"
          type="button"
        >
          删除
        </button>
      </div>
    </div>

    <!-- 新增模组对话框 -->
    <div v-if="showDialog" class="dialog-overlay">
      <div class="dialog">
        <h2>新增模组 - 步骤 {{ currentStep }}/{{ totalSteps }}</h2>
        
        <!-- 步骤指示器 -->
        <div class="step-indicator">
          <div 
            v-for="step in totalSteps" 
            :key="step"
            :class="['step', { active: step === currentStep, completed: step < currentStep }]"
          >
            {{ step }}
          </div>
        </div>

        <!-- 步骤 1: 基本信息 -->
        <div v-if="currentStep === 1">
          <form @submit.prevent="nextStep">
            <div class="form-group">
              <label>标题：</label>
              <input v-model="newModule.title" required>
            </div>
            <div class="form-group">
              <label>描述：</label>
              <textarea v-model="newModule.description" required></textarea>
            </div>
            <div class="form-group">
              <label>最少玩家数：</label>
              <input type="number" v-model="newModule.player_min" required min="1">
            </div>
            <div class="form-group">
              <label>最多玩家数：</label>
              <input type="number" v-model="newModule.player_max" required min="1">
            </div>
            <div class="form-group">
              <label>预计时长（小时）：</label>
              <input type="number" v-model="newModule.duration_hours" required min="0.5" step="0.5">
            </div>
            <div class="form-group">
              <label>难度：</label>
              <select v-model="newModule.difficulty" required>
                <option value="easy">简单</option>
                <option value="medium">中等</option>
                <option value="hard">困难</option>
              </select>
            </div>
          </form>
        </div>

        <!-- 步骤 2: 职业选项 -->
        <div v-if="currentStep === 2">
          <div class="professions-list">
            <div v-for="(profession, index) in newModule.professions" :key="index" class="profession-item">
              <div class="input-group">
                <span class="input-label">职业名称</span>
                <input v-model="profession.name" placeholder="请输入职业名称">
              </div>
              <div class="input-group">
                <span class="input-label">职业描述</span>
                <textarea v-model="profession.description" placeholder="请输入职业描述"></textarea>
              </div>
              <button @click="removeProfession(index)" class="remove-btn">删除</button>
            </div>
            <button @click="addProfession" class="add-btn">添加职业</button>
          </div>
        </div>

        <!-- 步骤 3: NPC信息 -->
        <div v-if="currentStep === 3">
          <div class="npcs-list">
            <div v-for="(npc, index) in newModule.npcs" :key="index" class="npc-item">
              <div class="input-group">
                <span class="input-label">NPC名称</span>
                <input v-model="npc.name" placeholder="请输入NPC名称" required>
              </div>
              <div class="input-group">
                <span class="input-label">职位</span>
                <input v-model="npc.position" placeholder="请输入职位">
              </div>
              <div class="input-group">
                <span class="input-label">阵营</span>
                <input v-model="npc.faction" placeholder="请输入阵营">
              </div>
              <div class="input-group">
                <span class="input-label">背景故事</span>
                <textarea v-model="npc.background" placeholder="请输入背景故事"></textarea>
              </div>
              <div class="input-group">
                <span class="input-label">性格特征</span>
                <textarea v-model="npc.personality" placeholder="请输入性格特征"></textarea>
              </div>
              <div class="input-group">
                <span class="input-label">初始态度值</span>
                <input 
                  type="number" 
                  v-model="npc.initial_attitude" 
                  placeholder="请输入初始态度值"
                  min="-100"
                  max="100"
                >
              </div>
              <div class="input-group">
                <span class="input-label">秘密等级</span>
                <input 
                  type="number" 
                  v-model="npc.secret_level" 
                  placeholder="请输入秘密等级"
                  min="0"
                  max="10"
                >
              </div>
              <div class="input-group">
                <span class="input-label">对话提示</span>
                <textarea v-model="npc.chat_prompt" placeholder="请输入对话提示"></textarea>
              </div>
              <button @click="removeNPC(index)" class="remove-btn">删除</button>
            </div>
            <button @click="addNPC" class="add-btn">添加NPC</button>
          </div>
        </div>

        <!-- 步骤 4: 结局 -->
        <div v-if="currentStep === 4">
          <div class="endings-list">
            <div v-for="(ending, index) in newModule.endings" :key="index" class="ending-item">
              <div class="input-group">
                <span class="input-label">结局名称</span>
                <input v-model="ending.ending_name" placeholder="请输入结局名称" required>
              </div>
              <div class="input-group">
                <span class="input-label">结局描述</span>
                <textarea v-model="ending.ending_description" placeholder="请输入结局描述" required></textarea>
              </div>
              <button @click="removeEnding(index)" class="remove-btn">删除</button>
            </div>
            <button @click="addEnding" class="add-btn">添加结局</button>
          </div>
        </div>

        <!-- 导航按钮 -->
        <div class="dialog-buttons">
          <button 
            v-if="currentStep > 1" 
            @click="currentStep--" 
            type="button"
          >上一步</button>
          <button 
            v-if="currentStep < totalSteps" 
            @click="nextStep" 
            type="button"
          >下一步</button>
          <button 
            v-if="currentStep === totalSteps" 
            @click="submitModule" 
            type="submit"
          >保存</button>
          <button type="button" @click="closeDialog">取消</button>
        </div>
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
  player_min: number;
  player_max: number;
  duration_hours: number;
  difficulty: string;
  cover_image_url?: string;
  professions?: Profession[];
  npcs?: NPC[];
  endings?: Ending[];
}

interface Profession {
  name: string;
  description: string;
}

interface NPC {
  name: string;
  position?: string;
  faction?: string;
  background?: string;
  personality?: string;
  initial_attitude?: number;
  secret_level?: number;
  chat_prompt?: string;
}

interface Ending {
  ending_name: string;
  ending_description: string;
}

const router = useRouter();
const modules = ref<Module[]>([]);
const searchQuery = ref('');
const loading = ref(true);
const error = ref<string | null>(null);
const showDialog = ref(false);
const currentStep = ref(1);
const totalSteps = 4;
const newModule = ref({
  // 基本信息 - 步骤 1
  title: '',
  description: '',
  player_min: 1,
  player_max: 4,
  duration_hours: 2,
  difficulty: 'medium',
  cover_image_url: '',
  
  // 职业选项 - 步骤 2
  professions: [] as Profession[],
  
  // NPC信息 - 步骤 3
  npcs: [] as NPC[],
  
  // 结局 - 步骤 4
  endings: [] as Ending[]
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
    error.value = null;
    const response = await api.get('/modules/');
    modules.value = response.data;
    console.log('Fetched modules:', response.data);
  } catch (err: any) {
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
  currentStep.value = 1;
  newModule.value = {
    title: '',
    description: '',
    player_min: 1,
    player_max: 4,
    duration_hours: 2,
    difficulty: 'medium',
    cover_image_url: '',
    professions: [],
    npcs: [],
    endings: []
  };
};

const deleteModule = async (moduleId: number) => {
  if (!confirm('确定要删除这个模组吗？')) return;
  
  try {
    // 添加错误处理和日志
    console.log('Attempting to delete module:', moduleId);
    const response = await api.delete(`/modules/${moduleId}`);
    console.log('Delete response:', response);

    if (response.status === 200 || response.status === 204) {
      // 删除成功，更新本地数据
      modules.value = modules.value.filter(m => m.module_id !== moduleId);
    } else {
      throw new Error('删除失败：服务器返回非成功状态码');
    }
  } catch (err: any) {
    console.error('Error deleting module:', err);
    // 提供更详细的错误信息
    error.value = err.response?.data?.detail || 
                 err.response?.data?.message || 
                 err.message || 
                 '删除模组失败，请稍后重试';
                 
    // 显示错误信息3秒后自动清除
    setTimeout(() => {
      error.value = null;
    }, 3000);
  }
};

const addProfession = () => {
  newModule.value.professions.push({
    name: '',
    description: ''
  });
};

const removeProfession = (index: number) => {
  newModule.value.professions.splice(index, 1);
};

const addNPC = () => {
  newModule.value.npcs.push({
    name: '',
    position: '',
    faction: '',
    background: '',
    personality: '',
    initial_attitude: 0,
    secret_level: 0,
    chat_prompt: ''
  });
};

const removeNPC = (index: number) => {
  newModule.value.npcs.splice(index, 1);
};

const addEnding = () => {
  newModule.value.endings.push({
    ending_name: '',
    ending_description: ''
  });
};

const removeEnding = (index: number) => {
  newModule.value.endings.splice(index, 1);
};

const nextStep = () => {
  if (currentStep.value < totalSteps) {
    currentStep.value++;
  }
};

const closeDialog = () => {
  showDialog.value = false;
  currentStep.value = 1;
  newModule.value = {
    title: '',
    description: '',
    player_min: 1,
    player_max: 4,
    duration_hours: 2,
    difficulty: 'medium',
    cover_image_url: '',
    professions: [],
    npcs: [],
    endings: []
  };
};

const submitModule = async () => {
  try {
    const moduleData = {
      ...newModule.value,
      endings: newModule.value.endings.map(ending => ({
        ending_name: ending.ending_name,
        ending_description: ending.ending_description
      }))
    };

    const response = await api.post('/modules/', moduleData);
    const newModuleData: Module = {
      module_id: response.data.module_id,
      title: response.data.title,
      description: response.data.description,
      player_min: response.data.player_min,
      player_max: response.data.player_max,
      duration_hours: response.data.duration_hours,
      difficulty: response.data.difficulty,
      cover_image_url: response.data.cover_image_url,
      professions: response.data.professions || [],
      npcs: response.data.npcs || [],
      endings: response.data.endings || []
    };
    modules.value.push(newModuleData);
    closeDialog();
  } catch (err: any) {
    error.value = err.response?.data?.detail || '添加模组失败';
    console.error('Error adding module:', err);
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
  background-color: #000000;
  color: #e0e0e0;
}

h1 {
  text-align: center;
  color: #e0e0e0;
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
  border: 1px solid #2a2a2a;
  border-radius: 4px;
  font-size: 1em;
  background-color: #121212;
  color: #e0e0e0;
}

.search-input:focus {
  outline: none;
  border-color: #4CAF50;
}

.modules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}

.error-message {
  color: #ff6b6b;
  text-align: center;
  padding: 16px;
}

.loading {
  text-align: center;
  padding: 32px;
  color: #999;
}

/* 修改所有按钮为黑色主题 */
.add-button,
.dialog-buttons button[type="submit"],
.dialog-buttons button[type="button"],
.retry-button,
.add-btn,
.delete-button {
  background-color: #333;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.add-button:hover,
.dialog-buttons button[type="submit"]:hover,
.dialog-buttons button[type="button"]:hover,
.retry-button:hover,
.add-btn:hover {
  background-color: #444;
}

.delete-button {
  background-color: #333;
}

.delete-button:hover {
  background-color: #444;
}

/* 对话框样式 */
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.dialog {
  background-color: #121212;
  padding: 30px;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
  width: 90%;
  max-width: 600px;
  max-height: 80vh;
  overflow-y: auto;
  color: #e0e0e0;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #e0e0e0;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #2a2a2a;
  border-radius: 6px;
  font-size: 14px;
  background-color: #1a1a1a;
  color: #e0e0e0;
  transition: all 0.3s ease;
}

.dialog-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 30px;
}

/* 步骤指示器 */
.step-indicator {
  display: flex;
  justify-content: center;
  margin: 20px 0 30px;
}

.step {
  width: 35px;
  height: 35px;
  border-radius: 50%;
  background-color: #1a1a1a;
  color: #999;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 15px;
  font-weight: bold;
  position: relative;
}

.step::after {
  content: '';
  position: absolute;
  width: 30px;
  height: 2px;
  background-color: #2a2a2a;
  right: -30px;
  top: 50%;
}

.step:last-child::after {
  display: none;
}

/* 输入组样式 */
.input-group {
  margin-bottom: 15px;
}

.input-group:last-child {
  margin-bottom: 0;
}

/* 修改模组卡片容器样式 */
.module-wrapper {
  position: relative;
  background-color: #1a1a1a;
  border-radius: 8px;
  transition: transform 0.2s;
}

/* 修改删除按钮样式 */
.delete-button {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 6px 12px;
  background-color: #333;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s ease;
  z-index: 10;  /* 确保按钮在最上层 */
  opacity: 0.8;
}

.delete-button:hover {
  background-color: #444;
  opacity: 1;
}

/* 确保卡片容器不会遮挡删除按钮 */
.module-wrapper .module-card {
  position: relative;
  z-index: 1;
}

/* 文本框样式 */
textarea {
  min-height: 120px;
  resize: vertical;
  line-height: 1.5;
  font-family: inherit;
}

/* 数字输入框特殊样式 */
input[type="number"] {
  width: 120px;
  text-align: center;
}
</style> 