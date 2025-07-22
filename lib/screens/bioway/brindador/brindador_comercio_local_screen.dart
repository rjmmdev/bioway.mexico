import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/colors.dart';
import '../../../models/bioway/comercio.dart';
import '../../../models/bioway/producto_descuento.dart';

class BrindadorComercioLocalScreen extends StatefulWidget {
  const BrindadorComercioLocalScreen({super.key});

  @override
  State<BrindadorComercioLocalScreen> createState() => _BrindadorComercioLocalScreenState();
}

class _BrindadorComercioLocalScreenState extends State<BrindadorComercioLocalScreen> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Datos mock
  late List<Comercio> _comercios;
  late List<ProductoDescuento> _productos;
  List<Comercio> _comerciosFiltrados = [];
  
  // Filtros
  String? _estadoSeleccionado;
  String? _municipioSeleccionado;
  List<String> _estados = [];
  List<String> _municipios = [];
  
  // Usuario mock
  final String _userId = 'user_123';
  final int _userBioCoins = 1250;
  
  // Control de búsqueda
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Listener para detectar cuando el campo de búsqueda tiene/pierde foco
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearching = _searchFocusNode.hasFocus;
        });
        
        // Si está buscando, resetear el scroll al principio
        if (_searchFocusNode.hasFocus) {
          // Esperar un momento para que la UI se actualice
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _scrollController.hasClients) {
              // Volver al inicio para mostrar la búsqueda en la parte superior
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  void _loadData() {
    _comercios = Comercio.getMockComercios();
    _productos = ProductoDescuento.getMockProductos();
    _comerciosFiltrados = _comercios;
    
    // Extraer estados y municipios únicos
    _estados = _comercios.map((c) => c.estado).toSet().toList();
    _municipios = _comercios.map((c) => c.municipio).toSet().toList();
  }

  void _filterComercios() {
    setState(() {
      _comerciosFiltrados = _comercios.where((comercio) {
        // Filtro por nombre
        final matchesSearch = _searchController.text.isEmpty ||
            comercio.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
        
        // Filtro por estado
        final matchesEstado = _estadoSeleccionado == null || 
            comercio.estado == _estadoSeleccionado;
        
        // Filtro por municipio
        final matchesMunicipio = _municipioSeleccionado == null || 
            comercio.municipio == _municipioSeleccionado;
        
        return matchesSearch && matchesEstado && matchesMunicipio;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si el teclado está visible
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Scaffold(
      backgroundColor: BioWayColors.backgroundGrey,
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // App Bar personalizado (se colapsa cuando está buscando)
          if (!_isSearching) 
            _buildSliverAppBar()
          else
            SliverAppBar(
              expandedHeight: kToolbarHeight,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: BioWayColors.backgroundGradient,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Text(
                      'Buscar Comercios',
                      style: TextStyle(
                        color: BioWayColors.darkGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Productos destacados (solo visible cuando NO está buscando)
          if (!_isSearching)
            SliverToBoxAdapter(
              child: _buildFeaturedProducts(),
            ),
          
          // Filtros (siempre visibles)
          SliverToBoxAdapter(
            child: _buildFilters(),
          ),
          
          // Lista de comercios
          SliverPadding(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
              right: MediaQuery.of(context).size.width * 0.05,
              bottom: MediaQuery.of(context).size.height * 0.02,
            ),
            sliver: _buildComerciosList(),
          ),
          
          // Padding adicional cuando el teclado está abierto
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: MediaQuery.of(context).viewInsets.bottom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      collapsedHeight: kToolbarHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: BioWayColors.backgroundGradient,
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: EdgeInsets.zero,
          expandedTitleScale: 1.0,
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          title: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Calcular el progreso de la animación (0.0 = expandido, 1.0 = colapsado)
              final double expandedHeight = 140;
              final double collapsedHeight = kToolbarHeight + 20;
              final double currentHeight = constraints.maxHeight;
              final double animationProgress = ((expandedHeight - currentHeight) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);
              
              // Valores interpolados para animaciones suaves
              final double titleOpacity = (1.0 - animationProgress * 2).clamp(0.0, 1.0);
              final double titleScale = 1.0 - (animationProgress * 0.3);
              final double subtitleOpacity = (1.0 - animationProgress).clamp(0.0, 1.0);
              final double topPadding = 16 * (1.0 - animationProgress);
              final double bottomPadding = 8 * (1.0 - animationProgress * 0.8);
              
              return Container(
                height: constraints.maxHeight,
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.05,
                  right: MediaQuery.of(context).size.width * 0.05,
                  bottom: bottomPadding,
                  top: topPadding,
                ),
                child: Column(
                  mainAxisAlignment: animationProgress > 0.5 ? MainAxisAlignment.end : MainAxisAlignment.center,
                  children: [
                    // Título superior (se desvanece al colapsar)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: titleOpacity,
                      child: Transform.scale(
                        scale: titleScale,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: titleOpacity > 0 ? null : 0,
                          margin: EdgeInsets.only(bottom: titleOpacity > 0 ? 4 : 0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.store,
                                color: BioWayColors.darkGreen,
                                size: 28,
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              Text(
                                'Comercio Local',
                                style: TextStyle(
                                  color: BioWayColors.darkGreen,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Sección inferior: Subtítulo y balance
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Contenedor flexible para título colapsado y subtítulo
                          Expanded(
                            child: animationProgress > 0.5
                                ? AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: animationProgress,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.store,
                                          color: BioWayColors.darkGreen,
                                          size: 20,
                                        ),
                                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                                        Flexible(
                                          child: Text(
                                            'Comercio Local',
                                            style: TextStyle(
                                              color: BioWayColors.darkGreen,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 2,
                                                  color: Colors.white.withValues(alpha: 0.5),
                                                ),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: subtitleOpacity,
                                    child: Text(
                                      'Canjea tus BioCoins por descuentos exclusivos',
                                      style: TextStyle(
                                        color: BioWayColors.darkGreen.withValues(alpha: 0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                          ),
                          
                          // Balance card con animación fluida
                          Transform.scale(
                            scale: 1.0 - (animationProgress * 0.1),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 - (animationProgress * 4),
                                vertical: 10 - (animationProgress * 4),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20 - (animationProgress * 4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6 - (animationProgress * 2)),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          BioWayColors.primaryGreen.withValues(alpha: 0.1),
                                          BioWayColors.lightGreen.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet,
                                      color: BioWayColors.primaryGreen,
                                      size: 20 - (animationProgress * 4),
                                    ),
                                  ),
                                  SizedBox(width: 10 - (animationProgress * 4)),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AnimatedOpacity(
                                        duration: const Duration(milliseconds: 150),
                                        opacity: subtitleOpacity,
                                        child: Text(
                                          'Tu balance',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '$_userBioCoins',
                                            style: TextStyle(
                                              color: BioWayColors.darkGreen,
                                              fontSize: 20 - (animationProgress * 4),
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'BioCoins',
                                            style: TextStyle(
                                              color: BioWayColors.primaryGreen,
                                              fontSize: 13 - (animationProgress * 2),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    final featuredProducts = _productos.where((p) => p.destacado).toList();
    
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BioWayColors.primaryGreen,
                        BioWayColors.lightGreen,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ofertas Destacadas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: BioWayColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BioWayColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
              ),
              itemCount: featuredProducts.length,
              itemBuilder: (context, index) {
                final producto = featuredProducts[index];
                final comercio = _comercios.firstWhere(
                  (c) => c.id == producto.comercioId,
                );
                return _buildFeaturedProductCard(producto, comercio);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductCard(ProductoDescuento producto, Comercio comercio) {
    return GestureDetector(
      onTap: () => _showProductDetail(producto, comercio),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BioWayColors.primaryGreen,
              BioWayColors.mediumGreen,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: BioWayColors.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      producto.icono,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          comercio.nombre,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${producto.descuentoPorcentaje.toInt()}%',
                      style: TextStyle(
                        color: BioWayColors.primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${producto.bioCoinsCosto} BioCoins',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Ver más',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: MediaQuery.of(context).size.height * 0.025,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BioWayColors.primaryGreen,
                      BioWayColors.lightGreen,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Comercios Afiliados',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: BioWayColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (_) => _filterComercios(),
              decoration: InputDecoration(
                hintText: 'Buscar comercio por nombre...',
                prefixIcon: Icon(
                  Icons.search,
                  color: BioWayColors.primaryGreen,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterComercios();
                          _searchFocusNode.unfocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          // Filtros de ubicación
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _estadoSeleccionado,
                      hint: const Text('Estado'),
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: BioWayColors.primaryGreen,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos los estados'),
                        ),
                        ..._estados.map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _estadoSeleccionado = value;
                          _municipioSeleccionado = null;
                          if (value != null) {
                            _municipios = _comercios
                                .where((c) => c.estado == value)
                                .map((c) => c.municipio)
                                .toSet()
                                .toList();
                          } else {
                            _municipios = _comercios
                                .map((c) => c.municipio)
                                .toSet()
                                .toList();
                          }
                        });
                        _filterComercios();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _municipioSeleccionado,
                      hint: const Text('Municipio'),
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: BioWayColors.primaryGreen,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos los municipios'),
                        ),
                        ..._municipios.map((municipio) => DropdownMenuItem(
                          value: municipio,
                          child: Text(municipio),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _municipioSeleccionado = value;
                        });
                        _filterComercios();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComerciosList() {
    if (_comerciosFiltrados.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                'No se encontraron comercios',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final comercio = _comerciosFiltrados[index];
          return _buildComercioCard(comercio);
        },
        childCount: _comerciosFiltrados.length,
      ),
    );
  }

  Widget _buildComercioCard(Comercio comercio) {
    final productosComercio = _productos
        .where((p) => p.comercioId == comercio.id)
        .toList();
    
    return GestureDetector(
      onTap: () => _showComercioProducts(comercio),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BioWayColors.primaryGreen.withValues(alpha: 0.1),
                      BioWayColors.lightGreen.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForCategory(comercio.categoria),
                  color: BioWayColors.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comercio.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BioWayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${comercio.municipio}, ${comercio.estado}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comercio.horario,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BioWayColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${productosComercio.length} ofertas',
                      style: TextStyle(
                        color: BioWayColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: BioWayColors.primaryGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComercioProducts(Comercio comercio) {
    final productosComercio = _productos
        .where((p) => p.comercioId == comercio.id)
        .toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BioWayColors.primaryGreen.withValues(alpha: 0.1),
                              BioWayColors.lightGreen.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForCategory(comercio.categoria),
                          color: BioWayColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comercio.nombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${comercio.direccion}, ${comercio.municipio}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Lista de productos
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: productosComercio.length,
                itemBuilder: (context, index) {
                  final producto = productosComercio[index];
                  return _buildProductItem(producto, comercio);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(ProductoDescuento producto, Comercio comercio) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showProductDetail(producto, comercio);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BioWayColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                producto.icono,
                color: BioWayColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    producto.descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: BioWayColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${producto.descuentoPorcentaje.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: BioWayColors.primaryGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${producto.bioCoinsCosto}',
                      style: TextStyle(
                        color: BioWayColors.primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetail(ProductoDescuento producto, Comercio comercio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícono y nombre del producto
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BioWayColors.primaryGreen.withValues(alpha: 0.1),
                              BioWayColors.lightGreen.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          producto.icono,
                          color: BioWayColors.primaryGreen,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        comercio.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Descripción
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            producto.descripcion,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Información del descuento
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BioWayColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${producto.descuentoPorcentaje.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: BioWayColors.success,
                                  ),
                                ),
                                const Text(
                                  'Descuento',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BioWayColors.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.monetization_on,
                                      color: BioWayColors.primaryGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${producto.bioCoinsCosto}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: BioWayColors.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'BioCoins',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Balance actual
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _userBioCoins >= producto.bioCoinsCosto
                            ? BioWayColors.info.withValues(alpha: 0.1)
                            : BioWayColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _userBioCoins >= producto.bioCoinsCosto
                                ? Icons.check_circle
                                : Icons.error,
                            color: _userBioCoins >= producto.bioCoinsCosto
                                ? BioWayColors.info
                                : BioWayColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _userBioCoins >= producto.bioCoinsCosto
                                ? 'Tienes $_userBioCoins BioCoins disponibles'
                                : 'BioCoins insuficientes (necesitas ${producto.bioCoinsCosto - _userBioCoins} más)',
                            style: TextStyle(
                              fontSize: 14,
                              color: _userBioCoins >= producto.bioCoinsCosto
                                  ? BioWayColors.info
                                  : BioWayColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botón de canjear
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _userBioCoins >= producto.bioCoinsCosto
                            ? () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context);
                                _showQRCode(producto, comercio);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BioWayColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        icon: const Icon(
                          Icons.qr_code,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Canjear Puntos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(ProductoDescuento producto, Comercio comercio) {
    // Generar datos del QR
    final qrData = '$_userId|${producto.bioCoinsCosto}|${producto.id}|${DateTime.now().millisecondsSinceEpoch}';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Muestra este código al comercio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: BioWayColors.primaryGreen,
                    width: 2,
                  ),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                producto.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                comercio.nombre,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: BioWayColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: BioWayColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${producto.bioCoinsCosto} BioCoins',
                      style: TextStyle(
                        color: BioWayColors.primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSuccessMessage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BioWayColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Código generado exitosamente. Muéstralo al comercio para canjear tu descuento.',
              ),
            ),
          ],
        ),
        backgroundColor: BioWayColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  IconData _getIconForCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'cafetería':
        return Icons.coffee;
      case 'supermercado':
        return Icons.shopping_cart;
      case 'deportes':
        return Icons.sports;
      case 'salud':
        return Icons.medical_services;
      case 'restaurante':
        return Icons.restaurant;
      default:
        return Icons.store;
    }
  }
}