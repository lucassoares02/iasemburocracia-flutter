import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/state/base_controller.dart';
import 'home_model.dart';
import 'home_usecase.dart';

class HomeController extends BaseController<DashboardModel> {
  final HomeUseCase usecase;

  HomeController(super.initialState, this.usecase);

  ValueNotifier<StateApp> stateDashboard = ValueNotifier(StartState());

  Future<void> loadDashboard() async =>
      runWithState(() => usecase.getDashboard(), stateDashboard);
}
