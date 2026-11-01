// Interoperabilidad con la API de JavaScript de Google Maps.
//
// Se hace a mano en vez de con `google_maps_flutter_web` por dos razones:
// controlar el Map ID (hace falta para los marcadores modernos) y no anadir
// dependencias pesadas a un proyecto que ya arrastra muchas.
//
// SOLO WEB. Importa `dart:ui_web`, que no existe en movil. `hulp_admin` es una
// app web, asi que no hace falta importacion condicional; si algun dia se
// compilara para otra plataforma, este archivo es lo primero que se rompe.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

// ---------------------------------------------------------------------------
// Tipos de la API de Maps
//
// Se declara solo lo que se usa. Cada `extension type` es una vista sobre el
// objeto de JavaScript, sin copiar nada.
// ---------------------------------------------------------------------------

extension type _LatLngLiteral._(JSObject _) implements JSObject {
  external factory _LatLngLiteral({double lat, double lng});
}

extension type _LatLng._(JSObject _) implements JSObject {
  external double lat();
  external double lng();
}

extension type _MapMouseEvent._(JSObject _) implements JSObject {
  external _LatLng? get latLng;
}

extension type _MapOptions._(JSObject _) implements JSObject {
  external factory _MapOptions({
    _LatLngLiteral center,
    int zoom,
    String? mapId,
    String gestureHandling,
    bool disableDefaultUI,
    bool zoomControl,
    bool streetViewControl,
    bool mapTypeControl,
    bool fullscreenControl,
    bool clickableIcons,
  });
}

extension type _GMap._(JSObject _) implements JSObject {
  external void setCenter(_LatLngLiteral latLng);
  external void setZoom(int zoom);
  external void addListener(String evento, JSFunction manejador);
}

extension type _MarkerOptions._(JSObject _) implements JSObject {
  external factory _MarkerOptions({
    _GMap? map,
    _LatLngLiteral position,
    bool gmpDraggable,
  });
}

extension type _AdvancedMarker._(JSObject _) implements JSObject {
  external set position(_LatLngLiteral valor);
  external set map(_GMap? valor);
  external void addListener(String evento, JSFunction manejador);
}

/// Resuelve una ruta como `google.maps.Map` sobre el objeto global.
///
/// Se hace asi en vez de con `@JS('google.maps.Map') external` porque esas
/// declaraciones se evaluan aunque `google` no exista todavia, y entonces
/// revientan con un ReferenceError en vez de devolver nulo.
JSObject? _global(String ruta) {
  JSObject actual = globalContext;
  for (final parte in ruta.split('.')) {
    if (!actual.has(parte)) return null;
    final siguiente = actual.getProperty(parte.toJS);
    if (siguiente == null || siguiente is! JSObject) return null;
    actual = siguiente;
  }
  return actual;
}

bool get _mapsCargado => _global('google.maps.Map') != null;

// ---------------------------------------------------------------------------
// Carga del script
// ---------------------------------------------------------------------------

Completer<bool>? _carga;

/// Inyecta el script de Maps una sola vez y espera a que este listo.
///
/// Devuelve false si no hay clave o si el script no carga: red caida, clave
/// revocada, dominio no autorizado. Quien llame debe seguir funcionando sin
/// mapa — es una mejora, no un requisito.
Future<bool> cargarGoogleMaps(String claveApi) {
  if (_carga != null) return _carga!.future;
  final completer = Completer<bool>();
  _carga = completer;

  if (claveApi.isEmpty) {
    completer.complete(false);
    return completer.future;
  }
  if (_mapsCargado) {
    completer.complete(true);
    return completer.future;
  }

  const nombreCallback = '__hulpGoogleMapsListo';
  globalContext.setProperty(
    nombreCallback.toJS,
    (() {
      if (!completer.isCompleted) completer.complete(true);
    }).toJS,
  );

  final script = web.HTMLScriptElement();
  // `loading=async` es lo que pide Google desde 2024 y evita el aviso de
  // rendimiento en consola. `libraries=marker` trae AdvancedMarkerElement,
  // que es el marcador que funciona con Map ID.
  script.src = 'https://maps.googleapis.com/maps/api/js'
      '?key=$claveApi&libraries=marker&loading=async&callback=$nombreCallback';
  script.async = true;
  script.addEventListener(
    'error',
    ((web.Event _) {
      if (!completer.isCompleted) completer.complete(false);
    }).toJS,
  );
  web.document.head!.appendChild(script);

  // Red de seguridad: si el callback no llega, no dejar la interfaz esperando
  // para siempre. Diez segundos sobran para un script de ~100 KB.
  Timer(const Duration(seconds: 10), () {
    if (!completer.isCompleted) completer.complete(_mapsCargado);
  });

  return completer.future;
}

// ---------------------------------------------------------------------------
// Fachada en Dart
// ---------------------------------------------------------------------------

/// Un mapa ya montado. Envuelve el objeto de JavaScript para que el resto del
/// codigo no vea nada de interoperabilidad.
class MapaGoogle {
  MapaGoogle._(this._mapa, this._alElegirPunto);

  final _GMap _mapa;
  final void Function(double lat, double lng) _alElegirPunto;
  _AdvancedMarker? _marcador;

