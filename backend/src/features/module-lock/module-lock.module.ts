import { Module } from '@nestjs/common';
import { ModuleLockService } from './application/module-lock.service';
import { ModuleLockController } from './presentation/module-lock.controller';

@Module({
  controllers: [ModuleLockController],
  providers: [ModuleLockService],
})
export class ModuleLockModule {}
