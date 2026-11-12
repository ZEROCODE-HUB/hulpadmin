// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Modelos de datos
class Categoria {
  final String id;
  final String nombre;
  List<Subcategoria> subcategorias = [];
  bool isSelected = false;
  bool isExpanded = false;

  Categoria({
    required this.id,
    required this.nombre,
  });
}

class Subcategoria {
  final String id;
  final String nombre;
  final String? descripcion;
  final String categoriaId;
  List<Servicio> servicios = [];
  bool isSelected = false;
  bool isExpanded = false;

  Subcategoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.categoriaId,
  });
}

class Servicio {
  final String id;
  final String nombre;
  final String? descripcion;
  final double? precio;
  final String subcategoriaId;
  bool isSelected = false;

  Servicio({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.precio,
    required this.subcategoriaId,
  });
}

class CrearProveedor extends StatefulWidget {
  const CrearProveedor({
    super.key,
    this.width,
    this.height,
    required this.serviciosid,
    this.action,
    this.readOnly = false,
  });

  final double? width;
  final double? height;
  final List<String> serviciosid;
  final Future Function(List<String>? serviciosidsss)? action;
  final bool readOnly;

  @override
  State<CrearProveedor> createState() => _CrearProveedorState();
}

class _CrearProveedorState extends State<CrearProveedor> {
  List<Categoria> categorias = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Usar la consulta SQL directamente
      final response = await SupaFlow.client.from('categorias').select('''
            id,
            nombre,
            subcategorias:subcategorias(
              id,
              nombre,
              descripcion,
              categoria_id,
              servicios:servicios(
                id,
                nombre,
                descripcion,
                precio,
                subcategoria_id
              )
            )
          ''');

      if (response == null) {
        throw Exception('No se pudieron cargar los datos');
      }

