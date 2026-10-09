import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_export.dart';
import '../../../core/app_localizations.dart';
import '../../../providers/user_provider.dart';
import '../../../services/vera_api_service.dart';

class ProfileHeaderWidget extends ConsumerStatefulWidget {
  const ProfileHeaderWidget({super.key});

  @override
  ConsumerState<ProfileHeaderWidget> createState() =>
      _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends ConsumerState<ProfileHeaderWidget> {
  VeraUser? _user;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await VeraApiService.instance.fetchProfile();
      if (mounted && user != null) {
        setState(() => _user = user);
        ref.read(currentUserProvider.notifier).setUser(user);
      }
    } catch (_) {}
  }

  Future<void> _pickAvatar() async {
    if (_isUploading) return;
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (file == null) return;
      setState(() => _isUploading = true);
      final avatarUrl = await VeraApiService.instance.updateAvatar(file.path);
      if (!mounted) return;
      setState(() => _isUploading = false);
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        setState(() {
          if (_user != null) {
            _user = _user!.copyWith(avatarUrl: avatarUrl);
            ref.read(currentUserProvider.notifier).setUser(_user);
          }
        });
        if (_user == null) await _loadProfile();
      } else {
        await _loadProfile();
        if (!mounted) return;
        if (_user?.avatarUrl.isNotEmpty != true) {
          _showMessage(AppLocalizations.of(context).avatarUpdateFailed);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showMessage(AppLocalizations.of(context).avatarUpdateFailed);
      }
    }
  }

  Future<void> _editProfile() async {
    final pageMessenger = ScaffoldMessenger.of(context);
    final successMessage = AppLocalizations.of(context).t('profileUpdated');
    final user = _user;
    if (user == null) {
      await _loadProfile();
      if (!mounted || _user == null) return;
    }
    final current = _user!;
    final nameController = TextEditingController(text: current.name);
    final phoneController = TextEditingController(text: current.phone);
    final cityController = TextEditingController(text: current.city);
    var isSaving = false;

    final changes = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).editProfile),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: isSaving ? null : () async {
                    Navigator.of(dialogContext).pop();
                    await _pickAvatar();
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(AppLocalizations.of(context).edit),
                ),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).fullName,
                  ),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).phoneNumber,
                  ),
                ),
                TextField(
                  controller: cityController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).t('cityLocation'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                setDialogState(() => isSaving = true);
                final saved = await VeraApiService.instance.updateProfile({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'city': cityController.text.trim(),
                });
                if (!mounted) return;
                if (saved) {
                  final updated = current.copyWith(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    city: cityController.text.trim(),
                  );
                  Navigator.of(dialogContext).pop({
                    'name': updated.name,
                    'phone': updated.phone,
                    'city': updated.city,
                  });
                } else {
                  setDialogState(() => isSaving = false);
                  pageMessenger.showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).t('profileUpdateFailed'))),
                  );
                }
              },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(AppLocalizations.of(context).save),
            ),
          ],
        ),
      ),
    );
    // Let the dialog closing animation finish before disposing its controllers.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    nameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    if (!mounted || changes == null) return;
    final updated = current.copyWith(
      name: changes['name'],
      phone: changes['phone'],
      city: changes['city'],
    );
    setState(() => _user = updated);
    ref.read(currentUserProvider.notifier).setUser(updated);
    pageMessenger.showSnackBar(SnackBar(content: Text(successMessage)));
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _user?.name.isNotEmpty == true ? _user!.name : l10n.veraMember;
    final email = _user?.email.isNotEmpty == true ? _user!.email : '';
    final avatarUrl = _user?.avatarUrl.isNotEmpty == true
        ? _user!.avatarUrl
        : 'assets/images/no-image.jpg';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(38),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: avatarUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      semanticLabel: l10n.profilePhotoOf(name),
                    ),
                  ),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: ClipOval(
                      child: Container(
                        color: Colors.black.withAlpha(120),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                PositionedDirectional(
                  bottom: 0,
                  end: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 12,
                      color: AppTheme.primaryPinkDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withAlpha(217),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Loyalty badge hidden temporarily
                // if (_user != null && _user!.loyaltyPoints > 0)
                //   Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 10,
                //       vertical: 4,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Colors.white.withAlpha(51),
                //       borderRadius: BorderRadius.circular(100),
                //     ),
                //     child: Row(
                //       mainAxisSize: MainAxisSize.min,
                //       children: [
                //         const Icon(
                //           Icons.workspace_premium_rounded,
                //           size: 14,
                //           color: Colors.white,
                //         ),
                //         const SizedBox(width: 4),
                //         Text(
                //           '${_user!.loyaltyPoints} ${l10n.pointsAbbr}',
                //           style: GoogleFonts.cairo(
                //             fontSize: 11,
                //             fontWeight: FontWeight.w700,
                //             color: Colors.white,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _editProfile,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
