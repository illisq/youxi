import { createRouter, createWebHistory } from 'vue-router'
import ModuleList from '../views/ModuleList.vue'
import ModuleDetail from '../views/ModuleDetail.vue'
import GameRoom from '../views/GameRoom.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: ModuleList
    },
    {
      path: '/modules/:id',
      name: 'module-detail',
      component: ModuleDetail
    },
    {
      path: '/game/:moduleId/:characterId',
      name: 'game-room',
      component: GameRoom
    }
  ]
})

export default router 