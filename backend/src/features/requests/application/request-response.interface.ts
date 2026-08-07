import { RequestStatus } from '../domain/enums/request-status.enum';

export interface RequestResponse {
  id: string;
  requesterId: string;
  requesterName: string;
  requesterPhotoUrl: string | null;
  subject: string;
  description: string;
  type: string | null;
  status: RequestStatus;
  managerDecisionAt: string | null;
  managerDecisionByName: string | null;
  hrDecisionAt: string | null;
  hrDecisionByName: string | null;
  rejectionReason: string | null;
  createdAt: string;
}
