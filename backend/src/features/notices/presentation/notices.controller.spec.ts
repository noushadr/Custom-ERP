import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import type { NoticesService } from '../application/notices.service';
import { NoticesController } from './notices.controller';

function userWith(permissions: string[]): JwtPayload {
  return {
    sub: 'user-1',
    email: 'jane@zeracreative.com',
    role: 'Employee',
    permissions,
  };
}

describe('NoticesController.findAll', () => {
  let service: jest.Mocked<
    Pick<NoticesService, 'findActive' | 'findAllIncludingExpired'>
  >;
  let controller: NoticesController;

  beforeEach(() => {
    service = {
      findActive: jest.fn().mockResolvedValue(['active']),
      findAllIncludingExpired: jest.fn().mockResolvedValue(['everything']),
    };
    controller = new NoticesController(service as unknown as NoticesService);
  });

  it('gives staff only the notices that are still showing', async () => {
    await expect(controller.findAll(userWith([]))).resolves.toEqual(['active']);
    expect(service.findAllIncludingExpired).not.toHaveBeenCalled();
  });

  it('ignores ?includeExpired=true for someone without notices.manage — expired notices stay hidden from them', async () => {
    await expect(controller.findAll(userWith([]), 'true')).resolves.toEqual([
      'active',
    ]);
    expect(service.findAllIncludingExpired).not.toHaveBeenCalled();
  });

  it('lets a notices.manage holder opt in to expired notices', async () => {
    await expect(
      controller.findAll(userWith(['notices.manage']), 'true'),
    ).resolves.toEqual(['everything']);
  });

  it('still defaults a manager to active-only unless they ask', async () => {
    await expect(
      controller.findAll(userWith(['notices.manage'])),
    ).resolves.toEqual(['active']);
  });
});
