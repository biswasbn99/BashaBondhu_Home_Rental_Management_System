import 'package:flutter/material.dart';


class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({
    super.key,
    required this.email,
    this.avatarUrl,
    this.onTap,
  });

  final String email;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
         
        
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                email,
                style: const TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}