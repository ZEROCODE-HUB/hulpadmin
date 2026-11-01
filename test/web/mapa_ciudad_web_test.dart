@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:hulp_admin/components/mapa_punto_web.dart';
import 'package:hulp_admin/flutter_flow/ubicacion_helpers.dart';

void main() {
  setUp(() {
    // Sustituye únicamente la API externa, conservando el widget y puente web
    // reales. No necesita red, clave ni datos de clientes.
    final script = web.HTMLScriptElement()
      ..text = '''
      window.__hulpMapaPrueba = null;
      window.__hulpMarcadoresPrueba = [];
      window.google = {maps: {
        Map: class {
          constructor(div, opciones) {
            this.center = opciones.center; this.zoom = opciones.zoom;
            window.__hulpMapaPrueba = this;
          }
          setCenter(punto) { this.center = punto; }
          setZoom(zoom) { this.zoom = zoom; }
          addListener() {}
        },
        marker: {AdvancedMarkerElement: class {
          constructor(opciones) {
            this.map = opciones.map; this.position = opciones.position;
            window.__hulpMarcadoresPrueba.push(this);
          }
          addListener() {}
        }}
      }};
    ''';
    web.document.head!.append(script);
    script.remove();
  });

  testWidgets('ciudad mueve solo cámara y el punto exacto mantiene prioridad',
      (tester) async {
    var selecciones = 0;
    Future<void> montar({Coordenadas? centro, Coordenadas? punto}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
          width: 600,
          height: 250,
          child: MapaPuntoWidget(
            claveApi: 'fake',
            centroCiudad: centro,
            punto: punto,
            onPunto: (_) => selecciones++,
          ),
        )),
      ));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    JSObject getMapa() =>
        globalContext.getProperty<JSObject>('__hulpMapaPrueba'.toJS);
    void comprobar(Coordenadas esperado, int zoom) {
      final mapa = getMapa();
      final centro = mapa.getProperty<JSObject>('center'.toJS);
      expect(centro.getProperty<JSNumber>('lat'.toJS).toDartDouble,
          esperado.latitud);
      expect(centro.getProperty<JSNumber>('lng'.toJS).toDartDouble,
          esperado.longitud);
      expect(mapa.getProperty<JSNumber>('zoom'.toJS).toDartInt, zoom);
    }

    List<JSObject> marcadores() => globalContext
        .getProperty<JSArray<JSObject>>('__hulpMarcadoresPrueba'.toJS)
        .toDart;

    const medellin = Coordenadas(6.24, -75.58);
    const cali = Coordenadas(3.45, -76.53);
    const exacto = Coordenadas(6.25, -75.56);
    await montar(centro: medellin);
    comprobar(medellin, 12);
    expect(marcadores(), isEmpty);
    await montar(centro: cali);
    comprobar(cali, 12);
    expect(marcadores(), isEmpty);
    await montar(centro: cali, punto: exacto);
    comprobar(exacto, 17);
    expect(marcadores(), hasLength(1));
    await montar(centro: medellin, punto: exacto);
    comprobar(exacto, 17);
    await montar(centro: medellin);
    comprobar(medellin, 12);
    expect(marcadores().single.getProperty<JSAny?>('map'.toJS), isNull);
    expect(selecciones, 0);
    expect(tester.takeException(), isNull);
  });
}
