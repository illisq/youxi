<template>
  <div class="game-room">
    <!-- 玩家信息区域 -->
    <div class="player-info">
      <div class="player-avatar">
        <img 
          :src="playerCharacter ? getAvatarUrl(playerCharacter.name) : getAvatarUrl('?')" 
          alt="Player Avatar"
        >
      </div>
      <div class="player-stats">
        <div class="stat">
          <span class="stat-label">理智值:</span>
          <div class="stat-bar">
            <div 
              class="stat-fill" 
              :style="{ width: `${playerCharacter?.current_sanity || 0}%` }"
            ></div>
            <span class="stat-value">{{ playerCharacter?.current_sanity || 0 }}</span>
          </div>
        </div>
        <div class="stat">
          <span class="stat-label">异化值:</span>
          <div class="stat-bar">
            <div 
              class="stat-fill red" 
              :style="{ width: `${playerCharacter?.current_alienation || 0}%` }"
            ></div>
            <span class="stat-value">{{ playerCharacter?.current_alienation || 0 }}</span>
          </div>
        </div>
        <div class="player-name">{{ playerCharacter?.name || '未知职业' }}</div>
      </div>
    </div>

    <!-- 左侧NPC列表 -->
    <div class="npc-list">
      <h2>NPC列表</h2>
      <div class="npc-items">
        <div
          v-for="npc in npcs"
          :key="npc.character_id"
          class="npc-item"
          :class="{ active: selectedNpc?.character_id === npc.character_id }"
          @click="selectNpc(npc)"
        >
          <img 
            :src="getAvatarUrl(npc.name)" 
            :alt="npc.name" 
            class="npc-avatar"
          >
          <div class="npc-info">
            <h3>{{ npc.name }}</h3>
            <p>{{ npc.position }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- 右侧聊天区域 -->
    <div class="chat-area">
      <div class="chat-header" v-if="selectedNpc">
        <h2>与 {{ selectedNpc.name }} 对话中</h2>
      </div>
      <div class="chat-messages" ref="messagesContainer">
        <div
          v-for="(message, index) in messages"
          :key="index"
          class="message"
          :class="message.type"
        >
          <div class="message-content">
            {{ message.content }}
          </div>
          <div class="message-time">{{ message.time }}</div>
        </div>
      </div>
      <div class="chat-input">
        <textarea
          v-model="newMessage"
          @keyup.enter.prevent="sendMessage"
          placeholder="输入消息..."
          :disabled="!selectedNpc"
        ></textarea>
        <button @click="sendMessage" :disabled="!selectedNpc || !newMessage.trim()">
          发送
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, nextTick, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '../services/api';
import { generateTextAvatar } from '../utils/avatar';

const route = useRoute();
const router = useRouter();

interface NPC {
  character_id: number;
  name: string;
  position: string;
}

interface Message {
  content: string;
  type: string;
  time: string;
  sender?: string;
}

interface PlayerCharacter {
  name: string;
  current_sanity: number;
  current_alienation: number;
}

const npcs = ref<NPC[]>([]);
const selectedNpc = ref<NPC | null>(null);
const messages = ref<Message[]>([]);
const newMessage = ref('');
const messagesContainer = ref<HTMLElement | null>(null);
const playerCharacter = ref<PlayerCharacter | null>(null);

const getSessionId = computed(() => {
  // 临时使用 moduleId 作为 sessionId，实际项目中应该从后端获取真实的 sessionId
  return route.params.moduleId;
});

// 获取模组NPC列表
const fetchNpcs = async () => {
  try {
    const moduleId = route.params.moduleId;
    console.log('Fetching NPCs for module:', moduleId); // 调试日志
    const response = await api.get(`/modules/${moduleId}`);
    console.log('Module data:', response.data); // 调试日志
    npcs.value = response.data.characters || [];
  } catch (error) {
    console.error('Error fetching NPCs:', error);
  }
};

const selectNpc = async (npc: NPC) => {
  selectedNpc.value = npc;
  messages.value = []; // 清空当前对话
  
  try {
    const response = await api.get(`/chat_history/${getSessionId.value}/${encodeURIComponent(npc.name)}`);
    if (response.data) {
      messages.value = response.data.map(msg => ({
        content: msg.content,
        type: msg.is_npc ? 'npc' : 'player',
        time: new Date(msg.timestamp).toLocaleTimeString(),
        sender: msg.sender
      }));
      await scrollToBottom();
    }
  } catch (error) {
    console.error('Error loading chat history:', error);
  }
};

const sendMessage = async () => {
  if (!newMessage.value.trim() || !selectedNpc.value) return;

  const message = {
    content: newMessage.value,
    type: 'player',
    time: new Date().toLocaleTimeString()
  };

  messages.value.push(message);
  const messageToSend = newMessage.value;
  newMessage.value = '';

  await scrollToBottom();

  try {
    const response = await api.post(`/chat/${getSessionId.value}/${encodeURIComponent(selectedNpc.value.name)}`, {
      message: messageToSend
    });

    if (response.data) {
      const npcResponse = {
        content: response.data.content,
        type: 'npc',
        time: new Date().toLocaleTimeString(),
        sender: selectedNpc.value.name
      };
      messages.value.push(npcResponse);
      await scrollToBottom();
    }
  } catch (error) {
    console.error('Error getting NPC response:', error);
    messages.value.push({
      content: '抱歉，暂时无法获取回复，请稍后再试。',
      type: 'system',
      time: new Date().toLocaleTimeString()
    });
  }
};

const scrollToBottom = async () => {
  await nextTick();
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
  }
};

