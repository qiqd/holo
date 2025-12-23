import 'package:flutter/material.dart';

class LoadingOrShowMsg extends StatelessWidget {
  final String? msg;
  final Color backgroundColor;
  const LoadingOrShowMsg({
    super.key,
    this.msg,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: msg == null || msg!.isEmpty
            ? const CircularProgressIndicator()
            : Text(msg!),
      ),
    );
  }
}
