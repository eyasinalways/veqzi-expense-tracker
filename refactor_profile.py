import re

with open('lib/profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove flutter_animate import
content = re.sub(r"import 'package:flutter_animate/flutter_animate\.dart';\n?", "", content)

# 2. Add with SingleTickerProviderStateMixin
content = content.replace('class _ProfileScreenState extends State<ProfileScreen> {', 'class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {')

# 3. Add AnimationController and Animations
init_state_block = '''  late final AnimationController _animationController;
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
'''
content = content.replace('  @override\n  void initState() {\n    super.initState();', init_state_block)

# 4. Add dispose
dispose_block = '''
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
'''
content = content.replace('  Future<void> _handleSignIn() async {', dispose_block + '\n  Future<void> _handleSignIn() async {')

# 5. Remove all .animate() chains
content = re.sub(r'\.animate\(\)\.scale\(duration: \d+.*?ms, curve: Curves\.easeOutBack\)', '', content)
content = re.sub(r'\.animate\(\)\.scale\(duration: \d+.*?ms\)', '', content)
content = re.sub(r'\.animate\(\)\.fade\(duration: \d+.*?ms\)\.scale\(begin: const Offset\(0\.9, 0\.9\)\)', '', content)
content = re.sub(r'\.animate\(\)\.fade\([^)]*\)\.slideX\([^)]*\)', '', content)

# 6. Wrap _buildOptionCard calls with explicitly optimized FadeTransition and SlideTransition
card_pattern = r'(_buildOptionCard\(\s*icon:.*?onTap: .*?,?\s*\))'
def wrap_card(match):
    return f'FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: {match.group(1)}))'

content = re.sub(card_pattern, wrap_card, content, flags=re.DOTALL)

with open('lib/profile_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Refactored profile_screen.dart successfully.')
