import '/backend/solicitudes_stream.dart';
import '/backend/solicitudes_http_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '/flutter_flow/flutter_flow_util.dart';
import '/environment_values.dart';

export 'database/database.dart';
export 'storage/storage.dart';

class SupaFlow {
  SupaFlow._();

  static SupaFlow? _instance;
  static SupaFlow get instance => _instance ??= SupaFlow._();

  final _supabase = Supabase.instance.client;
  static SupabaseClient get client => instance._supabase;
  static SolicitudesStream solicitudesStream() => SolicitudesStream(client);
  static bool get finanzasV1Habilitadas =>
      FFDevEnvironmentValues().supabaseUrl.contains('ptafsiwlhxomgqmdmidf');

  static Future initialize() => Supabase.initialize(
        url: FFDevEnvironmentValues().supabaseUrl,
        httpClient: SolicitudesHttpClient(),
        headers: {
          'X-Client-Info': 'flutterflow',
        },
        anonKey: FFDevEnvironmentValues().supabaseAnonKey,
        debug: false,
        authOptions:
            FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
      );
}
