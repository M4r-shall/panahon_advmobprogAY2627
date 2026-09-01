import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import 'product_details_screen.dart';
import '../widgets/custom_text.dart';

//Make a cart screen in order to render the new API endpoint.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  late Future<Cart> _cartFuture;

  @override
  void initState() {
    super.initState();
    // Enhancement 3: Based on the saved user data render the cart by userId
    _cartFuture = _initCart();
  }

  Future<Cart> _initCart() async {
    final user = await _userService.getUser();
    final userId = user.id > 0 ? user.id : 1;
    return _cartService.getCartByUserId(userId);
  }

  void _navigateToDetails(int productId) async {
    // Show a loading indicator while fetching full product details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final product = await _productService.getProductById(productId);
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading product details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cart>(
      future: _cartFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No cart found.'));
        }

        final cart = snapshot.data!;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: cart.products.length + 1,
                itemBuilder: (context, index) {
                  if (index < cart.products.length) {
                    final product = cart.products[index];
                    return GestureDetector(
                      // The items on the cart screen must be clickable going to the detail screen for the utilization of the screen widget.
                      onTap: () => _navigateToDetails(product.id),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Image.network(
                              product.thumbnail,
                              width: 70.w,
                              height: 70.w,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.image, size: 70.w),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: product.title,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text:
                                        '\$${product.price.toStringAsFixed(2)}',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text:
                                        '${product.discountPercentage.toStringAsFixed(0)}% off • \$${product.discountedTotal.toStringAsFixed(2)} total',
                                    fontSize: 10.sp,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  width: 28.w,
                                  height: 28.w,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 16.sp,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: CustomText(
                                    text: '${product.quantity}',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  width: 28.w,
                                  height: 28.w,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 16.sp,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Totals row at the bottom of the list items
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 8.h,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                text: 'Subtotal:',
                                fontSize: 14.sp,
                                color: Theme.of(context).hintColor,
                              ),
                              CustomText(
                                text: '\$${cart.total.toStringAsFixed(2)}',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                text: 'Delivery Fee:',
                                fontSize: 14.sp,
                                color: Theme.of(context).hintColor,
                              ),
                              CustomText(
                                text: '\$0.00',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
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
                  onPressed: () {
                    // Dummy action to demonstrate addToCart API interaction
                  },
                  child: CustomText(
                    text: 'Confirm Order',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
