import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { resolveActorName } from '../../../core/utils/resolve-actor-name.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../../authentication/domain/repositories/user-repository.interface';
import { EmployeesService } from '../../employee/application/employees.service';
import type { UpdateMyProfileDto } from '../../employee/application/dto/update-my-profile.dto';
import {
  EMPLOYEE_REPOSITORY,
  type EmployeeRepository,
} from '../../employee/domain/repositories/employee-repository.interface';
import { EmployeeRequest } from '../domain/entities/employee-request.entity';
import { RequestKind } from '../domain/enums/request-kind.enum';
import { RequestStatus } from '../domain/enums/request-status.enum';
import {
  REQUEST_REPOSITORY,
  type RequestRepository,
} from '../domain/repositories/request-repository.interface';
import { CreateRequestDto } from './dto/create-request.dto';
import { RequestResponse } from './request-response.interface';
import { toRequestResponse } from './request.mapper';

@Injectable()
export class RequestsService {
  constructor(
    @Inject(REQUEST_REPOSITORY)
    private readonly requestRepository: RequestRepository,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    private readonly employeesService: EmployeesService,
  ) {}

  async submit(
    actorUserId: string,
    dto: CreateRequestDto,
  ): Promise<RequestResponse> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    const request = new EmployeeRequest();
    request.employeeId = employee.id;
    request.subject = dto.subject;
    request.description = dto.description;
    request.type = dto.type;
    request.kind = RequestKind.GENERAL;
    request.status = RequestStatus.SUBMITTED;

    const saved = await this.requestRepository.save(request);
    const reloaded = await this.requestRepository.findById(saved.id);
    return toRequestResponse(reloaded!);
  }

  /** Self-service profile edits also skip the reporting-manager step and go
   * straight to HR/Admin, who can approve (applying the change) or reject. */
  async submitProfileChangeRequest(
    actorUserId: string,
    dto: UpdateMyProfileDto,
  ): Promise<RequestResponse> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    const changes = await this.employeesService.previewProfileChanges(
      employee.id,
      dto,
    );
    if (changes.length === 0) {
      throw new BadRequestException('No profile changes were submitted');
    }

    const request = new EmployeeRequest();
    request.employeeId = employee.id;
    request.subject = 'Profile update request';
    request.description = changes
      .map(
        (c) => `${c.fieldLabel}: ${c.oldValue ?? '—'} → ${c.newValue ?? '—'}`,
      )
      .join('\n');
    request.type = 'Profile Change';
    request.kind = RequestKind.PROFILE_CHANGE;
    request.payload = { ...dto };
    request.status = RequestStatus.MANAGER_APPROVED;

    const saved = await this.requestRepository.save(request);
    const reloaded = await this.requestRepository.findById(saved.id);
    return toRequestResponse(reloaded!);
  }

  async findMine(actorUserId: string): Promise<RequestResponse[]> {
    const employee = await this.employeeRepository.findByUserId(actorUserId);
    if (!employee) throw new NotFoundException('Employee profile not found');

    const requests = await this.requestRepository.findByEmployeeId(employee.id);
    return requests.map(toRequestResponse);
  }

  async findPendingManagerApproval(
    actorUserId: string,
  ): Promise<RequestResponse[]> {
    const manager = await this.employeeRepository.findByUserId(actorUserId);
    if (!manager) return [];

    const submitted = await this.requestRepository.findByStatus(
      RequestStatus.SUBMITTED,
    );
    return submitted
      .filter((request) => request.employee.reportingManagerId === manager.id)
      .map(toRequestResponse);
  }

  async findPendingHrApproval(): Promise<RequestResponse[]> {
    const requests = await this.requestRepository.findByStatus(
      RequestStatus.MANAGER_APPROVED,
    );
    return requests.map(toRequestResponse);
  }

  async approveAsManager(
    requestId: string,
    actorUserId: string,
  ): Promise<RequestResponse> {
    const { request, actorName } = await this.loadForManagerDecision(
      requestId,
      actorUserId,
    );

    request.status = RequestStatus.MANAGER_APPROVED;
    request.managerDecisionAt = new Date();
    request.managerDecisionByName = actorName;

    const saved = await this.requestRepository.save(request);
    return toRequestResponse(saved);
  }

  async rejectAsManager(
    requestId: string,
    actorUserId: string,
    reason: string | undefined,
  ): Promise<RequestResponse> {
    const { request, actorName } = await this.loadForManagerDecision(
      requestId,
      actorUserId,
    );

    request.status = RequestStatus.REJECTED;
    request.managerDecisionAt = new Date();
    request.managerDecisionByName = actorName;
    request.rejectionReason = reason;

    const saved = await this.requestRepository.save(request);
    return toRequestResponse(saved);
  }

  /** Gated by `users.manage` at the controller — any HR/Admin may decide,
   * not just the requester's own reporting manager. */
  async approveAsHr(
    requestId: string,
    actorUserId: string,
  ): Promise<RequestResponse> {
    const request = await this.loadForHrDecision(requestId);
    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );

    if (request.kind === RequestKind.PROFILE_CHANGE && request.payload) {
      await this.employeesService.applyApprovedProfileChange(
        request.employeeId,
        request.payload,
      );
    }

    request.status = RequestStatus.COMPLETED;
    request.hrDecisionAt = new Date();
    request.hrDecisionByName = actorName;

    const saved = await this.requestRepository.save(request);
    return toRequestResponse(saved);
  }

  async rejectAsHr(
    requestId: string,
    actorUserId: string,
    reason: string | undefined,
  ): Promise<RequestResponse> {
    const request = await this.loadForHrDecision(requestId);
    const actorName = await resolveActorName(
      this.employeeRepository,
      this.userRepository,
      actorUserId,
    );

    request.status = RequestStatus.REJECTED;
    request.hrDecisionAt = new Date();
    request.hrDecisionByName = actorName;
    request.rejectionReason = reason;

    const saved = await this.requestRepository.save(request);
    return toRequestResponse(saved);
  }

  private async loadForManagerDecision(
    requestId: string,
    actorUserId: string,
  ): Promise<{ request: EmployeeRequest; actorName: string }> {
    const request = await this.requestRepository.findById(requestId);
    if (!request) throw new NotFoundException('Request not found');
    if (request.status !== RequestStatus.SUBMITTED) {
      throw new BadRequestException(
        'This request has already moved past the manager approval stage',
      );
    }

    const manager = await this.employeeRepository.findByUserId(actorUserId);
    if (!manager || request.employee.reportingManagerId !== manager.id) {
      throw new ForbiddenException(
        "You aren't the reporting manager for this request",
      );
    }

    return { request, actorName: `${manager.firstName} ${manager.lastName}` };
  }

  private async loadForHrDecision(requestId: string): Promise<EmployeeRequest> {
    const request = await this.requestRepository.findById(requestId);
    if (!request) throw new NotFoundException('Request not found');
    if (request.status !== RequestStatus.MANAGER_APPROVED) {
      throw new BadRequestException('This request is not awaiting HR approval');
    }
    return request;
  }
}
