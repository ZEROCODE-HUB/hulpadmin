import { assert, assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';

const serve = Deno.serve;
Deno.serve = (() => ({})) as unknown as typeof Deno.serve;
const { manejarSolicitud } = await import('./index.ts');
Deno.serve = serve;
Deno.env.set('SUPABASE_URL', 'https://ptafsiwlhxomgqmdmidf.supabase.co');
Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'credencial-ficticia-de-prueba');
const actor = '11111111-1111-4111-8111-111111111111';
const response = (v: unknown, status = 200) => new Response(JSON.stringify(v), { status, headers: { 'Content-Type': 'application/json' } });

Deno.test('historial combinado consulta ambas fuentes para un administrador', async () => {
  const original = globalThis.fetch;
  const solicitud = '22222222-2222-4222-8222-222222222222';
  const proveedora = '33333333-3333-4333-8333-333333333333';
  const consultar = (id: string) => manejarSolicitud(new Request('http://local', { method: 'POST',
    headers: { Authorization: 'Bearer sesion' },
    body: JSON.stringify({ accion: 'historial_admin', id }),
  }));
  let rol = 'proveedor';
  const consultas = new Set<string>();
  globalThis.fetch = (input, init) => {
    const url = new URL(String(input));
    const recurso = url.pathname.split('/').at(-1)!;
    consultas.add(recurso);
    if (recurso === 'user') return Promise.resolve(response({ id: actor }));
    if (recurso === 'usuarios' && url.searchParams.get('select') === 'rol') {
      return Promise.resolve(response({ rol }));
    }
    if (recurso === 'solicitudes_servicio') {
      assertEquals(url.searchParams.get('id'), `eq.${solicitud}`);
      return Promise.resolve(response([{ creado_en: '2026-11-08T20:05:00', tipo: 'externo' }]));
    }
    if (recurso === 'solicitud_estado_historial_v1') {
      assertEquals(JSON.parse(String(init?.body)), { p_actor: actor, p_id: solicitud });
      return Promise.resolve(response([{ id: 'evento', accion: 'aceptar', actor_id: proveedora,
        ocurrido_en: '2026-11-08T20:40:00+00:00' }]));
    }
    if (recurso === 'solicitud_finanzas_historial') {
      assertEquals(url.searchParams.get('solicitud_id'), `eq.${solicitud}`);
      return Promise.resolve(response([{ revision: 1, entradas: { datos: {}, items: [] },
        resultados: {}, autor_id: actor, motivo: 'Creación', creado_en: '2026-11-08T20:05:00+00:00' }]));
    }
    assertEquals(recurso, 'usuarios');
    return Promise.resolve(response([
      { id: proveedora, nombres: 'Laura', apellidos: 'Méndez', rol: 'proveedor' },
      { id: actor, nombres: 'Equipo', apellidos: 'Hulp', rol: 'administrador' },
    ]));
  };
  try {
    assertEquals((await consultar(solicitud)).status, 403);
    assertEquals([...consultas], ['user', 'usuarios']);
    rol = 'administrador';
    assertEquals((await consultar('inválido')).status, 400);
    assertEquals([...consultas], ['user', 'usuarios']);
    const result = await consultar(solicitud);
    assertEquals(result.status, 200);
    const { creacion, eventos, revisiones } = await result.json();
    assertEquals(creacion, { fecha: '2026-11-08T20:05:00Z', tipo: 'externo' });
    assertEquals(eventos[0].autor, { nombre: 'Laura Méndez', rol: 'proveedor' });
    assertEquals(eventos[0].actor_id, undefined);
    assertEquals(revisiones[0].autor, { nombre: 'Equipo Hulp', rol: 'administrador' });
    assertEquals(revisiones[0].autor_id, undefined);
  } finally {
    globalThis.fetch = original;
  }
});

