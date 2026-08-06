import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/product_model.dart';
import '../widgets/custom_text.dart';

// Enhancement 2: Add details page when clicked the card.
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
                    text: 'Brand: ${product.brand.isNotEmpty ? product.brand : "Unknown"}',
                    fontSize: 14.sp,
                  ),
                  SizedBox(height: 5.h),
                  CustomText(
                    text: 'Stock: ${product.stock}',
                    fontSize: 14.sp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
