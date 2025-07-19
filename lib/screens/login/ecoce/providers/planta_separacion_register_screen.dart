import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import 'base_provider_register_screen.dart';

class PlantaSeparacionRegisterScreen extends BaseProviderRegisterScreen {
  const PlantaSeparacionRegisterScreen({super.key});

  @override
  State<PlantaSeparacionRegisterScreen> createState() => _PlantaSeparacionRegisterScreenState();
}

class _PlantaSeparacionRegisterScreenState extends BaseProviderRegisterScreenState<PlantaSeparacionRegisterScreen> {
  @override
  String get providerType => 'Planta de Separación';
  
  @override
  String get providerTitle => 'Registro Planta de Separación';
  
  @override
  String get providerSubtitle => 'Separación y clasificación de materiales';
  
  @override
  IconData get providerIcon => Icons.factory;
  
  @override
  Color get providerColor => BioWayColors.ecoceGreen;
  
  @override
  String get folioPrefix => 'P';
}