import 'package:flutter/material.dart';
import 'package:portal_assoc/features/payment_methods/payment_methods_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/state/app_state.dart';
import 'payment_methods_controller.dart';
import 'payment_methods_repository.dart';
import 'payment_methods_usecase.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  late final PaymentMethodsController controller = PaymentMethodsController(
    StartState(),
    PaymentMethodsUseCase(PaymentMethodsRepository()),
  );

  final TextEditingController _searchController = TextEditingController();
  List<PaymentMethodsModel> _activePaymentMethods = [];
  List<Map<String, dynamic>> _filteredAvailableMethods = [];

  final List<Map<String, dynamic>> _availablePaymentMethods = [
    {
      'type': 'credit_card',
      'label': 'Cartão de Crédito',
      'description': 'Aceite pagamentos com cartões de crédito das principais bandeiras',
      'icon': Icons.credit_card,
      'color': Color(0xFF2196F3),
    },
    {
      'type': 'debit_card',
      'label': 'Cartão de Débito',
      'description': 'Pagamentos instantâneos com cartão de débito',
      'icon': Icons.payment,
      'color': Color(0xFF4CAF50),
    },
    {
      'type': 'pix',
      'label': 'PIX',
      'description': 'Transferências instantâneas via PIX, disponível 24/7',
      'icon': Icons.pix,
      'color': Color(0xFF00BCD4),
    },
    {
      'type': 'cash',
      'label': 'Dinheiro',
      'description': 'Pagamento em espécie na entrega ou retirada',
      'icon': Icons.money,
      'color': Color(0xFF4CAF50),
    },
    {
      'type': 'voucher',
      'label': 'Vale Refeição',
      'description': 'Aceite vouchers e vales alimentação',
      'icon': Icons.card_giftcard,
      'color': Color(0xFFFF9800),
    },
    {
      'type': 'bank_transfer',
      'label': 'Transferência Bancária',
      'description': 'Transferência bancária tradicional (TED/DOC)',
      'icon': Icons.account_balance,
      'color': Color(0xFF9C27B0),
    },
    {
      'type': 'digital_wallet',
      'label': 'Carteira Digital',
      'description': 'Pagamentos via carteiras digitais como PicPay, Mercado Pago',
      'icon': Icons.wallet,
      'color': Color(0xFFE91E63),
    },
    {
      'type': 'paypal',
      'label': 'PayPal',
      'description': 'Aceite pagamentos internacionais via PayPal',
      'icon': Icons.payments_outlined,
      'color': Color(0xFF003087),
    },
    {
      'type': 'boleto',
      'label': 'Boleto Bancário',
      'description': 'Gere boletos para pagamento em bancos e lotéricas',
      'icon': Icons.receipt_long,
      'color': Color(0xFFFF5722),
    },
    {
      'type': 'apple_pay',
      'label': 'Apple Pay',
      'description': 'Pagamentos rápidos e seguros para usuários Apple',
      'icon': Icons.apple,
      'color': Color(0xFF000000),
    },
    {
      'type': 'google_pay',
      'label': 'Google Pay',
      'description': 'Pagamentos integrados com Google Pay',
      'icon': Icons.g_mobiledata,
      'color': Color(0xFF4285F4),
    },
    {
      'type': 'cryptocurrency',
      'label': 'Criptomoedas',
      'description': 'Aceite Bitcoin, Ethereum e outras criptomoedas',
      'icon': Icons.currency_bitcoin,
      'color': Color(0xFFF7931A),
    },
  ];

  @override
  void initState() {
    super.initState();
    controller.findAll();
    _filteredAvailableMethods = List.from(_availablePaymentMethods);
    _searchController.addListener(_filterMethods);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMethods() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredAvailableMethods = List.from(_availablePaymentMethods);
      } else {
        _filteredAvailableMethods = _availablePaymentMethods.where((method) {
          final label = method['label'].toString().toLowerCase();
          final description = method['description'].toString().toLowerCase();
          return label.contains(query) || description.contains(query);
        }).toList();
      }
    });
  }

  bool _isMethodActive(String type) {
    return _activePaymentMethods.any((method) => method.type == type);
  }

  PaymentMethodsModel? _getActiveMethod(String type) {
    try {
      return _activePaymentMethods.firstWhere((method) => method.type == type);
    } catch (e) {
      return null;
    }
  }

  void _togglePaymentMethod(Map<String, dynamic> method) async {
    final type = method['type'] as String;
    final activeMethod = _getActiveMethod(type);

    if (activeMethod != null) {
      // Desativar método
      controller.delete(activeMethod.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.remove_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${method['label']} removido'),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      int? company = prefs.getInt('company') ?? 0;
      final newMethod = PaymentMethodsModel.fromJson({
        'company_id': company,
        'type': type,
        'label': method['label'] as String,
        'description': method['description'] as String,
        'active': true,
      });
      controller.create(newMethod, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Métodos de Pagamento',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ValueListenableBuilder<StateApp>(
                            valueListenable: controller.stateFindAll,
                            builder: (context, state, _) {
                              if (state is SuccessState) {
                                final activeCount = (state.data as List<PaymentMethodsModel>).where((m) => m.active == true).length;
                                return Text(
                                  '$activeCount ${activeCount == 1 ? 'método ativo' : 'métodos ativos'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }
                              return const Text(
                                'Selecione as formas de pagamento aceitas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar método de pagamento...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Expanded(
            child: ValueListenableBuilder<StateApp>(
              valueListenable: controller.stateFindAll,
              builder: (context, state, _) {
                if (state is StartState || state is LoadingState) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is SuccessState) {
                  _activePaymentMethods = state.data as List<PaymentMethodsModel>;

                  if (_filteredAvailableMethods.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum método encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente ajustar sua pesquisa',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calcula quantos cards cabem por linha baseado na largura disponível
                        final cardWidth = 280.0;
                        final spacing = 16.0;
                        final crossAxisCount = (constraints.maxWidth / (cardWidth + spacing)).floor().clamp(1, 4);

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: _filteredAvailableMethods.map((method) {
                            final isActive = _isMethodActive(method['type'] as String);

                            return SizedBox(
                              width: (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount,
                              child: _PaymentMethodCard(
                                method: method,
                                isActive: isActive,
                                onToggle: () => _togglePaymentMethod(method),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  );
                } else if (state is ErrorState) {
                  return Center(
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
                          'Erro ao carregar métodos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => controller.findAll(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final Map<String, dynamic> method;
  final bool isActive;
  final VoidCallback onToggle;

  const _PaymentMethodCard({
    required this.method,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = method['color'] as Color;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    method['icon'] as IconData,
                    color: isActive ? color : Colors.grey,
                    size: 28,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? color : Colors.grey.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isActive ? Icons.check : Icons.add,
                    color: isActive ? color : Colors.grey,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              method['label'] as String,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black87 : Colors.grey[600],
              ),
            ),
            // const SizedBox(height: 8),
            // Text(
            //   method['description'] as String,
            //   style: TextStyle(
            //     fontSize: 13,
            //     color: isActive ? Colors.grey[600] : Colors.grey[500],
            //     height: 1.4,
            //   ),
            //   maxLines: 3,
            //   overflow: TextOverflow.ellipsis,
            // ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isActive ? 'Ativo' : 'Inativo',
                    style: TextStyle(
                      color: isActive ? Colors.green[700] : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
