import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PinWidget extends StatefulWidget {
  const PinWidget({
    required this.color,
    this.size = 80,
    super.key,
  });

  final Color color;
  final double size;

  @override
  State<PinWidget> createState() => _PinWidgetState();
}

class _PinWidgetState extends State<PinWidget> {
  late Future<String> _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = _loadSvgWithColor();
  }

  Future<String> _loadSvgWithColor() async {
    final String svg = await rootBundle.loadString('assets/images/pin.svg');
    final String colorHex =
        '#${widget.color.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';

    return svg
        .replaceAll('fill="#FF5093"', 'fill="$colorHex"')
        .replaceAll('stroke="#FF5093"', 'stroke="$colorHex"');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _svgFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: SvgPicture.string(snapshot.data!),
        );
      },
    );
  }
}
