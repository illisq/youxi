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
              <input v-model="profession.name" placeholder="职业名称">
              <textarea v-model="profession.description" placeholder="职业描述"></textarea>
              <button @click="removeProfession(index)" class="remove-btn">删除</button>
            </div>
            <button @click="addProfession" class="add-btn">添加职业</button>
          </div>
        </div>

        <!-- 步骤 3: NPC信息 -->
        <div v-if="currentStep === 3">
          <div class="npcs-list">
            <div v-for="(npc, index) in newModule.npcs" :key="index" class="npc-item">
              <input v-model="npc.name" placeholder="NPC名称" required>
              <input v-model="npc.position" placeholder="职位">
              <input v-model="npc.faction" placeholder="阵营">
              <textarea v-model="npc.background" placeholder="背景故事"></textarea>
              <textarea v-model="npc.personality" placeholder="性格特征"></textarea>
              <input 
                type="number" 
                v-model="npc.initial_attitude" 
                placeholder="初始态度值"
                min="-100"
                max="100"
              >
              <input 
                type="number" 
                v-model="npc.secret_level" 
                placeholder="秘密等级"
                min="0"
                max="10"
              >
              <textarea v-model="npc.chat_prompt" placeholder="对话提示"></textarea>
              <button @click="removeNPC(index)" class="remove-btn">删除</button>
            </div>
            <button @click="addNPC" class="add-btn">添加NPC</button>
          </div>
        </div>

        <!-- 步骤 4: 结局 -->
        <div v-if="currentStep === 4">
          <div class="endings-list">
            <div v-for="(ending, index) in newModule.endings" :key="index" class="ending-item">
              <input 
                v-model="ending.ending_name" 
                placeholder="结局名称"
                required
              >
              <textarea 
                v-model="ending.ending_description" 
                placeholder="结局描述"
                required
              ></textarea>
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

.step-indicator {
  display: flex;
  justify-content: center;
  margin-bottom: 20px;
}

.step {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background-color: #ddd;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 10px;
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
  border: 1px solid #ddd;
  padding: 10px;
  margin-bottom: 10px;
  border-radius: 4px;
}

.remove-btn {
  background-color: #f44336;
  color: white;
  border: none;
  padding: 5px 10px;
  border-radius: 4px;
  cursor: pointer;
  margin-top: 5px;
}

.add-btn {
  background-color: #4CAF50;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  margin-top: 10px;
}

.dialog {
  max-height: 80vh;
  overflow-y: auto;
}
</style> 