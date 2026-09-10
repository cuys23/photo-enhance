import 'dart:io';

import 'package:flutter/material.dart';

/// §33 — the comparison, hand-written. No package: this is the most important
/// pixel in the product (§32) and it is forty lines.
///
/// Both images are laid out at identical size and the top one is clipped to the
/// handle position, so "before" and "after" are always the same crop.
class BeforeAfter extends StatefulWidget {
  const BeforeAfter({super.key, required this.before, required this.after});

  final ImageProvider before;
  final ImageProvider after;

  @override
  State<BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<BeforeAfter> {
  double _t = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        void drag(Offset local) =>
            setState(() => _t = (local.dx / c.maxWidth).clamp(0.0, 1.0));

        return GestureDetector(
          onPanDown: (d) => drag(d.localPosition),
          onPanUpdate: (d) => drag(d.localPosition),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(image: widget.after, fit: BoxFit.contain),
              ClipRect(
                clipper: _LeftClipper(_t),
                child: Image(image: widget.before, fit: BoxFit.contain),
              ),
              Positioned(
                left: c.maxWidth * _t - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                left: c.maxWidth * _t - 18,
                top: c.maxHeight / 2 - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black38)],
                  ),
                  child: const Icon(Icons.code, size: 18, color: Colors.black87),
                ),
              ),
              const Positioned(left: 12, top: 12, child: _Tag('TRƯỚC')),
              const Positioned(right: 12, top: 12, child: _Tag('SAU')),
            ],
          ),
        );
      },
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  const _LeftClipper(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.t != t;
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
      );
}

/// Results may arrive as a local path (mock, cache) or an https URL (real API).
ImageProvider imageFor(String pathOrUrl) => pathOrUrl.startsWith('http')
    ? NetworkImage(pathOrUrl)
    : FileImage(File(pathOrUrl)) as ImageProvider;
