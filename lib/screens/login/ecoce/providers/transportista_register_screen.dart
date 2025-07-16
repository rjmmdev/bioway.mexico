import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import 'base_provider_register_screen.dart';

class TransportistaRegisterScreen extends BaseProviderRegisterScreen {
  const TransportistaRegisterScreen({super.key});

  @override
  State<TransportistaRegisterScreen> createState() => _TransportistaRegisterScreenState();
}

class _TransportistaRegisterScreenState extends BaseProviderRegisterScreenState<TransportistaRegisterScreen> {
  @override
  String get providerType => 'Transportista';
  
  @override
  String get providerTitle => 'Registro Transportista';
  
  @override
  String get providerSubtitle => 'Transporte de materiales reciclables';
  
  @override
  IconData get providerIcon => Icons.local_shipping;
  
  @override
  Color get providerColor => BioWayColors.deepBlue;
  
  @override
  String get folioPrefix => 'TR';
  
  @override
  void initState() {
    super.initState();
    // Los transportistas siempre tienen transporte
    hasTransport = true;
  }
  
  @override
  Widget buildOperationsStep() {
    // Llamar al método padre pero con isTransportLocked = true
    return super.buildOperationsStep();
  }
}