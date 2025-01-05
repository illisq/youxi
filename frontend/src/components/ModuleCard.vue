<template>
  <div class="module-card">
    <img v-if="module.cover_image_url" :src="module.cover_image_url" :alt="module.title" class="cover-image">
    <div v-else class="placeholder-image">暂无图片</div>
    <div class="content">
      <h3>{{ module.title }}</h3>
      <p class="description">{{ module.description }}</p>
      <div class="meta">
        <span>{{ module.player_min }}-{{ module.player_max }} 玩家</span>
        <span>{{ module.duration_hours }}小时</span>
        <span class="difficulty" :class="module.difficulty">
          {{ getDifficultyText(module.difficulty) }}
        </span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  module: {
    module_id: number;
    title: string;
    description: string;
    cover_image_url?: string;
    player_min: number;
    player_max: number;
    duration_hours: number;
    difficulty: string;
  }
}>();

const getDifficultyText = (difficulty: string) => {
  const difficultyMap: Record<string, string> = {
    'easy': '简单',
    'medium': '中等',
    'hard': '困难'
  };
  return difficultyMap[difficulty] || difficulty;
};
</script>

<style scoped>
.module-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  transition: transform 0.3s ease;
  cursor: pointer;
}

.module-card:hover {
  transform: translateY(-4px);
}

.cover-image, .placeholder-image {
  width: 100%;
  height: 200px;
  object-fit: cover;
  background: #f0f0f0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #999;
}

.content {
  padding: 16px;
}

h3 {
  margin: 0 0 8px 0;
  font-size: 1.2em;
  color: #333;
}

.description {
  color: #666;
  font-size: 0.9em;
  margin-bottom: 12px;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.meta {
  display: flex;
  gap: 12px;
  font-size: 0.8em;
  color: #888;
}

.difficulty {
  padding: 2px 8px;
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
</style> 