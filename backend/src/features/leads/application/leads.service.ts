import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { Lead } from '../domain/entities/lead.entity';
import {
  LEAD_REPOSITORY,
  type LeadRepository,
} from '../domain/repositories/lead-repository.interface';
import { CreateLeadDto } from './dto/create-lead.dto';
import { UpdateLeadDto } from './dto/update-lead.dto';
import { LeadResponseDto } from './lead-response.interface';
import { toLeadResponse } from './lead.mapper';

/** Ensures a phone number is stored with a leading "+" so it always reads
 * as including a country code — imported/typed numbers otherwise vary. */
function normalizePhone(phone: string | undefined): string | undefined {
  if (!phone) return phone;
  const trimmed = phone.trim();
  return trimmed.startsWith('+') ? trimmed : `+${trimmed}`;
}

@Injectable()
export class LeadsService {
  constructor(
    @Inject(LEAD_REPOSITORY)
    private readonly leadRepository: LeadRepository,
  ) {}

  async getLeads(): Promise<LeadResponseDto[]> {
    const leads = await this.leadRepository.findAll();
    return leads.map(toLeadResponse);
  }

  async createLead(dto: CreateLeadDto): Promise<LeadResponseDto> {
    const lead = new Lead();
    lead.leadDate = dto.leadDate;
    lead.fullName = dto.fullName;
    lead.companyName = dto.companyName;
    lead.leadSource = dto.leadSource;
    lead.phone = normalizePhone(dto.phone);
    lead.email = dto.email;
    lead.country = dto.country;
    lead.remarks = dto.remarks;
    lead.serviceInterested = dto.serviceInterested;

    const saved = await this.leadRepository.save(lead);
    return toLeadResponse(saved);
  }

  async updateLead(id: string, dto: UpdateLeadDto): Promise<LeadResponseDto> {
    const lead = await this.leadRepository.findById(id);
    if (!lead) throw new NotFoundException('Lead not found');
    const changes = definedFieldsOnly(dto);
    if (changes.phone !== undefined) changes.phone = normalizePhone(changes.phone);
    Object.assign(lead, changes);
    const saved = await this.leadRepository.save(lead);
    return toLeadResponse(saved);
  }
}