// 监听消息变化，自动滚动到底部
watch(messages, () => {
  scrollToBottom();
}, { deep: true });

// 获取玩家角色信息
const fetchPlayerCharacter = async () => {
  try {
    const characterId = route.params.characterId;
    const response = await api.get(`/player-characters/${characterId}`);
    playerCharacter.value = response.data;
  } catch (error) {
    console.error('Error fetching player character:', error);
  }
};

// 生成头像URL的计算属性
const getAvatarUrl = (name: string): string => {
  return generateTextAvatar(name);
};

// 组件挂载时获取NPC列表
onMounted(() => {
  console.log('GameRoom mounted'); // 调试日志
  fetchNpcs();
  fetchPlayerCharacter();
});
</script>

<style>
:root {
  --primary-color: #4CAF50;
  --primary-color-dark: #388E3C;
  --primary-color-light: #C8E6C9;
}
</style>

<style scoped>
.game-room {
  display: grid;
  grid-template-columns: 300px 1fr;
  height: 100vh;
  background-color: #f5f5f5;
}

.npc-list {
  background: white;
  border-right: 1px solid #eee;
  padding: 20px;
  overflow-y: auto;
}

.npc-items {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.npc-item {
  display: flex;
  align-items: center;
  padding: 12px;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.npc-item:hover {
  background-color: #f5f5f5;
}

.npc-item.active {
  background-color: var(--primary-color-light);
}

.npc-avatar {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  margin-right: 12px;
  object-fit: cover;
  background-color: #f0f0f0;
}

.npc-info h3 {
  margin: 0;
  font-size: 1em;
}

.npc-info p {
  margin: 4px 0 0;
  font-size: 0.9em;
  color: #666;
}

.chat-area {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.chat-header {
  padding: 20px;
  background: white;
  border-bottom: 1px solid #eee;
}

.chat-messages {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.message {
  max-width: 70%;
  padding: 12px;
  border-radius: 8px;
  position: relative;
}

.message.player {
  align-self: flex-end;
  background-color: var(--primary-color);
  color: white;
}

.message.npc {
  align-self: flex-start;
  background-color: white;
  border: 1px solid #eee;
}

.message-time {
  font-size: 0.8em;
  color: #999;
  margin-top: 4px;
}

.chat-input {
  padding: 20px;
  background: white;
  border-top: 1px solid #eee;
  display: flex;
  gap: 12px;
}

.chat-input textarea {
  flex: 1;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  resize: none;
  height: 60px;
}

.chat-input button {
  padding: 0 24px;
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.chat-input button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.player-info {
  position: fixed;
  top: 20px;
  right: 20px;
  background: white;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  gap: 15px;
  z-index: 1000;
}

.player-avatar img {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  object-fit: cover;
  background-color: #f0f0f0;
}

.player-stats {
  min-width: 150px;
}

.stat {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 0.9em;
  color: #666;
}

.stat-bar {
  width: 100%;
  height: 8px;
  background: #eee;
  border-radius: 4px;
  overflow: hidden;
  position: relative;
}

.stat-fill {
  height: 100%;
  background: var(--primary-color);
  transition: width 0.3s ease;
}

.stat-fill.red {
  background: #ff4444;
}

.stat-value {
  position: absolute;
  right: -25px;
  top: -4px;
  font-size: 0.8em;
  color: #666;
}

.player-name {
  font-weight: bold;
  color: #333;
  margin-top: 8px;
  text-align: center;
}
</style> 