import 'dart:async';
import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime comunica cambios; los datos completos se vuelven a leer por rol.
/// No se reconstruyen importes usando un evento parcial ni notas privadas.
class SolicitudesStream extends Stream<List<Map<String, dynamic>>> {
  SolicitudesStream(this.client, [Map<String, Object>? filters])
      : filters = filters ?? {};
  final SupabaseClient client;
  final Map<String, Object> filters;

  SolicitudesStream eq(String column, Object value) =>
      SolicitudesStream(client, {...filters, column: value});
  SolicitudesStream eqOrNull(String column, Object? value) =>
      value == null ? this : eq(column, value);

  @override
  StreamSubscription<List<Map<String, dynamic>>> listen(
    void Function(List<Map<String, dynamic>>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (!client.rest.url
        .toString()
        .contains('ptafsiwlhxomgqmdmidf.supabase.co')) {
      // Fuera de la rama activada conservar el stream anterior íntegro.
      final original =
          client.from('solicitudes_servicio').stream(primaryKey: ['id']);
      final Stream<List<Map<String, dynamic>>> stream = filters.isEmpty
          ? original
          : original.eq(filters.entries.first.key, filters.entries.first.value);
      return stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    }
    late StreamController<List<Map<String, dynamic>>> controller;
    RealtimeChannel? channel;
    var loading = false, queued = false, cancelled = false;
    List<Map<String, dynamic>>? previous;
    Future<void> refresh() async {
      if (cancelled || controller.isClosed) return;
      if (loading) {
        queued = true;
        return;
      }
      loading = true;
      do {
        queued = false;
        try {
          var query = client.from('solicitudes_servicio').select();
          for (final f in filters.entries) {
            query = query.eq(f.key, f.value);
          }
          final rows = await query;
          if (!cancelled &&
              !controller.isClosed &&
              !const DeepCollectionEquality().equals(previous, rows)) {
            previous = rows;
            controller.add(rows);
          }
        } catch (e, trace) {
          if (!cancelled && !controller.isClosed) controller.addError(e, trace);
        }
      } while (queued && !cancelled && !controller.isClosed);
      loading = false;
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        channel = client
            .channel(
                'solicitudes-${DateTime.now().microsecondsSinceEpoch}-$hashCode')
            .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'solicitudes_servicio',
                callback: (_) => refresh())
            .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) refresh();
        });
        refresh();
      },
      onCancel: () async {
        cancelled = true;
        if (channel != null) await client.removeChannel(channel!);
      },
    );
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
