import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'drive_helper.dart';
import 'database_helper.dart';
import 'language_helper.dart';
import 'app_settings_screen.dart';
import 'auth_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  GoogleSignInAccount? _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _animationController.forward();

    _currentUser = _googleSignIn.currentUser;
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (mounted) {
        setState(() {
          _currentUser = account;
        });
      }
    });

    _googleSignIn.signInSilently().whenComplete(() {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    });
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    try {
      setState(() => _isLoading = true);
      AuthHelper.isExternalIntentInProgress = true;
      await _googleSignIn.signIn();
    } catch (error) {
      if (mounted) {
        _showResultDialog(false, '${LanguageHelper.t('লগইন ব্যর্থ হয়েছে: ', 'Login failed: ')}$error');
      }
    } finally {
      AuthHelper.isExternalIntentInProgress = false;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    HapticFeedback.lightImpact();
    await _googleSignIn.disconnect();
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 45, height: 45,
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 3),
                  ),
                  const SizedBox(height: 24),
                  Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResultDialog(bool success, String message, {VoidCallback? onOk}) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (success ? Colors.green : Colors.redAccent).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(success ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: success ? Colors.green : Colors.redAccent, size: 50),
                ),
                const SizedBox(height: 20),
                Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    if (onOk != null) onOk();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    minimumSize: const Size(double.infinity, 55),
                    elevation: 0,
                  ),
                  child: Text(LanguageHelper.t('ঠিক আছে', 'OK'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _backupData() async {
    if (_currentUser == null) {
      _showResultDialog(false, LanguageHelper.t('আগে Google দিয়ে লগইন করুন!', 'Please login with Google first!'));
      return;
    }
    _showLoadingDialog(LanguageHelper.t('ব্যাকআপ নেওয়া হচ্ছে...', 'Taking backup...'));
    bool success = await DriveHelper.uploadBackup(_currentUser!);
    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog
    _showResultDialog(success, success ? LanguageHelper.t('ব্যাকআপ সফল হয়েছে! ☁️', 'Backup successful! ☁️') : LanguageHelper.t('ব্যাকআপ ব্যর্থ হয়েছে!', 'Backup failed!'));
  }

  Future<void> _restoreData() async {
    if (_currentUser == null) {
      _showResultDialog(false, LanguageHelper.t('আগে Google দিয়ে লগইন করুন!', 'Please login with Google first!'));
      return;
    }
    _showLoadingDialog(LanguageHelper.t('ডেটা রিস্টোর করা হচ্ছে...', 'Restoring data...'));
    bool success = await DriveHelper.restoreBackup(_currentUser!);
    if (success) {
      await DatabaseHelper.resetDatabase();
    }
    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog
    
    if (success) {
      _showResultDialog(true, LanguageHelper.t('রিস্টোর সফল হয়েছে!', 'Restore successful!'), onOk: () {
        Navigator.pop(context); // Close profile screen to refresh dashboard
      });
    } else {
      _showResultDialog(false, LanguageHelper.t('Drive এ কোনো ব্যাকআপ পাওয়া যায়নি!', 'No backup found in Drive!'));
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      const Text('Veqzi', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const Text('v1.0.0', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageHelper.t('আমাদের লক্ষ্য', 'Our Vision'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        LanguageHelper.t(
                          'হিসাব রাখাকে একদম সহজ ও ঝামেলাহীন করাই আমাদের মূল লক্ষ্য। এআই (AI) দিয়ে রসিদ স্ক্যান এবং গুগল ড্রাইভ ব্যাকআপের মতো স্মার্ট ফিচার দিয়ে Veqzi তৈরি করা হয়েছে আপনার মূল্যবান সময় বাঁচাতে।',
                          'Our goal is to make expense tracking simple and hassle-free. Veqzi is built with smart features like AI receipt scanning and Google Drive backup to save your valuable time.'
                        ),
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        LanguageHelper.t('ডেভেলপার', 'Developer'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 32,
                              backgroundColor: Color(0xFF4F46E5),
                              child: Icon(Icons.computer_rounded, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('MD. Eyasin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text(LanguageHelper.t('ডিপ্লোমা ইন C.S.T', 'Diploma in C.S.T'), style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  const Text('Abstract Developer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            foregroundColor: const Color(0xFF4F46E5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: Text(LanguageHelper.t('বন্ধ করুন', 'Close'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _currentUser != null ? 280.0 : 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: _currentUser != null ? _buildLoggedInHeader() : _buildLoggedOutHeader(),
                  ),
                ),
              ),
            ),
            title: Text(LanguageHelper.t('প্রোফাইল ও সেটিংস', 'Profile & Settings'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(LanguageHelper.t('ডেটা ব্যাকআপ', 'Data Backup')),
                  const SizedBox(height: 16),
                  FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: _buildOptionCard(
                    icon: Icons.cloud_upload_rounded,
                    iconColor: Colors.blueAccent,
                    title: LanguageHelper.t('Google Drive-এ ব্যাকআপ নিন', 'Backup to Google Drive'),
                    subtitle: LanguageHelper.t('আপনার সব হিসাব সুরক্ষিত রাখুন', 'Keep all your records safe'),
                    onTap: _backupData,
                  ))),
                  const SizedBox(height: 12),
                  FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: _buildOptionCard(
                    icon: Icons.settings_backup_restore_rounded,
                    iconColor: Colors.orangeAccent,
                    title: LanguageHelper.t('ডেটা রিস্টোর করুন', 'Restore Data'),
                    subtitle: LanguageHelper.t('পুরনো হিসাব ফিরিয়ে আনুন', 'Restore old records'),
                    onTap: _restoreData,
                  ))),
                  const SizedBox(height: 35),
                  
                  _buildSectionHeader(LanguageHelper.t('অন্যান্য', 'Others')),
                  const SizedBox(height: 16),
                  FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: _buildOptionCard(
                    icon: Icons.settings_rounded,
                    iconColor: Colors.green,
                    title: LanguageHelper.t('অ্যাপ সেটিংস', 'App Settings'),
                    subtitle: LanguageHelper.t('ভাষা ও কারেন্সি কাস্টমাইজ করুন', 'Customize language & currency'),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const AppSettingsScreen()));
                      if (mounted) setState(() {});
                    },
                  ))),
                  const SizedBox(height: 12),
                  FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: _buildOptionCard(
                    icon: Icons.info_outline_rounded,
                    iconColor: Colors.purpleAccent,
                    title: LanguageHelper.t('আমাদের সম্পর্কে', 'About Us'),
                    subtitle: LanguageHelper.t('অ্যাপের বিস্তারিত ও ডেভেলপার ইনফো', 'App details & developer info'),
                    onTap: _showAboutDialog,
                  ))),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLoggedInHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundImage: _currentUser!.photoUrl != null ? NetworkImage(_currentUser!.photoUrl!) : null,
            backgroundColor: Colors.white24,
            child: _currentUser!.photoUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(_currentUser!.displayName ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(_currentUser!.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _handleSignOut,
          icon: const Icon(Icons.logout, size: 16),
          label: Text(LanguageHelper.t('লগআউট', 'Logout')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        )
      ],
    );
  }

  Widget _buildLoggedOutHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(Icons.person_outline, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 25),
        (_isLoading || _isCheckingAuth)
            ? const CircularProgressIndicator(color: Colors.white)
            : ElevatedButton.icon(
                onPressed: _handleSignIn,
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                ),
                label: Text(LanguageHelper.t('Google দিয়ে লগইন করুন', 'Login with Google'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 5,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6)));
  }

  Widget _buildOptionCard({required IconData icon, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }
}