Deno.test('preflight permite las cabeceras de Flutter/PostgREST sin consultar datos', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = () => { throw new Error('OPTIONS no debe consultar el backend'); };
  try {
    const r = await manejarSolicitud(new Request('http://local', { method: 'OPTIONS',
      headers: { Origin: 'http://localhost:52802',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'accept-profile,content-profile,authorization,apikey,content-type,x-client-info,prefer,range,range-unit' },
    }));
    assertEquals(r.status, 200);
    assertEquals(r.headers.get('Access-Control-Allow-Origin'), '*');
    assert(r.headers.get('Access-Control-Allow-Methods')?.includes('POST'));
    const allowed = r.headers.get('Access-Control-Allow-Headers')!.split(',').map((h) => h.trim());
    for (const header of ['accept-profile', 'content-profile', 'authorization', 'apikey', 'content-type', 'x-client-info', 'prefer', 'range', 'range-unit']) {
      assert(allowed.includes(header), header);
    }
  } finally { globalThis.fetch = original; }
});

for (const [table, query] of [
  ['solicitudes_servicio', 'select=%2A'],
  ['vw_solicitudes_servicios_completa', 'select=%2A&cliente_nombre_completo=ilike.%25%25&order=fecha.desc.nullslast'],
]) {
  Deno.test(`Admin lee ${table} con cabeceras normales y Prefer heredado`, async () => {
    const original = globalThis.fetch;
    globalThis.fetch = (input, init) => {
      const url = String(input);
      if (url.includes('/auth/v1/user')) return Promise.resolve(response({ id: actor }));
      if (url.includes('/rest/v1/usuarios')) return Promise.resolve(response({ rol: 'administrador' }));
      assertEquals(new URL(url).pathname, `/rest/v1/${table}`);
      assertEquals(new URL(url).searchParams.get('select'), '*');
      assertEquals(new Headers(init?.headers).get('Prefer'), 'return=representation');
      assertEquals(new Headers(init?.headers).get('Range'), '0-9');
      if (table.startsWith('vw_')) {
        assertEquals(new URL(url).searchParams.get('cliente_nombre_completo'), 'ilike.%%');
        assertEquals(new URL(url).searchParams.get('order'), 'fecha.desc.nullslast');
      }
      return Promise.resolve(new Response('[{"id":"solicitud"}]', { headers: { 'Content-Range': '0-0/1' } }));
    };
    try {
      const r = await manejarSolicitud(new Request('http://local', { method: 'POST',
        headers: { Authorization: 'Bearer sesion', Origin: 'http://localhost:52802' },
        body: JSON.stringify({ accion: 'rest', tabla: table, metodo: 'GET', query,
          headers: { Prefer: 'nullreturn=representation', Range: '0-9', 'Accept-Profile': 'public' } }),
      }));
      assertEquals(r.status, 200);
      assertEquals(r.headers.get('Access-Control-Allow-Origin'), '*');
      assertEquals(r.headers.get('Content-Range'), '0-0/1');
      assertEquals(await r.json(), [{ id: 'solicitud' }]);
    } finally { globalThis.fetch = original; }
  });
}

Deno.test('proveedora recibe ingreso guardado, sin precio acordado ni notas', async () => {
  const original = globalThis.fetch;
  let consulta = '';
  globalThis.fetch = (input) => {
    const url = String(input);
    if (url.includes('/auth/v1/user')) return Promise.resolve(response({ id: actor }));
    if (url.includes('/rest/v1/usuarios')) return Promise.resolve(response({ rol: 'proveedor' }));
    consulta = url;
    return Promise.resolve(response([{ id: 'solicitud', finanzas_version: 1, precio: 120000,
      pago_proveedor: 86400, informacion_adicional: 'secreto', notas_cliente: 'privado' }]));
  };
  try {
    const r = await manejarSolicitud(new Request('http://local', { method: 'POST',
      headers: { Authorization: 'Bearer sesion' },
      body: JSON.stringify({ accion: 'rest', tabla: 'solicitudes_servicio', metodo: 'GET', query: 'select=*&estado=eq.entrantes' }),
    }));
    assertEquals(r.status, 200);
    const row = (await r.json())[0];
    assertEquals(row.pago_proveedor, 86400);
    assert(!('precio' in row)); assert(!('notas_cliente' in row)); assert(!('informacion_adicional' in row));
    assert(new URL(consulta).searchParams.get('and')?.includes(`profesional_id.eq.${actor}`));
  } finally { globalThis.fetch = original; }
});

