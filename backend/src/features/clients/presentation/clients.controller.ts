import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { CreateClientDto } from '../application/dto/create-client.dto';
import { UpdateClientDto } from '../application/dto/update-client.dto';
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

  @Get(':id')
  getClient(@Param('id') id: string) {
    return this.clientsService.getClient(id);
  }

  @Patch(':id')
  updateClient(@Param('id') id: string, @Body() dto: UpdateClientDto) {
    return this.clientsService.updateClient(id, dto);
  }
}
