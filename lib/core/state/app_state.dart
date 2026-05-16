import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

abstract class StateApp<T> {
  const StateApp();
}

class StartState<T> extends StateApp<T> {}

class LoadingState<T> extends StateApp<T> {}

class SuccessState<T> extends StateApp<T> {
  final T data;
  final String? message;
  final String? description;

  SuccessState(this.data, {this.message, this.description}) {
    if (message != null && message!.isNotEmpty) {
      _showToast(message!, description: description);
    }
  }

  void _showToast(String message, {String? description}) {
    toastification.show(
      animationDuration: const Duration(milliseconds: 300),
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(message),
      description: description != null ? Text(description) : null,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}

class ErrorState<T> extends StateApp<T> {
  final String message;
  ErrorState(this.message);
}
