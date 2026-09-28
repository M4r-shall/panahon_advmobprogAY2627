import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/login_type.dart';
import '../models/product_model.dart';
import '../widgets/custom_text.dart';

import '../services/cart_service.dart';
import '../services/user_service.dart';

//Add details page when clicked the card.
class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  /// Posts to the signed-in DummyJSON user's cart. This used to be a hardcoded
  /// userId 33, so every "Add to Cart" went to the same stranger's cart no
  /// matter who was signed in.
  Future<void> _addToCart(BuildContext context) async {
    final service = userService.value;

    try {
      final loginType = await service.getLoginType();
      if (!context.mounted) return;

      // DummyJSON owns carts, and it keys them by an integer user id a
      // Firebase account does not have. See CartScreen's empty state.
      if (loginType == LoginType.firebase) {
        _showMessage(
          context,
          'The cart is a DummyJSON feature. Sign in with DummyJSON to add '
          'items.',
        );
        return;
      }

      final user = await service.getUser();
      if (!context.mounted) return;
      if (user.id <= 0) {
        _showMessage(context, 'Sign in again to add items to your cart.');
        return;
      }

      await CartService().addToCart(user.id, product.id, 1);
      if (!context.mounted) return;
      _showMessage(context, '${product.title} added to cart!');
    } catch (e) {
      if (!context.mounted) return;
      _showMessage(context, 'Failed to add to cart: $e');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Details',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, size: 24.sp),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),
            Image.network(
              product.thumbnail,
              height: 200.h,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.image, size: 100.sp),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 10.h),
                  CustomText(
                    text: product.description,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.normal,
                  ),
                  SizedBox(height: 20.h),
                  CustomText(
                    text: '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 10.h),
                  CustomText(
                    text:
                        'Brand: ${product.brand.isNotEmpty ? product.brand : "Unknown"}',
                    fontSize: 14.sp,
                  ),
                  SizedBox(height: 5.h),
                  CustomText(text: 'Stock: ${product.stock}', fontSize: 14.sp),
                  SizedBox(height: 40.h),
                  //add to cart by passing the values of the product => cart
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () => _addToCart(context),
                      child: CustomText(
                        text: 'Add to Cart',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
