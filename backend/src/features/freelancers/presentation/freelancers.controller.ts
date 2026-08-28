import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { CreateFreelancerDto } from '../application/dto/create-freelancer.dto';
import { UpdateFreelancerDto } from '../application/dto/update-freelancer.dto';
import { FreelancersService } from '../application/freelancers.service';

/** Freelancers are a Payroll sub-concern — gated by the same
 * `payroll.manage` permission, no dedicated permission of their own. */
@Controller('freelancers')
@Permissions('payroll.manage')
export class FreelancersController {
  constructor(private readonly freelancersService: FreelancersService) {}

  @Get()
  getFreelancers(@Query('activeOnly') activeOnly?: string) {
    return this.freelancersService.getFreelancers(activeOnly === 'true');
  }

  @Post()
  createFreelancer(@Body() dto: CreateFreelancerDto) {
    return this.freelancersService.createFreelancer(dto);
  }

  @Patch(':id')
  updateFreelancer(@Param('id') id: string, @Body() dto: UpdateFreelancerDto) {
    return this.freelancersService.updateFreelancer(id, dto);
  }
}
