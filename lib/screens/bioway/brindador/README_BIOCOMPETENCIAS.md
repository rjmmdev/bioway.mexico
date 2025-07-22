# Sistema de BioCompetencias - BioWay México

## Resumen

El sistema de BioCompetencias es una funcionalidad de gamificación que incentiva a los usuarios generales (brindadores) de BioWay a mantener una actividad constante de reciclaje mediante el sistema de "BioImpulso" (momentum ecológico continuo), rankings semanales y recompensas.

## Características Principales

### 1. BioImpulso (Momentum Ecológico)
- **Concepto**: Energía y momentum que se genera al reciclar constantemente
- **Margen**: 48 horas entre reciclajes para mantener el impulso activo
- **Niveles**:
  - 🥉 **Bronce**: 3-6 días (+50 puntos bonus)
  - 🥈 **Plata**: 7-13 días (+100 puntos bonus)
  - 🥇 **Oro**: 14-29 días (+200 puntos bonus)
  - 💎 **Diamante**: 30+ días (+500 puntos bonus)

### 2. Sistema de Multiplicadores
Los puntos obtenidos por cada reciclaje se multiplican según el BioImpulso:
- 1-2 días: x1.0
- 3-6 días: x1.1
- 7-13 días: x1.2
- 14-29 días: x1.5
- 30+ días: x2.0

### 3. Rankings
- **Ranking Semanal**: Se reinicia cada domingo
- **Top 3**: Visualización especial con podio
- **Top 100**: Lista completa de competidores

### 4. Recompensas
- BioCoins por alcanzar hitos del BioImpulso
- Insignias especiales por logros
- Premios semanales para el top 10

## Estructura de Datos

### Colección: `bio_competencias`
```json
{
  "userId": "string",
  "userName": "string",
  "userAvatar": "string",
  "bioImpulso": 15,
  "bioImpulsoMaximo": 30,
  "ultimaActividad": "timestamp",
  "puntosSemanales": 1500,
  "puntosTotales": 10000,
  "posicionRanking": 5,
  "kgReciclados": 45.5,
  "co2Evitado": 120.3,
  "recompensasObtenidas": [...],
  "nivel": 3,
  "insigniaActual": "🥇"
}
```

## Integración

### 1. Actualización Automática
El BioImpulso se actualiza automáticamente cuando un usuario registra un nuevo residuo mediante el método `crearResiduo()` en `ResiduoService`.

### 2. Navegación
- Nueva pestaña "Competir" en el bottom navigation de brindadores
- Icono: `Icons.emoji_events_rounded`
- Posición: 4ta pestaña

### 3. Servicio
`BioCompetenciaService` maneja toda la lógica:
- `actualizarBioImpulso()`: Actualiza el impulso y calcula puntos
- `obtenerRanking()`: Obtiene el ranking de usuarios
- `reiniciarPuntosSemanales()`: Para ejecutar con Cloud Function

## Próximos Pasos Recomendados

### 1. Cloud Function para Reset Semanal
```javascript
// Ejecutar cada domingo a las 00:00
exports.resetPuntosSemanales = functions.pubsub
  .schedule('0 0 * * 0')
  .onRun(async (context) => {
    // Reiniciar puntos semanales
    // Otorgar premios al top 10
  });
```

### 2. Notificaciones Push
- Recordatorio diario si el BioImpulso está por perderse
- Felicitaciones por alcanzar hitos
- Avisos de posición en el ranking

### 3. Mejoras Futuras
- Sistema de amigos/seguidos
- Retos especiales temporales
- Logros desbloqueables
- Tienda de recompensas con BioCoins

## Notas de Implementación

- **Solo usuarios generales**: El sistema está limitado a usuarios brindadores
- **Sin restricción geográfica**: Compiten usuarios de todo México
- **Datos en tiempo real**: Rankings actualizados instantáneamente
- **Optimización**: Limitar queries a top 100 para rendimiento