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
  Cart? _currentCart;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final user = await _userService.getUser();
      final userId = user.id > 0 ? user.id : 1;
      final cart = await _cartService.getCartByUserId(userId);
      if (mounted) {
        setState(() {
          _currentCart = cart;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _incrementQuantity(int productId) {
    if (_currentCart == null) return;
    
    final products = List<CartProduct>.from(_currentCart!.products);
    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final p = products[index];
      final newQuantity = p.quantity + 1;
      final newTotal = p.price * newQuantity;
      final newDiscountedTotal = newTotal - (newTotal * (p.discountPercentage / 100));
      
      products[index] = p.copyWith(
        quantity: newQuantity,
        total: newTotal,
        discountedTotal: newDiscountedTotal,
      );
      _recalculateTotals(products);
    }
  }

  void _decrementQuantity(int productId) {
    if (_currentCart == null) return;
    
    final products = List<CartProduct>.from(_currentCart!.products);
    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final p = products[index];
      if (p.quantity > 1) {
        final newQuantity = p.quantity - 1;
        final newTotal = p.price * newQuantity;
        final newDiscountedTotal = newTotal - (newTotal * (p.discountPercentage / 100));
        
        products[index] = p.copyWith(
          quantity: newQuantity,
          total: newTotal,
          discountedTotal: newDiscountedTotal,
        );
      } else {
        products.removeAt(index);
      }
      _recalculateTotals(products);
    }
  }

  void _recalculateTotals(List<CartProduct> updatedProducts) {
    double total = 0;
    double discountedTotal = 0;
    int totalQuantity = 0;
    
    for (var p in updatedProducts) {
      total += p.total;
      discountedTotal += p.discountedTotal;
      totalQuantity += p.quantity;
    }
    
    setState(() {
      _currentCart = _currentCart!.copyWith(
        products: updatedProducts,
        total: total,
        discountedTotal: discountedTotal,
        totalProducts: updatedProducts.length,
        totalQuantity: totalQuantity,
      );
    });
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return Center(child: Text('Error: $_error'));
    } else if (_currentCart == null || _currentCart!.products.isEmpty) {
      return const Center(child: Text('No items in cart.'));
    }

    final cart = _currentCart!;

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
                                GestureDetector(
                                  onTap: () => _incrementQuantity(product.id),
                                  child: Container(
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
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: CustomText(
                                    text: '${product.quantity}',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _decrementQuantity(product.id),
                                  child: Container(
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
  }
}
