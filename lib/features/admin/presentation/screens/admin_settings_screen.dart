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

  late final Stream<Map<String, dynamic>> _settingsStream;

  late final TextEditingController _helplineController;
  late final TextEditingController _whatsappNumberController;
  late final TextEditingController _supportEmailController;
  late final TextEditingController _officeAddressController;

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settingsStream = _adminService.streamSettings();
    _helplineController = TextEditingController();
    _whatsappNumberController = TextEditingController();
    _supportEmailController = TextEditingController();
    _officeAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _helplineController.dispose();
    _whatsappNumberController.dispose();
    _supportEmailController.dispose();
    _officeAddressController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> data) {
    if (_isInitialized) return;
    _helplineController.text = data['helpline']?.toString() ?? '+880 1700-000000';
    _whatsappNumberController.text = data['whatsappNumber']?.toString() ?? '+8801700000000';
    _supportEmailController.text = data['supportEmail']?.toString() ?? 'support@bashabondhu.com';
    _officeAddressController.text = data['officeAddress']?.toString() ?? 'House 12, Road 5, Dhanmondi, Dhaka - 1205';
    _isInitialized = true;
  }

  Future<void> _saveSettings(bool isBn) async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> data = {
        'helpline': _helplineController.text.trim(),
        'whatsappNumber': _whatsappNumberController.text.trim(),
        'supportEmail': _supportEmailController.text.trim(),
        'officeAddress': _officeAddressController.text.trim(),
      };

      await _adminService.saveSettings(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  isBn
                      ? 'সাপোর্ট ও যোগাযোগ তথ্য সফলভাবে সংরক্ষিত হয়েছে! (রিয়েল-টাইমে আপডেট কার্যকর)'
                      : 'Support & contact settings saved successfully! (Live updated)',
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0D9488),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBn ? 'ত্রুটি: $e' : 'Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = context.select<AdminProvider, bool>((p) => p.isBangla);

    return StreamBuilder<Map<String, dynamic>>(
      stream: _settingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _populateControllers(snapshot.data!);
        } else if (!_isInitialized) {
          _populateControllers({});
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header & Save Action
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.themeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.headset_mic_rounded,
                                color: AppColors.themeColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isBn ? 'কাস্টমার সাপোর্ট ও যোগাযোগ তথ্য' : 'Customer Support & Contact Settings',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.themeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isBn
                              ? 'ভাড়াটিয়া এবং বাড়িওয়ালাদের জন্য ৪টি অফিশিয়াল যোগাযোগ মাধ্যম পরিচালনা করুন'
                              : 'Manage the 4 official contact channels accessible by tenants and house owners',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : () => _saveSettings(isBn),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isSaving
                            ? (isBn ? 'সংরক্ষণ হচ্ছে...' : 'Saving...')
                            : (isBn ? 'সেটিংস সেভ করুন' : 'Save Changes'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.themeColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Notice Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF0D9488), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isBn
                              ? 'এখানে সেট করা ৪টি তথ্য (হেল্পলাইন, হোয়াটসঅ্যাপ, সাপোর্ট ইমেইল ও অফিস ঠিকানা) সকল ভাড়াটিয়া ও বাড়িওয়ালার অ্যাপের অ্যাকাউন্ট স্ক্রিনে রিয়েল-টাইমে প্রদর্শিত হবে।'
                              : 'These 4 contact details (Helpline, WhatsApp, Support Email & Office Address) are streamed in real time to all Tenant and House Owner account screens.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Main 4-Field Card
                _buildCard(
                  title: isBn ? '৪টি সাপোর্ট ও কন্টাক্ট ফিল্ড' : '4 Official Contact Channels',
                  icon: Icons.contact_phone_rounded,
                  isDark: isDark,
                  children: [
                    // 1. Helpline
                    _buildField(
                      controller: _helplineController,
                      label: isBn ? '১. সরাসরি হেল্পলাইন নম্বর' : '1. Direct Helpline Number',
                      hint: '+880 1700-000000',
                      icon: Icons.phone_in_talk_rounded,
                      iconColor: const Color(0xFF0D9488),
                      helperText: isBn ? 'ভাড়াটিয়া বা বাড়িওয়ালা ক্লিক করলে সরাসরি ফোন কলে যাবে' : 'One-tap direct dial for callers',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isBn ? 'হেল্পলাইন নম্বর দিন' : 'Please enter helpline number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // 2. WhatsApp Number
                    _buildField(
                      controller: _whatsappNumberController,
                      label: isBn ? '২. অফিসিয়াল হোয়াটসঅ্যাপ নম্বর' : '2. Official WhatsApp Number',
                      hint: '+8801700000000',
                      icon: Icons.chat_rounded,
                      iconColor: const Color(0xFF25D366),
                      helperText: isBn ? 'ক্লিক করলে সরাসরি হোয়াটসঅ্যাপ চ্যাটে সংযুক্ত হবে' : 'One-tap WhatsApp direct messaging link',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isBn ? 'হোয়াটসঅ্যাপ নম্বর দিন' : 'Please enter WhatsApp number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // 3. Support Email
                    _buildField(
                      controller: _supportEmailController,
                      label: isBn ? '৩. কাস্টমার সাপোর্ট ইমেইল' : '3. Customer Support Email',
                      hint: 'support@bashabondhu.com',
                      icon: Icons.email_rounded,
                      iconColor: const Color(0xFF2563EB),
                      helperText: isBn ? 'যেকোনো জিজ্ঞাসা বা সাহায্যের জন্য ইমেইল' : 'Official inquiry & dispute mail',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isBn ? 'সাপোর্ট ইমেইল দিন' : 'Please enter support email';
                        }
                        if (!val.contains('@')) {
                          return isBn ? 'সঠিক ইমেইল এড্রেস লিখুন' : 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // 4. Office Address
                    _buildField(
                      controller: _officeAddressController,
                      label: isBn ? '৪. হেড অফিস / শাখা ঠিকানা' : '4. Head Office / Branch Address',
                      hint: 'House 12, Road 5, Dhanmondi, Dhaka - 1205',
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFEA580C),
                      helperText: isBn ? 'অফিসের বিস্তারিত ঠিকানা যা ব্যবহারকারীরা পরিদর্শন করতে পারেন' : 'Full physical location for visitor inquiries',
                      maxLines: 3,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isBn ? 'অফিসের ঠিকানা দিন' : 'Please enter office address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Live Preview Section
                _buildLivePreviewCard(isDark, isBn),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required String helperText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => setState(() {}),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[400]),
            helperText: helperText,
            helperStyle: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            filled: true,
            fillColor: isDark ? const Color(0xFF131D1C) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF263936) : const Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF263936) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.themeColor, width: 1.8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16211F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF263936) : const Color(0xFFE2EBE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.themeColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(bool isDark, bool isBn) {
    final helpline = _helplineController.text.isNotEmpty ? _helplineController.text : '+880 1700-000000';
    final whatsapp = _whatsappNumberController.text.isNotEmpty ? _whatsappNumberController.text : '+8801700000000';
    final email = _supportEmailController.text.isNotEmpty ? _supportEmailController.text : 'support@bashabondhu.com';
    final address = _officeAddressController.text.isNotEmpty
        ? _officeAddressController.text
        : 'House 12, Road 5, Dhanmondi, Dhaka - 1205';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F1D) : const Color(0xFFF1F8F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview_rounded, size: 20, color: AppColors.themeColor),
              const SizedBox(width: 8),
              Text(
                isBn ? 'ইউজার প্রিভিউ (ভাড়াটিয়া ও বাড়িওয়ালা যেভাবে দেখতে পাবেন)' : 'User Live Preview (As Seen in Tenant & Owner Apps)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.themeColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _previewBadge(Icons.phone_rounded, helpline, const Color(0xFF0D9488)),
              _previewBadge(Icons.chat_rounded, 'WhatsApp: $whatsapp', const Color(0xFF25D366)),
              _previewBadge(Icons.email_rounded, email, const Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFEA580C)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
