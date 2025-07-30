import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/bloc_extensions.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();
  final _subjectController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'General Inquiry';

  final List<String> _categories = [
    'General Inquiry',
    'Account Issues',
    'Payment Problems',
    'Technical Support',
    'Order Issues',
    'App Feedback',
    'Emergency',
  ];

  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How do I go online to receive orders?',
      answer: 'Navigate to your dashboard and tap the "Go Online" button. Make sure your location services are enabled and you have a stable internet connection.',
    ),
    FAQItem(
      question: 'When will I receive my earnings?',
      answer: 'Earnings are typically processed weekly on Mondays. You can view your earnings history in the Earnings tab and set up direct deposit in your profile settings.',
    ),
    FAQItem(
      question: 'What if a customer is not available for delivery?',
      answer: 'First, try calling the customer. If they don\'t respond, wait for 5 minutes at the delivery location. Then contact support through the app for further instructions.',
    ),
    FAQItem(
      question: 'How do I update my vehicle information?',
      answer: 'Go to Profile > Edit Profile > Vehicle Information. You can update your vehicle type and license plate number. Some changes may require document verification.',
    ),
    FAQItem(
      question: 'What should I do if the app crashes or has technical issues?',
      answer: 'Try restarting the app first. If the problem persists, restart your device. For ongoing issues, contact technical support with details about your device and the issue.',
    ),
    FAQItem(
      question: 'How do I report a safety concern?',
      answer: 'Safety is our priority. Use the emergency contact feature or call our 24/7 safety hotline immediately. You can also report incidents through the support chat.',
    ),
    FAQItem(
      question: 'Can I cancel an order after accepting it?',
      answer: 'Yes, but frequent cancellations may affect your account standing. Only cancel in emergencies. Use the "Report Issue" button in the order details to explain the situation.',
    ),
    FAQItem(
      question: 'How do I change my notification settings?',
      answer: 'Go to Settings > Notifications to customize your alert preferences. You can enable/disable order alerts, earnings notifications, and promotional messages.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      context.showErrorSnackBar('Could not make phone call');
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      context.showErrorSnackBar('Could not open email app');
    }
  }

  Future<void> _openWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      context.showErrorSnackBar('Could not open website');
    }
  }

  void _sendSupportMessage() {
    if (_formKey.currentState?.validate() ?? false) {
      // Simulate sending message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sending message...'),
            ],
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Close loading dialog
        _messageController.clear();
        _subjectController.clear();
        setState(() {
          _selectedCategory = 'General Inquiry';
        });
        context.showSuccessSnackBar('Message sent successfully! We\'ll get back to you within 24 hours.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Contact'),
            Tab(text: 'FAQ'),
            Tab(text: 'Resources'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactTab(),
          _buildFAQTab(),
          _buildResourcesTab(),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      child: Column(
        children: [
          _buildEmergencyCard(),
          const SizedBox(height: AppDimensions.spaceL),
          _buildContactMethodsCard(),
          const SizedBox(height: AppDimensions.spaceL),
          _buildSupportFormCard(),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Support',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '24/7 emergency assistance',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.surface.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.surface, width: 2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _makePhoneCall('+1-800-EMERGENCY'),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spaceM,
                    horizontal: AppDimensions.spaceL,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, color: AppColors.error),
                      const SizedBox(width: AppDimensions.spaceS),
                      Text(
                        'Call Emergency Support',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethodsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Text(
              'Contact Methods',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildContactMethod(
            icon: Icons.phone,
            title: 'Phone Support',
            subtitle: 'Mon-Fri 9AM-6PM',
            action: '+1 (555) 123-HELP',
            onTap: () => _makePhoneCall('+1-555-123-4357'),
          ),
          const Divider(height: 1),
          _buildContactMethod(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'Response within 24 hours',
            action: 'support@fooddelivery.com',
            onTap: () => _sendEmail('support@fooddelivery.com'),
          ),
          const Divider(height: 1),
          _buildContactMethod(
            icon: Icons.chat,
            title: 'Live Chat',
            subtitle: 'Available 24/7',
            action: 'Start Chat',
            onTap: () => context.showInfoSnackBar('Live chat feature coming soon!'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                action,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportFormCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send us a Message',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spaceM),
            CustomTextField(
              controller: _subjectController,
              label: 'Subject',
              hint: 'Brief description of your issue',
              prefixIcon: const Icon(Icons.subject),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Subject is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spaceM),
            CustomTextField(
              controller: _messageController,
              label: 'Message',
              hint: 'Describe your issue in detail...',
              maxLines: 5,
              prefixIcon: const Icon(Icons.message_outlined),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Message is required';
                }
                if (value.trim().length < 10) {
                  return 'Message must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomButton(
              text: 'Send Message',
              onPressed: _sendSupportMessage,
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
              isExpanded: true,
              prefixIcon: const Icon(
                Icons.send,
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      itemCount: _faqItems.length,
      itemBuilder: (context, index) {
        final faq = _faqItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: AppColors.textHint.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ExpansionTile(
            title: Text(
              faq.question,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                child: Text(
                  faq.answer,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourcesTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      children: [
        _buildResourceCard(
          title: 'Driver Handbook',
          description: 'Complete guide for new drivers',
          icon: Icons.menu_book,
          onTap: () => _openWebsite('https://fooddelivery.com/driver-handbook'),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildResourceCard(
          title: 'Safety Guidelines',
          description: 'Important safety tips and protocols',
          icon: Icons.security,
          onTap: () => _openWebsite('https://fooddelivery.com/safety'),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildResourceCard(
          title: 'Tax Information',
          description: 'Tax forms and deduction guidance',
          icon: Icons.receipt_long,
          onTap: () => _openWebsite('https://fooddelivery.com/taxes'),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildResourceCard(
          title: 'Community Forum',
          description: 'Connect with other drivers',
          icon: Icons.forum,
          onTap: () => _openWebsite('https://community.fooddelivery.com'),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildResourceCard(
          title: 'App Tutorial',
          description: 'Video guides for using the app',
          icon: Icons.play_circle,
          onTap: () => context.showInfoSnackBar('Tutorial videos coming soon!'),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildResourceCard(
          title: 'Driver Benefits',
          description: 'Health insurance and benefits info',
          icon: Icons.local_hospital,
          onTap: () => _openWebsite('https://fooddelivery.com/benefits'),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildResourceCard(
          title: 'Vehicle Maintenance',
          description: 'Tips for maintaining your delivery vehicle',
          icon: Icons.build,
          onTap: () => _openWebsite('https://fooddelivery.com/vehicle-care'),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildResourceCard(
          title: 'Customer Service Tips',
          description: 'Best practices for customer interactions',
          icon: Icons.thumb_up,
          onTap: () => _openWebsite('https://fooddelivery.com/customer-service'),
        ),
      ],
    );
  }

  Widget _buildResourceCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// FAQ Model
class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}