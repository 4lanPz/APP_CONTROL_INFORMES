import 'package:flutter/material.dart';

class DraftAppBarTitle extends StatelessWidget {
  const DraftAppBarTitle(
    this.title, {
    super.key,
  });

  static const bool showDraftBadge = true;

  final String title;

  @override
  Widget build(BuildContext context) {
    if (!showDraftBadge) {
      return Text(title);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF8C1C13),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'BORRADOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}
