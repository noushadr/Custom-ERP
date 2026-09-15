import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

// A single shared PIN gating the Leads and Financial Reports pages, on top
// of (not instead of) their existing `leads.manage`/`finances.manage`
// permission gates — this only adds a second, session-scoped confirmation
// step for someone who already has access. No per-module PIN was asked
// for, so one shared value keeps this simple.
@Injectable()
export class ModuleLockService {
  constructor(private readonly configService: ConfigService) {}

  verifyPin(pin: string): boolean {
    const expectedPin = this.configService.get<string>('moduleLockPin');
    return pin === expectedPin;
  }
}
