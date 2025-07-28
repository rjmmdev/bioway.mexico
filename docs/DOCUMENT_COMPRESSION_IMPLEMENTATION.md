# Implementación de Compresión de Documentos

## Fecha: 2025-01-28

## Descripción
Se implementó un sistema de compresión automática de documentos al CARGARLOS (no al subirlos), con restricciones de tipos de archivo y tamaños máximos. La compresión ocurre inmediatamente cuando el usuario selecciona el archivo.

## Cambios Realizados

### 1. Restricciones de Tipos de Archivo
- **Solo se permiten**: PDF, JPG, JPEG, PNG
- Otros tipos de archivo son rechazados con mensaje de error

### 2. Límites de Tamaño
- **PDFs**: Entrada máxima 5MB, salida máxima 1MB
  - Si el PDF es menor a 1MB, se carga sin cambios
  - Si el PDF está entre 1MB y 5MB, se intenta comprimir a menos de 1MB
  - Si el PDF es mayor a 5MB, se rechaza con mensaje de error
  - Si no se puede comprimir a menos de 1MB, se genera un PDF con instrucciones
  
- **Imágenes (JPG, PNG)**: Se comprimen automáticamente a menos de 50KB
  - Compresión en 3 niveles progresivos:
    1. 800x600 con calidad 60%
    2. 600x450 con calidad 40%
    3. 400x300 con calidad 30%

### 3. Archivos Modificados

#### `lib/services/document_compression_service.dart`
- Nuevo servicio para comprimir documentos
- Métodos principales:
  - `compressDocument()`: Punto de entrada principal
  - `compressPdf()`: Compresión de PDFs de hasta 5MB
  - `_compressImage()`: Compresión agresiva de imágenes
  - `getFileInfo()`: Obtener información del archivo

#### `lib/services/pdf_compression_service.dart` (NUEVO)
- Servicio especializado para compresión de PDFs
- Genera PDF con instrucciones cuando no se puede comprimir
- Preparado para implementar compresión real en el futuro

#### `lib/services/firebase/firebase_storage_service.dart`
- Actualizado `uploadFile()` para NO comprimir (ya viene comprimido)
- Actualizado `_compressImage()` para comprimir más agresivamente
- Límite máximo de 1MB para todos los archivos

#### `lib/screens/ecoce/shared/widgets/document_upload_per_requirement_widget.dart`
- Compresión inmediata al cargar el archivo
- Crea archivo temporal con datos comprimidos
- Muestra el tamaño original y comprimido
- Calcula y muestra el porcentaje de reducción
- Actualizado texto de tipos permitidos: "PDF (máx. 5MB), JPG, PNG"

#### `lib/services/document_service.dart`
- Agregado método `getTempDirectory()` para obtener directorio temporal

## Comportamiento

### Proceso de Carga:
1. Usuario selecciona archivo
2. Se muestra "Procesando archivo..."
3. El archivo se comprime inmediatamente
4. Se muestra el resultado: "Archivo optimizado: 2.5 MB → 45 KB (-98.2%)"
5. El archivo comprimido se almacena temporalmente
6. Al enviar el formulario, se sube el archivo ya comprimido

### Para PDFs:
```
< 1MB: Se carga sin cambios
1MB - 5MB: Se intenta comprimir automáticamente a < 1MB
> 5MB: Error "El PDF es demasiado grande. Por favor, use un archivo de menos de 5MB."

Si no se puede comprimir a < 1MB:
- Se genera un PDF temporal con instrucciones de compresión
- Incluye recomendaciones específicas para reducir el tamaño
- Muestra el porcentaje de reducción necesario
```

### Para Imágenes:
```
Cualquier tamaño: Se comprime automáticamente a < 50KB al cargar
Compresión en 3 niveles:
- Nivel 1: 800x600, calidad 60%
- Nivel 2: 600x450, calidad 40%  
- Nivel 3: 400x300, calidad 30%
Mensaje: "Archivo optimizado: 2.5 MB → 45 KB (-98.2%)"
```

### Para Otros Archivos:
```
Error: "Tipo de archivo no permitido. Solo se aceptan archivos PDF, JPG y PNG."
```

## Notas de Implementación

- La compresión de imágenes es muy agresiva para cumplir con el límite de 50KB
- Los PDFs entre 1MB y 5MB se intentan comprimir (actualmente genera un PDF con instrucciones)
- Si una imagen no puede comprimirse por debajo de 50KB después de 3 intentos, se sube con el menor tamaño posible y se registra una advertencia en los logs
- El sistema mantiene la funcionalidad existente de compresión de imágenes para fotos tomadas con la cámara
- La compresión real de PDFs requeriría librerías especializadas o servicios externos

## Trabajo Futuro

Para implementar compresión real de PDFs se podría:
1. Usar un servicio en la nube (API de compresión de PDF)
2. Implementar un backend que procese los PDFs
3. Esperar a que existan librerías de compresión de PDF para Flutter
4. Usar Flutter Web con librerías JavaScript de compresión