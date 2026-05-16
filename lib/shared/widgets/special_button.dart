import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/core/state/app_state.dart';

class SpecialButton extends StatefulWidget {
  SpecialButton({
    super.key,
    this.state,
    required this.label,
    this.type = 0,
    this.color,
    this.width,
    this.icon,
    required this.onPressButton,
    this.loading = false,
    this.error = false,
    this.textSucess,
  });

  final String label;
  final int? type;
  final IconData? icon;
  final Color? color;
  final Function()? onPressButton;
  final bool loading;
  final bool error;
  StateApp? state;
  String? textSucess;
  double? width;

  @override
  State<SpecialButton> createState() => _SpecialButtonState();
}

class _SpecialButtonState extends State<SpecialButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.state is SuccessState) {
      Timer(const Duration(seconds: 2), () {
        widget.state = StartState();

        (context as Element).markNeedsBuild();
      });
    }
    return widget.state is SuccessState
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: widget.type == 1 ? Colors.white : Colors.green,
              borderRadius: AppRadius.small,
              border: Border.all(color: widget.type == 1 ? Colors.green : Colors.white),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon != null
                    ? Icon(
                        LucideIcons.check,
                        color: widget.type == 1 ? Colors.green : Colors.white,
                        size: 16,
                      )
                    : Container(),
                const SizedBox(width: 3),
                Text(
                  widget.textSucess ?? "Sucesso",
                  style: TextStyle(color: widget.type == 1 ? Colors.green : Colors.white),
                ),
              ],
            ),
          )
        : widget.state is ErrorState
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: AppRadius.small,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.icon != null
                        ? const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : Container(),
                    const SizedBox(width: 3),
                    const Text(
                      "Algo deu errado",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : widget.type == 1
                ? InkWell(
                    borderRadius: AppRadius.small,
                    hoverColor: widget.color != null ? widget.color!.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.2),
                    onTap: !widget.loading ? widget.onPressButton : null,
                    child: Container(
                      padding: const EdgeInsets.only(left: 12, right: 18, top: 6, bottom: 6),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.small,
                        border: Border.all(color: widget.color ?? Colors.grey.withValues(alpha: 0.6), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.loading
                              ? Container(
                                  margin: const EdgeInsets.only(right: 5),
                                  height: 12,
                                  width: 12,
                                  child: CircularProgressIndicator(
                                    color: widget.color ?? Colors.black87,
                                    strokeWidth: 2,
                                  ),
                                )
                              : widget.icon != null
                                  ? Icon(
                                      widget.icon,
                                      color: widget.color ?? Colors.black87,
                                      size: 16,
                                    )
                                  : Container(),
                          const SizedBox(width: 3),
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: widget.color ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : widget.type == 2
                    ? InkWell(
                        borderRadius: AppRadius.small,
                        hoverColor: widget.color!.withValues(alpha: 0.3),
                        radius: AppRadius.small.bottomLeft.x,
                        onTap: !widget.loading ? widget.onPressButton : null,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 18, top: 8, bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null)
                                Icon(
                                  widget.icon,
                                  color: widget.color,
                                  size: 16,
                                ),
                              const SizedBox(width: 3),
                              Text(
                                widget.label,
                                style: TextStyle(color: widget.color),
                              ),
                            ],
                          ),
                        ),
                      )
                    : MouseRegion(
                        onEnter: (event) {
                          setState(() {
                            isHovered = true;
                          });
                        },
                        onExit: (event) {
                          setState(() {
                            isHovered = false;
                          });
                        },
                        child: InkWell(
                          borderRadius: AppRadius.small,
                          onTap: !widget.loading ? widget.onPressButton : null,
                          child: Container(
                            padding: const EdgeInsets.only(left: 12, right: 18, top: 8, bottom: 8),
                            decoration: BoxDecoration(
                              color: isHovered || widget.loading ? widget.color!.withValues(alpha: 0.7) : widget.color,
                              borderRadius: AppRadius.small,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                widget.loading
                                    ? Container(
                                        margin: const EdgeInsets.only(right: 5),
                                        height: 12,
                                        width: 12,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        widget.icon,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.label,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
  }
}
