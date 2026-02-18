import 'package:flutter/material.dart';

class PurchaseButton extends StatefulWidget {
  const PurchaseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final bool enabled;
  final EdgeInsets padding;

  @override
  State<PurchaseButton> createState() => _PurchaseButtonState();
}

class _PurchaseButtonState extends State<PurchaseButton> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    if (!widget.enabled || widget.onPressed == null) {
      return;
    }
    setState(() {
      _scale = pressed ? 0.96 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null;
    final backgroundColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
    final topColor = Color.lerp(backgroundColor, Colors.white, 0.28)!;
    final bottomColor = Color.lerp(backgroundColor, Colors.black, 0.2)!;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _scale,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 1,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
