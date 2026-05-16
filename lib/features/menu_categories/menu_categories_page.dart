// Imports updated
import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import 'menu_categories_controller.dart';
import 'menu_categories_repository.dart';
import 'menu_categories_usecase.dart';

class MenuCategoriesPage extends StatefulWidget {
  const MenuCategoriesPage({super.key});

  @override
  State<MenuCategoriesPage> createState() => _MenuCategoriesPageState();
}

class _MenuCategoriesPageState extends State<MenuCategoriesPage> {
  late final MenuCategoriesController controller = MenuCategoriesController(StartState(), MenuCategoriesUseCase(MenuCategoriesRepository()));

  @override
  void initState() {
    //add gel all items
    controller.findAll();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MenuCategories')),
      body: const Center(
        child: Text('Página de MenuCategories'),
      ),
    );
  }
}
