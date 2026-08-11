import 'package:bashabondhu_home_rental_management_system/app/language_changer.dart';
import 'package:bashabondhu_home_rental_management_system/app/theme_changer.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/screens/account_profile_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';



class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.email,
    this.avatarUrl,
    this.isProfileComplete = false,
  });

  final String email;
  final String? avatarUrl;

  
  final bool isProfileComplete;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      
      appBar: AppBar(
       
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text(
          'My Account',
          style: TextStyle(
           
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFECECEC)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccountProfileHeader(
                email: widget.email,
                avatarUrl: widget.avatarUrl,
                onTap: () {},
              ),
              const SizedBox(height: 16),
              
           Column( 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignInScreen()),
                    );
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('SIGN IN'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('SIGN UP'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ThemeChangerDropdown(),
              const SizedBox(height: 16),
              LocaleChangerDropdown(),
            ],
                     ),
           
            ],
          ),
        ),
      ),
    
    );
  }
}