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
  static bool get finanzasV1Habilitadas => true;

  static Future initialize() {
    final environment = FFDevEnvironmentValues();
    final url = environment.supabaseUrl;
    return Supabase.initialize(
      url: url,
      httpClient: SolicitudesHttpClient(supabaseUrl: Uri.parse(url)),
      headers: {
        'X-Client-Info': 'flutterflow',
      },
      anonKey: environment.supabaseAnonKey,
      debug: false,
      authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  }
}
