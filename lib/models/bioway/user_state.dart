/// Modelo de estado del usuario para BioWay
class UserState {
  final String userId;
  final String nombre;
  final String estado; // "0" = puede brindar, "1" = esperando recolección
  final String? token;
  final int totalBrindados;
  final double co2Evitado;
  final double materialReciclado;

  UserState({
    required this.userId,
    required this.nombre,
    required this.estado,
    this.token,
    this.totalBrindados = 0,
    this.co2Evitado = 0.0,
    this.materialReciclado = 0.0,
  });

  /// Determina si el usuario puede brindar residuos
  bool get puedeBrindar => estado == "0";

  /// Obtiene el mensaje de estado
  String get estadoMensaje {
    if (estado == "0") {
      return "✨ Puedes brindar reciclables";
    } else {
      return "⏳ No puedes brindar ahora";
    }
  }

  /// Crea una instancia de prueba (hardcoded)
  static UserState getMockUserState() {
    return UserState(
      userId: 'mock_user_123',
      nombre: 'Juan Pérez',
      estado: '0', // Puede brindar
      token: 'mock_fcm_token',
      totalBrindados: 15,
      co2Evitado: 48.5,
      materialReciclado: 120.3,
    );
  }
}