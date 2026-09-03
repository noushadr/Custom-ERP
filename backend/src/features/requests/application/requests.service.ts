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
import { NotificationLinkTarget } from '../../notifications/domain/enums/notification-link-target.enum';
import { NotificationsService } from '../../notifications/application/notifications.service';
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

/** Caps how far back Request History reaches, the same "bounded history,
 * not a time-window cutoff" approach the notification bell's own
 * `_maxDecidedHistory` uses — nothing vanishes just because time passed,
 * it just stops appearing once far enough down the list. */
const _HISTORY_LIMIT = 30;

/** The moment a REJECTED or COMPLETED request was actually decided — HR's
 * decision (the only path to COMPLETED, and one of the two paths to
 * REJECTED) if set, else the manager's rejection. */
function decidedAt(request: EmployeeRequest): Date {
  return request.hrDecisionAt ?? request.managerDecisionAt ?? request.createdAt;
}

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
    private readonly notificationsService: NotificationsService,
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

    // GENERAL requests need the reporting manager's approval first — let
    // them know right away rather than relying on them to notice it in the
    // Requests page's own "Awaiting My Approval" list. PROFILE_CHANGE
    // requests skip this step entirely (see submitProfileChangeRequest), so
    // there's no manager to notify there.
    if (employee.reportingManagerId) {
      const manager = await this.employeeRepository.findById(
        employee.reportingManagerId,
      );
      if (manager) {
        await this.notificationsService.create({
          recipientUserId: manager.userId,
          message: `${employee.firstName} ${employee.lastName} submitted a request — "${dto.subject}" — awaiting your approval`,
          linkTarget: NotificationLinkTarget.REQUESTS,
        });
      }
    }

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
      .map((c) =>
        c.oldValue == null
          ? `${c.fieldLabel} → ${c.newValue ?? '—'}`
          : `${c.fieldLabel}: ${c.oldValue} → ${c.newValue ?? '—'}`,
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

  /** Every decided request company-wide (approved-and-completed or
   * rejected, at either stage) — newest decision first, capped so this
   * doesn't grow unbounded the way the paginated company-wide audit log
   * does. `users.manage`-gated at the controller, same tier as
   * findPendingHrApproval, since HR/Admin is the only role that ever
   * finalizes every request regardless of who it's from. */
  async getHistory(): Promise<RequestResponse[]> {
    const decided = await this.findDecided();
    return decided.slice(0, _HISTORY_LIMIT).map(toRequestResponse);
  }

  /** Same as getHistory, but scoped to just the caller's own direct
   * reports' decided requests — deliberately no `@Permissions` guard
   * (mirrors getPendingManagerAction/getLatestForMyTeam's identity-scoped
   * pattern), so a Team Lead can see what they've approved/rejected
   * without holding `users.manage`. */
  async getHistoryForMyTeam(actorUserId: string): Promise<RequestResponse[]> {
    const manager = await this.employeeRepository.findByUserId(actorUserId);
    if (!manager) return [];

    const decided = await this.findDecided();
    return decided
      .filter((request) => request.employee.reportingManagerId === manager.id)
      .slice(0, _HISTORY_LIMIT)
      .map(toRequestResponse);
  }

  private async findDecided(): Promise<EmployeeRequest[]> {
    const [rejected, completed] = await Promise.all([
      this.requestRepository.findByStatus(RequestStatus.REJECTED),
      this.requestRepository.findByStatus(RequestStatus.COMPLETED),
    ]);
    return [...rejected, ...completed].sort(
      (a, b) => decidedAt(b).getTime() - decidedAt(a).getTime(),
    );
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
