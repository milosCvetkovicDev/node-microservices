import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface User {
  id: string;
  keycloakId: string;
  email: string;
  username: string;
  firstName: string;
  lastName: string;
  roles?: string[];
  createdAt: Date;
  updatedAt: Date;
}

interface CreateUserDto {
  keycloakId: string;
  email: string;
  username: string;
  firstName: string;
  lastName: string;
}

@Injectable()
export class UsersService {
  // In-memory storage for development. In production, use a database
  private users: Map<string, User> = new Map();
  private usersByKeycloakId: Map<string, User> = new Map();

  constructor(private configService: ConfigService) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const user: User = {
      id: this.generateId(),
      ...createUserDto,
      roles: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    this.users.set(user.id, user);
    this.usersByKeycloakId.set(user.keycloakId, user);

    return user;
  }

  async findById(id: string): Promise<User | null> {
    return this.users.get(id) || null;
  }

  async findByKeycloakId(keycloakId: string): Promise<User | null> {
    return this.usersByKeycloakId.get(keycloakId) || null;
  }

  async findByEmail(email: string): Promise<User | null> {
    for (const user of this.users.values()) {
      if (user.email === email) {
        return user;
      }
    }
    return null;
  }

  async findByUsername(username: string): Promise<User | null> {
    for (const user of this.users.values()) {
      if (user.username === username) {
        return user;
      }
    }
    return null;
  }

  async update(id: string, updateData: Partial<User>): Promise<User | null> {
    const user = this.users.get(id);
    if (!user) {
      return null;
    }

    const updatedUser = {
      ...user,
      ...updateData,
      id: user.id, // Ensure ID cannot be changed
      updatedAt: new Date(),
    };

    this.users.set(id, updatedUser);
    if (user.keycloakId !== updatedUser.keycloakId) {
      this.usersByKeycloakId.delete(user.keycloakId);
      this.usersByKeycloakId.set(updatedUser.keycloakId, updatedUser);
    }

    return updatedUser;
  }

  async delete(id: string): Promise<boolean> {
    const user = this.users.get(id);
    if (!user) {
      return false;
    }

    this.users.delete(id);
    this.usersByKeycloakId.delete(user.keycloakId);
    return true;
  }

  private generateId(): string {
    // Simple ID generation for development
    return `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
} 