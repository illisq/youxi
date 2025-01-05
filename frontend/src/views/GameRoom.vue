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
        <div class="day-counter">
          第 {{ playerCharacter?.day || 1 }} 天
        </div>
        <div class="stat">
          <span class="stat-label">理智值:</span>
          <div class="stat-bar">
            <div 
              class="stat-fill" 
              :style="{ width: `${playerCharacter?.current_sanity || 0}%` }"
            ></div>
            <div class="stat-value">
              {{ Math.round(playerCharacter?.current_sanity || 0) }}/100
            </div>
          </div>
        </div>
        <div class="stat">
          <span class="stat-label">异化值:</span>
          <div class="stat-bar">
            <div 
              class="stat-fill red" 
              :style="{ width: `${playerCharacter?.current_alienation || 0}%` }"
            ></div>
            <div class="stat-value">
              {{ Math.round(playerCharacter?.current_alienation || 0) }}/100
            </div>
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

    <!-- 添加状态变化提示框 -->
    <div v-if="showStatusChange" class="status-change-popup">
      <div class="status-change-content">
        <h3>状态变化</h3>
        <div v-if="statusChanges.sanity !== undefined" 
             :class="{'status-decrease': statusChanges.sanity < 0, 'status-increase': statusChanges.sanity > 0}">
          理智值: {{ statusChanges.sanity > 0 ? '+' : ''}}{{ statusChanges.sanity }}
          <span class="status-change-detail">
            ({{ statusChanges.oldValues?.sanity }} → {{ statusChanges.newValues?.sanity }})
          </span>
        </div>
        <div v-if="statusChanges.alienation !== undefined" 
             :class="{'status-decrease': statusChanges.alienation > 0, 'status-increase': statusChanges.alienation < 0}">
          异化值: {{ statusChanges.alienation > 0 ? '+' : ''}}{{ statusChanges.alienation }}
          <span class="status-change-detail">
            ({{ statusChanges.oldValues?.alienation }} → {{ statusChanges.newValues?.alienation }})
          </span>
        </div>
        <div v-if="statusChanges.chen_influence !== undefined" 
             :class="{'status-decrease': statusChanges.chen_influence < 0, 'status-increase': statusChanges.chen_influence > 0}">
          陈总影响: {{ statusChanges.chen_influence > 0 ? '+' : ''}}{{ statusChanges.chen_influence }}
          <span class="status-change-detail">
            ({{ statusChanges.oldValues?.chen_influence }} → {{ statusChanges.newValues?.chen_influence }})
          </span>
        </div>
        <div v-if="statusChanges.liu_influence !== undefined" 
             :class="{'status-decrease': statusChanges.liu_influence < 0, 'status-increase': statusChanges.liu_influence > 0}">
          刘总监影响: {{ statusChanges.liu_influence > 0 ? '+' : ''}}{{ statusChanges.liu_influence }}
          <span class="status-change-detail">
            ({{ statusChanges.oldValues?.liu_influence }} → {{ statusChanges.newValues?.liu_influence }})
          </span>
        </div>
        <div v-if="statusChanges.discovered_secrets && statusChanges.discovered_secrets.length > 0">
          <div class="discovered-secrets">
            发现的秘密:
            <div v-for="secret in statusChanges.discovered_secrets" :key="secret">
              {{ getSecretName(secret) }}
            </div>
          </div>
        </div>
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
  day: number;
}

interface StatusChanges {
  sanity?: number;
  alienation?: number;
  chen_influence?: number;
  liu_influence?: number;
  oldValues?: {
    sanity: number;
    alienation: number;
    chen_influence: number;
    liu_influence: number;
  };
  newValues?: {
    sanity: number;
    alienation: number;
    chen_influence: number;
    liu_influence: number;
  };
  discovered_secrets?: string[];
}

