import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import 'base_provider_register_screen.dart';

class RecicladorRegisterScreen extends BaseProviderRegisterScreen {
  const RecicladorRegisterScreen({super.key});

  @override
  State<RecicladorRegisterScreen> createState() => _RecicladorRegisterScreenState();
}

class _RecicladorRegisterScreenState extends BaseProviderRegisterScreenState<RecicladorRegisterScreen> {
  @override
  String get providerType => 'Reciclador';
  
  @override
  String get providerTitle => 'Registro Reciclador';
  
  @override
  String get providerSubtitle => 'Procesamiento y reciclaje de materiales';
  
  @override
  IconData get providerIcon => Icons.recycling;
  
  @override
  Color get providerColor => BioWayColors.recycleOrange;
  
  @override
  String get folioPrefix => 'R';
}