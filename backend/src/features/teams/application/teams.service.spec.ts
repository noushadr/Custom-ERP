import { ConflictException, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { Team } from '../domain/entities/team.entity';
import type { TeamRepository } from '../domain/repositories/team-repository.interface';
import { TeamsService } from './teams.service';
import { UpdateTeamDto } from './dto/update-team.dto';

function buildTeam(overrides: Partial<Team> = {}): Team {
  return {
    id: 'team-1',
    name: 'Platform',
    departmentId: 'department-1',
    ...overrides,
  } as Team;
}

describe('TeamsService', () => {
  let service: TeamsService;
  let teamRepository: jest.Mocked<TeamRepository>;

  beforeEach(() => {
    teamRepository = {
      findAll: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };

    service = new TeamsService(teamRepository);
  });

  describe('create', () => {
    it('saves a new team with the given fields', async () => {
      teamRepository.save.mockImplementation((team) =>
        Promise.resolve(team),
      );

      const result = await service.create({
        name: 'Platform',
        departmentId: 'department-1',
        leadEmployeeId: 'employee-1',
      });

      expect(result.name).toBe('Platform');
      expect(result.departmentId).toBe('department-1');
      expect(result.leadEmployeeId).toBe('employee-1');
    });
  });

  describe('update', () => {
    it('applies only the given fields onto the existing team', async () => {
      const existing = buildTeam({ leadEmployeeId: 'employee-1' });
      teamRepository.findById.mockResolvedValue(existing);
      teamRepository.save.mockImplementation((team) => Promise.resolve(team));

      const result = await service.update('team-1', {
        name: 'Platform & Infra',
      });

      expect(result.name).toBe('Platform & Infra');
      // Fields not present in the DTO are left untouched.
      expect(result.departmentId).toBe('department-1');
      expect(result.leadEmployeeId).toBe('employee-1');
    });

    it('clears the lead employee when explicitly set to null', async () => {
      // Simulates the real HTTP body: class-transformer maps a JSON `null`
      // onto the DTO instance as `null`, not `undefined` — that distinction
      // is what tells Object.assign to clear the field vs. leave it alone.
      const existing = buildTeam({ leadEmployeeId: 'employee-1' });
      teamRepository.findById.mockResolvedValue(existing);
      teamRepository.save.mockImplementation((team) => Promise.resolve(team));

      const result = await service.update('team-1', {
        leadEmployeeId: null as unknown as string,
      });

      expect(result.leadEmployeeId).toBeNull();
    });

    it('throws NotFoundException when the team does not exist', async () => {
      teamRepository.findById.mockResolvedValue(null);

      await expect(
        service.update('missing-team', { name: 'New Name' }),
      ).rejects.toThrow(NotFoundException);
      expect(teamRepository.save).not.toHaveBeenCalled();
    });

    it('archiving alone does not wipe the name — regression test for the real request shape', async () => {
      // A plain object literal like `{ isArchived: true }` has no `name` key
      // at all, so it can't reproduce this bug. The real HTTP pipeline runs
      // the body through class-transformer first, and every declared-but-
      // unset field on the resulting instance is an explicit `undefined` own
      // property (`useDefineForClassFields`) — that's what previously made
      // `Object.assign(team, dto)` overwrite `name` with `undefined`.
      const dto = plainToInstance(UpdateTeamDto, { isArchived: true });
      expect(Object.keys(dto)).toContain('name');

      const existing = buildTeam({ leadEmployeeId: 'employee-1' });
      teamRepository.findById.mockResolvedValue(existing);
      teamRepository.save.mockImplementation((team) => Promise.resolve(team));

      const result = await service.update('team-1', dto);

      expect(result.isArchived).toBe(true);
      expect(result.name).toBe('Platform');
      expect(result.departmentId).toBe('department-1');
      expect(result.leadEmployeeId).toBe('employee-1');
    });
  });

  describe('remove', () => {
    it('removes the team when nothing references it', async () => {
      const existing = buildTeam();
      teamRepository.findById.mockResolvedValue(existing);
      teamRepository.remove.mockResolvedValue(undefined);

      await service.remove('team-1');

      expect(teamRepository.remove).toHaveBeenCalledWith(existing);
    });

    it('throws NotFoundException when the team does not exist', async () => {
      teamRepository.findById.mockResolvedValue(null);

      await expect(service.remove('missing-team')).rejects.toThrow(
        NotFoundException,
      );
      expect(teamRepository.remove).not.toHaveBeenCalled();
    });

    it('translates a foreign-key violation into a friendly ConflictException', async () => {
      const existing = buildTeam();
      teamRepository.findById.mockResolvedValue(existing);
      teamRepository.remove.mockRejectedValue({ code: '23503' });

      await expect(service.remove('team-1')).rejects.toThrow(
        ConflictException,
      );
    });

    it('rethrows unrelated errors from the repository', async () => {
      const existing = buildTeam();
      teamRepository.findById.mockResolvedValue(existing);
      const unrelatedError = new Error('connection lost');
      teamRepository.remove.mockRejectedValue(unrelatedError);

      await expect(service.remove('team-1')).rejects.toThrow(
        'connection lost',
      );
    });
  });
});
