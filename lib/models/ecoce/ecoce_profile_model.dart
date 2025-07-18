import 'package:cloud_firestore/cloud_firestore.dart';

enum EcoceTipoActor {
  A, // Acopiador
  P, // Planta de selección  
  R, // Reciclador
  T, // Transformador
  V, // Transportista
  L, // Laboratorio
  D, // Desarrollo de Mercado
}

class EcoceProfileModel {
  // Identificación
  final String id; // Firebase document ID
  final String ecoce_tipo_actor; // Enumerado: A, P, R, T, V, L, D
  final String ecoce_nombre; // Nombre del proveedor (max 50 chars)
  final String ecoce_folio; // Folio único del sistema (A0000001, P0000001, etc.)
  
  // Información fiscal
  final String? ecoce_rfc; // RFC opcional (13 chars)
  
  // Datos de contacto
  final String ecoce_nombre_contacto; // Nombre del contacto (max 50 chars)
  final String ecoce_correo_contacto; // Correo del contacto (max 50 chars)
  final String ecoce_tel_contacto; // Teléfono contacto (max 15 chars)
  final String ecoce_tel_empresa; // Teléfono empresa (max 15 chars)
  
  // Ubicación física
  final String ecoce_calle; // Dirección calle (max 50 chars)
  final String ecoce_num_ext; // Número exterior (max 10 chars)
  final String ecoce_cp; // Código postal (5 chars)
  final String? ecoce_estado; // Estado
  final String? ecoce_municipio; // Municipio
  final String? ecoce_colonia; // Colonia
  final String? ecoce_ref_ubi; // Referencias adicionales (max 150 chars)
  final String? ecoce_link_maps; // Link de Google Maps generado automáticamente
  final String? ecoce_poligono_loc; // Zona asignada (max 50 chars)
  
  // Información operativa
  final DateTime ecoce_fecha_reg; // Fecha de registro (AAAA-MM-DD)
  final List<String> ecoce_lista_materiales; // Materiales que maneja (checkboxes múltiples)
  final bool? ecoce_transporte; // Si cuenta con transporte propio
  final String? ecoce_link_red_social; // Link a red social (max 150 chars)
  
  // Documentos fiscales (archivos PDF)
  final String? ecoce_const_sit_fis; // URL/referencia Constancia de Situación Fiscal
  final String? ecoce_comp_domicilio; // URL/referencia Comprobante de Domicilio
  final String? ecoce_banco_caratula; // URL/referencia Carátula de Banco
  final String? ecoce_ine; // URL/referencia Identificación oficial
  
