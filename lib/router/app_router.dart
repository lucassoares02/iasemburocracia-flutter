import 'package:go_router/go_router.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/features/account/account_page.dart';
import 'package:portal_assoc/features/app/app_page.dart';
import 'package:portal_assoc/features/auth/presentation/auth_page.dart';
import 'package:portal_assoc/features/companies/companies_page.dart';
import 'package:portal_assoc/features/customers/customers_page.dart';
import 'package:portal_assoc/features/home/home_page.dart';
import 'package:portal_assoc/features/orders/orders_page.dart';
import 'package:portal_assoc/features/payment_methods/payment_methods_page.dart';
import 'package:portal_assoc/features/public_order/public_order_page.dart';
import 'package:portal_assoc/features/register/register_page.dart';

GoRouter appRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final path = state.uri.path;

      // Rotas sempre públicas — nunca redirecionar, independente do login
      if (path == '/order' || path == '/register') return null;

      // Não logado fora da tela de login → login
      if (!loggedIn && path != '/') return '/';

      // Logado na tela de login → sempre para o Dashboard (home gerencia o wizard)
      if (loggedIn && path == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
          path: '/', name: 'login', builder: (_, __) => const AuthPage()),
      GoRoute(
        name: 'order',
        path: '/order',
        builder: (context, state) => PublicOrderPage(
          company: state.uri.queryParameters['company'],
          phone: state.uri.queryParameters['phone'],
        ),
      ),
      GoRoute(
        name: 'register',
        path: '/register',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: RegisterPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppPage(child: child),
        routes: [
          GoRoute(
            name: 'home',
            path: '/home',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            name: 'account',
            path: '/account',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AccountPage()),
          ),
          GoRoute(
            name: 'business-settings',
            path: '/business-settings',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CompaniesPage()),
          ),
          GoRoute(
            name: 'payment-methods',
            path: '/payment-methods',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: PaymentMethodsPage()),
          ),
          GoRoute(
            name: 'orders',
            path: '/orders',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: OrdersPage()),
          ),
          GoRoute(
            name: 'customers',
            path: '/customers',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CustomersPage()),
          ),
        ],
      ),
    ],
  );
}
