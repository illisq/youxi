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
    await api.delete(`/modules/${moduleId}`);
    modules.value = modules.value.filter(m => m.module_id !== moduleId);
  } catch (err) {
    error.value = '删除模组失败';
    console.error('Error deleting module:', err);
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
  padding: 30px;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  width: 90%;
  max-width: 600px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #333;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.3s;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  border-color: #4CAF50;
  outline: none;
  box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.2);
}

.dialog-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 30px;
}

.dialog-buttons button {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: background-color 0.3s;
}

.dialog-buttons button[type="submit"] {
  background-color: #4CAF50;
  color: white;
}

.dialog-buttons button[type="submit"]:hover {
  background-color: #45a049;
}

.dialog-buttons button[type="button"] {
  background-color: #6c757d;
  color: white;
}

.dialog-buttons button[type="button"]:hover {
  background-color: #5a6268;
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

.step-indicator {
  display: flex;
  justify-content: center;
  margin: 20px 0 30px;
}

.step {
  width: 35px;
  height: 35px;
  border-radius: 50%;
  background-color: #e0e0e0;
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
  background-color: #e0e0e0;
  right: -30px;
  top: 50%;
}

.step:last-child::after {
  display: none;
}

.step.active {
  background-color: #4CAF50;
  color: white;
}

.step.completed {
  background-color: #45a049;
  color: white;
}

.profession-item,
.npc-item,
.ending-item {
  background-color: white;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 25px;
  margin-bottom: 20px;
  position: relative;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  transition: transform 0.2s, box-shadow 0.2s;
}

.profession-item:hover,
.npc-item:hover,
.ending-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.add-btn {
  background-color: #4CAF50;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
  width: 100%;
  margin-top: 15px;
  font-size: 14px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.add-btn:hover {
  background-color: #45a049;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(76, 175, 80, 0.2);
}

.remove-btn {
  position: absolute;
  top: 15px;
  right: 15px;
  background-color: #dc3545;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s ease;
  opacity: 0.8;
}

.remove-btn:hover {
  background-color: #c82333;
  opacity: 1;
}

.npc-item input,
.npc-item textarea {
  margin-bottom: 10px;
}

.ending-item input,
.ending-item textarea {
  margin-bottom: 10px;
}

textarea {
  min-height: 120px;
  resize: vertical;
  line-height: 1.5;
  font-family: inherit;
}

.dialog {
  max-height: 80vh;
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: #888 #f1f1f1;
}

.dialog::-webkit-scrollbar {
  width: 8px;
}

.dialog::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

.dialog::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 4px;
}

.dialog::-webkit-scrollbar-thumb:hover {
  background: #555;
}

/* 通用输入框样式 */
.profession-item input,
.profession-item textarea,
.npc-item input,
.npc-item textarea,
.ending-item input,
.ending-item textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  font-size: 14px;
  margin-bottom: 12px;
  transition: all 0.3s ease;
  background-color: white;
}

/* 输入框焦点样式 */
.profession-item input:focus,
.profession-item textarea:focus,
.npc-item input:focus,
.npc-item textarea:focus,
.ending-item input:focus,
.ending-item textarea:focus {
  border-color: #4CAF50;
  outline: none;
  box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.1);
}

/* 输入框标签样式 */
.input-label {
  display: block;
  font-size: 13px;
  color: #666;
  margin-bottom: 4px;
  font-weight: 500;
}

/* 项目卡片样式优化 */
.profession-item,
.npc-item,
.ending-item {
  background-color: white;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 25px;
  margin-bottom: 20px;
  position: relative;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  transition: transform 0.2s, box-shadow 0.2s;
}

.profession-item:hover,
.npc-item:hover,
.ending-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
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

/* 删除按钮位置调整 */
.remove-btn {
  position: absolute;
  top: 15px;
  right: 15px;
  background-color: #dc3545;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s ease;
  opacity: 0.8;
}

.remove-btn:hover {
  background-color: #c82333;
  opacity: 1;
}

/* 添加按钮样式优化 */
.add-btn {
  background-color: #4CAF50;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
  width: 100%;
  margin-top: 15px;
  font-size: 14px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.add-btn:hover {
  background-color: #45a049;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(76, 175, 80, 0.2);
}

/* 输入组样式 */
.input-group {
  margin-bottom: 15px;
}

.input-group:last-child {
  margin-bottom: 0;
}

/* 添加分隔线 */
.profession-item + .profession-item,
.npc-item + .npc-item,
.ending-item + .ending-item {
  border-top: 1px solid #f0f0f0;
}
</style> 