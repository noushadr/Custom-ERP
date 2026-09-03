import { RequestStatus } from '../domain/enums/request-status.enum';

export interface RequestResponse {
  id: string;
  requesterId: string;
  requesterName: string;
  requesterPhotoUrl: string | null;
  subject: string;
  description: string;
  type: string | null;
  /** 'general' or 'profile_change' — a profile-change request skips
   * manager approval entirely (see EmployeeRequest's own doc comment), so
   * the frontend needs this to show "No need" rather than a blank/'—'
   * manager-approval status. */
  kind: string;
  status: RequestStatus;
  managerDecisionAt: string | null;
  managerDecisionByName: string | null;
  hrDecisionAt: string | null;
  hrDecisionByName: string | null;
  rejectionReason: string | null;
  createdAt: string;
}
