# ECOCE - Sistema de Trazabilidad de Reciclaje

<div align="center">
  <h3>Sistema completo de trazabilidad para materiales reciclables en México</h3>
  <p>
    <a href="#características">Características</a> •
    <a href="#instalación">Instalación</a> •
    <a href="#configuración">Configuración</a> •
    <a href="#uso">Uso</a> •
    <a href="#arquitectura">Arquitectura</a> •
    <a href="#documentación">Documentación</a>
  </p>
</div>

## 📋 Descripción

ECOCE Trazabilidad es una aplicación móvil Flutter que proporciona trazabilidad completa para materiales reciclables a través de toda la cadena de suministro. Utiliza códigos QR para el seguimiento en tiempo real y soporta múltiples tipos de usuarios con flujos de trabajo específicos.

### Estado del Proyecto
- **Versión**: 1.0.0+1
- **Plataforma ECOCE**: ✅ En producción
- **Última actualización**: 2025-08-08

## ✨ Características

### Sistema Unificado de Lotes
- **ID único inmutable** que persiste durante todo el ciclo de vida
- **Tracking en tiempo real** mediante códigos QR
- **Transferencias automáticas** con validación bidireccional
- **Historial completo** preservado en cada etapa

### Tipos de Usuario
1. **Origen** (Centros de Acopio y Plantas de Separación)
2. **Transportista** (Recolección y entrega)
3. **Reciclador** (Procesamiento de materiales)
4. **Laboratorio** (Análisis de muestras - proceso paralelo)
5. **Transformador** (Producción final)
6. **Maestro** (Administración del sistema)
7. **Repositorio** (Visualización completa - solo lectura)

### Características Técnicas
- **Firebase dedicado** para ECOCE
- **Compresión automática** de imágenes (50KB) y PDFs (5MB)
- **Firmas digitales** con captura y almacenamiento seguro
- **Cálculo dinámico de pesos** con sustracción automática de muestras
- **Navegación optimizada** con prevención de logout accidental

## 🚀 Instalación

### Requisitos Previos
- Flutter SDK ^3.8.1
- Dart SDK compatible
- Android Studio / VS Code con extensiones Flutter
- Emulador Android o dispositivo físico
- Firebase CLI (para configuración)

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/tu-organizacion/bioway-mexico.git
cd bioway-mexico
```

2. **Instalar dependencias**
```bash
flutter clean
flutter pub get
```

3. **Verificar instalación**
```bash
flutter doctor
```

4. **Ejecutar la aplicación**
```bash
# En emulador específico
flutter run -d emulator-5554

