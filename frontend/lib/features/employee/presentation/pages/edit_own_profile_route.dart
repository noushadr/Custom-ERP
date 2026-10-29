import 'package:flutter/material.dart';
import '../../domain/entities/employee.dart';
import 'edit_employee_page.dart';
import 'edit_my_profile_page.dart';

/// Where "edit my own profile" leads. Someone who can manage employees
/// (HR/Admin) gets the same full edit form they use on everyone else, so
/// they aren't limited to the self-service fields on their own record;
/// everyone else gets the limited self-service form.
Route<void> editOwnProfileRoute(Employee employee, {required bool canManage}) =>
    MaterialPageRoute<void>(
      builder: (_) => canManage
          ? EditEmployeePage(employee: employee)
          : EditMyProfilePage(employee: employee),
    );
