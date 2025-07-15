import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import 'base_provider_register_screen.dart';

class LaboratorioRegisterScreen extends BaseProviderRegisterScreen {
  const LaboratorioRegisterScreen({super.key});

  @override
  State<LaboratorioRegisterScreen> createState() => _LaboratorioRegisterScreenState();
}

class _LaboratorioRegisterScreenState extends BaseProviderRegisterScreenState<LaboratorioRegisterScreen> {
  @override
  String get providerType => 'Laboratorio';
  
  @override
  String get providerTitle => 'Registro Laboratorio';
  
  @override
  String get providerSubtitle => 'Análisis y certificación de calidad';
  
  @override
  IconData get providerIcon => Icons.science;
  
  @override
  Color get providerColor => BioWayColors.otherPurple;
  
  @override
  String get folioPrefix => 'L';
  
  // Personalización del paso 3 para laboratorio
  @override
  Widget buildOperationsStep() {
    // Los laboratorios pueden tener campos específicos diferentes
    // Por ahora usamos el mismo que los demás
    return super.buildOperationsStep();
  }
}