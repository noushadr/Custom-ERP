import '../../domain/entities/expense_category.dart';

String formatExpenseCategoryLabel(String category) => switch (category) {
  ExpenseCategory.rentUtilities => 'Rent & Utilities',
  ExpenseCategory.softwareTools => 'Software & Tools',
  ExpenseCategory.marketing => 'Marketing',
  ExpenseCategory.vendorPayment => 'Vendor Payment',
  ExpenseCategory.taxes => 'Taxes',
  ExpenseCategory.commissions => 'Commissions',
  ExpenseCategory.other => 'Other',
  _ => category,
};