  // Campos adicionales para Origen (Acopiador y Planta de Separación)
  final Map<String, double>? ecoce_dim_cap; // Dimensiones de prensado {largo, ancho}
  final double? ecoce_peso_cap; // Peso de prensado en kg (formato 5.3 hasta 99999.999)
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  EcoceProfileModel({
    required this.id,
    required this.ecoce_tipo_actor,
    required this.ecoce_nombre,
    required this.ecoce_folio,
    this.ecoce_rfc,
    required this.ecoce_nombre_contacto,
    required this.ecoce_correo_contacto,
    required this.ecoce_tel_contacto,
    required this.ecoce_tel_empresa,
    required this.ecoce_calle,
    required this.ecoce_num_ext,
    required this.ecoce_cp,
    this.ecoce_estado,
    this.ecoce_municipio,
    this.ecoce_colonia,
    this.ecoce_ref_ubi,
    this.ecoce_link_maps,
    this.ecoce_poligono_loc,
    required this.ecoce_fecha_reg,
    required this.ecoce_lista_materiales,
    this.ecoce_transporte,
    this.ecoce_link_red_social,
    this.ecoce_const_sit_fis,
    this.ecoce_comp_domicilio,
    this.ecoce_banco_caratula,
    this.ecoce_ine,
    this.ecoce_dim_cap,
    this.ecoce_peso_cap,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir de Firebase Document
  factory EcoceProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EcoceProfileModel(
      id: doc.id,
      ecoce_tipo_actor: data['ecoce_tipo_actor'] ?? '',
      ecoce_nombre: data['ecoce_nombre'] ?? '',
      ecoce_folio: data['ecoce_folio'] ?? '',
      ecoce_rfc: data['ecoce_rfc'],
      ecoce_nombre_contacto: data['ecoce_nombre_contacto'] ?? '',
      ecoce_correo_contacto: data['ecoce_correo_contacto'] ?? '',
      ecoce_tel_contacto: data['ecoce_tel_contacto'] ?? '',
      ecoce_tel_empresa: data['ecoce_tel_empresa'] ?? '',
      ecoce_calle: data['ecoce_calle'] ?? '',
      ecoce_num_ext: data['ecoce_num_ext'] ?? '',
      ecoce_cp: data['ecoce_cp'] ?? '',
      ecoce_estado: data['ecoce_estado'],
      ecoce_municipio: data['ecoce_municipio'],
      ecoce_colonia: data['ecoce_colonia'],
      ecoce_ref_ubi: data['ecoce_ref_ubi'],
      ecoce_link_maps: data['ecoce_link_maps'],
      ecoce_poligono_loc: data['ecoce_poligono_loc'],
      ecoce_fecha_reg: (data['ecoce_fecha_reg'] as Timestamp).toDate(),
      ecoce_lista_materiales: List<String>.from(data['ecoce_lista_materiales'] ?? []),
      ecoce_transporte: data['ecoce_transporte'],
      ecoce_link_red_social: data['ecoce_link_red_social'],
      ecoce_const_sit_fis: data['ecoce_const_sit_fis'],
      ecoce_comp_domicilio: data['ecoce_comp_domicilio'],
      ecoce_banco_caratula: data['ecoce_banco_caratula'],
      ecoce_ine: data['ecoce_ine'],
      ecoce_dim_cap: data['ecoce_dim_cap'] != null 
          ? Map<String, double>.from(data['ecoce_dim_cap'])
          : null,
      ecoce_peso_cap: data['ecoce_peso_cap']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'ecoce_tipo_actor': ecoce_tipo_actor,
      'ecoce_nombre': ecoce_nombre,
      'ecoce_folio': ecoce_folio,
      'ecoce_rfc': ecoce_rfc,
      'ecoce_nombre_contacto': ecoce_nombre_contacto,
      'ecoce_correo_contacto': ecoce_correo_contacto,
      'ecoce_tel_contacto': ecoce_tel_contacto,
      'ecoce_tel_empresa': ecoce_tel_empresa,
      'ecoce_calle': ecoce_calle,
      'ecoce_num_ext': ecoce_num_ext,
      'ecoce_cp': ecoce_cp,
      'ecoce_estado': ecoce_estado,
      'ecoce_municipio': ecoce_municipio,
      'ecoce_colonia': ecoce_colonia,
      'ecoce_ref_ubi': ecoce_ref_ubi,
      'ecoce_link_maps': ecoce_link_maps,
      'ecoce_poligono_loc': ecoce_poligono_loc,
      'ecoce_fecha_reg': Timestamp.fromDate(ecoce_fecha_reg),
      'ecoce_lista_materiales': ecoce_lista_materiales,
      'ecoce_transporte': ecoce_transporte,
      'ecoce_link_red_social': ecoce_link_red_social,
      'ecoce_const_sit_fis': ecoce_const_sit_fis,
      'ecoce_comp_domicilio': ecoce_comp_domicilio,
      'ecoce_banco_caratula': ecoce_banco_caratula,
      'ecoce_ine': ecoce_ine,
      'ecoce_dim_cap': ecoce_dim_cap,
      'ecoce_peso_cap': ecoce_peso_cap,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Método para verificar si es usuario Origen (Acopiador o Planta de Separación)
  bool get isOrigen => ecoce_tipo_actor == 'A' || ecoce_tipo_actor == 'P';

  // Obtener lista de materiales según el tipo de usuario
  static List<Map<String, String>> getMaterialesByTipo(String tipoActor) {
    switch (tipoActor) {
      case 'A': // Acopiador (Usuario Origen)
      case 'P': // Planta de Separación (Usuario Origen)
        return [
          {'id': 'ecoce_epf_poli', 'label': 'EPF - Poli (PE)'},
          {'id': 'ecoce_epf_pp', 'label': 'EPF - PP'},
          {'id': 'ecoce_epf_multi', 'label': 'EPF - Multi'},
        ];
      case 'R': // Reciclador
        return [
          {'id': 'ecoce_epf_separados', 'label': 'EPF separados por tipo'},
          {'id': 'ecoce_epf_semiseparados', 'label': 'EPF semiseparados'},
          {'id': 'ecoce_epf_pacas', 'label': 'EPF en pacas'},
          {'id': 'ecoce_epf_sacos', 'label': 'EPF en sacos'},
          {'id': 'ecoce_epf_granel', 'label': 'EPF a granel'},
          {'id': 'ecoce_epf_limpios', 'label': 'EPF limpios'},
          {'id': 'ecoce_epf_cont_leve', 'label': 'EPF con contaminación leve'},
        ];
      case 'T': // Transformador
        return [
          {'id': 'ecoce_pellets_poli', 'label': 'Pellets reciclados - Poli'},
          {'id': 'ecoce_pellets_pp', 'label': 'Pellets reciclados - PP'},
          {'id': 'ecoce_hojuelas_poli', 'label': 'Hojuelas recicladas - Poli'},
          {'id': 'ecoce_hojuelas_pp', 'label': 'Hojuelas recicladas - PP'},
        ];
      case 'L': // Laboratorio
        return [
          {'id': 'ecoce_muestra_pe', 'label': 'Muestras PE'},
          {'id': 'ecoce_muestra_pp', 'label': 'Muestras PP'},
          {'id': 'ecoce_muestra_multi', 'label': 'Muestras Multi'},
          {'id': 'ecoce_hojuelas', 'label': 'Hojuelas'},
          {'id': 'ecoce_pellets', 'label': 'Pellets reciclados'},
          {'id': 'ecoce_productos', 'label': 'Productos transformados'},
        ];
      default:
        return [];
    }
  }
}