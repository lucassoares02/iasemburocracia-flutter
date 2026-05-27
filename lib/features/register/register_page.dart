import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/utils/abstract_clip.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/features/register/companies_model.dart';
import 'package:portal_assoc/features/register/register_controller.dart';
import 'package:portal_assoc/features/register/register_model.dart';
import 'package:portal_assoc/features/register/register_repository.dart';
import 'package:portal_assoc/features/register/register_usecase.dart';
import 'package:portal_assoc/shared/extensions/context_screen_extension.dart';
import 'package:portal_assoc/shared/widgets/container_message.dart';
import 'package:portal_assoc/shared/widgets/custom_button.dart';
import 'package:portal_assoc/shared/widgets/custom_input.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/l10n/l10n_extension.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  RegisterController controller = RegisterController(StartState(), RegisterUseCase(RegisterRepository()));
  final _registerFormKey = GlobalKey<FormState>();
  final TextEditingController _nameCompany = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  bool _isVisiblePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int type = 0;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      int? savedStep = prefs.getInt('step');
      int? savedUserId = prefs.getInt('user_id');
      if (savedStep != null) {
        setState(() {
          controller.step = savedStep;
        });
      }
      if (savedUserId != null) {
        setState(() {
          controller.user = savedUserId;
        });
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_registerFormKey.currentState!.validate()) {
      await controller.create(RegisterModel.fromJson({
        "name": _name.text,
        "email": _email.text,
        "password": _password.text,
      }));
    }
  }

  Future<void> _registerCompany() async {
    CompaniesModel company = CompaniesModel.fromJson({
      "name": _nameCompany.text,
      "description": _description.text,
      "phone": _phone.text,
    });
    await controller.createCompany(company, type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.isDesktop;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background com gradiente animado
            _buildAnimatedBackground(colorScheme),

            // Padrão decorativo
            if (isDesktop) _buildDecorativePattern(colorScheme),

            // Conteúdo principal
            Center(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Card de Login
                        _buildLoginCard(context, theme, colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(ColorScheme colorScheme) {
    return Positioned(
      top: 0,
      left: 0,
      child: ClipPath(
        clipper: AbstractClipper(),
        child: Container(
          width: context.screenWidth * 0.6,
          height: context.screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomLeft,
              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativePattern(ColorScheme colorScheme) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _DecorativePatternPainter(
          color: colorScheme.primary.withValues(alpha: 0.03),
        ),
      ),
    );
  }

  Widget _buildLoginCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final maxH = context.screenHeight < 800 ? context.screenHeight * 0.70 : context.screenHeight * 0.75;
    final maxW = context.screenWidth < 1400 ? context.screenWidth * 0.80 : context.screenWidth * 0.65;

    final cardWidth = context.isDesktop
        ? context.screenWidth * 0.35
        : context.isTablet
            ? context.screenWidth * 0.5
            : context.screenWidth * 0.9;

    return Container(
      width: cardWidth.clamp(400.0, 550.0),
      constraints: const BoxConstraints(maxWidth: 550),
      margin: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 80,
            spreadRadius: 0,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Gradiente sutil no topo
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Conteúdo do formulário
            ValueListenableBuilder(
                valueListenable: controller.stateCreate,
                builder: (context, state, child) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.isDesktop ? 50 : 30,
                      vertical: context.isDesktop ? 60 : 40,
                    ),
                    child: AutofillGroup(
                      child: Form(
                        key: _registerFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo com efeito
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                                child: SvgPicture.asset(
                                  "assets/images/logo.svg",
                                  height: 50,
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),
                            ValueListenableBuilder(
                                valueListenable: controller.stateCreateCompany,
                                builder: (context, stateCreateCompany, child) {
                                  return stateCreateCompany is SuccessState
                                      ? Column(
                                          children: [
                                            ContainerMessage(color: Colors.green, title: "Cadastro realizado!", subtitle: "Cadastro realizado com sucesso, boas ${type == 1 ? 'compras' : 'vendas'}!"),
                                            const Spacing(),
                                            CustomButton(
                                                label: "Voltar ao login",
                                                onPressed: () {
                                                  context.go('/');
                                                })
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            controller.step == 2
                                                ? Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "Empresa",
                                                            style: AppTextStyles.title.copyWith(
                                                              fontSize: 20,
                                                              color: colorScheme.onSurface,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ],
                                                      ),
                                                      const Spacing(),
                                                      CustomInput(
                                                        validator: (value) {
                                                          if (value == null || value.isEmpty) {
                                                            return 'Nome necessário';
                                                          }
                                                          return null;
                                                        },
                                                        onEditingComplete: () {
                                                          FocusScope.of(context).nextFocus();
                                                        },
                                                        title: "Nome do seu negócio",
                                                        icon: LucideIcons.store,
                                                        hint: "Burguer Plus",
                                                        keyboardType: TextInputType.text,
                                                        controller: _nameCompany,
                                                        floatingLabel: false,
                                                      ),
                                                      const Spacing(),
                                                      CustomInput(
                                                        validator: (value) {
                                                          if (value == null || value.isEmpty) {
                                                            return 'Descrição necessária';
                                                          }
                                                          return null;
                                                        },
                                                        onEditingComplete: () {
                                                          FocusScope.of(context).nextFocus();
                                                        },
                                                        title: "Descrição",
                                                        icon: LucideIcons.fileText,
                                                        hint: "Negócio familiar de anos, buscando qualidade...",
                                                        keyboardType: TextInputType.text,
                                                        controller: _description,
                                                        floatingLabel: false,
                                                      ),
                                                      const Spacing(),
                                                      CustomInput(
                                                        onEditingComplete: () {
                                                          FocusScope.of(context).nextFocus();
                                                        },
                                                        title: "Telefone",
                                                        icon: LucideIcons.phone,
                                                        hint: "(27) 9 9999-9999",
                                                        keyboardType: TextInputType.number,
                                                        controller: _phone,
                                                        floatingLabel: false,
                                                        inputFormatters: [
                                                          MaskedInputFormatter('(##) # ####-####'),
                                                        ],
                                                      ),
                                                      const Spacing(),
                                                      ValueListenableBuilder(
                                                          valueListenable: controller.stateCreateCompany,
                                                          builder: (context, value, child) {
                                                            return CustomButton(
                                                              isLoading: value is LoadingState,
                                                              label: "Enviar",
                                                              icon: LucideIcons.check,
                                                              onPressed: () {
                                                                _registerCompany();
                                                              },
                                                            );
                                                          })
                                                    ],
                                                  )
                                                : Column(
                                                    children: [
                                                      Text(
                                                        "Cadastre-se",
                                                        style: AppTextStyles.title.copyWith(
                                                          fontSize: 28,
                                                          letterSpacing: -0.5,
                                                          color: colorScheme.onSurface,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),

                                                      const SizedBox(height: 8),

                                                      // Subtítulo
                                                      Text(
                                                        "Informe seus dados para criar sua conta",
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                                                          fontSize: 14,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),

                                                      const SizedBox(height: 40),

                                                      CustomInput(
                                                        validator: (value) {
                                                          if (value == null || value.isEmpty) {
                                                            return 'Nome obrigatório';
                                                          }
                                                          if (value.length < 2) {
                                                            return 'Nome deve ter no mínimo 2 caracteres';
                                                          }
                                                          return null;
                                                        },
                                                        onEditingComplete: () {
                                                          FocusScope.of(context).nextFocus();
                                                        },
                                                        autoFillHints: const [AutofillHints.name],
                                                        title: context.l10n.name,
                                                        icon: LucideIcons.user,
                                                        hint: "Marcos",
                                                        keyboardType: TextInputType.name,
                                                        controller: _name,
                                                        floatingLabel: true,
                                                      ),

                                                      const SizedBox(height: 20),

                                                      CustomInput(
                                                        validator: (value) {
                                                          if (value == null || value.isEmpty) {
                                                            return context.l10n.email_required;
                                                          }
                                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                                            return 'Digite um email válido';
                                                          }
                                                          return null;
                                                        },
                                                        autoFillHints: const [AutofillHints.email],
                                                        title: context.l10n.email,
                                                        icon: LucideIcons.mail,
                                                        hint: "seu@email.com",
                                                        keyboardType: TextInputType.emailAddress,
                                                        controller: _email,
                                                        floatingLabel: true,
                                                      ),

                                                      const SizedBox(height: 20),

                                                      // Campo de Senha
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            flex: 1,
                                                            child: CustomInput(
                                                              obscureText: _isVisiblePassword,
                                                              autoFillHints: const [AutofillHints.password],
                                                              title: context.l10n.password,
                                                              icon: LucideIcons.lock,
                                                              hint: "Digite sua senha",
                                                              keyboardType: TextInputType.visiblePassword,
                                                              floatingLabel: true,
                                                              validator: (value) {
                                                                if (value == null || value.isEmpty) {
                                                                  return 'Senha obrigatória';
                                                                }
                                                                if (value.length < 6) {
                                                                  return 'Senha deve ter no mínimo 6 caracteres';
                                                                }
                                                                return null;
                                                              },
                                                              suffixIcon: IconButton(
                                                                onPressed: () {
                                                                  setState(() {
                                                                    _isVisiblePassword = !_isVisiblePassword;
                                                                  });
                                                                },
                                                                icon: Icon(
                                                                  _isVisiblePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                                                                  size: 20,
                                                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                                                ),
                                                                tooltip: _isVisiblePassword ? 'Mostrar senha' : 'Ocultar senha',
                                                              ),
                                                              controller: _password,
                                                            ),
                                                          ),
                                                          const Spacing(),
                                                          Flexible(
                                                            flex: 1,
                                                            child: CustomInput(
                                                              obscureText: _isVisiblePassword,
                                                              autoFillHints: const [AutofillHints.password],
                                                              title: "Confirme a senha",
                                                              icon: LucideIcons.lock,
                                                              hint: "Confirme sua senha",
                                                              keyboardType: TextInputType.visiblePassword,
                                                              floatingLabel: true,
                                                              validator: (value) {
                                                                if (value == null || value.isEmpty) {
                                                                  return 'Senha obrigatória';
                                                                }
                                                                if (value != _password.text) {
                                                                  return 'As senhas não coincidem';
                                                                }
                                                                return null;
                                                              },
                                                              suffixIcon: IconButton(
                                                                onPressed: () {
                                                                  setState(() {
                                                                    _isVisiblePassword = !_isVisiblePassword;
                                                                  });
                                                                },
                                                                icon: Icon(
                                                                  _isVisiblePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                                                                  size: 20,
                                                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                                                ),
                                                                tooltip: _isVisiblePassword ? 'Mostrar senha' : 'Ocultar senha',
                                                              ),
                                                              controller: _confirmPassword,
                                                              textInputAction: TextInputAction.done,
                                                              onFieldSubmitted: (p0) async {
                                                                await _register();
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      const SizedBox(height: 24),

                                                      // Botão de Login
                                                      ValueListenableBuilder(
                                                        valueListenable: controller.stateCreate,
                                                        builder: (context, stateAuth, child) {
                                                          return AnimatedContainer(
                                                            duration: const Duration(milliseconds: 300),
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(12),
                                                              boxShadow: stateAuth is! LoadingState
                                                                  ? [
                                                                      BoxShadow(
                                                                        color: colorScheme.primary.withValues(alpha: 0.3),
                                                                        blurRadius: 20,
                                                                        offset: const Offset(0, 10),
                                                                      ),
                                                                    ]
                                                                  : null,
                                                            ),
                                                            child: CustomButton(
                                                              isLoading: stateAuth is LoadingState,
                                                              label: "Cadastrar",
                                                              icon: LucideIcons.userCheck2,
                                                              onPressed: () {
                                                                _register();
                                                              },
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                          ],
                                        );
                                }),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () {
                                context.go('/');
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Já possuí conta? Faça login"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: colorScheme.outline.withValues(alpha: 0.2),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "Acesso seguro",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: colorScheme.outline.withValues(alpha: 0.2),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Footer info
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.shield,
                                    size: 14,
                                    color: colorScheme.primary.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Seus dados estão protegidos",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }
}

// Painter para criar padrão decorativo no fundo
class _DecorativePatternPainter extends CustomPainter {
  final Color color;

  _DecorativePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Desenha círculos decorativos
    const radius1 = 300.0;
    const radius2 = 450.0;

    // Canto superior direito
    canvas.drawCircle(
      Offset(size.width + 100, -100),
      radius1,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width + 100, -100),
      radius2,
      paint,
    );

    // Canto inferior esquerdo
    canvas.drawCircle(
      Offset(-100, size.height + 100),
      radius1,
      paint,
    );
    canvas.drawCircle(
      Offset(-100, size.height + 100),
      radius2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
