export interface AssetResponse {
  id: string;
  name: string;
  status: string;
  assignedEmployeeId: string | null;
  assignedAt: Date | null;
  value: string | null;
  createdAt: Date;
}
