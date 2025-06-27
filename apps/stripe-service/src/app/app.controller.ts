import { Controller, Get, Post, Body, ValidationPipe, BadRequestException } from '@nestjs/common';
import { AppService } from './app.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getData() {
    return this.appService.getData();
  }

  @Post('create-payment-intent')
  async createPaymentIntent(
    @Body(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }))
    createPaymentIntentDto: CreatePaymentIntentDto
  ) {
    try {
      return await this.appService.createPaymentIntent(createPaymentIntentDto.amount, createPaymentIntentDto.currency);
    } catch (error: any) {
      throw new BadRequestException(error.message || 'Failed to create payment intent');
    }
  }
}
