import 'package:flutter/cupertino.dart';

import 'network_image.dart';

class CustomImageCircle extends StatelessWidget {
  const CustomImageCircle({
    super.key,
    required this.imageUrl,
    required this.radius,
  });

  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: NetworkImages(
          imagepath: imageUrl,

          width: radius * 2,
          height: radius * 2,
        ),
      ),
    );
  }
}
