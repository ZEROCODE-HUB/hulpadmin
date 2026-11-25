import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.119.0';

const cors = {
  'Access-Control-Allow-Origin': '*',
  // Incluye PostgREST para clientes abiertos antes de actualizar el transporte.
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info, accept, accept-profile, content-profile, prefer, range, range-unit',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Expose-Headers': 'content-range, preference-applied',
};
const financial = ['precio_base', 'precio', 'motivo_precio_pagado', 'adelanto_proveedor',
  'adelanto_motivo', 'aplica_wompi', 'aplica_ajuste_iva', 'requiere_fe'];
const operational = ['usuario_id', 'servicio_id', 'descripcion', 'informacion_adicional',
  'notas_cliente', 'ubicacion', 'fecha', 'hora', 'profesional_id', 'ciudad_id',
  'latitud', 'longitud', 'direccion_usuario_id'];
const pick = (data: Record<string, unknown>, keys: string[]) =>
  Object.fromEntries(keys.filter((k) => k in data).map((k) => [k, data[k]]));
const queryHeader = (headers: Record<string, unknown> | undefined, name: string) =>
  Object.entries(headers ?? {}).find(([key]) => key.toLowerCase() === name)?.[1];
const queryPrefer = (headers: Record<string, unknown> | undefined) =>
  String(queryHeader(headers, 'prefer') ?? '').replace(/^(?:null)+/i, '').trim() || 'return=representation';
const esUuid = (value: unknown): value is string =>
  typeof value === 'string' && /^[a-f\d]{8}(?:-[a-f\d]{4}){3}-[a-f\d]{12}$/i.test(value);
const estadosExcepcion = ['cancelada', 'canceladas', 'reagendada', 'reagendadas'];

