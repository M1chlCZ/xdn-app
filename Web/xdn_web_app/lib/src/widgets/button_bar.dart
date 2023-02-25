import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xdn_web_app/src/support/qr_dialog.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';
import 'package:xdn_web_app/src/widgets/send_overlay.dart';

class ButtonBarWidget extends ConsumerWidget {
  final void Function(String address, double amount) onSend;
  const ButtonBarWidget({
    super.key, required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final bool isBig = width > 600;
    return AnimatedContainer(
      width: isBig ? 580 : width * 0.90,
      height: height * 0.06,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastLinearToSlowEaseIn,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: FlatCustomButton(
                getHover: (val) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AutoSizeText("Receive",
                        maxLines: 1,
                        minFontSize: 8.0,
                        style: Theme.of(context).textTheme.displayLarge!.copyWith(color: val ? Colors.white : Colors.white70, fontWeight: FontWeight.w800)),
                  );
                },
                onTap: () {
                  QRDialog.openUserQR(context, {});
                },
                radius: 8.0,
                splashColor: Colors.black.withOpacity(0.4),
                color: const Color(0xFF395198),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: FlatCustomButton(
                getHover: (val) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AutoSizeText("Send",
                        maxLines: 1,
                        minFontSize: 8.0,
                        style: Theme.of(context).textTheme.displayLarge!.copyWith(color: val ? Colors.white : Colors.white70, fontWeight: FontWeight.w800)),
                  );
                },
                onTap: () {
                        Navigator.of(context).push(SendOverlay(onSend: (String address, double amount) {onSend(address, amount);}));
                },
                radius: 8.0,
                splashColor: Colors.black.withOpacity(0.4),
                color: const Color(0xFF395198),
              ),
            ),
          ]),
    );
  }
}
