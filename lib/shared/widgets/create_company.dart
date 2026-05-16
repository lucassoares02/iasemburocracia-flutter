import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/features/register/companies_model.dart';
import 'package:portal_assoc/features/register/register_controller.dart';
import 'package:portal_assoc/features/register/register_repository.dart';
import 'package:portal_assoc/features/register/register_usecase.dart';
import 'package:portal_assoc/shared/widgets/card_company.dart';
import 'package:portal_assoc/shared/widgets/container_message.dart';
import 'package:portal_assoc/shared/widgets/custom_button.dart';
import 'package:portal_assoc/shared/widgets/custom_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateCompany extends StatefulWidget {
  const CreateCompany({super.key, required this.type});

  final int? type;

  @override
  State<CreateCompany> createState() => _CreateCompanyState();
}

class _CreateCompanyState extends State<CreateCompany> {
  final TextEditingController _cnpj = TextEditingController();
  RegisterController controller = RegisterController(StartState(), RegisterUseCase(RegisterRepository()));

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    controller.user = prefs.getInt('user_id');
  }

  Future<void> _getCnpj() async {
    if (_cnpj.text.isNotEmpty && _cnpj.text.length == 18) {
      String cnpj = _cnpj.text.replaceAll(RegExp(r'[^0-9]'), '');
      await controller.find(cnpj);
    }
  }

  Future<void> _registerCompany(CompaniesModel company) async {
    await controller.createCompany(company, widget.type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Text(
              "Empresa",
              style: AppTextStyles.title.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const Spacing(),
        CustomInput(
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 18) {
              return 'CPNJ inválido';
            }
            return null;
          },
          onChanged: (value) {
            if (value.length == 18) {
              _getCnpj();
            }
          },
          onEditingComplete: () {
            FocusScope.of(context).nextFocus();
          },
          title: "Informe seu CNPJs",
          icon: widget.type == 1 ? LucideIcons.shoppingCart : LucideIcons.store,
          hint: "12.345.678/0001-90",
          keyboardType: TextInputType.number,
          controller: _cnpj,
          inputFormatters: [
            MaskedInputFormatter(
              '##.###.###/####-##',
              allowedCharMatcher: RegExp(r'[0-9]'),
            ),
          ],
          floatingLabel: false,
        ),
        const Spacing(),
        ValueListenableBuilder(
          valueListenable: controller.stateFind,
          builder: (context, stateFind, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (stateFind is ErrorState) const ContainerMessage(color: Colors.red, title: "CNPJ não encontrado!", subtitle: "Não conseguimos localizar o CPNJ informado."),
                  if (stateFind is SuccessState) ...[
                    Column(
                      children: [
                        CardCompany(
                          icon: widget.type == 1 ? LucideIcons.shoppingCart : LucideIcons.store,
                          cep: stateFind.data.cep,
                          cnpj: _cnpj.text,
                          razaoSocial: stateFind.data.razaoSocial,
                          nomeFantasia: stateFind.data.nomeFantasia,
                          bairro: stateFind.data.bairro,
                          logradouro: stateFind.data.logradouro,
                          numero: stateFind.data.numero,
                          municipio: stateFind.data.municipio,
                          uf: stateFind.data.uf,
                        ),
                        const Spacing(),
                      ],
                    ),
                    const Spacing(),
                  ],
                  if (stateFind is SuccessState && widget.type != 0)
                    ValueListenableBuilder(
                        valueListenable: controller.stateCreateCompany,
                        builder: (context, stateCreate, child) {
                          return CustomButton(
                            isLoading: stateCreate is LoadingState,
                            label: "Enviar",
                            icon: LucideIcons.check,
                            onPressed: () {
                              _registerCompany(stateFind.data);
                            },
                          );
                        }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
