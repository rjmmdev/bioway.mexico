import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../utils/colors.dart';
import '../../../../utils/ui_constants.dart';

class WeightInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final Color primaryColor;
  final double? minValue;
  final double? maxValue;
  final double incrementValue;
  final List<int> quickAddValues;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool isRequired;

  const WeightInputWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.primaryColor,
    this.minValue = 0.0,
    this.maxValue = 99999.99,
    this.incrementValue = 1.0,
    this.quickAddValues = const [100, 250, 500, 1000],
    this.onChanged,
    this.validator,
    this.isRequired = false,
  });

  @override
  State<WeightInputWidget> createState() => _WeightInputWidgetState();
}

class _WeightInputWidgetState extends State<WeightInputWidget> {
  Timer? _incrementTimer;
  Timer? _decrementTimer;

  @override
  void dispose() {
    _incrementTimer?.cancel();
    _decrementTimer?.cancel();
    super.dispose();
  }

  void _startIncrement() {
    HapticFeedback.lightImpact();
    _incrementWeight();
    
    _incrementTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _incrementWeight();
    });
  }
  
  void _stopIncrement() {
    _incrementTimer?.cancel();
    _incrementTimer = null;
  }
  
  void _incrementWeight() {
    final currentValue = double.tryParse(widget.controller.text) ?? 0.0;
    if (currentValue < (widget.maxValue ?? 99999.99)) {
      final newValue = (currentValue + widget.incrementValue)
          .clamp(widget.minValue ?? 0.0, widget.maxValue ?? 99999.99);
      widget.controller.text = newValue.toStringAsFixed(2);
      widget.onChanged?.call(widget.controller.text);
    }
  }
  
  void _startDecrement() {
    HapticFeedback.lightImpact();
    _decrementWeight();
    
    _decrementTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _decrementWeight();
    });
  }
  
  void _stopDecrement() {
    _decrementTimer?.cancel();
    _decrementTimer = null;
  }
  
  void _decrementWeight() {
    final currentValue = double.tryParse(widget.controller.text) ?? 0.0;
    if (currentValue > (widget.minValue ?? 0.0)) {
      final newValue = (currentValue - widget.incrementValue)
          .clamp(widget.minValue ?? 0.0, widget.maxValue ?? 99999.99);
      widget.controller.text = newValue.toStringAsFixed(2);
      widget.onChanged?.call(widget.controller.text);
    }
  }

  void _addQuickWeight(int weight) {
    HapticFeedback.lightImpact();
    final currentValue = double.tryParse(widget.controller.text) ?? 0.0;
    final newValue = (currentValue + weight)
        .clamp(widget.minValue ?? 0.0, widget.maxValue ?? 99999.99);
    widget.controller.text = newValue.toStringAsFixed(2);
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: BioWayColors.textGrey,
              ),
            ),
            if (widget.isRequired) ...[
              SizedBox(width: UIConstants.spacing4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: BioWayColors.error,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: screenHeight * 0.01),
        
        // Weight input container
        Container(
          decoration: BoxDecoration(
            color: BioWayColors.backgroundGrey,
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: UIConstants.opacityMedium),
              width: UIConstants.borderWidthThin,
            ),
          ),
          child: Row(
            children: [
              // Decrement button
              GestureDetector(
                onTapDown: (_) => _startDecrement(),
                onTapUp: (_) => _stopDecrement(),
                onTapCancel: () => _stopDecrement(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.03),
                      bottomLeft: Radius.circular(screenWidth * 0.03),
                    ),
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Icon(
                    Icons.remove_circle_outline,
                    color: widget.primaryColor,
                    size: screenWidth * 0.06,
                  ),
                ),
              ),
              
              // Weight input field
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}\.?\d{0,2}')),
                  ],
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final numValue = double.tryParse(value) ?? 0.0;
                      if (numValue > (widget.maxValue ?? 99999.99)) {
                        widget.controller.text = (widget.maxValue ?? 99999.99).toStringAsFixed(2);
                        widget.controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: widget.controller.text.length),
                        );
                      }
                    }
                    widget.onChanged?.call(value);
                  },
                  validator: widget.validator,
                ),
              ),
              
              // Increment button
              GestureDetector(
                onTapDown: (_) => _startIncrement(),
                onTapUp: (_) => _stopIncrement(),
                onTapCancel: () => _stopIncrement(),
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: widget.primaryColor,
                    size: screenWidth * 0.06,
                  ),
                ),
              ),
              
              // Unit label
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(screenWidth * 0.03),
                    bottomRight: Radius.circular(screenWidth * 0.03),
                  ),
                ),
                child: Text(
                  'kg',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Quick add buttons
        if (widget.quickAddValues.isNotEmpty) ...[
          SizedBox(height: screenHeight * 0.015),
          Wrap(
            spacing: screenWidth * 0.02,
            runSpacing: screenHeight * 0.01,
            alignment: WrapAlignment.center,
            children: widget.quickAddValues.map((weight) {
              final String displayText = weight >= 1000 
                  ? '+${(weight / 1000).toStringAsFixed(0)}T' 
                  : '+$weight kg';
              
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _addQuickWeight(weight),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  child: Container(
                    constraints: BoxConstraints(minWidth: screenWidth * 0.18),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      border: Border.all(
                        color: widget.primaryColor.withValues(alpha: UIConstants.opacityMedium),
                        width: UIConstants.borderWidthThin,
                      ),
                    ),
                    child: Text(
                      displayText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeSmall + 1,
                        fontWeight: FontWeight.w600,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'Toque los botones para agregar peso rápidamente',
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}