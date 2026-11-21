import 'package:flutter/material.dart';
import 'language_helper.dart';

enum PinMode { create, verify, change }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final String? expectedPin; // Used for verify mode or change mode
  final ValueChanged<String>? onPinSet; // Callback when PIN is created/verified

  const PinScreen({
    super.key,
    required this.mode,
    this.expectedPin,
    this.onPinSet,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _enteredPin = '';
  String _step1Pin = ''; // Used when creating or changing
  bool _isConfirmStep = false;
  bool _hasError = false;

  void _onKeypadPressed(String value) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += value;
        _hasError = false;
      });

      if (_enteredPin.length == 4) {
        _processPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      });
    }
  }

  void _processPin() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      if (widget.mode == PinMode.verify) {
        if (_enteredPin == widget.expectedPin) {
          final canPop = Navigator.canPop(context);
          if (widget.onPinSet != null) widget.onPinSet!(_enteredPin);
          if (canPop && mounted) {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _enteredPin = '';
            _hasError = true;
          });
        }
      } else if (widget.mode == PinMode.create || widget.mode == PinMode.change) {
        if (!_isConfirmStep) {
          // First step of creating PIN
          setState(() {
            _step1Pin = _enteredPin;
            _enteredPin = '';
            _isConfirmStep = true;
          });
        } else {
          // Confirmation step
          if (_enteredPin == _step1Pin) {
            final canPop = Navigator.canPop(context);
            if (widget.onPinSet != null) widget.onPinSet!(_enteredPin);
            if (canPop && mounted) {
              Navigator.pop(context, true);
            }
          } else {
            setState(() {
              _enteredPin = '';
              _hasError = true;
            });
          }
        }
      }
    });
  }

  String _getTitle() {
    if (widget.mode == PinMode.verify) {
      return LanguageHelper.t('পিন দিন', 'Enter PIN');
    }
    if (!_isConfirmStep) {
      return widget.mode == PinMode.change 
          ? LanguageHelper.t('নতুন পিন দিন', 'Enter New PIN') 
          : LanguageHelper.t('পিন সেট করুন', 'Set PIN');
    } else {
      return LanguageHelper.t('পিনটি নিশ্চিত করুন', 'Confirm PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_outline, size: 60, color: Color(0xFF4F46E5)),
            const SizedBox(height: 20),
            Text(
              _getTitle(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_hasError)
              Text(
                widget.mode == PinMode.verify 
                    ? LanguageHelper.t('ভুল পিন, আবার চেষ্টা করুন', 'Incorrect PIN, try again')
                    : LanguageHelper.t('পিন মিলেনি, আবার চেষ্টা করুন', 'PIN mismatch, try again'),
                style: const TextStyle(color: Colors.red, fontSize: 16),
              )
            else
              const SizedBox(height: 16), // Placeholder
            const SizedBox(height: 30),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length
                        ? const Color(0xFF4F46E5)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
            const Spacer(),

            // Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 20),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 20),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 70), // empty space
                      _buildKeypadButton('0'),
                      SizedBox(
                        width: 70,
                        child: IconButton(
                          onPressed: _onBackspacePressed,
                          icon: const Icon(Icons.backspace_outlined, size: 30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildKeypadButton(k)).toList(),
    );
  }

  Widget _buildKeypadButton(String text) {
    return InkWell(
      onTap: () => _onKeypadPressed(text),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
