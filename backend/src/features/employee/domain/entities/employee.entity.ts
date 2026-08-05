import { Column, Entity, JoinColumn, ManyToOne, OneToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { User } from '../../../authentication/domain/entities/user.entity';
import { Department } from '../../../departments/domain/entities/department.entity';
import { Team } from '../../../teams/domain/entities/team.entity';
import { EmploymentStatus } from '../enums/employment-status.enum';
import { EmploymentType } from '../enums/employment-type.enum';
import { WorkMode } from '../enums/work-mode.enum';

@Entity('employees')
export class Employee extends BaseEntity {
  @Column({ unique: true })
  employeeCode: string;

  @Column()
  userId: string;

  @OneToOne(() => User, { eager: true })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  firstName: string;

  @Column()
  lastName: string;

  @Column({ nullable: true })
  profilePhotoUrl?: string;

  @Column({ nullable: true })
  designation?: string;

  @Column({ nullable: true })
  departmentId?: string;

  @ManyToOne(() => Department, { eager: true })
  @JoinColumn({ name: 'departmentId' })
  department?: Department;

  @Column({ nullable: true })
  teamId?: string;

  @ManyToOne(() => Team, { eager: true })
  @JoinColumn({ name: 'teamId' })
  team?: Team;

  @Column({ nullable: true })
  reportingManagerId?: string;

  @ManyToOne(() => Employee)
  @JoinColumn({ name: 'reportingManagerId' })
  reportingManager?: Employee;

  @Column({
    type: 'enum',
    enum: EmploymentType,
    default: EmploymentType.FULL_TIME,
  })
  employmentType: EmploymentType;

  @Column({
    type: 'enum',
    enum: EmploymentStatus,
    default: EmploymentStatus.ACTIVE,
  })
  employmentStatus: EmploymentStatus;

  @Column({
    type: 'enum',
    enum: WorkMode,
    default: WorkMode.ON_SITE,
  })
  workMode: WorkMode;

  @Column({ type: 'date' })
  joiningDate: string;

  @Column({ type: 'date', nullable: true })
  dateOfLeaving?: string;

  @Column({ type: 'date', nullable: true })
  dateOfBirth?: string;

  @Column({ nullable: true })
  personalEmail?: string;

  @Column({ nullable: true })
  phoneNumber?: string;

  @Column({ nullable: true })
  emergencyContactName?: string;

  @Column({ nullable: true })
  emergencyContactPhone?: string;

  @Column({ nullable: true })
  emergencyContactRelation?: string;

  @Column({ nullable: true })
  address?: string;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  skills: string[];

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  certifications: string[];
}
