import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String firstName = args?['firstName'] ?? 'Profile';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E202C),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: (_selectedIndex == 1) ? 0 : 2,
          backgroundColor: (_selectedIndex == 1 || _selectedIndex == 2)
              ? const Color(0xFF31323E)
              : const Color(0xFF1E202C),
          title: (_selectedIndex == 0)
              ? Image.asset('assets/images/nubdexchange_logo.png', scale: 11.sp)
              : CustomText(
                  text: (_selectedIndex == 1)
                      ? 'Cart'
                      : (_selectedIndex == 2)
                      ? firstName
                      : 'Home',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: (_selectedIndex == 1 || _selectedIndex == 2) ? const Color(0xFFBFC0D1) : Colors.white,
                ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.settings,
                size: 24.sp,
                color: (_selectedIndex == 1 || _selectedIndex == 2) ? const Color(0xFFBFC0D1) : Colors.white,
              ),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: const <Widget>[ProductScreen(), CartScreen(), ProfileScreen()],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF1E202C),
          selectedItemColor: const Color(0xFF60519B),
          unselectedItemColor: const Color(0xFFBFC0D1),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
        // Make the chat bottom navigation as FloatingActionButton.
        // When in the cart screen the FloatingActionButton must be hidden.
        floatingActionButton: _selectedIndex != 1
            ? FloatingActionButton(
                onPressed: () {},
                backgroundColor: const Color(0xFF60519B),
                child: const Icon(Icons.chat, color: Color(0xFF1E202C)),
              )
            : null,
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}
