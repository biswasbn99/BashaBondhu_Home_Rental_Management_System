import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _appNameController;
  late TextEditingController _bannerNoticeController;
  late TextEditingController _helplineController;
  late TextEditingController _supportEmailController;
  late TextEditingController _officeAddressController;
  late TextEditingController _facebookUrlController;
  late TextEditingController _youtubeUrlController;
  late TextEditingController _whatsappNumberController;
  late TextEditingController _websiteUrlController;
  late TextEditingController _termsController;
  late TextEditingController _privacyController;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController();
    _bannerNoticeController = TextEditingController();
    _helplineController = TextEditingController();
    _supportEmailController = TextEditingController();
    _officeAddressController = TextEditingController();
    _facebookUrlController = TextEditingController();
    _youtubeUrlController = TextEditingController();
    _whatsappNumberController = TextEditingController();
    _websiteUrlController = TextEditingController();
    _termsController = TextEditingController();
    _privacyController = TextEditingController();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _bannerNoticeController.dispose();
    _helplineController.dispose();
    _supportEmailController.dispose();
    _officeAddressController.dispose();
    _facebookUrlController.dispose();
    _youtubeUrlController.dispose();
    _whatsappNumberController.dispose();
    _websiteUrlController.dispose();
    _termsController.dispose();
    _privacyController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> data) {
    if (_isInitialized) return;
    _appNameController.text = data['appName']?.toString() ?? '';
    _bannerNoticeController.text = data['bannerNotice']?.toString() ?? '';
    _helplineController.text = data['helpline']?.toString() ?? '';
    _supportEmailController.text = data['supportEmail']?.toString() ?? '';
    _officeAddressController.text = data['officeAddress']?.toString() ?? '';
    _facebookUrlController.text = data['facebookUrl']?.toString() ?? '';
    _youtubeUrlController.text = data['youtubeUrl']?.toString() ?? '';
    _whatsappNumberController.text = data['whatsappNumber']?.toString() ?? '';
    _websiteUrlController.text = data['websiteUrl']?.toString() ?? '';
    _termsController.text = data['termsAndConditions']?.toString() ?? '';
    _privacyController.text = data['privacyPolicy']?.toString() ?? '';
    _isInitialized = true;
  }

  Future<void> _saveSettings(bool isBn) async {
    final Map<String, dynamic> data = {
      'appName': _appNameController.text.trim(),
      'bannerNotice': _bannerNoticeController.text.trim(),
      'helpline': _helplineController.text.trim(),
      'supportEmail': _supportEmailController.text.trim(),
      'officeAddress': _officeAddressController.text.trim(),
      'facebookUrl': _facebookUrlController.text.trim(),
      'youtubeUrl': _youtubeUrlController.text.trim(),
      'whatsappNumber': _whatsappNumberController.text.trim(),
      'websiteUrl': _websiteUrlController.text.trim(),
      'termsAndConditions': _termsController.text.trim(),
      'privacyPolicy': _privacyController.text.trim(),
    };

    await _adminService.saveSettings(data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(isBn ? 'সেটিংস সফলভাবে সংরক্ষিত হয়েছে!' : 'Settings Saved Successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;

    return StreamBuilder<Map<String, dynamic>>(
      stream: _adminService.streamSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _populateControllers(snapshot.data!);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Save Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? 'সিস্টেম সেটিংস' : 'System Settings',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.themeColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn
                              ? 'অ্যাপের নাম, যোগাযোগ, সোশাল লিংক ও নীতিমালা পরিচালনা করুন'
                              : 'Manage branding, contact info, social links, and legal policies',
                          style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88)),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => _saveSettings(isBn),
                      icon: const Icon(Icons.save_rounded),
                      label: Text(isBn ? 'সেভ করুন' : 'Save Changes'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.themeColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 1. General Branding
                _buildCard(
                  title: isBn ? 'সাধারণ ও ব্র্যান্ডিং তথ্য' : 'General & Branding',
                  icon: Icons.branding_watermark_rounded,
                  isDark: isDark,
                  children: [
                    _buildTextField(_appNameController, isBn ? 'অ্যাপ / ওয়েবসাইটের নাম' : 'App / Website Name', Icons.apps_rounded),
                    const SizedBox(height: 14),
                    _buildTextField(_bannerNoticeController, isBn ? 'ব্যানার নোটিশ / ঘোষণা' : 'Banner Notice / Announcement', Icons.campaign_rounded, maxLines: 2),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Contact Information
                _buildCard(
                  title: isBn ? 'যোগাযোগের তথ্য (Contact Information)' : 'Contact Information',
                  icon: Icons.contact_phone_rounded,
                  isDark: isDark,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_helplineController, isBn ? 'হেল্পলাইন নম্বর' : 'Helpline Number', Icons.phone_rounded)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildTextField(_supportEmailController, isBn ? 'সাপোর্ট ইমেইল' : 'Support Email', Icons.email_rounded)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(_officeAddressController, isBn ? 'অফিসের ঠিকানা' : 'Office Address', Icons.location_on_rounded),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Social Media & Website Links
                _buildCard(
                  title: isBn ? 'সোশাল মিডিয়া ও অনলাইন লিংক' : 'Social Media & Online Links',
                  icon: Icons.share_rounded,
                  isDark: isDark,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_facebookUrlController, 'Facebook Page URL', Icons.facebook)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildTextField(_youtubeUrlController, 'YouTube Channel URL', Icons.play_circle_fill_rounded)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_whatsappNumberController, 'WhatsApp Number', Icons.chat_rounded)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildTextField(_websiteUrlController, 'Website URL', Icons.language_rounded)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Legal Policies
                _buildCard(
                  title: isBn ? 'নীতিমালা ও শর্তাবলী (Legal Policies)' : 'Legal Policies',
                  icon: Icons.policy_rounded,
                  isDark: isDark,
                  children: [
                    _buildTextField(_termsController, isBn ? 'শর্তাবলী (Terms & Conditions)' : 'Terms & Conditions', Icons.gavel_rounded, maxLines: 5),
                    const SizedBox(height: 14),
                    _buildTextField(_privacyController, isBn ? 'গোপনীয়তা নীতি (Privacy Policy)' : 'Privacy Policy', Icons.privacy_tip_rounded, maxLines: 5),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2625) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.themeColor, size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
