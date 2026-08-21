import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { CreateClientDto } from '../application/dto/create-client.dto';
import { UpdateClientDto } from '../application/dto/update-client.dto';
import { UpdateClientHealthDto } from '../application/dto/update-client-health.dto';
import { ClientsService } from '../application/clients.service';

/** The entire module is Super-Admin-only by default: `clients.manage` is
 * granted only to Super Admin at seed time (see seed.ts) — no self-service
 * tier, unlike Tasks/Performance Reviews, since this whole module is meant
 * to be admin-only end to end. */
@Controller('clients')
@Permissions('clients.manage')
export class ClientsController {
  constructor(private readonly clientsService: ClientsService) {}

  @Get()
  getClients(@Query('includeArchived') includeArchived?: string) {
    return this.clientsService.getClients(includeArchived === 'true');
  }

  @Post()
  createClient(@Body() dto: CreateClientDto) {
    return this.clientsService.createClient(dto);
  }

  // Must come before @Get(':id') — otherwise "health-summary" would be
  // captured as the :id parameter instead of matching this route.
  @Get('health-summary')
  getClientHealthSummary() {
    return this.clientsService.getClientHealthSummary();
  }

  @Get(':id')
  getClient(@Param('id') id: string) {
    return this.clientsService.getClient(id);
  }

  @Patch(':id')
  updateClient(@Param('id') id: string, @Body() dto: UpdateClientDto) {
    return this.clientsService.updateClient(id, dto);
  }

  @Post(':id/health')
  updateClientHealth(
    @Param('id') id: string,
    @Body() dto: UpdateClientHealthDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.clientsService.updateClientHealth(id, user.sub, dto);
  }

  @Get(':id/health-history')
  getClientHealthHistory(@Param('id') id: string) {
    return this.clientsService.getClientHealthHistory(id);
  }
}
