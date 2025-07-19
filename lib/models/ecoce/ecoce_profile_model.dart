import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados de aprobación para perfiles ECOCE
enum EcoceApprovalStatus {
  pending(0, 'Pendiente'),
  approved(1, 'Aprobado'),
  rejected(2, 'Rechazado');

  final int value;
  final String label;
  
  const EcoceApprovalStatus(this.value, this.label);
  
  static EcoceApprovalStatus fromValue(int value) {
    return EcoceApprovalStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EcoceApprovalStatus.pending,
    );
  }
}

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
  final String ecoceTipoActor; // Enumerado: O (Origen), R, T, V, L, D
  final String? ecoceSubtipo; // Para Origen: A (Acopiador), P (Planta). Null para otros tipos
  final String ecoceNombre; // Nombre del proveedor (max 50 chars)
  final String ecoceFolio; // Folio único del sistema (A0000001, P0000001, etc.)
  
  // Información fiscal
  final String? ecoceRfc; // RFC opcional (13 chars)
  
  // Datos de contacto
  final String ecoceNombreContacto; // Nombre del contacto (max 50 chars)
  final String ecoceCorreoContacto; // Correo del contacto (max 50 chars)
  final String ecoceTelContacto; // Teléfono contacto (max 15 chars)
  final String ecoceTelEmpresa; // Teléfono empresa (max 15 chars)
  
  // Ubicación física
  final String ecoceCalle; // Dirección calle (max 50 chars)
  final String ecoceNumExt; // Número exterior (max 10 chars)
  final String ecoceCp; // Código postal (5 chars)
  final String? ecoceEstado; // Estado
  final String? ecoceMunicipio; // Municipio
  final String? ecoceColonia; // Colonia
  final String? ecoceRefUbi; // Referencias adicionales (max 150 chars)
  final String? ecoceLinkMaps; // Link de Google Maps generado automáticamente
  final String? ecocePoligonoLoc; // Zona asignada (max 50 chars)
  final double? ecoceLatitud; // Coordenada latitud
  final double? ecoceLongitud; // Coordenada longitud
  
  // Información operativa
  final DateTime ecoceFechaReg; // Fecha de registro (AAAA-MM-DD)
  final List<String> ecoceListaMateriales; // Materiales que maneja (checkboxes múltiples)
  final bool? ecoceTransporte; // Si cuenta con transporte propio
  final String? ecoceLinkRedSocial; // Link a red social (max 150 chars)
  
  // Estado de aprobación
  final int ecoceEstatusAprobacion; // 0 = Pendiente, 1 = Aprobado, 2 = Rechazado
  final DateTime? ecoceFechaAprobacion; // Fecha cuando fue aprobado/rechazado
  final String? ecoceAprobadoPor; // ID del usuario maestro que aprobó
  final String? ecoceComentariosRevision; // Comentarios de la revisión
  
  // Documentos fiscales (archivos PDF)
  final String? ecoceConstSitFis; // URL/referencia Constancia de Situación Fiscal
  final String? ecoceCompDomicilio; // URL/referencia Comprobante de Domicilio
  final String? ecoceBancoCaratula; // URL/referencia Carátula de Banco
  final String? ecoceIne; // URL/referencia Identificación oficial
  
  // Campos adicionales para Origen (Acopiador y Planta de Separación)
  final Map<String, double>? ecoceDimCap; // Dimensiones de prensado {largo, ancho}
  final double? ecocePesoCap; // Peso de prensado en kg (formato 5.3 hasta 99999.999)
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  EcoceProfileModel({
    required this.id,
    required this.ecoceTipoActor,
    this.ecoceSubtipo,
    required this.ecoceNombre,
    required this.ecoceFolio,
    this.ecoceRfc,
    required this.ecoceNombreContacto,
    required this.ecoceCorreoContacto,
    required this.ecoceTelContacto,
    required this.ecoceTelEmpresa,
    required this.ecoceCalle,
    required this.ecoceNumExt,
    required this.ecoceCp,
    this.ecoceEstado,
    this.ecoceMunicipio,
    this.ecoceColonia,
    this.ecoceRefUbi,
    this.ecoceLinkMaps,
    this.ecocePoligonoLoc,
    this.ecoceLatitud,
    this.ecoceLongitud,
    required this.ecoceFechaReg,
    required this.ecoceListaMateriales,
    this.ecoceTransporte,
    this.ecoceLinkRedSocial,
    this.ecoceEstatusAprobacion = 0, // Por defecto pendiente
    this.ecoceFechaAprobacion,
    this.ecoceAprobadoPor,
    this.ecoceComentariosRevision,
    this.ecoceConstSitFis,
    this.ecoceCompDomicilio,
    this.ecoceBancoCaratula,
    this.ecoceIne,
    this.ecoceDimCap,
    this.ecocePesoCap,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir de Firebase Document
  factory EcoceProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EcoceProfileModel(
      id: doc.id,
      ecoceTipoActor: data['ecoce_tipo_actor'] ?? '',
      ecoceSubtipo: data['ecoce_subtipo'],
      ecoceNombre: data['ecoce_nombre'] ?? '',
      ecoceFolio: data['ecoce_folio'] ?? '',
      ecoceRfc: data['ecoce_rfc'],
      ecoceNombreContacto: data['ecoce_nombre_contacto'] ?? '',
      ecoceCorreoContacto: data['ecoce_correo_contacto'] ?? '',
      ecoceTelContacto: data['ecoce_tel_contacto'] ?? '',
      ecoceTelEmpresa: data['ecoce_tel_empresa'] ?? '',
      ecoceCalle: data['ecoce_calle'] ?? '',
      ecoceNumExt: data['ecoce_num_ext'] ?? '',
      ecoceCp: data['ecoce_cp'] ?? '',
      ecoceEstado: data['ecoce_estado'],
      ecoceMunicipio: data['ecoce_municipio'],
      ecoceColonia: data['ecoce_colonia'],
      ecoceRefUbi: data['ecoce_ref_ubi'],
      ecoceLinkMaps: data['ecoce_link_maps'],
      ecocePoligonoLoc: data['ecoce_poligono_loc'],
      ecoceLatitud: data['ecoce_latitud']?.toDouble(),
      ecoceLongitud: data['ecoce_longitud']?.toDouble(),
      ecoceFechaReg: (data['ecoce_fecha_reg'] as Timestamp).toDate(),
      ecoceListaMateriales: List<String>.from(data['ecoce_lista_materiales'] ?? []),
      ecoceTransporte: data['ecoce_transporte'],
      ecoceLinkRedSocial: data['ecoce_link_red_social'],
      ecoceEstatusAprobacion: data['ecoce_estatus_aprobacion'] ?? 0,
      ecoceFechaAprobacion: data['ecoce_fecha_aprobacion'] != null 
          ? (data['ecoce_fecha_aprobacion'] as Timestamp).toDate() 
          : null,
      ecoceAprobadoPor: data['ecoce_aprobado_por'],
      ecoceComentariosRevision: data['ecoce_comentarios_revision'],
      ecoceConstSitFis: data['ecoce_const_sit_fis'],
      ecoceCompDomicilio: data['ecoce_comp_domicilio'],
      ecoceBancoCaratula: data['ecoce_banco_caratula'],
      ecoceIne: data['ecoce_ine'],
      ecoceDimCap: data['ecoce_dim_cap'] != null 
          ? Map<String, double>.from(data['ecoce_dim_cap'])
          : null,
      ecocePesoCap: data['ecoce_peso_cap']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'ecoce_tipo_actor': ecoceTipoActor,
      'ecoce_subtipo': ecoceSubtipo,
      'ecoce_nombre': ecoceNombre,
      'ecoce_folio': ecoceFolio,
      'ecoce_rfc': ecoceRfc,
      'ecoce_nombre_contacto': ecoceNombreContacto,
      'ecoce_correo_contacto': ecoceCorreoContacto,
      'ecoce_tel_contacto': ecoceTelContacto,
      'ecoce_tel_empresa': ecoceTelEmpresa,
      'ecoce_calle': ecoceCalle,
      'ecoce_num_ext': ecoceNumExt,
      'ecoce_cp': ecoceCp,
      'ecoce_estado': ecoceEstado,
      'ecoce_municipio': ecoceMunicipio,
      'ecoce_colonia': ecoceColonia,
      'ecoce_ref_ubi': ecoceRefUbi,
      'ecoce_link_maps': ecoceLinkMaps,
      'ecoce_poligono_loc': ecocePoligonoLoc,
      'ecoce_latitud': ecoceLatitud,
      'ecoce_longitud': ecoceLongitud,
      'ecoce_fecha_reg': Timestamp.fromDate(ecoceFechaReg),
      'ecoce_lista_materiales': ecoceListaMateriales,
      'ecoce_transporte': ecoceTransporte,
      'ecoce_link_red_social': ecoceLinkRedSocial,
      'ecoce_estatus_aprobacion': ecoceEstatusAprobacion,
      'ecoce_fecha_aprobacion': ecoceFechaAprobacion != null 
          ? Timestamp.fromDate(ecoceFechaAprobacion!) 
          : null,
      'ecoce_aprobado_por': ecoceAprobadoPor,
      'ecoce_comentarios_revision': ecoceComentariosRevision,
      'ecoce_const_sit_fis': ecoceConstSitFis,
      'ecoce_comp_domicilio': ecoceCompDomicilio,
      'ecoce_banco_caratula': ecoceBancoCaratula,
      'ecoce_ine': ecoceIne,
      'ecoce_dim_cap': ecoceDimCap,
      'ecoce_peso_cap': ecocePesoCap,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Método para verificar si es usuario Origen (Acopiador o Planta de Separación)
  bool get isOrigen => ecoceTipoActor == 'O';
  
  // Métodos para identificar subtipo de usuario origen
  bool get isAcopiador => ecoceTipoActor == 'O' && ecoceSubtipo == 'A';
  bool get isPlantaSeparacion => ecoceTipoActor == 'O' && ecoceSubtipo == 'P';

  // Métodos auxiliares para estado de aprobación
  bool get isPending => ecoceEstatusAprobacion == 0;
  bool get isApproved => ecoceEstatusAprobacion == 1;
  bool get isRejected => ecoceEstatusAprobacion == 2;
  
  EcoceApprovalStatus get approvalStatus => EcoceApprovalStatus.fromValue(ecoceEstatusAprobacion);
  
  // Método para obtener el nombre del tipo de actor
  String get tipoActorLabel {
    switch (ecoceTipoActor) {
      case 'O':
        // Para usuarios origen, usar el subtipo
        switch (ecoceSubtipo) {
          case 'A':
            return 'Acopiador';
          case 'P':
            return 'Planta de Separación';
          default:
            return 'Usuario Origen';
        }
      case 'R':
        return 'Reciclador';
      case 'T':
        return 'Transformador';
      case 'V':
        return 'Transportista';
      case 'L':
        return 'Laboratorio';
      case 'D':
        return 'Desarrollo de Mercado';
      default:
        return 'Desconocido';
    }
  }

  // Obtener lista de materiales según el tipo de usuario
  static List<Map<String, String>> getMaterialesByTipo(String tipoActor, [String? subtipo]) {
    switch (tipoActor) {
      case 'O': // Usuario Origen
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