<template>
  <div class="module-card" @click="$emit('click')">
    <div class="module-cover">
      <img 
        :src="coverImage" 
        :alt="module.title"
        @error="handleImageError"
      >
    </div>
    <div class="module-info">
      <h3>{{ module.title }}</h3>
      <p>{{ module.description }}</p>
      <div class="module-meta">
        <span>{{ module.player_min }}-{{ module.player_max }}人</span>
        <span>{{ module.duration_hours }}小时</span>
        <span>{{ getDifficultyText(module.difficulty) }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import defaultCover from '../assets/1.png';

const props = defineProps<{
  module: {
    title: string;
    description: string;
    player_min: number;
    player_max: number;
    duration_hours: number;
    difficulty: string;
    cover_image_url?: string;
  }
}>();

const coverImage = ref(props.module.cover_image_url || defaultCover);

const handleImageError = () => {
  coverImage.value = defaultCover;
};

const getDifficultyText = (difficulty: string) => {
  const difficultyMap: Record<string, string> = {
    easy: '简单',
    medium: '中等',
    hard: '困难'
  };
  return difficultyMap[difficulty] || difficulty;
};
</script>

<style scoped>
.module-card {
  background-color: #1a1a1a;
  border-radius: 8px;
  overflow: hidden;
  transition: transform 0.2s;
  cursor: pointer;
}

.module-card:hover {
  transform: translateY(-4px);
}

.module-cover {
  width: 100%;
  height: 200px;
  overflow: hidden;
}

.module-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.module-info {
  padding: 16px;
}

.module-info h3 {
  margin: 0 0 8px 0;
  color: #e0e0e0;
}

.module-info p {
  margin: 0 0 16px 0;
  color: #999;
  font-size: 0.9em;
  line-height: 1.4;
}

.module-meta {
  display: flex;
  gap: 12px;
  font-size: 0.8em;
  color: #666;
}

.module-meta span {
  background-color: #222;
  padding: 4px 8px;
  border-radius: 4px;
}
</style> 