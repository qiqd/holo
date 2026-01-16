import 'package:flutter/material.dart';

class LoadingOrShowMsg extends StatelessWidget {
  final String? msg;
  final String? subMsg;
  final Color backgroundColor;
  final Function()? onMsgTab;
  const LoadingOrShowMsg({
    super.key,
    this.msg,
    this.subMsg,
    this.backgroundColor = Colors.transparent,
    this.onMsgTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: msg == null || msg!.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  if (subMsg != null && subMsg!.isNotEmpty)
                    Text(
                      subMsg!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                ],
              )
            : TextButton(onPressed: () => onMsgTab?.call(), child: Text(msg!)),
      ),
    );
  }
}
