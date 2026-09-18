import { IsString } from 'class-validator';

/** A team's head picking a specific member for a currently-unclaimed team
 * task — see `TasksService.assignTeamMember`. */
export class AssignTeamMemberDto {
  @IsString()
  employeeId: string;
}