Deno.test('consulta histórica conserva precio y oculta las notas', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = (input) => Promise.resolve(response(String(input).includes('/auth/v1/user') ? { id: actor }
    : String(input).includes('/rest/v1/usuarios') ? { rol: 'proveedor' }
    : [{ id: 'historica', precio: 180000, finanzas_version: null, informacion_adicional: 'privado' }]));
  try {
    const r = await manejarSolicitud(new Request('http://local', { method: 'POST', headers: { Authorization: 'Bearer sesion' },
      body: JSON.stringify({ accion: 'rest', tabla: 'solicitudes_servicio', metodo: 'GET', query: 'select=*' }) }));
    const row = (await r.json())[0];
    assertEquals(row.precio, 180000); assert(!('informacion_adicional' in row));
  } finally { globalThis.fetch = original; }
});

Deno.test('sesión inválida y filtros sobre notas privadas se rechazan', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = () => Promise.resolve(response({ message: 'Sesión inválida' }, 401));
  try {
    const r = await manejarSolicitud(new Request('http://local', { method: 'POST', headers: { Authorization: 'Bearer invalida' }, body: '{}' }));
    assertEquals(r.status, 401);
    globalThis.fetch = (input) => Promise.resolve(response(String(input).includes('/auth/v1/user') ? { id: actor } : { rol: 'proveedor' }));
    const denied = await manejarSolicitud(new Request('http://local', { method: 'POST', headers: { Authorization: 'Bearer sesion' },
      body: JSON.stringify({ accion: 'rest', tabla: 'solicitudes_servicio', metodo: 'GET', query: 'select=*&informacion_adicional=eq.secreto' }) }));
    assertEquals(denied.status, 403);
  } finally { globalThis.fetch = original; }
});


for (const medio of ['CARD', 'NEQUI', 'DAVIPLATA', 'BANCOLOMBIA_TRANSFER', 'NEQUI_PAGADO']) {
  Deno.test(`cotización ${medio}: recargo Wompi y respeto del pago histórico`, async () => {
    const original = globalThis.fetch;
    let cotizaciones = 0;
    globalThis.fetch = (input, init) => {
      const url = String(input);
      if (url.includes('/auth/v1/user')) return Promise.resolve(response({ id: actor }));
      if (url.includes('/rest/v1/usuarios')) return Promise.resolve(response({ rol: 'administrador' }));
      if (url.includes('/rest/v1/solicitudes_servicio')) return Promise.resolve(response({
        usuario_id: actor, estado_pago: medio === 'NEQUI_PAGADO' ? 'pagado' : 'pendiente', aplica_wompi: false,
      }));
      if (url.includes('/rest/v1/tarjetas_guardadas')) return Promise.resolve(response(medio === 'CARD' ? { id: 'tarjeta' } : null));
      if (url.includes('/rest/v1/metodos_pago')) return Promise.resolve(response({ tipo: medio }));
      assertEquals(new URL(url).pathname, '/rest/v1/rpc/solicitud_cobro_cotizar_v1');
      const args = JSON.parse(String(init?.body));
      assertEquals(args.p_tarjeta, medio !== 'NEQUI_PAGADO');
      assertEquals(args.p_actor, actor);
      cotizaciones++;
      return Promise.resolve(response({ version: 1, recargo: args.p_tarjeta ? 676.6 : 0 }));
    };
    try {
      const r = await manejarSolicitud(new Request('http://local', { method: 'POST',
        headers: { Authorization: 'Bearer sesion' },
        body: JSON.stringify({ accion: 'cotizar_cobro', id: 'solicitud',
          fuente: medio === 'BANCOLOMBIA_TRANSFER' ? null : 123 }),
      }));
      assertEquals(r.status, 200);
      assertEquals(cotizaciones, 1);
    } finally { globalThis.fetch = original; }
  });
}

