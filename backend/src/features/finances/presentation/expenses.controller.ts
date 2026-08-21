import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import { CreateExpenseDto } from '../application/dto/create-expense.dto';
import { UpdateExpenseDto } from '../application/dto/update-expense.dto';
import { FinancesService } from '../application/finances.service';

@Controller('expenses')
@Permissions('finances.manage')
export class ExpensesController {
  constructor(private readonly financesService: FinancesService) {}

  @Get()
  getExpenses(@Query('from') from?: string, @Query('to') to?: string) {
    return this.financesService.getExpenses(from, to);
  }

  @Post()
  createExpense(@Body() dto: CreateExpenseDto) {
    return this.financesService.createExpense(dto);
  }

  @Patch(':id')
  updateExpense(@Param('id') id: string, @Body() dto: UpdateExpenseDto) {
    return this.financesService.updateExpense(id, dto);
  }
}
