import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/login_type.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';

// Add settings page to move the dark/light mode switch.
// Also hosts the logout entry point required by the lab.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Clears the Firebase session (when signed in) and the stored tokens.
    await userService.value.logout();

    if (!context.mounted) return;
    // Settings is pushed on top of /home, and HomeScreen blocks pops with
    // PopScope. Replacing only this route would leave the signed-in home
    // screen alive underneath, so the whole stack has to go.
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          const Divider(),
          FutureBuilder<LoginType>(
            future: userService.value.getLoginType(),
            builder: (context, snapshot) {
              return ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Login Method'),
                subtitle: Text(snapshot.data?.label ?? '-'),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Log Out'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
