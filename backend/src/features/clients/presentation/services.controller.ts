import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { CreateServiceDto } from '../application/dto/create-service.dto';
import { UpdateServiceDto } from '../application/dto/update-service.dto';
import { ClientsService } from '../application/clients.service';

@Controller('services')
@Permissions('clients.manage')
export class ServicesController {
  constructor(private readonly clientsService: ClientsService) {}

  @Get()
  getServices(@Query('includeArchived') includeArchived?: string) {
    return this.clientsService.getServices(includeArchived === 'true');
  }

  @Post()
  createService(@Body() dto: CreateServiceDto) {
    return this.clientsService.createService(dto);
  }

  @Patch(':id')
  updateService(@Param('id') id: string, @Body() dto: UpdateServiceDto) {
    return this.clientsService.updateService(id, dto);
  }
}
