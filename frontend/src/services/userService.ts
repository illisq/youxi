import api from './api'
import type { User, UserCreate } from '@/types/user'

export const userService = {
  async createUser(userData: UserCreate) {
    const response = await api.post<User>('/users/', userData)
    return response.data
  },

  async getUsers() {
    const response = await api.get<User[]>('/users/')
    return response.data
  },

  async getUser(id: number) {
    const response = await api.get<User>(`/users/${id}`)
    return response.data
  }
} 