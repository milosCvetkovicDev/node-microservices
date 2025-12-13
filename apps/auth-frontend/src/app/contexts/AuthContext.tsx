import React, { createContext, useState, useContext, useEffect, useCallback, ReactNode } from 'react';
import keycloak from '../../keycloak';
import axios from 'axios';

interface User {
  id: string;
  email: string;
  username: string;
  roles: string[];
}

interface AuthContextType {
  isAuthenticated: boolean;
  user: User | null;
  loading: boolean;
  login: (username: string, password: string) => Promise<void>;
  loginWithKeycloak: () => void;
  register: (data: RegisterData) => Promise<void>;
  logout: () => Promise<void>;
  refreshToken: () => Promise<void>;
}

interface RegisterData {
  username: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const API_URL = import.meta.env.VITE_AUTH_SERVICE_URL || 'http://localhost:3334';

// Configure axios defaults
axios.defaults.baseURL = API_URL;
axios.defaults.withCredentials = true;

// Auth endpoints that should not trigger token refresh
const AUTH_ENDPOINTS = ['/api/auth/me', '/api/auth/login', '/api/auth/register', '/api/auth/refresh'];

// Public pages that should not redirect to login on 401
const PUBLIC_PATHS = ['/login', '/register', '/'];

// Add response interceptor to handle token refresh
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    const requestUrl = originalRequest?.url || '';
    
    // Don't try to refresh for auth endpoints or if already retried
    const isAuthEndpoint = AUTH_ENDPOINTS.some(endpoint => requestUrl.includes(endpoint));
    
    if (error.response?.status === 401 && !originalRequest._retry && !isAuthEndpoint) {
      originalRequest._retry = true;
      
      try {
        await axios.post('/api/auth/refresh');
        return axios(originalRequest);
      } catch (refreshError) {
        // Refresh failed - only redirect to login if not already on a public page
        const currentPath = window.location.pathname;
        const isPublicPage = PUBLIC_PATHS.some(path => currentPath === path || currentPath.startsWith(path + '/'));
        if (!isPublicPage) {
          window.location.href = '/login';
        }
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  // Check authentication status on mount
  useEffect(() => {
    checkAuthStatus();
  }, []);

  const checkAuthStatus = async () => {
    try {
      setLoading(true);
      const response = await axios.get('/api/auth/me');
      setUser(response.data);
      setIsAuthenticated(true);
    } catch (error) {
      setIsAuthenticated(false);
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  const login = async (username: string, password: string) => {
    try {
      const response = await axios.post('/api/auth/login', {
        username,
        password,
      });
      
      setUser(response.data.user);
      setIsAuthenticated(true);
    } catch (error) {
      console.error('Login failed:', error);
      throw error;
    }
  };

  const loginWithKeycloak = useCallback(() => {
    keycloak.login({
      redirectUri: window.location.origin + '/auth/callback',
    });
  }, []);

  const register = async (data: RegisterData) => {
    try {
      await axios.post('/api/auth/register', data);
      // After successful registration, log the user in
      await login(data.username, data.password);
    } catch (error) {
      console.error('Registration failed:', error);
      throw error;
    }
  };

  const logout = async () => {
    try {
      await axios.post('/api/auth/logout');
      setUser(null);
      setIsAuthenticated(false);
      
      // If using Keycloak, also logout from Keycloak
      if (keycloak.authenticated) {
        keycloak.logout({
          redirectUri: window.location.origin,
        });
      }
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  const refreshToken = async () => {
    try {
      const response = await axios.post('/api/auth/refresh');
      setUser(response.data.user);
      setIsAuthenticated(true);
    } catch (error) {
      console.error('Token refresh failed:', error);
      setIsAuthenticated(false);
      setUser(null);
      throw error;
    }
  };

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated,
        user,
        loading,
        login,
        loginWithKeycloak,
        register,
        logout,
        refreshToken,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}; 