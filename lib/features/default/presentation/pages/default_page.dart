import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/default/data/default_repository.dart';
import 'package:portal_assoc/features/default/presentation/controllers/default_controller.dart';

class DefaultPage extends StatefulWidget {
  const DefaultPage({super.key});

  @override
  State<DefaultPage> createState() => _DefaultPageState();
}

class _DefaultPageState extends State<DefaultPage> with TickerProviderStateMixin {
  DefaultController defaultController = DefaultController(StartState(), DefaultRepository());

  @override
  void initState() {
    defaultController.defaultGetItems();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: AppSpacing.mediumPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Default Page", style: AppTextStyles.title),
            ],
          ),
        ),
      ),
    );
  }
}
