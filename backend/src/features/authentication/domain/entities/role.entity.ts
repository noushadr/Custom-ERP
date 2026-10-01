import { Column, Entity, JoinTable, ManyToMany, OneToMany } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Permission } from './permission.entity';
import { User } from './user.entity';

@Entity('roles')
export class Role extends BaseEntity {
  @Column({ unique: true })
  name: string;

  @Column({ nullable: true })
  description?: string;

  /** System roles (the four defaults) are protected from deletion once role management exists. */
  @Column({ default: false })
  isSystem: boolean;

  /** Deliberately NOT eager — `User.role` (and `Employee.user`, and every
   * entity that eager-loads an `Employee`/`assignee`/`user` relation, e.g.
   * `Task`, `Project`, `PayrollLineItem`) would otherwise drag this whole
   * relation along on every single row of every list endpoint, even though
   * almost none of those consumers ever read `.role.permissions` (only
   * `.role.name`). The few call sites that genuinely need permissions
   * (login/refresh, role management, `findUsersWithPermission`) request
   * this relation explicitly via their repository. */
  @ManyToMany(() => Permission, (permission) => permission.roles)
  @JoinTable({ name: 'role_permissions' })
  permissions: Permission[];

  @OneToMany(() => User, (user) => user.role)
  users: User[];
}