Deno.test('cotización rechaza fuente ajena incluso con recargo Wompi universal', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = (input) => {
    const url = String(input);
    if (url.includes('/auth/v1/user')) return Promise.resolve(response({ id: actor }));
    if (url.includes('/rest/v1/usuarios')) return Promise.resolve(response({ rol: 'administrador' }));
    if (url.includes('/rest/v1/solicitudes_servicio')) return Promise.resolve(response({ usuario_id: actor, estado_pago: 'pendiente' }));
    if (url.includes('/rest/v1/tarjetas_guardadas') || url.includes('/rest/v1/metodos_pago')) return Promise.resolve(response(null));
    throw new Error('No debe cotizar con una fuente ajena');
  };
  try {
    const r = await manejarSolicitud(new Request('http://local', { method: 'POST',
      headers: { Authorization: 'Bearer sesion' },
      body: JSON.stringify({ accion: 'cotizar_cobro', id: 'solicitud', fuente: 999 }),
    }));
    assertEquals(r.status, 403);
  } finally { globalThis.fetch = original; }
});

for (const rol of ['usuario', 'proveedor']) {
 Deno.test(`desglose_app ${rol}: pagos del chat sin duplicar ni exponer finanzas privadas`, async () => {
  const original = globalThis.fetch;
  globalThis.fetch = (input) => {
   const url = String(input);
   if (url.includes('/auth/v1/user')) return Promise.resolve(response({ id: actor }));
   if (url.includes('/rest/v1/usuarios')) return Promise.resolve(response({ rol }));
   if (url.includes('/rpc/solicitud_finanzas_leer')) return Promise.resolve(response({ version:1,
    precio:10000, materiales_total:3000, ajuste_iva_valor:532, wompi_valor:676.6,
    total_cliente:14208.6, items:[], pago_proveedor:7200, adelanto_proveedor:2000, saldo_transferir:5200 }));
   if (url.includes('/rest/v1/transacciones')) return Promise.resolve(response([{monto:3150,recibo_id:'recibo'}]));
   if (url.includes('/rest/v1/recibos')) return Promise.resolve(response([{id:'recibo',titulo:'Grifos'}]));
   if (url.includes('/rest/v1/solicitudes_servicio')) {
    assertEquals(new URL(url).searchParams.get('select'), 'adelanto_motivo');
    return Promise.resolve(response({adelanto_motivo:'Para su pasaje'}));
   }
   throw new Error(url);
  };
  try {
   const r=await manejarSolicitud(new Request('http://local',{method:'POST',headers:{Authorization:'Bearer sesion'},
    body:JSON.stringify({accion:'desglose_app',id:'solicitud'})}));
   assertEquals(r.status,200); const d=await r.json();
   if(rol==='usuario') { assertEquals(d.total_cliente,14208.6); assertEquals(d.pagos_realizados,3150);
    assertEquals(d.saldo_pendiente,11058.6); assertEquals(d.pago_proveedor,undefined); }
   else { assertEquals(d.saldo_transferir,5200); assertEquals(d.recibos_pagados,[{titulo:'Grifos'}]);
    assertEquals(d.total_cliente,undefined); assertEquals(d.pagos,undefined); assertEquals(d.wompi_valor,undefined);
    assertEquals(d.adelanto_motivo,'Para su pasaje'); assertEquals(d.adelanto_concepto,undefined); }
  } finally { globalThis.fetch=original; }
 });
}
Deno.test('desglose_app rechaza solicitud ajena antes de consultar pagos',async()=>{
 const original=globalThis.fetch;
 globalThis.fetch=(input)=>{
  const url=String(input);
  if(url.includes('/auth/v1/user'))return Promise.resolve(response({id:actor}));
  if(url.includes('/rest/v1/usuarios'))return Promise.resolve(response({rol:'usuario'}));
  if(url.includes('/rpc/solicitud_finanzas_leer'))return Promise.resolve(response({message:'Acceso no autorizado',code:'42501'},403));
  throw new Error('No debe consultar datos privados');
 };
 try {const r=await manejarSolicitud(new Request('http://local',{method:'POST',headers:{Authorization:'Bearer sesion'},body:JSON.stringify({accion:'desglose_app',id:'ajena'})}));
  assertEquals(r.status,400); assertEquals((await r.json()).code,'42501');
 }finally{globalThis.fetch=original;}
});
