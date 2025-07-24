# Solución: Estadísticas de Lotes Recibidos del Reciclador

## Problema
La estadística "Lotes Recibidos" en la pantalla de inicio del usuario Reciclador estaba mostrando solo los lotes en estados específicos ('recibido' o 'procesando'), en lugar del total acumulado de todos los lotes escaneados históricamente.

## Solución Implementada

### 1. Modelo de Datos
Se agregó un nuevo campo al modelo `EcoceProfileModel` para rastrear el total de lotes recibidos:

```dart
// lib/models/ecoce/ecoce_profile_model.dart
final int? ecoceLotesTotalesRecibidos; // Total de lotes escaneados por el reciclador
```

### 2. Actualización del Contador
En el formulario de entrada, se actualiza el contador cada vez que se escanean nuevos lotes:

```dart
// lib/screens/ecoce/reciclador/reciclador_formulario_entrada.dart
// Actualizar contador de lotes totales recibidos
final currentTotal = (userProfile['ecoce_lotes_totales_recibidos'] ?? 0) as int;
await _userSession.updateCurrentUserProfile({
  'ecoce_lotes_totales_recibidos': currentTotal + widget.totalLotes,
});
```

### 3. Visualización en Pantalla de Inicio
La pantalla de inicio ahora obtiene el valor del perfil del usuario:

```dart
// lib/screens/ecoce/reciclador/reciclador_inicio.dart
// Obtener el total de lotes recibidos del perfil
final profile = await _sessionService.getCurrentUserProfile();
final lotesRecibidosTotal = profile?.ecoceLotesTotalesRecibidos ?? 0;

setState(() {
  _lotesRecibidos = lotesRecibidosTotal;
  // ...
});
```

### 4. Actualización Automática
Se implementó un observador del ciclo de vida de la aplicación para refrescar las estadísticas cuando:
- La aplicación vuelve al primer plano
- El usuario regresa de escanear lotes

```dart
class _RecicladorInicioState extends State<RecicladorInicio> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app returns to foreground
      _loadUserProfile();
      _loadStatistics();
    }
  }
  
  void _navigateToNewLot() async {
    HapticFeedback.lightImpact();
    await Navigator.pushNamed(context, '/reciclador_escaneo');
    // Refresh statistics when returning from scanning
    _loadUserProfile();
    _loadStatistics();
  }
}
```

## Beneficios
1. **Persistencia**: El contador se mantiene en el perfil del usuario en Firebase
2. **Precisión**: Refleja el total real de lotes escaneados, independientemente de su estado actual
3. **Actualización en Tiempo Real**: Se actualiza inmediatamente después de escanear nuevos lotes
4. **Historial Completo**: Mantiene un registro acumulativo de toda la actividad del reciclador

## Consideraciones
- Los usuarios existentes comenzarán con un contador en 0 hasta que escaneen nuevos lotes
- El campo se inicializa como null para usuarios nuevos y se actualiza en el primer escaneo
- El contador es incremental y no puede decrementarse