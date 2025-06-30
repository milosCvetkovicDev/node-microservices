import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { KeycloakService } from '../keycloak/keycloak.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly usersService: UsersService,
    private readonly keycloakService: KeycloakService,
  ) {}

  async validateKeycloakToken(token: string) {
    try {
      const userInfo = await this.keycloakService.validateToken(token);
      
      // Sync user with local database
      let user = await this.usersService.findByKeycloakId(userInfo.sub);
      if (!user) {
        user = await this.usersService.create({
          keycloakId: userInfo.sub,
          email: userInfo.email,
          firstName: userInfo.given_name,
          lastName: userInfo.family_name,
          username: userInfo.preferred_username,
        });
      }

      return this.generateTokens(user);
    } catch (error) {
      throw new UnauthorizedException('Invalid Keycloak token');
    }
  }

  async login(loginDto: LoginDto) {
    try {
      // Authenticate with Keycloak
      const keycloakTokens = await this.keycloakService.login(
        loginDto.username,
        loginDto.password,
      );

      // Get user info from Keycloak
      const userInfo = await this.keycloakService.getUserInfo(keycloakTokens.access_token);

      // Sync user with local database
      let user = await this.usersService.findByKeycloakId(userInfo.sub);
      if (!user) {
        user = await this.usersService.create({
          keycloakId: userInfo.sub,
          email: userInfo.email,
          firstName: userInfo.given_name,
          lastName: userInfo.family_name,
          username: userInfo.preferred_username,
        });
      }

      return {
        ...this.generateTokens(user),
        keycloakTokens,
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid credentials');
    }
  }

  async register(registerDto: RegisterDto) {
    try {
      // Register user in Keycloak
      const keycloakUser = await this.keycloakService.createUser(registerDto);

      // Create user in local database
      const user = await this.usersService.create({
        keycloakId: keycloakUser.id,
        email: registerDto.email,
        firstName: registerDto.firstName,
        lastName: registerDto.lastName,
        username: registerDto.username,
      });

      return {
        message: 'User registered successfully',
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
        },
      };
    } catch (error) {
      throw new UnauthorizedException('Registration failed');
    }
  }

  async refreshToken(refreshTokenDto: RefreshTokenDto) {
    try {
      const payload = this.jwtService.verify(refreshTokenDto.refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });

      const user = await this.usersService.findById(payload.sub);
      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      return this.generateTokens(user);
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(userId: string) {
    // Invalidate refresh token in database if needed
    // For now, just return success
    return { message: 'Logged out successfully' };
  }

  private generateTokens(user: any) {
    const payload = {
      sub: user.id,
      email: user.email,
      username: user.username,
      roles: user.roles || [],
    };

    return {
      accessToken: this.jwtService.sign(payload),
      refreshToken: this.jwtService.sign(payload, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: '7d',
      }),
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        roles: user.roles || [],
      },
    };
  }
} 