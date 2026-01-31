import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? heroTag;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.broken_image, color: Colors.grey[600], size: 48),
        ),
      ),
      fadeInDuration: Duration(milliseconds: 300),
      fadeOutDuration: Duration(milliseconds: 100),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: imageWidget);
    }

    return imageWidget;
  }
}

class OptimizedCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final Color? backgroundColor;
  final double radius;

  const OptimizedCircleAvatar({
    Key? key,
    this.imageUrl,
    required this.fallbackText,
    this.backgroundColor,
    this.radius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        radius: radius,
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      );
    }

    return CircleAvatar(
      backgroundColor: backgroundColor ?? Colors.grey[300],
      radius: radius,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: Icon(Icons.person, color: Colors.grey[600], size: radius),
          ),
          errorWidget: (context, url, error) => Container(
            color: backgroundColor ?? Theme.of(context).primaryColor,
            child: Text(
              fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
