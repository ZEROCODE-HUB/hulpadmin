import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/ubicacion_helpers.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'crear_solicitud_widget.dart' show CrearSolicitudWidget;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CrearSolicitudModel extends FlutterFlowModel<CrearSolicitudWidget> {
  ///  Local state fields for this component.

  List<String> serviciosid = [];
  void addToServiciosid(String item) => serviciosid.add(item);
  void removeFromServiciosid(String item) => serviciosid.remove(item);
  void removeAtIndexFromServiciosid(int index) => serviciosid.removeAt(index);
  void insertAtIndexInServiciosid(int index, String item) =>
      serviciosid.insert(index, item);
  void updateServiciosidAtIndex(int index, Function(String) updateFn) =>
      serviciosid[index] = updateFn(serviciosid[index]);

  String? foto1;

  String? foto2;

  String? foto3;

  String precio = '0';

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for usuarioSeleccionado widget.
  String? usuarioSeleccionadoValue;
  FormFieldController<String>? usuarioSeleccionadoValueController;
  // Estado de las sugerencias provenientes del perfil del cliente.
  String? clienteAutocompletadoId;
  bool direccionSugeridaPorCliente = false;
  bool direccionEditadaManualmente = false;
  bool ciudadSugeridaPorCliente = false;
  bool ciudadEditadaManualmente = false;
  String? ciudadPerfilNoDisponible;
  // Sugerencias obtenidas de solicitudes anteriores del cliente. Se mantienen
  // separadas de las del perfil para respetar su prioridad al cambiar cliente.
  String? historialClienteId;
  Future<List<VwSolicitudesServiciosCompletaRow>>?
      historialSolicitudesRequest;
  bool servicioSugeridoPorHistorial = false;
  bool servicioEditadoManualmente = false;
  bool ciudadSugeridaPorHistorial = false;
  String? servicioHistorialNoDisponible;
  String? ciudadHistorialNoDisponible;
  // State field(s) for usuarioSeleccionado2 widget.
  String? usuarioSeleccionado2Value;
  FormFieldController<String>? usuarioSeleccionado2ValueController;
  // State field(s) for proveedorSeleccionado widget.
  String? proveedorSeleccionadoValue;
  FormFieldController<String>? proveedorSeleccionadoValueController;
  Future<List<VwProfesionalesCompletoRow>>? profesionalesDisponiblesRequest;
  // State field(s) for descripcion widget.
  FocusNode? descripcionFocusNode;
  TextEditingController? descripcionTextController;
  String? Function(BuildContext, String?)? descripcionTextControllerValidator;
  // State field(s) for direccion widget.
  FocusNode? direccionFocusNode;
  TextEditingController? direccionTextController;
  String? Function(BuildContext, String?)? direccionTextControllerValidator;
  String? _direccionTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Ingresa la dirección';
    }

    return null;
  }

  // Punto exacto de la solicitud. Nulo mientras no se capture: la direccion en
  // texto sigue siendo obligatoria, la coordenada no.
  Coordenadas? coordenadas;

  // State field(s) for preciobase widget.
  FocusNode? preciobaseFocusNode;
  TextEditingController? preciobaseTextController;
  String? Function(BuildContext, String?)? preciobaseTextControllerValidator;
  List<ItemsReciboStruct> preciosAdicionalesSolicitud = [];
  void addToPreciosAdicionalesSolicitud(ItemsReciboStruct item) =>
      preciosAdicionalesSolicitud.add(item);
  void removeAtIndexFromPreciosAdicionalesSolicitud(int index) =>
      preciosAdicionalesSolicitud.removeAt(index);
  // State field(s) for servicioSelecc widget.
  String? servicioSeleccValue;
  FormFieldController<String>? servicioSeleccValueController;
  Future<List<ServiciosRow>>? serviciosDisponiblesRequest;
  // State field(s) for ciudadSelecc widget.
  String? ciudadSeleccValue;
  Future<List<CiudadesRow>>? ciudadesActivasRequest;
  // Stores action output result for [Backend Call - Query Rows] action in servicioSelecc widget.
  List<ServiciosRow>? precioss;
  DateTime? datePicked;
  // State field(s) for notas widget.
  FocusNode? notasFocusNode;
  TextEditingController? notasTextController;
  String? Function(BuildContext, String?)? notasTextControllerValidator;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<SolicitudesServicioRow>? serv;

  @override
  void initState(BuildContext context) {
    direccionTextControllerValidator = _direccionTextControllerValidator;
  }

  @override
  void dispose() {
    descripcionFocusNode?.dispose();
    descripcionTextController?.dispose();

    direccionFocusNode?.dispose();
    direccionTextController?.dispose();

    preciobaseFocusNode?.dispose();
    preciobaseTextController?.dispose();


    notasFocusNode?.dispose();
    notasTextController?.dispose();
  }
}
