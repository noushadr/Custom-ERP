import { Lead } from '../domain/entities/lead.entity';
import { LeadResponseDto } from './lead-response.interface';

export function toLeadResponse(lead: Lead): LeadResponseDto {
  return {
    id: lead.id,
    leadDate: lead.leadDate,
    fullName: lead.fullName,
    companyName: lead.companyName ?? null,
    leadSource: lead.leadSource ?? null,
    phone: lead.phone ?? null,
    email: lead.email ?? null,
    country: lead.country ?? null,
    remarks: lead.remarks ?? null,
    serviceInterested: lead.serviceInterested ?? null,
    createdAt: lead.createdAt.toISOString(),
    updatedAt: lead.updatedAt.toISOString(),
  };
}