export async function manejarSolicitud(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  const reply = (value: unknown, status = 200, headers: Record<string, string> = {}) =>
    new Response(JSON.stringify(value), { status, headers: { ...cors, 'Content-Type': 'application/json', ...headers } });
  try {
    const url = Deno.env.get('SUPABASE_URL')!;
    const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
    const { data: auth, error: authError } = await admin.auth.getUser(token);
    if (authError || !auth.user) return reply({ message: 'Sesión inválida' }, 401);
    const actor = auth.user.id;
    const { data: profile, error: profileError } = await admin.from('usuarios').select('rol').eq('id', actor).single();
    if (profileError || !profile) return reply({ message: 'Perfil no encontrado' }, 403);
    const isAdmin = profile.rol === 'administrador';
    const body = await req.json();
    const rpc = async (name: string, args: Record<string, unknown>) => {
      const { data, error } = await admin.rpc(name, args);
      if (error) throw error;
      return data;
    };
    if (!isAdmin && esUuid(body.id) &&
        ['leer', 'desglose_app', 'cotizar_cobro', 'historial_estado'].includes(body.accion)) {
      const { data: solicitud, error } = await admin.from('solicitudes_servicio')
        .select('tipo_asignacion').eq('id', body.id).maybeSingle();
      if (error) throw error;
      if (solicitud?.tipo_asignacion === 'sin_asignar') {
        return reply({ message: 'Solicitud no encontrada' }, 404);
      }
    }
    if (body.accion === 'transicionar') {
      if (profile.rol !== 'proveedor') return reply({ message: 'Acción exclusiva de proveedor' }, 403);
      if (!esUuid(body.id) || !esUuid(body.idempotencia_id) ||
          !['aceptar', 'en_camino', 'empece', 'termine', 'rechazar', 'cancelar_proveedor'].includes(body.operacion) ||
          (body.publicacion_id != null && !esUuid(body.publicacion_id))) {
        return reply({ message: 'Datos de transición inválidos' }, 400);
      }
      if (body.publicacion_id == null && ['aceptar', 'rechazar'].includes(body.operacion)) {
        return reply({ message: 'Actualiza Talento para responder a esta oferta.' }, 409);
      }
      if (body.operacion === 'cancelar_proveedor' && !('publicacion_id' in body)) {
        return reply({ message: 'Actualiza Talento para cancelar esta asignación.' }, 409);
      }
      return reply(await rpc('solicitud_transicion_sprint4', {
        p_actor: actor, p_id: body.id, p_accion: body.operacion,
        p_idempotencia: body.idempotencia_id, p_publicacion: body.publicacion_id ?? null,
      }));
    }
    if (['asignar_sprint4', 'perfil_sprint4', 'proveedores_sprint4'].includes(body.accion)) {
      if (!isAdmin) return reply({ message: 'Sin permiso' }, 403);
      if (body.accion === 'proveedores_sprint4') {
        if (!esUuid(body.ciudad_id) || !esUuid(body.servicio_id)) return reply([], 200);
        return reply(await rpc('proveedores_asignacion_sprint4', {
          p_actor: actor, p_ciudad: body.ciudad_id, p_servicio: body.servicio_id,
        }));
      }
      if (!esUuid(body.id) || (body.profesional_id != null && !esUuid(body.profesional_id)) ||
          (body.publicacion_id != null && !esUuid(body.publicacion_id))) {
        return reply({ message: 'Identificadores de asignación inválidos' }, 400);
      }
      const args = {
        p_actor: actor, p_id: body.id, p_publicacion: body.publicacion_id ?? null,
        p_profesional: body.profesional_id ?? null,
      };
      return reply(body.accion === 'perfil_sprint4'
        ? await rpc('solicitud_perfil_enviado_sprint4', args)
        : await rpc('solicitud_asignar_sprint4', { ...args, p_tipo: body.tipo }));
    }
    if (body.accion === 'historial_admin') {
      if (!isAdmin) return reply({ message: 'Sin permiso' }, 403);
      if (!esUuid(body.id)) return reply({ message: 'Identificador inválido' }, 400);
      const { data: solicitud, error: solicitudError } = await admin.from('solicitudes_servicio')
        .select('creado_en,tipo').eq('id', body.id).maybeSingle();
      if (solicitudError) throw solicitudError;
      if (!solicitud) return reply({ message: 'Solicitud no encontrada' }, 404);

      const leerRevisiones = async () => {
        const revisiones = [];
        const pagina = 500;
        let revision = 0;
        while (true) {
          const { data, error } = await admin.from('solicitud_finanzas_historial')
            .select('revision,entradas,resultados,autor_id,motivo,creado_en')
            .eq('solicitud_id', body.id).gt('revision', revision).order('revision').limit(pagina);
          if (error) throw error;
          revisiones.push(...data);
          if (data.length < pagina) return revisiones;
          revision = data[data.length - 1].revision;
        }
      };
      const [resultadoEventos, revisiones] = await Promise.all([
        admin.from('solicitud_estado_eventos')
          .select('id,accion,actor_id,ocurrido_en,detalles')
          .eq('solicitud_id', body.id).order('ocurrido_en'),
        leerRevisiones(),
      ]);
      if (resultadoEventos.error) throw resultadoEventos.error;
      const eventos = resultadoEventos.data;
      const autores = new Map<string, { nombre: string; rol: string }>();
      const ids = [...new Set([
        ...eventos.map((evento) => evento.actor_id),
        ...revisiones.map((revision) => revision.autor_id),
      ].filter(esUuid))];
      for (let inicio = 0; inicio < ids.length; inicio += 100) {
        const { data, error } = await admin.from('usuarios')
          .select('id,nombres,apellidos,rol').in('id', ids.slice(inicio, inicio + 100));
        if (error) throw error;
        for (const usuario of data) {
          autores.set(usuario.id, {
            nombre: [usuario.nombres, usuario.apellidos].filter(Boolean).join(' ').trim(),
            rol: usuario.rol,
          });
        }
      }
      // creado_en es timestamp sin zona con default now() en UTC en Hulp/test.
      return reply({
        creacion: solicitud.creado_en ? { fecha: `${solicitud.creado_en}Z`, tipo: solicitud.tipo } : null,
        eventos: eventos.map(({ id, accion, actor_id, ocurrido_en, detalles }) => ({
          id, accion, fecha: ocurrido_en, detalles, autor: actor_id ? autores.get(actor_id) ?? null : null,
        })),
        revisiones: revisiones.map(({ revision, entradas, resultados, autor_id, motivo, creado_en }) => ({
          revision, entradas, resultados, motivo, fecha: creado_en,
          autor: autor_id ? autores.get(autor_id) ?? null : null,
        })),
      });
    }
    if (body.accion === 'activar_admin' || body.accion === 'iniciar_admin') {
      if (!isAdmin) return reply({ message: 'Sin permiso' }, 403);
      if (!esUuid(body.id)) return reply({ message: 'Identificador inválido' }, 400);
      const operacion = body.accion === 'activar_admin'
        ? 'solicitud_activar_admin_v1'
        : 'solicitud_iniciar_admin_v1';
      return reply(await rpc(operacion, { p_actor: actor, p_id: body.id }));
    }
    if (body.accion === 'historial_estado' || body.accion === 'finalizar_admin') {
      if (!esUuid(body.id)) return reply({ message: 'Identificador inválido' }, 400);
      if (body.accion === 'historial_estado') {
        return reply(await rpc('solicitud_estado_historial_v1', { p_actor: actor, p_id: body.id }));
      }
      if (!isAdmin) return reply({ message: 'Sin permiso' }, 403);
      if (body.profesional_id != null && !esUuid(body.profesional_id)) {
        return reply({ message: 'Identificador de proveedor inválido' }, 400);
      }
      return reply(await rpc('solicitud_finalizar_admin_v1', {
        p_actor: actor, p_id: body.id, p_profesional_id: body.profesional_id ?? null,
      }));
    }
    if (body.accion === 'metricas') {
      if (!isAdmin || !/^\d{4}-\d{2}-\d{2}T/.test(body.inicio ?? '') || !/^\d{4}-\d{2}-\d{2}T/.test(body.fin ?? '')) {
        return reply({ message: 'Período no permitido' }, 403);
      }
      const { data, error } = await admin.rpc('solicitud_metricas_periodo_v1', { p_inicio: body.inicio, p_fin: body.fin });
      if (error) throw error;
      return reply(data);
    }
    if (body.accion === 'cotizar_cobro') {
      const { data: s, error } = await admin.from('solicitudes_servicio')
        .select('usuario_id,estado_pago,aplica_wompi').eq('id', body.id).single();
      if (error) throw error;
      // Todo cobro Wompi lleva el 5 %, incluso sin fuente guardada (Bancolombia).
      // Una solicitud liquidada conserva su importe histórico, sin nueva deuda.
      const aplicaWompi = s.estado_pago === 'pagado' ? s.aplica_wompi === true : true;
      if (body.fuente != null) {
        const { data: card } = await admin.from('tarjetas_guardadas').select('id').eq('usuario_id', s.usuario_id)
          .eq('payment_source_id', String(body.fuente)).eq('activa', true).maybeSingle();
        if (!card) {
          const { data: other } = await admin.from('metodos_pago').select('tipo').eq('usuario_id', s.usuario_id)
            .eq('payment_source_id', body.fuente).maybeSingle();
          if (!other) return reply({ message: 'Método de pago ajeno o inexistente' }, 403);
        }
      }
      return reply(await rpc('solicitud_cobro_cotizar_v1', {
        p_actor: actor, p_id: body.id, p_recibo: body.recibo ?? null, p_tarjeta: aplicaWompi,
      }));
    }
    if (body.accion === 'pago_qr') {
      if (!isAdmin) return reply({ message: 'Sin permiso' }, 403);
      return reply(await rpc('solicitud_pago_qr_v1', { p_actor: actor, p_id: body.id }));
    }
    if (body.accion === 'preview') {
      if (!isAdmin) return reply({ message: 'Sin permiso' }, 403);
      return reply(await rpc('solicitud_finanzas_previsualizar_v1', { p_entradas: body.entradas, p_items: body.items ?? [] }));
    }
    if (body.accion === 'desglose_app') {
      // El RPC comprueba propiedad/asignación ANTES de leer pagos con privilegios.
      const financial = await rpc('solicitud_finanzas_leer', { p_actor: actor, p_id: body.id });
      if (financial.version !== 1) return reply({ version: financial.version });
      const { data: payments, error: paymentError } = await admin.from('transacciones')
        .select('monto,recibo_id').eq('solicitud_id', body.id);
      if (paymentError) throw paymentError;
      const ids = [...new Set((payments ?? []).map((p) => p.recibo_id).filter(Boolean))];
      let receipts: Array<{ id: string; titulo: string }> = [];
      if (ids.length) {
        const { data, error } = await admin.from('recibos').select('id,titulo').in('id', ids);
        if (error) throw error;
        receipts = data ?? [];
      }
      if (profile.rol === 'proveedor') {
        const { data: s, error } = await admin.from('solicitudes_servicio')
          .select('adelanto_motivo').eq('id', body.id).single();
        if (error) throw error;
        return reply({ version: 1, pago_proveedor: financial.pago_proveedor,
          adelanto_proveedor: financial.adelanto_proveedor, saldo_transferir: financial.saldo_transferir,
          adelanto_motivo: s.adelanto_motivo,
          recibos_pagados: receipts.map((r) => ({ titulo: r.titulo })) });
      }
      const pagado = (payments ?? []).reduce((sum, p) => sum + Number(p.monto), 0);
      // Solo presentación: los importes del servicio se leen persistidos, nunca se recotizan.
      return reply({ version: 1, precio: financial.precio, materiales_total: financial.materiales_total,
        ajuste_iva_valor: financial.ajuste_iva_valor, wompi_valor: financial.wompi_valor,
        total_cliente: financial.total_cliente, items: financial.items,
        subtotal: Number(financial.total_cliente) - Number(financial.wompi_valor),
        pagos_realizados: pagado, saldo_pendiente: Math.max(0, Number(financial.total_cliente) - pagado),
        pagos: (payments ?? []).map((p) => ({ monto: p.monto, recibo_id: p.recibo_id,
          titulo: p.recibo_id ? receipts.find((r) => r.id === p.recibo_id)?.titulo ?? 'Recibo del chat' : 'Pago del servicio' })) });
    }
    if (body.accion === 'leer') {
      return reply(await rpc('solicitud_finanzas_leer', { p_actor: actor, p_id: body.id }));
    }
    if (body.accion === 'guardar') {
      if (!isAdmin) return reply({ message: 'Sin permiso' }, 403);
      if (body.datos && ('estado' in body.datos || 'fecha_aceptacion' in body.datos)) {
        return reply({ message: 'Usa la operación de estado correspondiente' }, 409);
      }
      return reply(await rpc('solicitud_editar_sprint4', {
        p_actor: actor, p_id: body.id, p_revision: body.revision,
        p_datos: body.datos ?? {}, p_finanzas: body.entradas,
        p_items: body.items ?? [],
        p_tipo: body.tipo_asignacion ?? null,
        p_profesional: body.profesional_id ?? null,
        p_publicacion: body.publicacion_id ?? null,
      }));
    }
    if (body.accion !== 'rest') return reply({ message: 'Acción inválida' }, 400);
    const table = body.tabla;
    const method = body.metodo;
    if (!['solicitudes_servicio', 'vw_solicitudes_servicios_completa', 'transacciones'].includes(table) ||
        !['GET', 'HEAD', 'POST', 'PATCH', 'DELETE'].includes(method)) return reply({ message: 'Operación no permitida' }, 403);
    if (method === 'DELETE' && !isAdmin) return reply({ message: 'Sin permiso' }, 403);
    const input = body.body ?? {};
    if (method === 'POST' && table === 'solicitudes_servicio') {
      if (Array.isArray(input)) return reply({ message: 'Crear una solicitud a la vez' }, 400);
      const datos = pick(input, operational);
      if (!isAdmin) {
        datos.usuario_id = actor;
        delete datos.descripcion;
        delete datos.informacion_adicional;
      }
      const entradas = input._finanzas ?? {
        ...pick(input, financial),
        adelanto_proveedor: 0, aplica_wompi: false, aplica_ajuste_iva: false, requiere_fe: false,
      };
      const created = await rpc('solicitud_crear_sprint4', {
        p_actor: actor, p_datos: datos, p_finanzas: entradas, p_items: input._items ?? [],
        p_tipo: isAdmin ? input.tipo_asignacion ?? null : null,
      });
      const { data: row, error } = await admin.from(table).select('*').eq('id', created.solicitud_id).single();
      if (error) throw error;
      if (!isAdmin) delete row.informacion_adicional;
      const single = String(body.headers?.accept ?? body.headers?.Accept ?? '').includes('object+json');
      return reply(single ? row : [row], 201);
    }
    const params = new URLSearchParams(body.query ?? '');
    if (!isAdmin && [...params].some(([k, v]) => k !== 'select' &&
      /\b(informacion_adicional|notas_cliente|comision_neta_hulp|comision_base|iva_valor)\b/.test(k + ' ' + v))) {
      return reply({ message: 'Filtro privado no permitido' }, 403);
    }
    // Never accept SQL expressions/embedded joins as an elevated select.
    const select = params.get('select') ?? '*';
    if (!/^[a-zA-Z0-9_,.*]+$/.test(select) || select.includes('.')) {
      return reply({ message: 'Selección no permitida' }, 400);
    }
    const idKey = table === 'vw_solicitudes_servicios_completa' ? 'solicitud_id' : 'id';
    if (method === 'POST' && table === 'transacciones') {
      const { data: s, error } = await admin.from('solicitudes_servicio').select('id,usuario_id,profesional_id,finanzas_version').eq('id', input.solicitud_id).single();
      if (error) throw error;
      if (!isAdmin && s.usuario_id !== actor && s.profesional_id !== actor) return reply({ message: 'Sin permiso' }, 403);
      if (s.finanzas_version === 1) {
        // A client callback is never proof of approval. Wompi records v1 on the server.
        const { data: confirmed } = await admin.from('transacciones').select('*')
          .eq('solicitud_id', s.id).eq('numero_transaccion', input.numero_transaccion ?? '').maybeSingle();
        if (!confirmed) return reply({ message: 'El pago aún no está confirmado por el servidor' }, 409);
        const single = String(body.headers?.accept ?? body.headers?.Accept ?? '').includes('object+json');
        return reply(single ? confirmed : [confirmed], 201);
      }
    }
    if (method === 'PATCH') {
      if (table !== 'solicitudes_servicio') return reply({ message: 'Operación no permitida' }, 403);
      if (!input || typeof input !== 'object' || Array.isArray(input)) {
        return reply({ message: 'Datos de actualización inválidos' }, 400);
      }
      if ('fecha_aceptacion' in input || ('estado' in input && !estadosExcepcion.includes(input.estado))) {
        return reply({ message: 'Usa la operación de estado correspondiente' }, 409);
      }
      const allowed = ['estado', 'fecha_cancelacion', 'fecha_pago', 'estado_pago'];
      if (Object.keys(input).some(k => ['tipo_asignacion', 'publicacion_id', 'revision_asignacion',
        'perfil_enviado_en', 'proveedor_cancelacion', 'cancelacion_proveedor_en', 'perfil_pendiente',
        'asignacion_chat_id'].includes(k))) return reply({ message: 'Usa la operación de asignación.' }, 409);
      if (profile.rol === 'proveedor' && ['cancelada', 'canceladas'].includes(input.estado)) {
        return reply({ message: 'Actualiza Talento para cancelar esta asignación.' }, 409);
      }
      if (!isAdmin && Object.keys(input).some((k) => !allowed.includes(k))) return reply({ message: 'Campos no permitidos' }, 403);
      if (!isAdmin) {
        const rule = profile.rol === 'proveedor'
          ? `profesional_id.eq.${actor}`
          : `usuario_id.eq.${actor},tipo_asignacion.neq.sin_asignar`;
        const prior = params.get('and');
        params.set('and', `(${rule}${prior ? ',' + prior.slice(1, -1) : ''})`);
      }
      if (!params.has('id')) return reply({ message: 'Identificador requerido' }, 400);
      const { data: target } = await admin.from('solicitudes_servicio').select('finanzas_version,estado_pago').eq('id', (params.get('id') ?? '').replace(/^eq\./, '')).single();
      if (target?.finanzas_version === 1) {
        if (input.estado_pago && input.estado_pago !== target.estado_pago) return reply({ message: 'Confirmar el pago desde el backend' }, 409);
        const immutable = financial.filter((k) => k in input);
        if (immutable.length || '_finanzas' in input) return reply({ message: 'Guardar mediante el desglose financiero' }, 409);
      }
    }
    const extra = new Set<string>();
    let readTable = table;
    let providerForRead: string | undefined;
    if (method === 'GET' || method === 'HEAD') {
      if (table === 'transacciones') return reply({ message: 'Operación no permitida' }, 403);
      if (!isAdmin) {
        if (profile.rol === 'proveedor') {
          providerForRead = actor;
          readTable = table === 'solicitudes_servicio'
            ? 'solicitudes_talento_v1'
            : 'solicitudes_talento_completa_v1';
        } else {
          const prior = params.get('and');
          params.set('and', `(usuario_id.eq.${actor},tipo_asignacion.neq.sin_asignar${prior ? ',' + prior.slice(1, -1) : ''})`);
        }
        if (select !== '*') {
          for (const k of ['finanzas_version', 'pago_proveedor', 'saldo_transferir', 'total_cliente']) {
            if (!select.split(',').includes(k)) extra.add(k);
          }
          params.set('select', [select, ...extra].join(','));
        }
      }
    }
    const response = await fetch(`${url}/rest/v1/${readTable}?${params}`, {
      method,
      headers: {
        apikey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
        Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!}`,
        'Content-Type': 'application/json',
        Prefer: queryPrefer(body.headers),
        Accept: String(queryHeader(body.headers, 'accept') ?? 'application/json'),
        ...(providerForRead ? { 'x-hulp-proveedor': providerForRead } : {}),
        ...(queryHeader(body.headers, 'range') ? { Range: String(queryHeader(body.headers, 'range')) } : {}),
      },
      body: method === 'GET' || method === 'HEAD' ? undefined : JSON.stringify(input),
    });
    const text = await response.text();
    let rows = text ? JSON.parse(text) : null;
    if (response.ok && rows && !isAdmin) {
      const clean = (row: Record<string, unknown>) => {
        delete row.informacion_adicional;
        if (profile.rol === 'proveedor') {
          delete row.notas_cliente;
          if (row.finanzas_version === 1) {
            for (const k of ['precio', 'precio_base', 'precio_solicitud', 'precio_total', 'precio_calculado',
              'total_cliente', 'materiales_total', 'wompi_valor', 'aplica_wompi', 'aplica_ajuste_iva',
              'ajuste_iva_valor', 'motivo_precio_pagado', 'comision_base', 'comision_hulp_iva', 'comision_neta_hulp',
              'iva_valor', 'comision_efectiva', 'adelanto_motivo']) delete row[k];
          }
        }
        for (const k of extra) delete row[k];
        return row;
      };
      rows = Array.isArray(rows) ? rows.map(clean) : clean(rows);
    }
    const headers: Record<string, string> = {};
    for (const k of ['content-range', 'preference-applied']) {
      const v = response.headers.get(k); if (v) headers[k] = v;
    }
    // Preserve the array response expected by PostgREST's single/maybeSingle client.
    return reply(rows, response.status === 204 ? 200 : response.status, headers);
  } catch (e) {
    const err = e as { message?: string; code?: string };
    const status = err.code === '40001' || err.code === 'PT409' ? 409
      : err.code === '42501' ? 403 : err.code === 'PT404' ? 404 : 400;
    return reply({ message: err.message ?? 'No se pudo procesar la solicitud', code: err.code }, status);
  }
}

Deno.serve(manejarSolicitud);
