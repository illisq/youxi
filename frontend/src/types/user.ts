export interface UserCreate {
  username: string
  email: string
  password: string
}

export interface User {
  id: number
  username: string
  email: string
  created_at: string
  updated_at: string | null
} 