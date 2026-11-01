import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

type Responder = (cuerpo: unknown, status?: number) => Response;
type ResponderError = (
  mensaje: string,
  status?: number,
  extra?: Record<string, unknown>,
) => Response;

interface ContextoConsultaTransaccion {
  admin: SupabaseClient;
  usuarioId: string;
  baseWompi: string;
  cabeceraWompi: HeadersInit;
  responder: Responder;
  error: ResponderError;
}

/**
 * Se llama desde index.ts DESPUÉS de autenticar al usuario.
 * El contexto lo construye el servidor, nunca el cuerpo de la petición.
 * Solo consulta: no crea cobros ni modifica registros en Supabase.
 */
export async function consultarTransaccion(
  cuerpo: unknown,
  contexto: ContextoConsultaTransaccion,
): Promise<Response> {
  const {
    admin,
    usuarioId,
    baseWompi,
    cabeceraWompi,
    responder,
    error,
  } = contexto;

  const valor = cuerpo && typeof cuerpo === 'object'
    ? (cuerpo as Record<string, unknown>).transaction_id
    : undefined;
  const transactionId = typeof valor === 'string' ? valor.trim() : '';

  if (!/^[a-zA-Z0-9_-]{1,150}$/.test(transactionId)) {
    return error('transaction_id inválido', 400);
  }

  // El ID debe estar vinculado a una solicitud registrada en el backend.
  const { data: intentos, error: errIntento } = await admin
    .from('intentos_cobro')
    .select('solicitud_id')
    .eq('wompi_transaction_id', transactionId)
    .limit(1);

  if (errIntento) {
    console.error('Error consultando el intento:', errIntento);
    return error('No se pudo verificar el cobro', 500);
  }

  const solicitudId = intentos?.[0]?.solicitud_id;
  if (!solicitudId) {
    return error('No se encontró el cobro registrado', 404);
  }

  const { data: solicitud, error: errSolicitud } = await admin
    .from('solicitudes_servicio')
    .select('id, usuario_id, profesional_id')
    .eq('id', solicitudId)
    .maybeSingle();

  if (errSolicitud) {
    console.error('Error consultando la solicitud:', errSolicitud);
    return error('No se pudo verificar la solicitud', 500);
  }
  if (!solicitud) {
    return error('No se encontró la solicitud del cobro', 404);
  }

  const { data: perfil, error: errPerfil } = await admin
    .from('usuarios')
    .select('rol')
    .eq('id', usuarioId)
    .maybeSingle();

  if (errPerfil) {
    console.error('Error verificando el perfil:', errPerfil);
    return error('No se pudo verificar la autorización', 500);
  }

  const esAdministrador = perfil?.rol === 'administrador' ||
    perfil?.rol === 'admin';
  const autorizado = esAdministrador ||
    usuarioId === solicitud.usuario_id ||
    usuarioId === solicitud.profesional_id;

  if (!autorizado) {
    return error('No autorizado para consultar este cobro', 403);
  }

  let respuesta: Response;
  try {
    respuesta = await fetch(
      `${baseWompi}/transactions/${encodeURIComponent(transactionId)}`,
      {
        method: 'GET',
        headers: cabeceraWompi,
        signal: AbortSignal.timeout(10_000),
      },
    );
  } catch {
    return error('No se pudo contactar con Wompi', 502);
  }

  if (!respuesta.ok) {
    return error('Wompi no permitió consultar la transacción', 502, {
      statusCode: respuesta.status,
    });
  }

  const datos = await respuesta.json().catch(() => null);
  const t = datos?.data;
  if (!t || t.id !== transactionId || typeof t.status !== 'string') {
    return error('Wompi devolvió una respuesta inválida', 502);
  }

  // success significa consulta exitosa; solo APPROVED acredita aprobación.
  return responder({
    success: true,
    transactionId: t.id,
    status: t.status,
    statusMessage: t.status_message ?? '',
    amount: t.amount_in_cents,
    currency: t.currency,
    customerEmail: t.customer_email,
    reference: t.reference,
    createdAt: t.created_at,
    finalizedAt: t.finalized_at,
    paymentMethod: t.payment_method,
    paymentSourceId: t.payment_source_id,
    fullData: t,
  });
}
