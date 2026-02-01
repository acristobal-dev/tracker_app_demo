import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PinWidget extends StatelessWidget {
  const PinWidget({
    required this.color,
    required this.svgString,
    this.size = 80,
    super.key,
  });

  final Color color;
  final String svgString;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String colorHex =
        '#${color.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';

    final String coloredSvg = svgString
        .replaceAll('fill="#FF5093"', 'fill="$colorHex"')
        .replaceAll('stroke="#FF5093"', 'stroke="$colorHex"');

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        coloredSvg,
      ),
    );
  }
}
