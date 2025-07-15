import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import 'base_provider_register_screen.dart';

class TransformadorRegisterScreen extends BaseProviderRegisterScreen {
  const TransformadorRegisterScreen({super.key});

  @override
  State<TransformadorRegisterScreen> createState() => _TransformadorRegisterScreenState();
}

class _TransformadorRegisterScreenState extends BaseProviderRegisterScreenState<TransformadorRegisterScreen> {
  @override
  String get providerType => 'Transformador';
  
  @override
  String get providerTitle => 'Registro Transformador';
  
  @override
  String get providerSubtitle => 'Transformación de materiales reciclados';
  
  @override
  IconData get providerIcon => Icons.auto_fix_high;
  
  @override
  Color get providerColor => BioWayColors.petBlue;
  
  @override
  String get folioPrefix => 'T';
}