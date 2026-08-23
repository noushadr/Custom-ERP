import { Client } from '../domain/entities/client.entity';
import { ClientHealthHistory } from '../domain/entities/client-health-history.entity';
import { Project } from '../domain/entities/project.entity';
import { Service } from '../domain/entities/service.entity';
import {
  ClientHealthHistoryResponseDto,
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
    country: client.country ?? null,
    address: client.address ?? null,
    primaryContactName: client.primaryContactName ?? null,
    primaryContactEmail: client.primaryContactEmail ?? null,
    primaryContactPhone: client.primaryContactPhone ?? null,
    leadSource: client.leadSource ?? null,
    notes: client.notes ?? null,
    isArchived: client.isArchived,
    archivedAt: client.archivedAt ? client.archivedAt.toISOString() : null,
    healthStatus: client.healthStatus,
    healthFactors: client.healthFactors,
    healthNotes: client.healthNotes ?? null,
    createdAt: client.createdAt.toISOString(),
    updatedAt: client.updatedAt.toISOString(),
  };
}

export function toClientHealthHistoryResponse(
  entry: ClientHealthHistory,
): ClientHealthHistoryResponseDto {
  return {
    id: entry.id,
    clientId: entry.clientId,
    previousStatus: entry.previousStatus,
    newStatus: entry.newStatus,
    factors: entry.factors,
    notes: entry.notes ?? null,
    actorName: entry.actorName,
    createdAt: entry.createdAt.toISOString(),
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

export function toProjectResponse(project: Project): ProjectResponseDto {
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
    notes: project.notes ?? null,
    packageName: project.packageName ?? null,
    backlinksTarget: project.backlinksTarget ?? null,
    seoSheetName: project.seoSheetName ?? null,
    projectFolderName: project.projectFolderName ?? null,
    workingEmailAccount: project.workingEmailAccount ?? null,
    ahrefsAccount: project.ahrefsAccount ?? null,
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
