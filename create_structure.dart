import 'dart:io';

import 'package:flutter/material.dart';

final folders = [
  'lib/core/config',
  'lib/core/constants',
  'lib/core/utils',
  'lib/core/services',
  'lib/core/exceptions',
  //
  'lib/shared/widgets',
  'lib/shared/extensions',
  'lib/shared/themes',
  //
  'lib/features/auth/data/models',
  'lib/features/auth/data/datasources',
  'lib/features/auth/data/repositories',
  'lib/features/auth/domain/entities',
  'lib/features/auth/domain/repositories',
  'lib/features/auth/domain/usecases',
  'lib/features/auth/presentation/pages',
  'lib/features/auth/presentation/blocs',
  'lib/features/auth/presentation/widgets',
  //
  'lib/features/home/data/models',
  'lib/features/home/data/datasources',
  'lib/features/home/data/repositories',
  'lib/features/home/domain/entities',
  'lib/features/home/domain/repositories',
  'lib/features/home/domain/usecases',
  'lib/features/home/presentation/pages',
  'lib/features/home/presentation/blocs',
  'lib/features/home/presentation/widgets',
];

final filesWithContent = {
  'lib/features/auth/presentation/pages/auth_page.dart': '''
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Auth Page')),
    );
  }
}
''',
  'lib/features/auth/domain/repositories/auth_repository.dart': '''
abstract class AuthRepository {
  Future<bool> login(String email, String password);
}
''',
  'lib/features/auth/domain/usecases/auth_usecase.dart': '''
import '../repositories/auth_repository.dart';

class AuthUseCase {
  final AuthRepository repository;

  AuthUseCase(this.repository);

  Future<bool> call(String email, String password) {
    return repository.login(email, password);
  }
}
''',
  'lib/features/auth/data/models/auth_model.dart': '''
class AuthModel {
  final String email;
  final String password;

  AuthModel({required this.email, required this.password});
}
''',
  'lib/features/auth/domain/entities/auth_entity.dart': '''
class AuthEntity {
  final String email;

  AuthEntity(this.email);
}
''',
  'lib/shared/widgets/custom_button.dart': '''
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const CustomButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
''',
};

void main() {
  // Criação das pastas
  for (var folder in folders) {
    final directory = Directory(folder);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      debugPrint('✅ Pasta criada: $folder');
    } else {
      debugPrint('ℹ️ Pasta já existia: $folder');
    }
  }

  // Criação dos arquivos
  filesWithContent.forEach((path, content) {
    final file = File(path);
    if (!file.existsSync()) {
      file.writeAsStringSync(content);
      debugPrint('📄 Arquivo criado: $path');
    } else {
      debugPrint('⚠️ Arquivo já existia: $path');
    }
  });

  debugPrint('\n🚀 Estrutura com arquivos criada com sucesso!');
}
