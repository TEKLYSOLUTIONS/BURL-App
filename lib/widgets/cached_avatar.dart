import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final String? fallbackText;
  final Color backgroundColor;
  final Color foregroundColor;

  const CachedAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.fallbackText,
    this.backgroundColor = Colors.grey,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildFallback();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: backgroundColor,
      ),
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildFallback(),
    );
  }

  Widget _buildPlaceholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor.withValues(alpha: 0.3),
      child: SizedBox(
        width: radius,
        height: radius,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: foregroundColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: fallbackText != null && fallbackText!.isNotEmpty
          ? Text(
              fallbackText![0].toUpperCase(),
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : Icon(
              Icons.person,
              color: foregroundColor,
              size: radius * 1.2,
            ),
    );
  }
}
