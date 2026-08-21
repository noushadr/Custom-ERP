export interface TaskResponseDto {
  id: string;
  title: string;
  description: string | null;
  assigneeEmployeeId: string;
  assigneeName: string;
  assigneePhotoUrl: string | null;
  departmentId: string | null;
  departmentName: string | null;
  assignedByUserId: string;
  assignedByName: string;
  assignedByPhotoUrl: string | null;
  priority: string;
  dueDate: string;
  status: string;
  completedAt: string | null;
  projectId: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface TaskCommentResponseDto {
  id: string;
  authorName: string;
  body: string;
  createdAt: string;
}

export interface TaskAuditLogResponseDto {
  id: string;
  actorName: string;
  fieldLabel: string;
  oldValue: string | null;
  newValue: string | null;
  createdAt: string;
}
