import { Client } from '../domain/entities/client.entity';
import { Project } from '../domain/entities/project.entity';
import { Service } from '../domain/entities/service.entity';
import {
  ClientResponseDto,
  ProjectResponseDto,
  ServiceResponseDto,
} from './client-response.interface';

export function toClientResponse(client: Client): ClientResponseDto {
  return {
    id: client.id,
    companyName: client.companyName,
    industry: client.industry ?? null,
    website: client.website ?? null,
    address: client.address ?? null,
    primaryContactName: client.primaryContactName ?? null,
    primaryContactEmail: client.primaryContactEmail ?? null,
    primaryContactPhone: client.primaryContactPhone ?? null,
    notes: client.notes ?? null,
    isArchived: client.isArchived,
    createdAt: client.createdAt.toISOString(),
    updatedAt: client.updatedAt.toISOString(),
  };
}

export function toServiceResponse(service: Service): ServiceResponseDto {
  return {
    id: service.id,
    name: service.name,
    description: service.description ?? null,
    isArchived: service.isArchived,
    createdAt: service.createdAt.toISOString(),
    updatedAt: service.updatedAt.toISOString(),
  };
}

/** `netPrice`/`profit` are computed here, never stored — see Project entity
 * doc comment. */
export function toProjectResponse(project: Project): ProjectResponseDto {
  const originalClientPrice = Number(project.originalClientPrice);
  const deductionRate = Number(project.deductionRate);
  const cost = Number(project.cost);
  const netPrice = originalClientPrice * (1 - deductionRate / 100);

  return {
    id: project.id,
    clientId: project.clientId,
    clientName: project.client.companyName,
    name: project.name,
    type: project.type,
    status: project.status,
    startDate: project.startDate,
    endDate: project.endDate ?? null,
    renewalDate: project.renewalDate ?? null,
    originalClientPrice,
    deductionRate,
    netPrice,
    cost,
    profit: netPrice - cost,
    notes: project.notes ?? null,
    assignedEmployees: project.assignedEmployees.map((employee) => ({
      id: employee.id,
      fullName: `${employee.firstName} ${employee.lastName}`,
      photoUrl: employee.profilePhotoUrl ?? null,
    })),
    targetDepartments: project.targetDepartments.map((department) => ({
      id: department.id,
      name: department.name,
    })),
    services: project.services.map((service) => ({
      id: service.id,
      name: service.name,
    })),
    createdAt: project.createdAt.toISOString(),
    updatedAt: project.updatedAt.toISOString(),
  };
}
