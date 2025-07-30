import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../../data/models/driver_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _vehicleTypeFocusNode = FocusNode();
  final _vehicleNumberFocusNode = FocusNode();

  Driver? _currentDriver;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentDriver();
    _addTextListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _vehicleTypeFocusNode.dispose();
    _vehicleNumberFocusNode.dispose();
    super.dispose();
  }

  void _loadCurrentDriver() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentDriver = authState.driver;
      _populateFields();
    }
  }

  void _populateFields() {
    if (_currentDriver != null) {
      _nameController.text = _currentDriver!.name;
      _emailController.text = _currentDriver!.email;
      _phoneController.text = _currentDriver!.phone;
      _vehicleTypeController.text = _currentDriver!.vehicleType;
      _vehicleNumberController.text = _currentDriver!.vehicleNumber;
    }
  }

  void _addTextListeners() {
    _nameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _vehicleTypeController.addListener(_checkForChanges);
    _vehicleNumberController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    if (_currentDriver == null) return;

    final hasTextChanges = _nameController.text != _currentDriver!.name ||
        _emailController.text != _currentDriver!.email ||
        _phoneController.text != _currentDriver!.phone ||
        _vehicleTypeController.text != _currentDriver!.vehicleType ||
        _vehicleNumberController.text != _currentDriver!.vehicleNumber;

    final hasImageChanges = _selectedImage != null;

    setState(() {
      _hasChanges = hasTextChanges || hasImageChanges;
    });
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      context.showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      context.showErrorSnackBar('Failed to take photo: ${e.toString()}');
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update Profile Photo',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Camera',
                    onPressed: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                    variant: ButtonVariant.outline,
                    prefixIcon: const Icon(Icons.camera_alt),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: CustomButton(
                    text: 'Gallery',
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                    variant: ButtonVariant.primary,
                    prefixIcon: const Icon(
                      Icons.photo_library,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_currentDriver == null) return;

      final updatedDriver = _currentDriver!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        // In a real app, you would upload the image and get a URL
        profileImage: _selectedImage != null ? _selectedImage!.path : _currentDriver!.profileImage,
      );

      context.authBloc.add(AuthDriverUpdated(updatedDriver));
    }
  }

  void _discardChanges() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close edit screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _hasChanges ? _discardChanges : () => Navigator.pop(context),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: () {
                _populateFields();
                setState(() {
                  _selectedImage = null;
                  _hasChanges = false;
                });
              },
              child: const Text('Reset'),
            ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.showSuccessSnackBar('Profile updated successfully!');
            Navigator.pop(context);
          } else if (state is AuthError) {
            context.showErrorSnackBar(state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProfileImageSection(),
                const SizedBox(height: AppDimensions.spaceXL),
                _buildPersonalInfoSection(),
                const SizedBox(height: AppDimensions.spaceL),
                _buildVehicleInfoSection(),
                const SizedBox(height: AppDimensions.spaceXL),
                _buildSaveButton(),
                const SizedBox(height: AppDimensions.spaceL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
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
      child: Column(
        children: [
          Text(
            'Profile Photo',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          GestureDetector(
            onTap: _showImagePickerDialog,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 3,
                    ),
                    color: AppColors.primaryLight,
                  ),
                  child: _buildProfileImage(),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceS),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.surface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            'Tap to change photo',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_selectedImage != null) {
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          width: 114,
          height: 114,
          fit: BoxFit.cover,
        ),
      );
    } else if (_currentDriver?.profileImage != null) {
      return ClipOval(
        child: Image.network(
          _currentDriver!.profileImage!,
          width: 114,
          height: 114,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(),
        ),
      );
    } else {
      return _buildInitialsAvatar();
    }
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        _currentDriver?.name.substring(0, 1).toUpperCase() ?? 'D',
        style: AppTextStyles.displayLarge.copyWith(
          color: AppColors.surface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          CustomTextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            label: 'Full Name',
            hint: 'Enter your full name',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.person_outline,
              color: AppColors.textSecondary,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
            onSubmitted: (_) => _emailFocusNode.requestFocus(),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          CustomTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'Email Address',
            hint: 'Enter your email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: AppColors.textSecondary,
            ),
            validator: Validators.email,
            onSubmitted: (_) => _phoneFocusNode.requestFocus(),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          CustomTextField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: AppColors.textSecondary,
            ),
            validator: Validators.phone,
            onSubmitted: (_) => _vehicleTypeFocusNode.requestFocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Information',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          CustomTextField(
            controller: _vehicleTypeController,
            focusNode: _vehicleTypeFocusNode,
            label: 'Vehicle Type',
            hint: 'e.g., Car, Motorcycle, Bicycle',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.directions_car_outlined,
              color: AppColors.textSecondary,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vehicle type is required';
              }
              return null;
            },
            onSubmitted: (_) => _vehicleNumberFocusNode.requestFocus(),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          CustomTextField(
            controller: _vehicleNumberController,
            focusNode: _vehicleNumberFocusNode,
            label: 'Vehicle Number/License Plate',
            hint: 'Enter your vehicle number',

            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.textSecondary,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vehicle number is required';
              }
              return null;
            },
            onSubmitted: (_) => _saveProfile(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return CustomButton(
          text: 'Save Changes',
          onPressed: (_hasChanges && !isLoading) ? _saveProfile : null,
          variant: ButtonVariant.primary,
          size: ButtonSize.large,
          isExpanded: true,
          isLoading: isLoading,
          prefixIcon: !isLoading
              ? const Icon(
            Icons.save,
            color: AppColors.surface,
          )
              : null,
        );
      },
    );
  }
}