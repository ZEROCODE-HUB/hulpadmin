import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Completa icono y placeholder sin reemplazar el estilo del campo existente.
InputDecoration decorarInputHulp(
  BuildContext context,
  InputDecoration base, {
  String? etiqueta,
  bool busqueda = false,
  bool soloLectura = false,
  String? placeholder,
}) {
  final descriptor = etiqueta ?? base.labelText ?? base.hintText ?? 'Campo';
  final tema = Theme.of(context);
  final colorEnFoco = FlutterFlowTheme.of(context).primary;
  final iconoOriginal = base.prefixIcon;
  final colorBaseIcono = iconoOriginal is Icon ? iconoOriginal.color : null;
  final icono = iconoOriginal is Icon && iconoOriginal.color != null
      ? _iconoHeredado(iconoOriginal)
      : iconoOriginal;
  final colorIcono = WidgetStateColor.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? colorEnFoco
        : colorBaseIcono ??
            base.prefixIconColor ??
            tema.inputDecorationTheme.prefixIconColor ??
            tema.colorScheme.onSurfaceVariant,
  );
  final bordeEnFoco = _bordeEnFoco(
    base.focusedBorder ?? base.enabledBorder ?? base.border,
    colorEnFoco,
  );
  final hintActual = base.hintText?.trim();
  final hintEsSoloEtiqueta = base.labelText == null &&
      hintActual != null &&
      _etiquetasSinAyuda.contains(_normalizar(hintActual));
  final hint = placeholder ??
      (hintActual == null || hintActual.isEmpty || hintEsSoloEtiqueta
          ? _placeholderPara(descriptor, busqueda: busqueda)
          : hintActual);

  return base.copyWith(
    hintText: hint,
    prefixIcon: icono ??
        (soloLectura
            ? null
            : Icon(
                _iconoPara(descriptor, busqueda: busqueda),
                size: 19,
              )),
    prefixIconColor: colorIcono,
    focusedBorder: bordeEnFoco ?? base.focusedBorder,
  );
}

Icon _iconoHeredado(Icon icono) => Icon(
      icono.icon,
      key: icono.key,
      size: icono.size,
      fill: icono.fill,
      weight: icono.weight,
      grade: icono.grade,
      opticalSize: icono.opticalSize,
      shadows: icono.shadows,
      semanticLabel: icono.semanticLabel,
      textDirection: icono.textDirection,
      applyTextScaling: icono.applyTextScaling,
      blendMode: icono.blendMode,
      fontWeight: icono.fontWeight,
    );

InputBorder? _bordeEnFoco(InputBorder? borde, Color color) {
  final lado = borde?.borderSide.copyWith(color: color, width: 1.5);
  if (borde is OutlineInputBorder) {
    return borde.copyWith(borderSide: lado);
  }
  if (borde is UnderlineInputBorder) {
    return borde.copyWith(borderSide: lado);
  }
  return null;
}

IconData _iconoPara(String etiqueta, {required bool busqueda}) {
  final texto = _normalizar(etiqueta);
  if (busqueda || _contiene(texto, ['buscar', 'busqueda'])) {
    return Icons.search_rounded;
  }
  if (_contiene(texto, ['correo', 'email', 'e-mail'])) {
    return Icons.mail_outline_rounded;
  }
  if (_contiene(texto, ['contrasena', 'password', 'clave'])) {
    return Icons.key_outlined;
  }
  if (_contiene(texto, ['telefono', 'celular', 'movil'])) {
    return Icons.phone_outlined;
  }
  if (_contiene(texto, ['direccion', 'ubicacion', 'ciudad', 'barrio'])) {
    return Icons.location_on_outlined;
  }
  if (_contiene(texto, [
    'documento',
    'identificacion',
    'identificador',
    'nit',
    'rut',
    'id del'
  ])) {
    return Icons.badge_outlined;
  }
  if (_contiene(texto, ['cuenta', 'banco', 'entidad financiera'])) {
    return Icons.account_balance_outlined;
  }
  if (_contiene(texto, ['fecha', 'hora'])) return Icons.calendar_month_outlined;
  if (_contiene(texto, ['duracion', 'tiempo'])) return Icons.schedule_outlined;
  if (_contiene(texto, ['cantidad', 'unidades'])) return Icons.numbers_rounded;
  if (_contiene(
      texto, ['precio', 'valor', 'pago', 'comision', 'iva', 'costo'])) {
    return Icons.attach_money_rounded;
  }
  if (_contiene(texto, ['nota', 'comentario', 'observacion', 'descripcion'])) {
    return Icons.notes_outlined;
  }
  if (_contiene(texto, [
    'servicio',
    'material',
    'categoria',
    'subcategoria',
    'item',
    'elemento',
    'lista',
  ])) {
    return Icons.home_repair_service_outlined;
  }
  if (_contiene(
      texto, ['nombre', 'usuario', 'cliente', 'proveedor', 'persona'])) {
    return Icons.person_outline_rounded;
  }
  return Icons.edit_outlined;
}

String _placeholderPara(String etiqueta, {required bool busqueda}) {
  if (busqueda) return 'Buscar...';

  final texto = _normalizar(etiqueta);
  if (_contiene(texto, ['correo', 'email', 'e-mail'])) {
    return 'nombre@ejemplo.com';
  }
  if (_contiene(texto, ['contrasena', 'password', 'clave'])) {
    return 'Digite la contraseña';
  }
  if (_contiene(texto, ['telefono', 'celular', 'movil'])) {
    return 'Ej. 300 123 4567';
  }
  if (_contiene(texto, ['direccion', 'ubicacion'])) {
    return 'Ej. Calle 10 #20-30';
  }
  if (_contiene(texto, ['ciudad'])) return 'Ej. Bogotá D.C.';
  if (_contiene(texto, ['documento', 'identificacion'])) {
    return 'Número de documento';
  }
  if (_contiene(texto, ['identificador', 'id del'])) {
    return 'Número de identificación';
  }
  if (_contiene(texto, ['nit', 'rut'])) return 'Ingresa el NIT o RUT';
  if (_contiene(texto, ['cuenta'])) return 'Número de cuenta';
  if (_contiene(texto, ['banco', 'entidad financiera'])) {
    return 'Escribe el nombre de la entidad';
  }
  if (_contiene(
      texto, ['precio', 'valor', 'pago', 'comision', 'iva', 'costo'])) {
    return '0';
  }
  if (_contiene(texto, ['cantidad', 'unidades'])) return '0';
  if (_contiene(texto, ['nota', 'comentario', 'observacion'])) {
    return 'Agrega una nota';
  }
  if (_contiene(texto, ['descripcion', 'informacion'])) {
    return 'Escribe una descripción';
  }
  if (_contiene(texto, ['apellido'])) return 'Ingresa los apellidos';
  if (_contiene(texto, ['nombre'])) return 'Ingresa el nombre';
  if (_contiene(texto, ['servicio', 'material', 'categoria', 'subcategoria'])) {
    return 'Escribe el nombre';
  }
  return 'Escribe ${etiqueta.replaceAll('*', '').trim().toLowerCase()}';
}

bool _contiene(String texto, List<String> opciones) =>
    opciones.any(texto.contains);

String _normalizar(String texto) => texto
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u')
    .replaceAll('ñ', 'n')
    .replaceAll('*', '')
    .trim();

const _etiquetasSinAyuda = {
  'nombre',
  'nombres',
  'apellidos',
  'correo',
  'telefono',
  'direccion',
  'descripcion',
  'notas',
  'precio',
  'cantidad',
  'documento',
  'contrasena',
  'usuario',
};
