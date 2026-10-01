import { Controller, Get, Query } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { SearchService } from '../application/search.service';

@Controller('search')
// No permission requirement beyond being logged in (enforced globally by
// JwtAuthGuard) — each category inside SearchService checks its own
// permission independently, since no single `@Permissions()` gate here could
// express "run every category this viewer's own permissions unlock."
@Permissions()
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  search(
    @Query('q') query: string | undefined,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.searchService.search(user, query ?? '');
  }
}
