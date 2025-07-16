import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import 'base_provider_register_screen.dart';

class AcopiadorRegisterScreen extends BaseProviderRegisterScreen {
  const AcopiadorRegisterScreen({super.key});

  @override
  State<AcopiadorRegisterScreen> createState() => _AcopiadorRegisterScreenState();
}

class _AcopiadorRegisterScreenState extends BaseProviderRegisterScreenState<AcopiadorRegisterScreen> {
  @override
  String get providerType => 'Acopiador';
  
  @override
  String get providerTitle => 'Registro Acopiador';
  
  @override
  String get providerSubtitle => 'Centro de acopio de materiales';
  
  @override
  IconData get providerIcon => Icons.warehouse;
  
  @override
  Color get providerColor => BioWayColors.darkGreen;
  
  @override
  String get folioPrefix => 'A';
}