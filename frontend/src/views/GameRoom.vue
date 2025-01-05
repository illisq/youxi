<template>
  <div class="game-room">
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
          <img :src="npc.avatar_url || '/default-avatar.png'" :alt="npc.name" class="npc-avatar">
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
import { ref, onMounted, watch, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '../services/api';

const route = useRoute();
const router = useRouter();
const npcs = ref([]);
const selectedNpc = ref(null);
const messages = ref([]);
const newMessage = ref('');
const messagesContainer = ref(null);

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

const selectNpc = (npc) => {
  selectedNpc.value = npc;
  messages.value = []; // 清空当前对话
  // 可以在这里加载与该NPC的历史对话
};

const sendMessage = async () => {
  if (!newMessage.value.trim() || !selectedNpc.value) return;

  const message = {
    content: newMessage.value,
    type: 'player',
    time: new Date().toLocaleTimeString()
  };

  messages.value.push(message);
  newMessage.value = '';

  // 滚动到最新消息
  await scrollToBottom();

  // 模拟NPC回复
  setTimeout(async () => {
    try {
      // TODO: 这里应该调用后端API获取NPC回复
      const response = {
        content: `[${selectedNpc.value.name}] 这是一个模拟的回复消息。`,
        type: 'npc',
        time: new Date().toLocaleTimeString()
      };
      messages.value.push(response);
      await scrollToBottom();
    } catch (error) {
      console.error('Error getting NPC response:', error);
    }
  }, 1000);
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

// 组件挂载时获取NPC列表
onMounted(() => {
  console.log('GameRoom mounted'); // 调试日志
  fetchNpcs();
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
  width: 48px;
  height: 48px;
  border-radius: 24px;
  margin-right: 12px;
  object-fit: cover;
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
</style> 