      _processData(response);
    } catch (e) {
      setState(() {
        error = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _processData(dynamic data) {
    List<Categoria> categoriasTemp = [];

    for (var categoriaData in data) {
      Categoria categoria = Categoria(
        id: categoriaData['id'],
        nombre: categoriaData['nombre'],
      );

      // Procesar subcategorías si existen
      if (categoriaData['subcategorias'] != null) {
        for (var subcategoriaData in categoriaData['subcategorias']) {
          Subcategoria subcategoria = Subcategoria(
            id: subcategoriaData['id'],
            nombre: subcategoriaData['nombre'],
            descripcion: subcategoriaData['descripcion'],
            categoriaId: categoriaData['id'],
          );

          // Procesar servicios si existen
          if (subcategoriaData['servicios'] != null) {
            for (var servicioData in subcategoriaData['servicios']) {
              Servicio servicio = Servicio(
                id: servicioData['id'],
                nombre: servicioData['nombre'],
                descripcion: servicioData['descripcion'],
                precio: servicioData['precio'] != null
                    ? double.tryParse(servicioData['precio'].toString())
                    : null,
                subcategoriaId: subcategoriaData['id'],
              );

              // Verificar si este servicio ya está seleccionado
              if (widget.serviciosid.contains(servicio.id)) {
                servicio.isSelected = true;
              }

              subcategoria.servicios.add(servicio);
            }
          }

          categoria.subcategorias.add(subcategoria);
        }
      }

      categoriasTemp.add(categoria);
    }

    setState(() {
      categorias = categoriasTemp;
      // Actualizar estados de subcategorías y categorías basado en servicios seleccionados
      _updateSelectionStates();
    });
  }

  // Actualizar estados de selección basado en servicios preseleccionados
  void _updateSelectionStates() {
    for (var categoria in categorias) {
      for (var subcategoria in categoria.subcategorias) {
        // Verificar si todos los servicios están seleccionados
        if (subcategoria.servicios.isNotEmpty) {
          subcategoria.isSelected =
              subcategoria.servicios.every((s) => s.isSelected);
        }
      }

      // Verificar si todas las subcategorías están seleccionadas
      if (categoria.subcategorias.isNotEmpty) {
        categoria.isSelected =
            categoria.subcategorias.every((s) => s.isSelected);
      }
    }
  }

  void _onCategoriaChanged(Categoria categoria, bool? value) {
    setState(() {
      categoria.isSelected = value ?? false;

      // Seleccionar/deseleccionar todas las subcategorías y servicios
      for (var subcategoria in categoria.subcategorias) {
        subcategoria.isSelected = categoria.isSelected;
        for (var servicio in subcategoria.servicios) {
          servicio.isSelected = categoria.isSelected;
        }
      }

      // Ejecutar la acción callback
      _executeAction();
    });
  }

  void _onSubcategoriaChanged(Subcategoria subcategoria, bool? value) {
    setState(() {
      subcategoria.isSelected = value ?? false;

      // Seleccionar/deseleccionar todos los servicios de la subcategoría
      for (var servicio in subcategoria.servicios) {
        servicio.isSelected = subcategoria.isSelected;
      }

      // Actualizar estado de la categoría padre
      _updateCategoriaState(subcategoria.categoriaId);

      // Ejecutar la acción callback
      _executeAction();
    });
  }

  void _onServicioChanged(Servicio servicio, bool? value) {
    setState(() {
      servicio.isSelected = value ?? false;

      // Actualizar estado de la subcategoría y categoría padre
      _updateSubcategoriaState(servicio.subcategoriaId);

      // Ejecutar la acción callback
      _executeAction();
    });
  }

  void _updateCategoriaState(String categoriaId) {
    Categoria categoria = categorias.firstWhere((cat) => cat.id == categoriaId);

    bool allSubcategoriasSelected = categoria.subcategorias.isNotEmpty &&
        categoria.subcategorias.every((sub) => sub.isSelected);

    categoria.isSelected = allSubcategoriasSelected;
  }

  void _updateSubcategoriaState(String subcategoriaId) {
    Subcategoria? subcategoria;
    String categoriaId = '';

    for (var categoria in categorias) {
      for (var sub in categoria.subcategorias) {
        if (sub.id == subcategoriaId) {
          subcategoria = sub;
          categoriaId = categoria.id;
          break;
        }
      }
      if (subcategoria != null) break;
    }

    if (subcategoria != null) {
      bool allServiciosSelected = subcategoria.servicios.isNotEmpty &&
          subcategoria.servicios.every((serv) => serv.isSelected);

      subcategoria.isSelected = allServiciosSelected;
      _updateCategoriaState(categoriaId);
    }
  }

  // Método para ejecutar la acción callback con la lista de servicios seleccionados
  void _executeAction() {
    if (!widget.readOnly && widget.action != null) {
      List<String> serviciosSeleccionados = _getServiciosSeleccionados();

      // Ejecutar la acción de manera asíncrona
      widget.action!(serviciosSeleccionados);
    }
  }

  // Método para obtener los servicios seleccionados
  List<String> _getServiciosSeleccionados() {
    List<String> serviciosSeleccionados = [];

    for (var categoria in categorias) {
      for (var subcategoria in categoria.subcategorias) {
        for (var servicio in subcategoria.servicios) {
          if (servicio.isSelected) {
            serviciosSeleccionados.add(servicio.id);
          }
        }
      }
    }

    return serviciosSeleccionados;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ Se adapta al contenido
        children: [
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: FlutterFlowTheme.of(context).primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando servicios...',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Readex Pro',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: FlutterFlowTheme.of(context).error,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Readex Pro',
                      color: FlutterFlowTheme.of(context).error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (categorias.isEmpty) {
      return Container(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 48,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay categorías disponibles',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Readex Pro',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.readOnly) {
      return _buildReadOnlyServices();
    }

    // El contenido principal se adapta completamente al contenido
    return Column(
      mainAxisSize: MainAxisSize.min, // Clave: Se adapta al contenido
      children: categorias
          .map((categoria) => _buildCategoriaCard(categoria))
          .toList(),
    );
  }

  Widget _buildReadOnlyServices() {
    final groups = <Widget>[];
    for (final categoria in categorias) {
      final subcategorias = categoria.subcategorias
          .map((subcategoria) => MapEntry(
                subcategoria,
                subcategoria.servicios
                    .where((servicio) => servicio.isSelected)
                    .toList(),
              ))
          .where((entry) => entry.value.isNotEmpty)
          .toList();
      if (subcategorias.isEmpty) continue;

      groups.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth >= 560
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBF8),
                  border: Border.all(color: const Color(0xFFDCE9DF)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria.nombre,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Readex Pro',
                            color: FlutterFlowTheme.of(context).customColor1,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...subcategorias.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key.nombre,
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Readex Pro',
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 6,
                                runSpacing: 5,
                                children: entry.value
                                    .map((servicio) => Chip(
                                          avatar: Icon(
                                            Icons.check_rounded,
                                            size: 15,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                          label: Text(servicio.nombre),
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide.none,
                                          backgroundColor:
                                              const Color(0xFFDFF3E5),
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodySmall
                                              .override(
                                                fontFamily: 'Readex Pro',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          'No hay servicios ofrecidos registrados.',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Readex Pro',
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: groups,
    );
  }

  Widget _buildCategoriaCard(Categoria categoria) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(
              value: categoria.isSelected,
              onChanged: (value) => _onCategoriaChanged(categoria, value),
              activeColor: FlutterFlowTheme.of(context).primary,
            ),
            title: Text(
              categoria.nombre,
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'Readex Pro',
                    fontWeight: FontWeight.w500,
                  ),
            ),
            trailing: categoria.subcategorias.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      categoria.isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        categoria.isExpanded = !categoria.isExpanded;
                      });
                    },
                  )
                : null,
          ),
          if (categoria.isExpanded && categoria.subcategorias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
              child: Column(
                children: categoria.subcategorias
                    .map((subcategoria) => _buildSubcategoriaCard(subcategoria))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubcategoriaCard(Subcategoria subcategoria) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: FlutterFlowTheme.of(context).secondaryBackground,
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(
              value: subcategoria.isSelected,
              onChanged: (value) => _onSubcategoriaChanged(subcategoria, value),
              activeColor: FlutterFlowTheme.of(context).primary,
            ),
            title: Text(
              subcategoria.nombre,
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Readex Pro',
                    fontWeight: FontWeight.w500,
                  ),
            ),
            trailing: subcategoria.servicios.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      subcategoria.isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        subcategoria.isExpanded = !subcategoria.isExpanded;
                      });
                    },
                  )
                : null,
          ),
          if (subcategoria.isExpanded && subcategoria.servicios.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
              child: Column(
                children: subcategoria.servicios
                    .map((servicio) => _buildServicioCard(servicio))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServicioCard(Servicio servicio) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Checkbox(
          value: servicio.isSelected,
          onChanged: (value) => _onServicioChanged(servicio, value),
          activeColor: FlutterFlowTheme.of(context).primary,
        ),
        title: Text(
          servicio.nombre,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Readex Pro',
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
