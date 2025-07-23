# Solución para el Error de Compilación (Exit Code 126)

## Problema
El proyecto no compila debido a un error con código de salida 126, que generalmente indica problemas de permisos o configuración del entorno en Windows.

## Soluciones

### Opción 1: Usar PowerShell (Recomendado)

1. Abrir PowerShell como Administrador
2. Navegar al directorio del proyecto:
   ```powershell
   cd C:\Users\hurta\StudioProjects\bioway.mexico
   ```
3. Ejecutar el script de reparación:
   ```powershell
   .\fix_gradle_permissions.ps1
   ```

### Opción 2: Usar Command Prompt

1. Abrir Command Prompt (cmd) como Administrador
2. Navegar al directorio del proyecto:
   ```cmd
   cd C:\Users\hurta\StudioProjects\bioway.mexico
   ```
3. Ejecutar:
   ```cmd
   build_android.bat
   ```

### Opción 3: Reparación Manual

1. **Verificar Java**:
   ```cmd
   java -version
   ```
   Debe mostrar Java 11 o superior.

2. **Limpiar caché de Gradle**:
   ```cmd
   cd android
   gradlew.bat clean
   cd ..
   ```

3. **Eliminar carpetas de build**:
   - Eliminar `android\.gradle`
   - Eliminar `android\app\build`
   - Eliminar `.dart_tool`
   - Eliminar `build`

4. **Reconstruir**:
   ```cmd
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

### Opción 4: Usar Android Studio

1. Abrir el proyecto en Android Studio
2. File → Sync Project with Gradle Files
3. Build → Clean Project
4. Build → Rebuild Project
5. Run → Run 'app'

### Opción 5: Verificar Variables de Entorno

1. Asegurarse de que estas variables estén configuradas:
   - `JAVA_HOME` = ruta a JDK 11+
   - `ANDROID_HOME` = `C:\Users\hurta\AppData\Local\Android\sdk`
   - `PATH` debe incluir:
     - `%JAVA_HOME%\bin`
     - `%ANDROID_HOME%\platform-tools`
     - `%ANDROID_HOME%\tools`

### Opción 6: Desactivar Antivirus Temporalmente

Algunos antivirus pueden interferir con la compilación. Intenta:
1. Desactivar temporalmente el antivirus
2. Agregar excepciones para:
   - `C:\Users\hurta\StudioProjects\bioway.mexico`
   - `C:\Users\hurta\.gradle`
   - `C:\Users\hurta\AppData\Local\Android\sdk`

### Opción 7: Reinstalar Gradle Wrapper

1. Eliminar `android\gradle\wrapper`
2. En el directorio `android`, ejecutar:
   ```cmd
   gradle wrapper --gradle-version 8.7
   ```

## Si Nada Funciona

1. **Crear un nuevo proyecto Flutter**:
   ```cmd
   flutter create test_project
   cd test_project
   flutter run
   ```
   Si esto funciona, el problema es específico del proyecto.

2. **Clonar el proyecto en otra ubicación**:
   A veces cambiar la ubicación del proyecto resuelve problemas de permisos.

3. **Usar WSL2 (Windows Subsystem for Linux)**:
   Como última opción, puedes desarrollar en un entorno Linux dentro de Windows.

## Logs para Debugging

Si necesitas más información, ejecuta:
```cmd
flutter run -v > flutter_log.txt 2>&1
```

Esto creará un archivo con logs detallados que pueden ayudar a identificar el problema exacto.