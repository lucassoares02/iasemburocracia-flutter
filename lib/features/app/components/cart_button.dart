import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/utils/format_currency.dart';

class CartButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback? onPressed;
  final double value;

  const CartButton({
    Key? key,
    required this.itemCount,
    required this.value,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNotEmpty = itemCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onPressed?.call();
          if (onPressed == null) context.go("/orders");
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isNotEmpty ? theme.colorScheme.primary : theme.colorScheme.background,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(theme, isNotEmpty),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: isNotEmpty
                    ? Row(
                        children: [
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAnimatedCounter(theme),
                              // Text(
                              //   itemCount == 1 ? "item" : "itens",
                              //   style: TextStyle(
                              //     fontSize: 10,
                              //     letterSpacing: 0.5,
                              //     color: theme.colorScheme.onPrimary.withOpacity(0.8),
                              // ,
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, bool isNotEmpty) {
    return Icon(
      isNotEmpty ? LucideIcons.shoppingCart : LucideIcons.shoppingCart,
      color: isNotEmpty ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
      size: 20,
    );
  }

  Widget _buildAnimatedCounter(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Slide vertical profissional: o número antigo sobe e o novo entra por baixo
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.4),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatCurrency(value),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          // Text(
          //   itemCount.toString(),
          //   key: ValueKey<int>(itemCount),
          //   style: TextStyle(
          //     color: theme.colorScheme.onPrimary,
          //     fontSize: 10,
          //   ),
          // ),
        ],
      ),
    );
  }
}
