// Imports updated
import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import 'home_controller.dart';
import 'home_repository.dart';
import 'home_usecase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController controller = HomeController(StartState(), HomeUseCase(HomeRepository()));

  @override
  void initState() {
    super.initState();
    controller.findAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Página de Home'),
      ),
    );
  }
}
