import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/features/auth/data/user_model.dart';
import 'package:portal_assoc/features/auth/presentation/auth_controller.dart';
import 'package:portal_assoc/shared/extensions/context_screen_extension.dart';
import 'package:portal_assoc/shared/widgets/custom_button.dart';
import 'package:portal_assoc/shared/widgets/custom_input.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/l10n/l10n_extension.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({
    super.key,
    required this.actionForgotPassword,
    required this.authController,
  });

  final void Function() actionForgotPassword;
  final AuthController authController;

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isVisiblePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configuração das animações
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

    widget.authController.stateLogin.addListener(() {
      final state = widget.authController.stateLogin.value;

      if (state is SuccessState<UserModel>) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setAccessToken(widget.authController.user!);
        context.go("/home");
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    if (_loginFormKey.currentState!.validate()) {
      await widget.authController.login(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.isDesktop;

    return Stack(
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
    );
  }

  Widget _buildAnimatedBackground(ColorScheme colorScheme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.secondary.withValues(alpha: 0.03),
              colorScheme.tertiary.withValues(alpha: 0.05),
            ],
            stops: const [0.0, 0.5, 1.0],
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
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.isDesktop ? 50 : 30,
                vertical: context.isDesktop ? 60 : 40,
              ),
              child: AutofillGroup(
                child: Form(
                  key: _loginFormKey,
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
                            height: 80,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Título
                      Text(
                        "${context.l10n.hello}, ${context.l10n.welcome}",
                        style: AppTextStyles.title.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Subtítulo
                      Text(
                        "Entre com suas credenciais para continuar",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Campo de Email
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
                        onEditingComplete: () {
                          FocusScope.of(context).nextFocus();
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
                      CustomInput(
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
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (p0) async {
                          await _login(context);
                        },
                      ),

                      const SizedBox(height: 12),

                      // Esqueceu a senha
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.actionForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            context.l10n.forgot_password,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botão de Login
                      ValueListenableBuilder(
                        valueListenable: widget.authController.stateLogin,
                        builder: (context, stateAuth, child) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CustomButton(
                              isLoading: stateAuth is LoadingState,
                              label: context.l10n.login,
                              icon: LucideIcons.logIn,
                              onPressed: () {
                                _login(context);
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          context.go('/register');
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Não possui cadastro?"),
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
            ),
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
