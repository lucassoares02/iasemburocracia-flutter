import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/onboarding_provider.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/core/utils/format_date.dart';
import 'package:portal_assoc/core/utils/invert_date_format.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/features/account/account_controller.dart';
import 'package:portal_assoc/features/account/account_model.dart';
import 'package:portal_assoc/features/account/widgets/base_account.dart';
import 'package:portal_assoc/shared/widgets/custom_input.dart';
import 'package:portal_assoc/shared/widgets/loading_container.dart';
import 'package:provider/provider.dart';

class AccountInformation extends StatefulWidget {
  const AccountInformation({super.key, required this.controller});

  final AccountController controller;

  @override
  State<AccountInformation> createState() => _AccountInformationState();
}

class _AccountInformationState extends State<AccountInformation> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _documentController;
  late TextEditingController _birthdayController;

  AccountModel? _currentAccount;

  @override
  void initState() {
    widget.controller.find();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _documentController = TextEditingController();
    _birthdayController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _initializeControllers(AccountModel account) {
    _currentAccount = account;
    _nameController.text = account.name ?? '';
    _emailController.text = account.email ?? '';
    _phoneController.text = account.phone ?? '';
    _documentController.text = account.document ?? '';
    _birthdayController.text = formatDate(account.birthday);
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing && _currentAccount != null) {
        _initializeControllers(_currentAccount!);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedAccount = AccountModel.fromJson({
        "id": _currentAccount?.id,
        "name": _nameController.text,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "document": _documentController.text,
        "birthday": invertDateFormat(_birthdayController.text),
        "createdAt": _currentAccount?.createdAt,
        "active": _currentAccount?.active,
      });

      await widget.controller.update(updatedAccount);
      if (!mounted) return;
      context.read<OnboardingProvider>().refresh(silent: true);
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseAccount(
      title: "Informações da conta",
      child: Expanded(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: widget.controller.stateFind,
                builder: (context, state, _) {
                  if (state is LoadingState) {
                    return _buildLoadingSkeleton();
                  } else if (state is ErrorState) {
                    return _buildErrorState(state.message);
                  } else if (state is SuccessState) {
                    AccountModel account = state.data;
                    if (_currentAccount == null || !_isEditing) {
                      _initializeControllers(account);
                    }
                    return _buildAccountContent(account);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoadingContainer(height: 80, width: 80, borderRadius: BorderRadius.all(Radius.circular(100))),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingContainer(height: 24, width: 200),
                    SizedBox(height: 8),
                    LoadingContainer(
                      height: 16,
                      width: 150,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          LoadingContainer(height: 100, width: double.infinity),
          SizedBox(height: 16),
          LoadingContainer(height: 100, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              "Erro ao carregar informações",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => widget.controller.find(),
              icon: const Icon(Icons.refresh),
              label: const Text("Tentar novamente"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountContent(AccountModel account) {
    return Column(
      children: [
        // Conteúdo scrollável
        Expanded(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com avatar e informações principais
                    _buildAccountHeader(account),

                    const Spacing(),
                    Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                    const Spacing(),

                    // Seções de informações organizadas
                    _buildInfoSection(
                      title: "Informações pessoais",
                      children: [
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: "Nome completo",
                          value: account.name ?? "Não informado",
                          controller: _nameController,
                          isEditable: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nome é obrigatório';
                            }
                            return null;
                          },
                        ),
                        _buildInfoRow(
                          icon: Icons.cake_outlined,
                          label: "Data de nascimento",
                          value: formatDate(account.birthday),
                          controller: _birthdayController,
                          isEditable: true,
                          inputFormatters: [
                            MaskedInputFormatter(
                              '##/##/####',
                              allowedCharMatcher: RegExp(r'[0-9]'),
                            ),
                          ],
                          keyboardType: TextInputType.datetime,
                        ),
                        _buildInfoRow(
                          icon: Icons.description_outlined,
                          label: "Documento (CPF)",
                          value: _formatDocument(account.document) ?? "Não informado",
                          controller: _documentController,
                          isEditable: true,
                          inputFormatters: [
                            MaskedInputFormatter(
                              '###.###.###-##',
                              allowedCharMatcher: RegExp(r'[0-9]'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildInfoSection(
                      title: "Contato",
                      children: [
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: "E-mail",
                          value: account.email ?? "Não informado",
                          controller: _emailController,
                          isEditable: true,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'E-mail é obrigatório';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: "Telefone",
                          value: _formatPhone(account.phone) ?? "Não informado",
                          controller: _phoneController,
                          isEditable: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            MaskedInputFormatter(
                              '(##) #####-####',
                              allowedCharMatcher: RegExp(r'[0-9]'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildInfoSection(
                      title: "Conta",
                      children: [
                        _buildInfoRow(
                          icon: Icons.tag_outlined,
                          label: "ID da conta",
                          value: account.id?.toString() ?? "Não informado",
                          isEditable: false,
                        ),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: "Membro desde",
                          value: formatDate(account.createdAt),
                          isEditable: false,
                        ),
                        _buildInfoRowWithCustomValue(
                          icon: Icons.verified_outlined,
                          label: "Status",
                          customValue: _buildStatusBadge(account.active ?? false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountHeader(AccountModel account) {
    return Row(
      children: [
        // Avatar com iniciais
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Text(
              _getInitials(account.name ?? ""),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Informações principais
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    account.name ?? "Nome não disponível",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(),
                  ),
                  Row(
                    children: [
                      if (_isEditing) ...[
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                          ),
                          onPressed: _toggleEditMode,
                          child: const Text("Cancelar"),
                        ),
                        const Spacing(),
                      ],
                      TextButton.icon(
                        onPressed: _isEditing ? _saveChanges : _toggleEditMode,
                        label: Text(_isEditing ? "Salvar" : "Editar"),
                        icon: Icon(_isEditing ? LucideIcons.check : LucideIcons.edit2),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      account.email ?? "Email não disponível",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(account.active ?? false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[800],
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: _intersperse(
              children,
              Divider(height: 1, color: Colors.grey[200]),
            ).toList(),
          ),
        ),
      ],
    );
  }

  List<Widget> _intersperse(List<Widget> list, Widget separator) {
    if (list.isEmpty) return list;

    final result = <Widget>[];
    for (var i = 0; i < list.length; i++) {
      result.add(list[i]);
      if (i < list.length - 1) {
        result.add(separator);
      }
    }
    return result;
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isEditable = false,
    List<TextInputFormatter>? inputFormatters,
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                if (_isEditing && isEditable && controller != null)
                  CustomInput(
                    controller: controller,
                    keyboardType: keyboardType,
                    validator: validator,
                    inputFormatters: inputFormatters,
                  )
                else
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithCustomValue({
    required IconData icon,
    required String label,
    required Widget customValue,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                customValue,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? "Ativa" : "Inativa",
            style: TextStyle(
              color: isActive ? Colors.green[700] : Colors.red[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    List<String> parts = name.trim().split(" ");
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return "${parts[0][0]}${parts[parts.length - 1][0]}".toUpperCase();
  }

  String? _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return null;
    // Implementar formatação de telefone conforme necessidade
    return phone;
  }

  String? _formatDocument(String? document) {
    if (document == null || document.isEmpty) return null;
    // Implementar formatação de documento (CPF/CNPJ) conforme necessidade
    return document;
  }
}
