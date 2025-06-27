import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  @Get('health')
  health() {
    return { status: 'ok' };
  }

  @Get('liveness')
  liveness() {
    return { status: 'alive' };
  }

  @Get('readiness')
  readiness() {
    // Add checks for DB, Stripe, etc. as needed
    return { status: 'ready' };
  }
} 