import 'package:flutter/material.dart';

class AppTextInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;
  final bool readOnly;

  const AppTextInput({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.readOnly = false,
  });

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  bool _obscureText = false;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode?.hasFocus ?? false;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _validateInput(String? value) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Input Container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.enabled 
                ? (isDark ? Colors.grey[800] : Colors.white)
                : (isDark ? Colors.grey[900] : Colors.grey[100]),
            border: Border.all(
              color: _getBorderColor(theme, isDark),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused 
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Prefix Icon
              if (widget.prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: _getIconColor(theme, isDark),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Text Field
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  obscureText: _obscureText,
                  enabled: widget.enabled,
                  focusNode: widget.focusNode,
                  textInputAction: widget.textInputAction,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  autofocus: widget.autofocus,
                  readOnly: widget.readOnly,
                  onChanged: (value) {
                    widget.onChanged?.call(value);
                    _validateInput(value);
                  },
                  onFieldSubmitted: widget.onSubmitted,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.enabled 
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    counterText: '', // Hide character counter
                  ),
                ),
              ),
              
              // Suffix Icon
              if (widget.suffixIcon != null || widget.obscureText) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: widget.obscureText 
                      ? _togglePasswordVisibility
                      : widget.onSuffixIconPressed,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      widget.obscureText
                          ? (_obscureText ? Icons.visibility : Icons.visibility_off)
                          : widget.suffixIcon,
                      size: 20,
                      color: _getIconColor(theme, isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Error Text
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorText!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Color _getBorderColor(ThemeData theme, bool isDark) {
    if (!widget.enabled) {
      return isDark ? Colors.grey[700]! : Colors.grey[300]!;
    }
    if (_errorText != null) {
      return Colors.red[400]!;
    }
    if (_isFocused) {
      return theme.primaryColor;
    }
    return isDark ? Colors.grey[600]! : Colors.grey[300]!;
  }

  Color _getIconColor(ThemeData theme, bool isDark) {
    if (!widget.enabled) {
      return isDark ? Colors.grey[500]! : Colors.grey[400]!;
    }
    return isDark ? Colors.grey[400]! : Colors.grey[600]!;
  }
}
