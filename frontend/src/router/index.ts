import { createRouter, createWebHistory } from 'vue-router'
import ModuleList from '../views/ModuleList.vue'

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
      component: () => import('../views/ModuleDetail.vue')
    }
  ]
})

export default router 