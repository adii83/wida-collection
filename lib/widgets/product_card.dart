import 'package:flutter/material.dart';

import '../config/design_tokens.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.badge,
    this.rating = 4.8,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  final Product product;
  final String? badge;
  final double rating;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final badgeColor = scheme.surface;
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: product.image.startsWith('http')
                            ? Image.network(
                                product.image,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) =>
                                    AnimatedOpacity(
                                      opacity: progress == null ? 1 : 0.6,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: child,
                                    ),
                              )
                            : Image.asset(product.image, fit: BoxFit.cover),
                      ),
                      if (badge != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: AppColors.primaryPink,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: onFavorite,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppColors.primaryPink
                                : Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Rp ${product.price.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPink,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFC542),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
