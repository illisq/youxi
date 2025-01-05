<template>
  <div class="module-detail" v-if="module">
    <div class="header">
      <button class="back-button" @click="router.back()">返回</button>
      <h1>{{ module.title }}</h1>
    </div>

    <div class="content">
      <div class="main-info">
        <img v-if="module.cover_image_url" :src="module.cover_image_url" :alt="module.title" class="cover-image">
        <div v-else class="placeholder-image">暂无图片</div>
        
        <div class="info-box">
          <p class="description">{{ module.description }}</p>
          <div class="meta">
            <span>玩家人数: {{ module.player_min }}-{{ module.player_max }}人</span>
            <span>时长: {{ module.duration_hours }}小时</span>
            <span class="difficulty" :class="module.difficulty">
              难度: {{ module.difficulty }}
            </span>
          </div>
          <button class="start-button" @click="showProfessionSelect = true" v-if="!showProfessionSelect">
            开始游戏
          </button>
        </div>
      </div>

      <div class="profession-select" v-if="showProfessionSelect">
        <h2>选择你的职业</h2>
        <div class="profession-grid">
          <div 
            v-for="profession in module.professions" 
            :key="profession.profession_id"
            class="profession-card"
            :class="{ selected: selectedProfession === profession.profession_id }"
            @click="selectedProfession = profession.profession_id"
          >
            <h3>{{ profession.name }}</h3>
            <p>{{ profession.description }}</p>
          </div>
        </div>
        <div class="action-buttons">
          <button class="cancel-button" @click="cancelSelection">取消</button>
          <button 
            class="confirm-button" 
            @click="createCharacter"
            :disabled="!selectedProfession"
          >
            确认选择
          </button>
        </div>
      </div>

      <div class="sections" v-if="!showProfessionSelect">
        <div class="section professions">
          <h2>可选职业</h2>
          <div class="profession-list">
            <div v-for="profession in module.professions" :key="profession.profession_id" class="profession-card">
              <h3>{{ profession.name }}</h3>
              <p>{{ profession.description }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div v-else class="loading">加载中...</div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '../services/api';

const route = useRoute();
const router = useRouter();
const module = ref<any>(null);
const showProfessionSelect = ref(false);
const selectedProfession = ref<number | null>(null);

const fetchModuleDetail = async () => {
  try {
    const response = await api.get(`/modules/${route.params.id}`);
    module.value = response.data;
  } catch (error) {
    console.error('Error fetching module details:', error);
  }
};

const createCharacter = async () => {
  if (!selectedProfession.value) return;
  
  try {
    const response = await api.post('/create-game-character/', {
      module_id: Number(route.params.id),
      profession_id: selectedProfession.value
    });
    
    console.log('Character created:', response.data);
    
    // 使用完整的路径进行跳转
    await router.push(`/game/${route.params.id}/${response.data.player_character_id}`);
    
    /* 或者使用对象方式：
    await router.push({
      path: `/game/${route.params.id}/${response.data.player_character_id}`
    });
    */
  } catch (error) {
    console.error('Error creating character:', error);
    const errorMessage = error.response?.data?.detail || '创建角色失败，请重试';
    alert(errorMessage);
  }
};

const cancelSelection = () => {
  showProfessionSelect.value = false;
  selectedProfession.value = null;
};

onMounted(() => {
  fetchModuleDetail();
});
</script>

<style scoped>
.module-detail {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
}

.header {
  display: flex;
  align-items: center;
  margin-bottom: 32px;
}

.back-button {
  padding: 8px 16px;
  background: var(--primary-color);
  border: none;
  border-radius: 4px;
  color: white;
  cursor: pointer;
  margin-right: 16px;
}

.content {
  background: white;
  border-radius: 8px;
  padding: 24px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.main-info {
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: 24px;
  margin-bottom: 32px;
}

.cover-image, .placeholder-image {
  width: 100%;
  height: 400px;
  object-fit: cover;
  border-radius: 8px;
  background: #f0f0f0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #999;
}

.info-box {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.description {
  font-size: 1.1em;
  line-height: 1.6;
  color: #666;
}

.meta {
  display: flex;
  gap: 16px;
  font-size: 0.9em;
}

.sections {
  display: grid;
  gap: 32px;
}

.section h2 {
  margin-bottom: 16px;
  color: #333;
}

.profession-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 16px;
}

.profession-card {
  background: #f8f8f8;
  border-radius: 8px;
  padding: 16px;
}

.difficulty {
  padding: 4px 8px;
  border-radius: 4px;
}

.difficulty.easy {
  background: #e6f4ea;
  color: #1e8e3e;
}

.difficulty.medium {
  background: #fef7e0;
  color: #b06000;
}

.difficulty.hard {
  background: #fce8e6;
  color: #c5221f;
}

.loading {
  text-align: center;
  padding: 48px;
  color: #666;
  font-size: 1.2em;
}

@media (max-width: 768px) {
  .main-info {
    grid-template-columns: 1fr;
  }
  
  .cover-image, .placeholder-image {
    height: 200px;
  }
}

.start-button {
  margin-top: 20px;
  padding: 12px 24px;
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1.1em;
  cursor: pointer;
  transition: background-color 0.3s;
}

.start-button:hover {
  background-color: var(--primary-color-dark);
}

.profession-select {
  background: white;
  padding: 24px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  margin-top: 24px;
}

.profession-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 16px;
  margin: 20px 0;
}

.profession-card {
  border: 2px solid #eee;
  border-radius: 8px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.3s;
}

.profession-card:hover {
  border-color: var(--primary-color);
}

.profession-card.selected {
  border-color: var(--primary-color);
  background-color: var(--primary-color-light);
}

.action-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 20px;
}

.cancel-button, .confirm-button {
  padding: 8px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1em;
}

.cancel-button {
  background-color: #f5f5f5;
  border: 1px solid #ddd;
  color: #666;
}

.confirm-button {
  background-color: var(--primary-color);
  border: none;
  color: white;
}

.confirm-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}
</style> 