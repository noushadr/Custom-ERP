import { Body, Controller, Post } from '@nestjs/common';
import { VerifyModulePinDto } from '../application/dto/verify-module-pin.dto';
import { ModuleLockService } from '../application/module-lock.service';

// Deliberately no @Permissions guard: the pages this gates (Leads,
// Financial Reports) are already Super-Admin-exclusive at the nav/page
// level, so the only requirement here is a valid JWT (enforced globally
// by JwtAuthGuard) — this endpoint just checks the PIN itself.
@Controller('module-locks')
export class ModuleLockController {
  constructor(private readonly moduleLockService: ModuleLockService) {}

  @Post('verify')
  verify(@Body() dto: VerifyModulePinDto) {
    return { valid: this.moduleLockService.verifyPin(dto.pin) };
  }
}
