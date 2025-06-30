import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-custom';
import { Request } from 'express';
import { KeycloakService } from '../../keycloak/keycloak.service';
import { UsersService } from '../../users/users.service';

@Injectable()
export class KeycloakStrategy extends PassportStrategy(Strategy, 'keycloak') {
  constructor(
    private keycloakService: KeycloakService,
    private usersService: UsersService,
  ) {
    super();
  }

  async validate(req: Request): Promise<any> {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      return false;
    }

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

      return user;
    } catch (error) {
      return false;
    }
  }
} 