import { Injectable, UnauthorizedException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { RegisterDto } from '../auth/dto/register.dto';

@Injectable()
export class KeycloakService {
  private keycloakUrl: string;
  private realm: string;
  private clientId: string;
  private clientSecret: string;
  private adminToken: string | null = null;
  private adminTokenExpiry = 0;

  constructor(
    private httpService: HttpService,
    private configService: ConfigService,
  ) {
    this.keycloakUrl = this.configService.get<string>('KEYCLOAK_URL') || 'http://localhost:8180';
    this.realm = this.configService.get<string>('KEYCLOAK_REALM') || 'microservices';
    this.clientId = this.configService.get<string>('KEYCLOAK_CLIENT_ID') || 'auth-service';
    this.clientSecret = this.configService.get<string>('KEYCLOAK_CLIENT_SECRET') || 'auth-service-secret';
  }

  async login(username: string, password: string): Promise<any> {
    try {
      const tokenUrl = `${this.keycloakUrl}/realms/${this.realm}/protocol/openid-connect/token`;
      
      const params = new URLSearchParams();
      params.append('grant_type', 'password');
      params.append('client_id', this.clientId);
      params.append('client_secret', this.clientSecret);
      params.append('username', username);
      params.append('password', password);

      const response = await firstValueFrom(
        this.httpService.post(tokenUrl, params.toString(), {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        }),
      );

      return response.data;
    } catch (error) {
      throw new UnauthorizedException('Invalid credentials');
    }
  }

  async validateToken(token: string): Promise<any> {
    try {
      const introspectUrl = `${this.keycloakUrl}/realms/${this.realm}/protocol/openid-connect/token/introspect`;
      
      const params = new URLSearchParams();
      params.append('token', token);
      params.append('client_id', this.clientId);
      params.append('client_secret', this.clientSecret);

      const response = await firstValueFrom(
        this.httpService.post(introspectUrl, params.toString(), {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        }),
      );

      if (!response.data.active) {
        throw new UnauthorizedException('Token is not active');
      }

      return response.data;
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }

  async getUserInfo(accessToken: string): Promise<any> {
    try {
      const userInfoUrl = `${this.keycloakUrl}/realms/${this.realm}/protocol/openid-connect/userinfo`;
      
      const response = await firstValueFrom(
        this.httpService.get(userInfoUrl, {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        }),
      );

      return response.data;
    } catch (error) {
      throw new UnauthorizedException('Failed to get user info');
    }
  }

  async createUser(registerDto: RegisterDto): Promise<any> {
    try {
      const adminToken = await this.getAdminToken();
      const usersUrl = `${this.keycloakUrl}/admin/realms/${this.realm}/users`;

      const userData = {
        username: registerDto.username,
        email: registerDto.email,
        firstName: registerDto.firstName,
        lastName: registerDto.lastName,
        enabled: true,
        credentials: [
          {
            type: 'password',
            value: registerDto.password,
            temporary: false,
          },
        ],
      };

      const response = await firstValueFrom(
        this.httpService.post(usersUrl, userData, {
          headers: {
            Authorization: `Bearer ${adminToken}`,
            'Content-Type': 'application/json',
          },
        }),
      );

      // Get the created user's ID from the Location header
      const locationHeader = response.headers.location;
      const userId = locationHeader?.split('/').pop();

      // Fetch the created user
      const userResponse = await firstValueFrom(
        this.httpService.get(`${usersUrl}/${userId}`, {
          headers: {
            Authorization: `Bearer ${adminToken}`,
          },
        }),
      );

      return userResponse.data;
    } catch (error) {
      if (error.response?.status === 409) {
        throw new UnauthorizedException('User already exists');
      }
      throw new UnauthorizedException('Failed to create user');
    }
  }

  async refreshToken(refreshToken: string): Promise<any> {
    try {
      const tokenUrl = `${this.keycloakUrl}/realms/${this.realm}/protocol/openid-connect/token`;
      
      const params = new URLSearchParams();
      params.append('grant_type', 'refresh_token');
      params.append('client_id', this.clientId);
      params.append('client_secret', this.clientSecret);
      params.append('refresh_token', refreshToken);

      const response = await firstValueFrom(
        this.httpService.post(tokenUrl, params.toString(), {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        }),
      );

      return response.data;
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  private async getAdminToken(): Promise<string> {
    // Check if we have a valid admin token
    if (this.adminToken && this.adminTokenExpiry > Date.now()) {
      return this.adminToken;
    }

    try {
      const tokenUrl = `${this.keycloakUrl}/realms/master/protocol/openid-connect/token`;
      
      const params = new URLSearchParams();
      params.append('grant_type', 'password');
      params.append('client_id', 'admin-cli');
      params.append('username', 'admin');
      params.append('password', 'admin'); // This should come from env in production

      const response = await firstValueFrom(
        this.httpService.post(tokenUrl, params.toString(), {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        }),
      );

      this.adminToken = response.data.access_token;
      // Set expiry to 5 minutes before actual expiry
      this.adminTokenExpiry = Date.now() + (response.data.expires_in - 300) * 1000;

      return this.adminToken as string;
    } catch (error) {
      throw new UnauthorizedException('Failed to get admin token');
    }
  }
} 