# En todos los dispositivos disponibles
flutter run -d all
```

## ⚙️ Configuración

### Firebase (ECOCE - Ya configurado)
La plataforma ECOCE ya está configurada y funcionando. El archivo `google-services.json` está incluido en el proyecto.

### Firebase (BioWay - Pendiente)
Para configurar la plataforma BioWay:

1. Crear proyecto Firebase con ID: `bioway-mexico`
2. Agregar app Android: `com.biowaymexico.app`
3. Descargar y agregar `google-services.json`
4. Actualizar `lib/services/firebase/firebase_config.dart` con las credenciales

### Google Maps API (Opcional)
Para habilitar el selector de ubicación:
1. Obtener API key de Google Cloud Console
2. Actualizar `lib/config/google_maps_config.dart`

### Reglas de Firebase Storage
Aplicar las siguientes reglas en Firebase Console:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /ecoce/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 📱 Uso

### Flujo Principal

1. **Selección de Plataforma**
   - Al iniciar, seleccionar entre ECOCE o BioWay

2. **Autenticación**
   - Login con credenciales aprobadas
   - Registro requiere aprobación del Maestro

3. **Operaciones por Usuario**
   
   **Origen**:
   - Crear nuevos lotes
   - Generar códigos QR
   - Ver estadísticas de producción
   
   **Transportista**:
   - Escanear QR para recoger
   - Crear cargas con múltiples lotes
   - Entregar mediante QR temporal
   
   **Reciclador**:
   - Recibir lotes del transportista
   - Procesar materiales
   - Preparar para siguiente fase
   
   **Laboratorio**:
   - Tomar muestras sin transferir propiedad
   - Subir certificados de análisis
   - Ver historial de muestras

### Códigos QR

El sistema utiliza 4 tipos de códigos QR:

1. **USER-[TIPO]-[ID]**: Identificación de usuarios
2. **LOTE-[MATERIAL]-[ID]**: Tracking de lotes individuales
3. **CARGA-[ID]**: Agrupación para transporte
4. **ENTREGA-[ID]**: Transferencia temporal (15 min)

## 🏗️ Arquitectura

### Estructura del Proyecto
```
lib/
├── screens/          # Pantallas organizadas por usuario
├── services/         # Lógica de negocio y Firebase
├── models/           # Modelos de datos
├── utils/            # Utilidades (colores, formatos)
└── widgets/          # Componentes reutilizables
```

### Modelo de Datos Principal
```dart
LoteUnificadoModel {
  String id                    // ID único inmutable
  DatosGeneralesLote          // Información general
  ProcesoOrigenData?          // Datos de origen
  Map<String, ProcesoTransporteData> // Fases de transporte
  ProcesoRecicladorData?      // Datos del reciclador
  List<AnalisisLaboratorioData> // Análisis de laboratorio
  ProcesoTransformadorData?   // Datos del transformador
}
```

### Base de Datos (Firestore)
```
lotes/
└── [loteId]/
    ├── datos_generales/
    ├── origen/
    ├── transporte/
    │   ├── fase_1/
    │   └── fase_2/
    ├── reciclador/
    ├── analisis_laboratorio/
    └── transformador/
```

## 📚 Documentación

### Documentos Principales
- **[CLAUDE.md](./CLAUDE.md)** - Guía técnica detallada para desarrollo
- **[docs/SISTEMA_TRAZABILIDAD_COMPLETO.md](./docs/SISTEMA_TRAZABILIDAD_COMPLETO.md)** - Documentación completa del sistema

### Guías Específicas
- Configuración Firebase: `docs/FIX_FIREBASE_CONFIG.md`
- Cloud Functions: `docs/CLOUD_FUNCTION_DELETE_USERS.md`
- Soluciones implementadas: `docs/SOLUCION_*.md`

## 🧪 Testing

```bash
# Ejecutar todas las pruebas
flutter test

# Pruebas con cobertura
flutter test --coverage

# Prueba específica
flutter test test/widget_test.dart
```

## 🏗️ Build

### Android

```bash
# APK Debug
flutter build apk --debug

# APK Release
flutter build apk --release

# App Bundle (para Play Store)
flutter build appbundle
```

### iOS

```bash
# Requiere macOS y configuración adicional
flutter build ios
```

## 🐛 Troubleshooting

### Problemas Comunes

1. **"No Firebase App has been created"**
   - Verificar que se seleccionó una plataforma (ECOCE/BioWay)
   - Confirmar que `google-services.json` está en su lugar

2. **Documentos no se visualizan**
   - Verificar reglas de Firebase Storage
   - Confirmar permisos del usuario autenticado

3. **QR no se escanea**
   - Verificar permisos de cámara
   - Confirmar formato correcto del QR

4. **Lotes no aparecen después de transferencia**
   - Verificar campo `proceso_actual`
   - Confirmar que ambas partes completaron la transferencia

## 👥 Contribución

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/NuevaCaracteristica`)
3. Commit cambios (`git commit -m 'Agregar nueva característica'`)
4. Push al branch (`git push origin feature/NuevaCaracteristica`)
5. Abrir Pull Request

### Estándares de Código
- Usar `flutter analyze` antes de commits
- Seguir convenciones de nombres en `CLAUDE.md`
- Mantener documentación actualizada
- Agregar tests para nuevas características

## 📄 Licencia

Este proyecto es propiedad privada de BioWay México. Todos los derechos reservados.

## 🆘 Soporte

Para soporte técnico o preguntas:
- Revisar documentación en `/docs`
- Contactar al equipo de desarrollo
- Crear issue en el repositorio

---

<div align="center">
  <p>Desarrollado con ❤️ para un México más sustentable</p>
</div>