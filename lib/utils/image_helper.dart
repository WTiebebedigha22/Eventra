import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageHelper {
  // Check if URL is from ImgBB
  static bool isImgBBUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('ibb.co') || 
           url.contains('imgbb.com') || 
           url.contains('.jpg') ||
           url.contains('.png') ||
           url.contains('.jpeg');
  }
  
  // Get optimized image URL
  static String getOptimizedImageUrl(String? url, {int width = 200}) {
    if (url == null || url.isEmpty) return '';
    
    // For ImgBB, we can add size parameters
    if (url.contains('ibb.co')) {
      return url;
    }
    return url;
  }
  
  // Build CachedNetworkImage widget
  static Widget buildProfileImage({
    required String? imageUrl,
    required double radius,
    VoidCallback? onTap,
    BoxFit fit = BoxFit.cover,
  }) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: hasImage 
            ? CachedNetworkImageProvider(
                getOptimizedImageUrl(imageUrl),
              )
            : null,
        child: !hasImage
            ? Icon(Icons.person, size: radius * 0.8, color: Colors.grey[400])
            : null,
      ),
    );
  }
  
  // Build CachedNetworkImage for posts
  static Widget buildPostImage({
    required String? imageUrl,
    required double height,
    required double width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: getOptimizedImageUrl(imageUrl),
      height: height,
      width: width,
      fit: fit,
      placeholder: (context, url) => Container(
        height: height,
        width: width,
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: height,
        width: width,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}