  /// Mueve el mapa y el marcador. Se usa cuando el punto cambia desde fuera:
  /// al pegar un enlace o al elegir una sugerencia del autocompletado.
  void moverA(double latitud, double longitud, {int? zoom}) {
    final pos = _LatLngLiteral(lat: latitud, lng: longitud);
    _mapa.setCenter(pos);
    if (zoom != null) _mapa.setZoom(zoom);
    _ponerMarcador(pos);
  }

  /// Quita el marcador sin destruir el mapa.
  void quitarMarcador() => _marcador?.map = null;

  /// Cambia solo la cámara, sin marcador ni callback de selección.
  void centrarEn(double latitud, double longitud, {required int zoom}) {
    _mapa.setCenter(_LatLngLiteral(lat: latitud, lng: longitud));
    _mapa.setZoom(zoom);
  }

  void _ponerMarcador(_LatLngLiteral pos) {
    final existente = _marcador;
    if (existente != null) {
      existente.position = pos;
      existente.map = _mapa;
      return;
    }
    final ctor = _global('google.maps.marker.AdvancedMarkerElement');
    if (ctor == null) return;
    final nuevo = (ctor as JSFunction).callAsConstructor<_AdvancedMarker>(
      _MarkerOptions(map: _mapa, position: pos, gmpDraggable: true),
    );
    // El oyente se engancha aqui, al crear el marcador, y no fuera: los
    // marcadores creados despues (al pegar un punto en un mapa que no tenia)
    // tambien tienen que poder arrastrarse.
    nuevo.addListener(
      'dragend',
      ((_MapMouseEvent evento) {
        final punto = evento.latLng;
        if (punto != null) _alElegirPunto(punto.lat(), punto.lng());
      }).toJS,
    );
    _marcador = nuevo;
  }
}

/// Registra el div del mapa como vista de plataforma. Hay que llamarlo una vez
/// por identificador antes de montar el `HtmlElementView`.
void registrarVistaMapa(String idVista, web.HTMLElement elemento) {
  ui_web.platformViewRegistry.registerViewFactory(idVista, (int _) => elemento);
}

/// Crea un div con el tamano al 100%, listo para alojar el mapa.
web.HTMLElement crearContenedorMapa() {
  final div = web.HTMLDivElement();
  div.style.width = '100%';
  div.style.height = '100%';
  return div;
}

/// El mapa recibe los eventos antes que esta barrera, en fase de burbujeo.
/// Flutter no debe recibir la rueda ni iniciar un arrastre desde el mapa.
void Function() aislarEventosMapa(web.HTMLElement elemento) {
  final alIniciarArrastre = ((web.Event evento) {
    evento.stopPropagation();
  }).toJS;
  final alUsarRueda = ((web.Event evento) {
    evento.stopPropagation();
    if (evento.cancelable) evento.preventDefault();
  }).toJS;

  elemento.addEventListener('pointerdown', alIniciarArrastre);
  elemento.addEventListener(
    'wheel',
    alUsarRueda,
    web.AddEventListenerOptions(passive: false),
  );

  // No se bloquean move/up: Maps los necesita al arrastrar fuera del recuadro.
  return () {
    elemento.removeEventListener('pointerdown', alIniciarArrastre);
    elemento.removeEventListener('wheel', alUsarRueda);
  };
}

/// Crea el mapa dentro de `elemento` y conecta los avisos de cambio de punto.
///
/// `alElegirPunto` se dispara tanto al hacer clic en el mapa como al soltar el
/// marcador tras arrastrarlo: para quien lo usa son el mismo gesto.
///
/// Devuelve null si el script todavia no cargo, en vez de reventar.
MapaGoogle? crearMapa({
  required web.HTMLElement elemento,
  required double latitud,
  required double longitud,
  required int zoom,
  required String? mapId,
  required bool conMarcador,
  required void Function(double lat, double lng) alElegirPunto,
}) {
  final ctor = _global('google.maps.Map');
  if (ctor == null) return null;

  final centro = _LatLngLiteral(lat: latitud, lng: longitud);
  final mapa = (ctor as JSFunction).callAsConstructor<_GMap>(
    elemento as JSObject,
    _MapOptions(
      center: centro,
      zoom: zoom,
      mapId: mapId,
      // En el formulario el mapa está dentro de una página desplazable; este
      // modo hace que la rueda sobre el mapa interactúe con el propio mapa.
      gestureHandling: 'greedy',
      disableDefaultUI: true,
      zoomControl: true,
      streetViewControl: false,
      mapTypeControl: false,
      // Amplía la misma instancia del mapa y conserva el punto seleccionado.
      fullscreenControl: true,
      // Sin esto, pinchar sobre un negocio abre su ficha en vez de fijar el
      // punto, que es justo lo contrario de lo que se busca aqui.
      clickableIcons: false,
    ),
  );

  final envoltorio = MapaGoogle._(mapa, alElegirPunto);
  if (conMarcador) envoltorio._ponerMarcador(centro);

  mapa.addListener(
    'click',
    ((_MapMouseEvent evento) {
      final punto = evento.latLng;
      if (punto == null) return;
      final lat = punto.lat();
      final lng = punto.lng();
      envoltorio.moverA(lat, lng);
      alElegirPunto(lat, lng);
    }).toJS,
  );

  return envoltorio;
}
