import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule } from '@nestjs/config';
import { KeycloakService } from './keycloak.service';

@Module({
  imports: [HttpModule, ConfigModule],
  providers: [KeycloakService],
  exports: [KeycloakService],
})
export class KeycloakModule {} 