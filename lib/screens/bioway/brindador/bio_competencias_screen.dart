import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../models/bio_competencia.dart';
import '../../../widgets/common/gradient_background.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../../../widgets/bioway/bio_celebration_widget.dart';
import '../../../widgets/bioway/bio_motivational_popup.dart';
import 'brindador_residuos_grid_screen.dart';

class BioCompetenciasScreen extends StatefulWidget {
  const BioCompetenciasScreen({super.key});

  @override
  State<BioCompetenciasScreen> createState() => _BioCompetenciasScreenState();
}

class _BioCompetenciasScreenState extends State<BioCompetenciasScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseAnimationController;
  BioCompetencia? _miCompetencia;
  List<BioCompetencia> _rankingGlobal = [];
  bool _isLoading = true;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimationController.repeat();
    _cargarDatos();
    
    // Mostrar mensaje motivacional aleatorio después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _mostrarMensajeMotivacional();
      }
    });
  }
  
  void _mostrarMensajeMotivacional() {
    final mensaje = MotivationalMessages.getRandomMessage();
    BioMotivationalPopup.show(
      context,
      message: mensaje['message'],
      icon: mensaje['icon'],
    );
  }
  
  DateTime _getInicioSemana(DateTime fecha) {
    final diasDesdeElLunes = fecha.weekday - 1;
    return DateTime(fecha.year, fecha.month, fecha.day).subtract(Duration(days: diasDesdeElLunes));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    // Simular carga de datos
    await Future.delayed(const Duration(seconds: 1));

    // Datos hardcodeados para visualización
    _miCompetencia = BioCompetencia(
      userId: 'usuario_actual',
      userName: 'Juan Pérez',
      userAvatar: '',
      bioImpulso: 5, // 5 semanas consecutivas
      bioImpulsoMaximo: 8,
      bioImpulsoActivo: true,
      ultimaActividad: DateTime.now().subtract(const Duration(days: 2)),
      reciclajesEstaSemana: 1, // Ya ha reciclado 1 vez esta semana
      inicioSemanaActual: _getInicioSemana(DateTime.now()),
      puntosSemanales: 3450,
      puntosTotales: 15780,
      posicionRanking: 7,
      kgReciclados: 245.5,
      co2Evitado: 612.3,
      recompensasObtenidas: [],
      nivel: 3,
      insigniaActual: '🥈',
    );

    // Generar ranking con datos ficticios
    _rankingGlobal = [
      BioCompetencia(
        userId: '1',
        userName: 'María García',
        userAvatar: '',
        bioImpulso: 15,
        bioImpulsoMaximo: 15,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 5)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 8920,
        puntosTotales: 45200,
        posicionRanking: 1,
        kgReciclados: 890.2,
        co2Evitado: 2225.5,
        nivel: 5,
        insigniaActual: '💎',
      ),
      BioCompetencia(
        userId: '2',
        userName: 'Carlos Mendoza',
        userAvatar: '',
        bioImpulso: 12,
        bioImpulsoMaximo: 14,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 12)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 7850,
        puntosTotales: 38900,
        posicionRanking: 2,
        kgReciclados: 723.8,
        co2Evitado: 1809.5,
        nivel: 4,
        insigniaActual: '💎',
      ),
      BioCompetencia(
        userId: '3',
        userName: 'Ana Rodríguez',
        userAvatar: '',
        bioImpulso: 10,
        bioImpulsoMaximo: 10,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 8)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 6230,
        puntosTotales: 28400,
        posicionRanking: 3,
        kgReciclados: 567.3,
        co2Evitado: 1418.25,
        nivel: 4,
        insigniaActual: '🥇',
      ),
      BioCompetencia(
        userId: '4',
        userName: 'Luis Hernández',
        userAvatar: '',
        bioImpulso: 8,
        bioImpulsoMaximo: 9,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 15)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 5120,
        puntosTotales: 22100,
        posicionRanking: 4,
        kgReciclados: 445.6,
        co2Evitado: 1114.0,
        nivel: 3,
        insigniaActual: '🥇',
      ),
      BioCompetencia(
        userId: '5',
        userName: 'Patricia López',
        userAvatar: '',
        bioImpulso: 6,
        bioImpulsoMaximo: 8,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 18)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 4580,
        puntosTotales: 19800,
        posicionRanking: 5,
        kgReciclados: 398.2,
        co2Evitado: 995.5,
        nivel: 3,
        insigniaActual: '🥇',
      ),
      BioCompetencia(
        userId: '6',
        userName: 'Roberto Sánchez',
        userAvatar: '',
        bioImpulso: 4,
        bioImpulsoMaximo: 7,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 10)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 3890,
        puntosTotales: 16200,
        posicionRanking: 6,
        kgReciclados: 325.9,
        co2Evitado: 814.75,
        nivel: 3,
        insigniaActual: '🥈',
      ),
      // Mi usuario en posición 7
      BioCompetencia(
        userId: 'usuario_actual',
        userName: 'Juan Pérez',
        userAvatar: '',
        bioImpulso: 5,
        bioImpulsoMaximo: 8,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 20)),
        reciclajesEstaSemana: 1,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 3450,
        puntosTotales: 15780,
        posicionRanking: 7,
        kgReciclados: 245.5,
        co2Evitado: 612.3,
        nivel: 3,
        insigniaActual: '🥈',
      ),
      BioCompetencia(
        userId: '8',
        userName: 'Elena Martínez',
        userAvatar: '',
        bioImpulso: 3,
        bioImpulsoMaximo: 6,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 22)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 2980,
        puntosTotales: 14500,
        posicionRanking: 8,
        kgReciclados: 289.4,
        co2Evitado: 723.5,
        nivel: 2,
        insigniaActual: '🥈',
      ),
      BioCompetencia(
        userId: '9',
        userName: 'Miguel Torres',
        userAvatar: '',
        bioImpulso: 3,
        bioImpulsoMaximo: 5,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 14)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 2450,
        puntosTotales: 12300,
        posicionRanking: 9,
        kgReciclados: 234.7,
        co2Evitado: 586.75,
        nivel: 2,
        insigniaActual: '🥉',
      ),
      BioCompetencia(
        userId: '10',
        userName: 'Carmen Ruiz',
        userAvatar: '',
        bioImpulso: 2,
        bioImpulsoMaximo: 4,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 30)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 1890,
        puntosTotales: 9800,
        posicionRanking: 10,
        kgReciclados: 187.3,
        co2Evitado: 468.25,
        nivel: 2,
        insigniaActual: '🥉',
      ),
      // Más usuarios para hacer la lista más completa
      BioCompetencia(
        userId: '11',
        userName: 'Jorge Ramírez',
        userAvatar: '',
        bioImpulso: 1,
        bioImpulsoMaximo: 3,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 40)),
        reciclajesEstaSemana: 1,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 1450,
        puntosTotales: 8200,
        posicionRanking: 11,
        kgReciclados: 156.8,
        co2Evitado: 392.0,
        nivel: 2,
        insigniaActual: '',
      ),
      BioCompetencia(
        userId: '12',
        userName: 'Diana Flores',
        userAvatar: '',
        bioImpulso: 1,
        bioImpulsoMaximo: 2,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 25)),
        reciclajesEstaSemana: 1,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 980,
        puntosTotales: 6500,
        posicionRanking: 12,
        kgReciclados: 124.5,
        co2Evitado: 311.25,
        nivel: 1,
        insigniaActual: '',
      ),
      BioCompetencia(
        userId: '13',
        userName: 'Fernando Cruz',
        userAvatar: '',
        bioImpulso: 0,
        bioImpulsoMaximo: 3,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(days: 3)),
        reciclajesEstaSemana: 0,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 750,
        puntosTotales: 5200,
        posicionRanking: 13,
        kgReciclados: 98.7,
        co2Evitado: 246.75,
        nivel: 1,
        insigniaActual: '',
      ),
      BioCompetencia(
        userId: '14',
        userName: 'Sofía Vargas',
        userAvatar: '',
        bioImpulso: 2,
        bioImpulsoMaximo: 2,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 16)),
        reciclajesEstaSemana: 2,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 680,
        puntosTotales: 4100,
        posicionRanking: 14,
        kgReciclados: 78.3,
        co2Evitado: 195.75,
        nivel: 1,
        insigniaActual: '🥉',
      ),
      BioCompetencia(
        userId: '15',
        userName: 'Alejandro Mora',
        userAvatar: '',
        bioImpulso: 1,
        bioImpulsoMaximo: 1,
        bioImpulsoActivo: true,
        ultimaActividad: DateTime.now().subtract(const Duration(hours: 36)),
        reciclajesEstaSemana: 0,
        inicioSemanaActual: _getInicioSemana(DateTime.now()),
        puntosSemanales: 450,
        puntosTotales: 2800,
        posicionRanking: 15,
        kgReciclados: 54.2,
        co2Evitado: 135.5,
        nivel: 1,
        insigniaActual: '',
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  // Método comentado - solo se usa para datos reales de Firebase
  // Future<void> _crearCompetenciaInicial() async {
  //   // Implementación real con Firebase
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                  children: [
                    _buildMotivationalHeader(),
                    if (_miCompetencia != null) ...[
                      _buildBioImpulsoHero(),
                      _buildDailyProgress(),
                    ],
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRankingTab(),
                          _buildBioImpulsosTab(),
                          _buildRecompensasTab(),
                        ],
                      ),
                    ),
                  ],
                    ),
            ),
          ),
          // Celebración overlay
          if (_showCelebration)
            BioCelebrationWidget(
              title: '¡Felicidades!',
              message: '¡Meta semanal completada!',
              onComplete: () {
                setState(() {
                  _showCelebration = false;
                });
              },
            ),
        ],
      ),
      floatingActionButton: _buildReciclarFAB(),
    );
  }

  Widget _buildMotivationalHeader() {
    final horaDelDia = DateTime.now().hour;
    String saludo = horaDelDia < 12 ? 'Buenos días' : 
                   horaDelDia < 19 ? 'Buenas tardes' : 'Buenas noches';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$saludo, ${_miCompetencia?.userName ?? 'Campeón'}! 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _miCompetencia!.reciclajesEstaSemana >= 2
                      ? '¡BioImpulso activo! Llevas ${_miCompetencia!.bioImpulso} semanas 🔥'
                      : _miCompetencia!.reciclajesEstaSemana == 1
                          ? '¡Solo falta 1 reciclaje más esta semana! 💪'
                          : '¡Recicla 2 veces esta semana para mantener tu impulso! 🌱',
                  style: TextStyle(
                    fontSize: 16,
                    color: _miCompetencia!.reciclajesEstaSemana >= 2
                        ? BioWayColors.primaryGreen 
                        : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Icono de competencias
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [BioWayColors.primaryGreen, BioWayColors.limeGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioImpulsoHero() {
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _miCompetencia!.bioImpulsoActivo
              ? [BioWayColors.primaryGreen, BioWayColors.limeGreen]
              : [Colors.orange[600]!, Colors.orange[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_miCompetencia!.bioImpulsoActivo 
                ? BioWayColors.primaryGreen 
                : Colors.orange[600]!).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Número grande del BioImpulso con animación
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _miCompetencia!.bioImpulso.toDouble()),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Círculo de fondo con pulsación
                      AnimatedBuilder(
                        animation: _pulseAnimationController,
                        builder: (context, child) {
                          final pulse = 0.95 + (0.1 * math.sin(_pulseAnimationController.value * 2 * math.pi));
                          return Transform.scale(
                            scale: pulse,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white.withValues(alpha: 0.9),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_miCompetencia!.bioImpulsoActivo 
                                        ? BioWayColors.primaryGreen 
                                        : Colors.orange).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Número animado
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${value.round()}',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _miCompetencia!.bioImpulsoActivo
                                  ? BioWayColors.primaryGreen
                                  : Colors.orange[600],
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'SEMANAS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _miCompetencia!.bioImpulsoActivo ? '🔥' : '❄️',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BioImpulso',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_miCompetencia!.reciclajesEstaSemana >= 2) ...[
                      Text(
                        '¡Impulso activo esta semana! ✓',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        _miCompetencia!.reciclajesEstaSemana == 1
                            ? '¡Solo falta 1 reciclaje más!'
                            : '¡Necesitas ${2 - _miCompetencia!.reciclajesEstaSemana} reciclajes esta semana!',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Récord: ${_miCompetencia!.bioImpulsoMaximo} semanas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progreso mejorada
          _buildProgresoMejorado(),
        ],
      ),
      ),
        );
      },
    );
  }

  Widget _buildProgresoMejorado() {
    int proximaMeta = 3;
    String proximaRecompensa = 'Bronce';
    String proximoEmoji = '🥉';
    
    if (_miCompetencia!.bioImpulso >= 3 && _miCompetencia!.bioImpulso < 7) {
      proximaMeta = 7;
      proximaRecompensa = 'Plata';
      proximoEmoji = '🥈';
    } else if (_miCompetencia!.bioImpulso >= 7 && _miCompetencia!.bioImpulso < 14) {
      proximaMeta = 14;
      proximaRecompensa = 'Oro';
      proximoEmoji = '🥇';
    } else if (_miCompetencia!.bioImpulso >= 14 && _miCompetencia!.bioImpulso < 30) {
      proximaMeta = 30;
      proximaRecompensa = 'Diamante';
      proximoEmoji = '💎';
    } else if (_miCompetencia!.bioImpulso >= 30) {
      proximaMeta = 50;
      proximaRecompensa = 'Leyenda';
      proximoEmoji = '👑';
    }

    final progreso = (_miCompetencia!.bioImpulso % proximaMeta) / proximaMeta;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    proximoEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Próximo: $proximaRecompensa',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${_miCompetencia!.bioImpulso}/$proximaMeta semanas',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress() {
    // Progreso semanal
    final metaSemanal = 2; // Meta de 2 reciclajes semanales
    final progresoSemanal = _miCompetencia!.reciclajesEstaSemana;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // División/Liga actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Ícono de la liga
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Liga Oro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Top 30% de recicladores',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '#${_miCompetencia!.posicionRanking}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.primaryGreen,
                      ),
                    ),
                    Text(
                      'de 50',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Progreso semanal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.lightGreen.withValues(alpha: 0.3),
                  BioWayColors.aquaGreen.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.recycling,
                          color: BioWayColors.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Meta Semanal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: progresoSemanal >= metaSemanal
                            ? BioWayColors.primaryGreen
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$progresoSemanal/$metaSemanal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Círculos de progreso animados
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(metaSemanal, (index) {
                    final completado = index < progresoSemanal;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: completado ? 1 : 0),
                      duration: Duration(milliseconds: 500 + (index * 200)),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: completado
                                  ? const LinearGradient(
                                      colors: [BioWayColors.primaryGreen, BioWayColors.limeGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: completado ? null : Colors.grey[300],
                              shape: BoxShape.circle,
                              boxShadow: completado
                                  ? [
                                      BoxShadow(
                                        color: BioWayColors.primaryGreen.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: completado ? null : () {
                                    // Simular completar una tarea de reciclaje
                                    HapticFeedback.mediumImpact();
                                    setState(() {
                                      _showCelebration = true;
                                    });
                                    _mostrarMensajeMotivacional();
                                  },
                                  child: Icon(
                                    completado ? Icons.check_circle : Icons.recycling,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                if (completado)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.yellow,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '★',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                if (progresoSemanal < metaSemanal) ...[
                  Text(
                    '¡Te faltan ${metaSemanal - progresoSemanal} reciclajes para completar tu meta semanal!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🎉 ',
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        '¡Meta semanal completada!',
                        style: TextStyle(
                          fontSize: 14,
                          color: BioWayColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' 🎉',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: BioWayColors.primaryGreen,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: const [
          Tab(text: 'Ranking'),
          Tab(text: 'Tu BioImpulso'),
          Tab(text: 'Recompensas'),
        ],
      ),
    );
  }

  Widget _buildRankingTab() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de resumen personal
          _buildPersonalSummaryCard(),
          const SizedBox(height: 20),
          // Top 3
          _buildTopTres(),
          const SizedBox(height: 20),
          // Título de la sección
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ranking Semanal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: BioWayColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 16,
                      color: BioWayColors.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_getDiasRestantes()} días',
                      style: const TextStyle(
                        fontSize: 14,
                        color: BioWayColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lista del ranking
          ..._rankingGlobal.map((competidor) {
            final esMiPerfil = competidor.userId == 'usuario_actual';
            return _buildRankingItem(competidor, esMiPerfil: esMiPerfil);
          }),
        ],
      ),
    );
  }

  int _getDiasRestantes() {
    final ahora = DateTime.now();
    final diasHastaDomingo = DateTime.sunday - ahora.weekday + 1;
    return diasHastaDomingo == 8 ? 1 : diasHastaDomingo;
  }

  Widget _buildPersonalSummaryCard() {
    final miPosicion = _miCompetencia!.posicionRanking;
    final cambio = miPosicion <= 5 ? '+2' : '-1'; // Simulado
    final esPositivo = cambio.startsWith('+');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BioWayColors.primaryGreen.withValues(alpha: 0.9),
            BioWayColors.limeGreen.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu posición',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '#$miPosicion',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: esPositivo ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              esPositivo ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: Colors.white,
                            ),
                            Text(
                              cambio,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_miCompetencia!.puntosSemanales}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'puntos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('🔥', '${_miCompetencia!.bioImpulso} semanas', 'BioImpulso'),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildMiniStat('♻️', '${_miCompetencia!.kgReciclados.toStringAsFixed(1)} kg', 'Reciclados'),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildMiniStat('🌱', '${_miCompetencia!.co2Evitado.toStringAsFixed(1)} kg', 'CO₂ evitado'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String valor, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTopTres() {
    if (_rankingGlobal.length < 3) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Segundo lugar
          if (_rankingGlobal.length > 1)
            _buildPodioItem(_rankingGlobal[1], 2, 100),
          const SizedBox(width: 8),
          // Primer lugar
          _buildPodioItem(_rankingGlobal[0], 1, 120),
          const SizedBox(width: 8),
          // Tercer lugar
          if (_rankingGlobal.length > 2)
            _buildPodioItem(_rankingGlobal[2], 3, 80),
        ],
      ),
    );
  }

  Widget _buildPodioItem(BioCompetencia competidor, int posicion, double altura) {
    final colores = {
      1: Colors.amber,
      2: Colors.grey,
      3: Colors.brown[300]!,
    };

    return Column(
      children: [
        // Avatar y corona
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colores[posicion]!,
                  width: 3,
                ),
                image: competidor.userAvatar.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(competidor.userAvatar),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: competidor.userAvatar.isEmpty
                  ? Center(
                      child: Text(
                        competidor.userName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colores[posicion],
                        ),
                      ),
                    )
                  : null,
            ),
            if (posicion == 1)
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 32,
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Nombre
        Text(
          competidor.userName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Puntos
        Text(
          '${competidor.puntosSemanales} pts',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        // Podio
        Container(
          width: 80,
          height: altura,
          decoration: BoxDecoration(
            color: colores[posicion],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$posicion',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingItem(BioCompetencia competidor, {bool esMiPerfil = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: esMiPerfil
            ? LinearGradient(
                colors: [
                  BioWayColors.primaryGreen.withValues(alpha: 0.1),
                  BioWayColors.limeGreen.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: esMiPerfil ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: esMiPerfil
            ? Border.all(color: BioWayColors.primaryGreen, width: 2)
            : Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: esMiPerfil
                ? BioWayColors.primaryGreen.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: esMiPerfil ? 10 : 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Aquí se podría mostrar el perfil del competidor
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Posición con diseño mejorado
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getGradientePorPosicion(competidor.posicionRanking),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${competidor.posicionRanking}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    if (competidor.posicionRanking <= 3)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getEmojiPorPosicion(competidor.posicionRanking),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Avatar con borde
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: competidor.bioImpulsoActivo
                          ? Colors.orange
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: competidor.userAvatar.isNotEmpty
                        ? NetworkImage(competidor.userAvatar)
                        : null,
                    backgroundColor: BioWayColors.lightGreen.withValues(alpha: 0.3),
                    child: competidor.userAvatar.isEmpty
                        ? Text(
                            competidor.userName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: BioWayColors.primaryGreen,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Información del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              competidor.userName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: esMiPerfil
                                    ? BioWayColors.primaryGreen
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (competidor.bioImpulsoActivo) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🔥', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          if (competidor.insigniaActual?.isNotEmpty ?? false) ...[
                            const SizedBox(width: 4),
                            Text(
                              competidor.insigniaActual!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${competidor.bioImpulso} semanas',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.recycling,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${competidor.kgReciclados.toStringAsFixed(0)} kg',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Puntos con diseño mejorado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BioWayColors.primaryGreen.withValues(alpha: 0.1),
                        BioWayColors.limeGreen.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${competidor.puntosSemanales}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: BioWayColors.primaryGreen,
                        ),
                      ),
                      const Text(
                        'pts',
                        style: TextStyle(
                          fontSize: 12,
                          color: BioWayColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientePorPosicion(int posicion) {
    if (posicion == 1) return [Colors.amber, Colors.orange];
    if (posicion == 2) return [Colors.grey[400]!, Colors.grey[600]!];
    if (posicion == 3) return [Colors.brown[300]!, Colors.brown[500]!];
    if (posicion <= 10) return [BioWayColors.primaryGreen, BioWayColors.darkGreen];
    return [Colors.grey[400]!, Colors.grey[500]!];
  }

  String _getEmojiPorPosicion(int posicion) {
    switch (posicion) {
      case 1: return '👑';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }

  Widget _buildBioImpulsosTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSeccionBioImpulso(
          titulo: '¿Qué es el BioImpulso?',
          contenido: 'El BioImpulso es tu energía y momentum ecológico. '
              'Cada semana que reciclas al menos 2 veces, tu impulso crece y se fortalece. '
              '¡Mantén tu impulso activo reciclando mínimo 2 veces por semana!',
          icono: '⚡',
        ),
        const SizedBox(height: 16),
        _buildSeccionBioImpulso(
          titulo: 'Niveles del Impulso',
          contenido: null,
          icono: '📊',
          child: Column(
            children: [
              _buildNivelBioImpulso('Bronce', '🥉', '2-3 semanas', '+50 puntos bonus'),
              _buildNivelBioImpulso('Plata', '🥈', '4-7 semanas', '+100 puntos bonus'),
              _buildNivelBioImpulso('Oro', '🥇', '8-11 semanas', '+200 puntos bonus'),
              _buildNivelBioImpulso('Diamante', '💎', '12+ semanas', '+500 puntos bonus'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSeccionBioImpulso(
          titulo: 'Potencia tu Impulso',
          contenido: 'Mientras más fuerte sea tu BioImpulso, más puntos '
              'multiplicarás en cada reciclaje:',
          icono: '✨',
          child: Column(
            children: [
              _buildMultiplicador('1 semana', 'x1.0'),
              _buildMultiplicador('2-3 semanas', 'x1.1'),
              _buildMultiplicador('4-7 semanas', 'x1.2'),
              _buildMultiplicador('8-11 semanas', 'x1.5'),
              _buildMultiplicador('12+ semanas', 'x2.0'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecompensasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRecompensaCard(
          titulo: 'Primer Impulso',
          descripcion: 'Activa tu BioImpulso con tu primer reciclaje',
          bioCoins: 10,
          completada: _miCompetencia!.bioImpulso > 0,
        ),
        _buildRecompensaCard(
          titulo: 'Impulso de Bronce',
          descripcion: 'Mantén tu impulso activo por 2 semanas',
          bioCoins: 50,
          completada: _miCompetencia!.bioImpulsoMaximo >= 3,
        ),
        _buildRecompensaCard(
          titulo: 'Impulso de Plata',
          descripcion: 'Mantén tu impulso activo por 4 semanas',
          bioCoins: 100,
          completada: _miCompetencia!.bioImpulsoMaximo >= 7,
        ),
        _buildRecompensaCard(
          titulo: 'Impulso de Oro',
          descripcion: 'Mantén tu impulso activo por 8 semanas',
          bioCoins: 200,
          completada: _miCompetencia!.bioImpulsoMaximo >= 14,
        ),
        _buildRecompensaCard(
          titulo: 'Impulso de Diamante',
          descripcion: 'Mantén tu impulso activo por 12 semanas',
          bioCoins: 500,
          completada: _miCompetencia!.bioImpulsoMaximo >= 30,
        ),
        _buildRecompensaCard(
          titulo: 'Top 10 Semanal',
          descripcion: 'Termina la semana en el top 10',
          bioCoins: 300,
          completada: false,
        ),
        _buildRecompensaCard(
          titulo: 'Top 3 Semanal',
          descripcion: 'Termina la semana en el top 3',
          bioCoins: 1000,
          completada: false,
        ),
      ],
    );
  }

  Widget _buildSeccionBioImpulso({
    required String titulo,
    String? contenido,
    required String icono,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icono, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (contenido != null) ...[
            const SizedBox(height: 8),
            Text(
              contenido,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildNivelBioImpulso(String nivel, String icono, String dias, String bonus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icono, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nivel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dias,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: BioWayColors.limeGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              bonus,
              style: const TextStyle(
                fontSize: 12,
                color: BioWayColors.limeGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplicador(String dias, String multiplicador) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dias,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BioWayColors.primaryGreen.withValues(alpha: 0.8),
                  BioWayColors.limeGreen.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              multiplicador,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecompensaCard({
    required String titulo,
    required String descripcion,
    required int bioCoins,
    required bool completada,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completada ? BioWayColors.primaryGreen.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completada ? BioWayColors.primaryGreen : Colors.grey[300]!,
          width: completada ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: completada
                  ? BioWayColors.primaryGreen
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              completada ? Icons.check : Icons.lock,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: completada ? BioWayColors.primaryGreen : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              SvgPicture.asset(
                'assets/svg/biocoin.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(height: 4),
              Text(
                '+$bioCoins',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: completada ? BioWayColors.primaryGreen : Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildReciclarFAB() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [BioWayColors.primaryGreen, BioWayColors.limeGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: BioWayColors.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Navegar a la pantalla de tirar/reciclar
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrindadorResiduosGridScreen(
                      selectedCantMin: "0",
                    ),
                  ),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.recycling,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
}