export interface AssetResponse {
  id: string;
  name: string;
  category: string | null;
  serialNumber: string | null;
  status: string;
  assignedEmployeeId: string | null;
  assignedAt: Date | null;
  notes: string | null;
  createdAt: Date;
}
