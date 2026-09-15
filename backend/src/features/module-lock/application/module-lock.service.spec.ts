import { ConfigService } from '@nestjs/config';
import { ModuleLockService } from './module-lock.service';

describe('ModuleLockService', () => {
  let service: ModuleLockService;
  let configService: jest.Mocked<ConfigService>;

  beforeEach(() => {
    configService = {
      get: jest.fn().mockReturnValue('2803'),
    } as unknown as jest.Mocked<ConfigService>;
    service = new ModuleLockService(configService);
  });

  it('returns true when the pin matches the configured value', () => {
    expect(service.verifyPin('2803')).toBe(true);
  });

  it('returns false when the pin does not match', () => {
    expect(service.verifyPin('0000')).toBe(false);
  });

  it('reads the configured pin from the "moduleLockPin" config key', () => {
    service.verifyPin('2803');
    expect(configService.get).toHaveBeenCalledWith('moduleLockPin');
  });
});
