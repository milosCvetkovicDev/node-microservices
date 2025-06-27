import { Injectable, Logger } from '@nestjs/common';
import Stripe from 'stripe';

@Injectable()
export class AppService {
  private readonly logger = new Logger(AppService.name);
  private stripe = new Stripe(process.env.STRIPE_SECRET_KEY || 'sk_test_your_secret_key', { apiVersion: '2025-05-28.basil' });

  getData(): { message: string } {
    return { message: 'Hello API' };
  }

  async createPaymentIntent(amount: number, currency: string) {
    try {
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount,
        currency,
      });
      return { client_secret: paymentIntent.client_secret };
    } catch (error) {
      this.logger.error('Stripe error', error);
      throw error;
    }
  }
}
