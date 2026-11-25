import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.57.4';

const cors = { 'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS' };
const response = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { ...cors, 'Content-Type': 'application/json' },
});

export function crearHandler(admin: SupabaseClient) {
return async (req: Request) => {
  if (req.method === 'OPTIONS') return response({});
  if (req.method !== 'POST') return response({ error: 'Método no permitido' }, 405);
  const token = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) return response({ error: 'Sesión requerida' }, 401);
  const { data: { user }, error: authError } = await admin.auth.getUser(token);
  if (authError || !user) return response({ error: 'Sesión inválida' }, 401);
  const { data: operador, error: operadorError } = await admin.from('usuarios').select('rol').eq('id', user.id).maybeSingle();
  if (operadorError) return response({ error: 'No se pudo validar la sesión' }, 503);
  if (operador?.rol !== 'administrador') return response({ error: 'No tienes permiso para crear clientes' }, 403);
  try {
    const body = await req.json();
    const nombre = typeof body.nombre === 'string' ? body.nombre.trim() : '';
    const apellido = typeof body.apellido === 'string' ? body.apellido.trim() : '';
    let telefono = typeof body.telefono === 'string' ? body.telefono.replace(/\D/g, '') : '';
    if (telefono.length === 10) telefono = '57' + telefono;
    const d = body.direccion;
    if (!nombre || nombre.length > 200 || !apellido || apellido.length > 200 || !/^573\d{9}$/.test(telefono))
      return response({ error: 'Ingresa nombre, apellido y celular colombiano de 10 dígitos' }, 400);
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(body.request_id ?? '') || !d ||
      typeof d.direccion !== 'string' || !d.direccion.trim() || typeof d.ciudad_id !== 'string' || !d.ciudad_id ||
      !['casa','oficina','otra'].includes(d.tipo) || (d.tipo === 'otra' && (typeof d.nombre !== 'string' || !d.nombre.trim())) ||
      ['nombre','complemento','referencia'].some(k => d[k] != null && typeof d[k] !== 'string'))
      return response({ error: 'Completa los datos de la dirección' }, 400);
    if ((d.latitud == null) !== (d.longitud == null) ||
      (d.latitud != null && (!Number.isFinite(d.latitud) || Math.abs(d.latitud)>90 ||
        !Number.isFinite(d.longitud) || Math.abs(d.longitud)>180)))
      return response({ error: 'Coordenadas inválidas' }, 400);
    const { data: ciudad } = await admin.from('ciudades').select('id').eq('id', d.ciudad_id).eq('activo',true).maybeSingle();
    if (!ciudad) return response({ error: 'Selecciona una ciudad activa' }, 400);
    const { data: existente, error: errBuscar } = await admin.rpc('quick_add_buscar', { p_telefono: telefono });
    if (errBuscar) return response({ error: errBuscar.message }, 409);
    if (existente) return response({ ok: true, ...existente });
    // Recuperar solo identidades pendientes de Quick Add, sin perfil ni sesiones.
    // También permite reabrir el modal tras un corte; no apropia cuentas ajenas.
    const lookupInicial = await admin.rpc('quick_add_identidad', { p_telefono: telefono });
    if (lookupInicial.error) return response({ error: 'No se pudo consultar la identidad. Reintenta.' }, 503);
    let identidad = lookupInicial.data;
    if (!identidad) {
      const { data, error } = await admin.auth.admin.createUser({
        phone: '+' + telefono, phone_confirm: false,
        app_metadata: { quick_add_request_id: body.request_id, quick_add_operador_id: user.id },
      });
      if (error) {
        const lookup = await admin.rpc('quick_add_identidad', { p_telefono: telefono });
        identidad = lookup.data;
        if (!identidad) return response({ error: 'No se pudo crear la identidad. Intenta nuevamente.' }, 409);
      } else identidad = { id: data.user.id, request_id: body.request_id, recuperable: true };
    }
    if (!identidad.recuperable) {
      const lookup = await admin.rpc('quick_add_buscar', { p_telefono: telefono });
      if (lookup.data) return response({ ok: true, ...lookup.data });
      return response({ error: 'Ese celular ya tiene una identidad registrada. Revisa el perfil existente.' }, 409);
    }
    const { data, error } = await admin.rpc('quick_add_finalizar', {
      p_usuario: identidad.id, p_operador: user.id, p_request: identidad.request_id,
      p_nombre: nombre, p_apellido: apellido, p_telefono: telefono, p_direccion: d,
    });
    if (error) {
      // Conservar la identidad para recuperar el alta con el mismo request_id.
      // No borrarla: un timeout podría ocultar una transacción ya confirmada.
      console.error('Quick Add pendiente de reintento', identidad.id, error.code);
      return response({ error: 'No se pudo completar el alta. Tus datos se conservan; vuelve a guardar.' }, 500);
    }
    return response({ ok: true, ...data });
  } catch (_) { return response({ error: 'Solicitud inválida o servicio no disponible' }, 400); }
};
}
