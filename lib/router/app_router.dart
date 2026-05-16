import 'package:go_router/go_router.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/features/account/account_page.dart';
import 'package:portal_assoc/features/app/app_page.dart';
import 'package:portal_assoc/features/auth/presentation/auth_page.dart';
import 'package:portal_assoc/features/companies/companies_page.dart';
import 'package:portal_assoc/features/home/home_page.dart';
import 'package:portal_assoc/features/payment_methods/payment_methods_page.dart';
import 'package:portal_assoc/features/register/register_page.dart';

GoRouter appRouter(AuthProvider authProvider) {
  const Set<String> publicRoutes = {
    '/',
    '/register',
  };

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final isLoggingIn = state.fullPath == '/';

      // permite acesso se o caminho começar com qualquer rota pública
      final isPublic = publicRoutes.any((r) => state.fullPath?.startsWith(r) ?? false);

      if (!loggedIn && !isPublic) return '/';
      if (loggedIn && isLoggingIn) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/', name: 'login', builder: (context, state) => const AuthPage()),
      GoRoute(
        name: "register",
        path: '/register',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: RegisterPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppPage(child: child),
        routes: [
          GoRoute(
            name: "home",
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            name: "account",
            path: '/account',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountPage(),
            ),
          ),
          GoRoute(
            name: "business-settings",
            path: '/business-settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CompaniesPage(),
            ),
          ),
          GoRoute(
            name: "payment-methods",
            path: '/payment-methods',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PaymentMethodsPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
