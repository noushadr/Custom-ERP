import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { Freelancer } from '../domain/entities/freelancer.entity';
import {
  FREELANCER_REPOSITORY,
  type FreelancerRepository,
} from '../domain/repositories/freelancer-repository.interface';
import { CreateFreelancerDto } from './dto/create-freelancer.dto';
import { UpdateFreelancerDto } from './dto/update-freelancer.dto';
import { FreelancerResponseDto } from './freelancer-response.interface';
import { toFreelancerResponse } from './freelancers.mapper';

@Injectable()
export class FreelancersService {
  constructor(
    @Inject(FREELANCER_REPOSITORY)
    private readonly freelancerRepository: FreelancerRepository,
  ) {}

  async getFreelancers(activeOnly = false): Promise<FreelancerResponseDto[]> {
    const freelancers = await this.freelancerRepository.findAll(activeOnly);
    return freelancers.map(toFreelancerResponse);
  }

  async createFreelancer(
    dto: CreateFreelancerDto,
  ): Promise<FreelancerResponseDto> {
    const freelancer = new Freelancer();
    freelancer.fullName = dto.fullName;
    freelancer.role = dto.role;
    freelancer.notes = dto.notes;
    freelancer.isActive = true;

    const saved = await this.freelancerRepository.save(freelancer);
    return toFreelancerResponse(saved);
  }

  async updateFreelancer(
    id: string,
    dto: UpdateFreelancerDto,
  ): Promise<FreelancerResponseDto> {
    const freelancer = await this.freelancerRepository.findById(id);
    if (!freelancer) throw new NotFoundException('Freelancer not found');
    Object.assign(freelancer, definedFieldsOnly(dto));
    const saved = await this.freelancerRepository.save(freelancer);
    return toFreelancerResponse(saved);
  }
}