const npcs = ref<NPC[]>([]);
const selectedNpc = ref<NPC | null>(null);
const messages = ref<Message[]>([]);
const newMessage = ref('');
const messagesContainer = ref<HTMLElement | null>(null);
const playerCharacter = ref<PlayerCharacter | null>(null);
const allNpcsInteractedToday = ref<Set<number>>(new Set());
const showStatusChange = ref(false);
const statusChanges = ref<StatusChanges>({});
const playerStatus = ref({
  sanity: 100,
  alienation: 0,
  chen_influence: 0,
  liu_influence: 0,
  discovered_secrets: []
});

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
      messages.value = response.data.map((msg: any) => ({
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
    const characterId = route.params.characterId;
    const response = await api.post(
      `/chat/${characterId}/${encodeURIComponent(selectedNpc.value.name)}`,
      { message: messageToSend }
    );

    if (response.data) {
      const npcResponse = {
        content: response.data.content,
        type: 'npc',
        time: new Date().toLocaleTimeString(),
        sender: selectedNpc.value.name
      };
      messages.value.push(npcResponse);
      
      // 处理状态变化效果
      if (response.data.effects) {
        showStatusChanges(response.data.effects);
        updatePlayerStatus(response.data.effects);
        await updatePlayerCharacterStatus();
      }
      
      allNpcsInteractedToday.value.add(selectedNpc.value.character_id);
      await checkDayCompletion();
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
    
    // 同步获取最新的玩家状态
    const statusResponse = await api.get(`/player-status/${characterId}`);
    if (statusResponse.data) {
      playerStatus.value = statusResponse.data;
      // 更新 playerCharacter 的状态值
      if (playerCharacter.value) {
        playerCharacter.value.current_sanity = statusResponse.data.sanity;
        playerCharacter.value.current_alienation = statusResponse.data.alienation;
      }
    }
  } catch (error) {
    console.error('Error fetching player character:', error);
  }
};

// 生成头像URL的计算属性
const getAvatarUrl = (name: string): string => {
  return generateTextAvatar(name);
};

// 组件挂载时获取NPC列表
onMounted(async () => {
  console.log('GameRoom mounted');
  await fetchNpcs();
  await fetchPlayerCharacter();
  
  // 获取初始玩家状态
  try {
    const characterId = route.params.characterId;
    const response = await api.get(`/player-status/${characterId}`);
    playerStatus.value = response.data;
    
    // 同步初始状态到 playerCharacter
    if (playerCharacter.value) {
      playerCharacter.value.current_sanity = playerStatus.value.sanity;
      playerCharacter.value.current_alienation = playerStatus.value.alienation;
    }
  } catch (error) {
    console.error('Error fetching initial player status:', error);
  }
});

const checkDayCompletion = async () => {
  if (allNpcsInteractedToday.value.size === npcs.value.length) {
    try {
      const response = await api.post(`/advance_day/${getSessionId.value}`);
      if (response.data) {
        playerCharacter.value = {
          ...playerCharacter.value!,
          day: response.data.day
        };
        allNpcsInteractedToday.value.clear();
      }
    } catch (error) {
      console.error('Error advancing day:', error);
    }
  }
};

async function checkEnding() {
  try {
    const response = await api.get(`/api/game/check-ending/${getSessionId.value}`);
    const endings = response.data.endings;
    
    if (endings.length > 0) {
      // 显示结局对话框
      showEndingDialog(endings[0]);
    }
  } catch (error) {
    console.error('检查结局失败:', error);
  }
}

function showEndingDialog(ending) {
  api.post(`/api/game/end-session/${getSessionId.value}`, {
    ending_id: ending.ending_id
  }).then(() => {
    // 跳转到结算页面
    router.push(`/game/ending/${getSessionId.value}`);
  }).catch((error) => {
    console.error('接受结局失败:', error);
  });
}

// 监听对话或行动后的状态变化
watch(() => playerCharacter.value, {
  deep: true,
  handler() {
    checkEnding();
  }
});

const showStatusChanges = (changes) => {
  statusChanges.value = changes;
  showStatusChange.value = true;
  setTimeout(async () => {
    showStatusChange.value = false;
    // 弹窗消失后再次确保状态同步
    const characterId = route.params.characterId;
    try {
      const response = await api.get(`/player-status/${characterId}`);
      if (response.data) {
        playerStatus.value = response.data;
        if (playerCharacter.value) {
          playerCharacter.value = {
            ...playerCharacter.value,
            current_sanity: response.data.sanity,
            current_alienation: response.data.alienation
          };
        }
      }
    } catch (error) {
      console.error('Error refreshing player status:', error);
    }
  }, 3000);
};

const updatePlayerStatus = async (effects) => {
  try {
    // 直接从 player_status 表获取最新状态
    const characterId = route.params.characterId;
    const response = await api.get(`/player-status/${characterId}`);
    
    if (response.data) {
      // 更新 playerStatus
      playerStatus.value = response.data;
      
      // 同步更新 playerCharacter
      if (playerCharacter.value) {
        playerCharacter.value = {
          ...playerCharacter.value,
          current_sanity: response.data.sanity,
          current_alienation: response.data.alienation
        };
      }
    }

    // 显示状态变化
    showStatusChanges(effects);
  } catch (error) {
    console.error('Error updating player status:', error);
  }
};

const getSecretName = (secretKey) => {
  const secretNames = {
    'chen_fraud': '陈总诈骗',
    'liu_cult': '刘总监邪教',
    'layoff_list': '裁员名单'
  };
  return secretNames[secretKey] || secretKey;
};

const updatePlayerCharacterStatus = async () => {
  try {
    const characterId = route.params.characterId;
    const response = await api.get(`/player-characters/${characterId}`);
    if (response.data) {
      playerCharacter.value = response.data;
    }
  } catch (error) {
    console.error('更新玩家状态失败:', error);
  }
};

const handleDialogClose = async () => {
  showDialog.value = false;
  await updatePlayerCharacterStatus();
};

const handleOptionSelect = async (option: any) => {
  // 原有的选项处理逻辑
  // ...
  
  // 在处理完选项后更新状态
  await updatePlayerCharacterStatus();
};
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
  min-width: 300px;
}

.player-avatar img {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  object-fit: cover;
  background-color: #f0f0f0;
}

.player-stats {
  min-width: 200px;
  flex: 1;
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
  width: 180px;
  height: 8px;
  background: #eee;
  border-radius: 4px;
  overflow: visible;
  position: relative;
  margin-right: 45px;
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
  right: -45px;
  top: -4px;
  font-size: 0.8em;
  color: #666;
  white-space: nowrap;
  width: 40px;
  text-align: left;
}

.player-name {
  font-weight: bold;
  color: #333;
  margin-top: 8px;
  text-align: center;
}

.day-counter {
  background-color: #2196F3;
  color: white;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.9em;
  margin-bottom: 8px;
  text-align: center;
}

.status-change-popup {
  position: fixed;
  top: 20px;
  right: 20px;
  transform: none;
  background: rgba(0, 0, 0, 0.9);
  color: white;
  padding: 15px;
  border-radius: 8px;
  z-index: 1001;
  animation: fadeInRight 0.3s ease-in-out;
  min-width: 300px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.status-change-content {
  min-width: 200px;
}

.status-change-content h3 {
  margin: 0 0 10px 0;
  font-size: 14px;
  color: #fff;
  text-align: left;
}

.status-change-content > div {
  margin: 8px 0;
  font-size: 13px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.status-decrease {
  color: #ff6b6b;
}

.status-increase {
  color: #69db7c;
}

.status-change-content > div::after {
  content: attr(data-change);
  margin-left: 8px;
  font-size: 0.9em;
  opacity: 0.8;
}

.discovered-secrets {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
}

@keyframes fadeInRight {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.player-status {
  position: fixed;
  top: 20px;
  right: 20px;
  background: rgba(0, 0, 0, 0.8);
  color: white;
  padding: 15px;
  border-radius: 8px;
  z-index: 999;
}

.status-bar {
  width: 100%;
  height: 10px;
  background: #333;
  border-radius: 5px;
  margin: 5px 0;
}

.status-bar-fill {
  height: 100%;
  border-radius: 5px;
  transition: width 0.3s ease;
}

.sanity-bar { background: #44ff44; }
.alienation-bar { background: #ff4444; }
.chen-bar { background: #4444ff; }
.liu-bar { background: #ff44ff; }

.status-change-detail {
  color: #aaa;
  margin-left: 8px;
  font-size: 0.9em;
}
</style> 