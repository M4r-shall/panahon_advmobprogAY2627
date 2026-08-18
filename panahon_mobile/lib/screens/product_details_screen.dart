import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/product_model.dart';
import '../widgets/custom_text.dart';

import '../services/cart_service.dart';

//Add details page when clicked the card.
class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

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
                  // Enhancement 3: Use add to cart by passing the values of the product => cart
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          final cartService = CartService();
                          await cartService.addToCart(33, product.id, 1);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.title} added to cart!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add to cart: $e')),
                            );
                          }
                        }
                      },
                      child: CustomText(
                        text: 'Add to Cart',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
