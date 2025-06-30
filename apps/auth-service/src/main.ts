/**
 * This is not a production server yet!
 * This is only a minimal backend to get started.
 */

import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import cookieParser from 'cookie-parser';

import { AppModule } from './app/app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS with credentials
  app.enableCors({
    origin: ['http://localhost:4200', 'http://localhost:3000'], // Add your frontend URLs
    credentials: true,
  });
  
  // Use cookie parser
  app.use(cookieParser());
  
  // Global validation pipe
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
  }));
  
  const globalPrefix = 'api';
  app.setGlobalPrefix(globalPrefix);
  
  const port = process.env.PORT || 3334;
  await app.listen(port);
  
  Logger.log(
    `🚀 Application is running on: http://localhost:${port}/${globalPrefix}`
  );
}

bootstrap();
