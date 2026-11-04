import { crearHandler } from './handler.ts';
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.57.4';

function assert(value: unknown, message = 'Condición incumplida'): asserts value {
  if (!value) throw new Error(message);
}
const requestId = '11111111-1111-4111-8111-111111111111';
const payload = () => ({ request_id: requestId, nombre: 'Paola Andrea', apellido: 'Ochoa', telefono: '3001234567',
  direccion: { tipo: 'casa', direccion: 'Calle 1 #2', ciudad_id: 'ciudad' } });
function fixture(options: { rol?: string; sinSesion?: boolean; existente?: boolean;
  identidad?: unknown; fallaFinalizar?: boolean; carrera?: boolean } = {}) {
  let creaciones = 0;
  const llamadas: {name: string; args: Record<string, unknown>}[] = [];
  let authPayload: Record<string, unknown> | undefined;
  const resultado = { cliente: { id: 'cliente', nombres: 'Paola' }, direccion: {id: 'dir'}, existente: false };
  const client = {
    auth: { getUser: () => Promise.resolve({ data: { user: options.sinSesion ? null : {id: 'operador'} }, error: null }),
      admin: { createUser: (p: Record<string, unknown>) => {
        creaciones++; authPayload = p;
        return Promise.resolve(options.carrera ? {data: {}, error: {code: 'phone_exists'}} : {data: {user: {id: 'cliente'}}, error: null});
      } } },
    from: (table: string) => {
      const q = {select: () => q, eq: () => q, maybeSingle: () => Promise.resolve({data:
        table === 'usuarios' ? {rol: options.rol ?? 'administrador'} : {id: 'ciudad'}, error: null})};
      return q;
    },
    rpc: (name: string, args: Record<string, unknown>) => {
      llamadas.push({name, args});
      if (name === 'quick_add_buscar') return Promise.resolve({data: options.existente ? {...resultado, existente: true} : null, error: null});
      if (name === 'quick_add_identidad') return Promise.resolve({data: options.carrera && creaciones > 0
        ? {id: 'cliente', request_id: requestId, recuperable: true} : options.identidad ?? null, error: null});
      return Promise.resolve({data: resultado, error: options.fallaFinalizar ? {code: 'error'} : null});
    },
  };
  return { handler: crearHandler(client as unknown as SupabaseClient), llamadas,
    get creaciones() {return creaciones;}, get authPayload() {return authPayload;} };
}
const req = (body: unknown = payload(), token = 'Bearer sesión') => new Request('https://test.invalid', {
  method: 'POST', headers: {Authorization: token, 'Content-Type': 'application/json'}, body: JSON.stringify(body),
});

Deno.test('sin sesión y sin rol admin no crean identidades', async () => {
  const anon = fixture({sinSesion: true});
  assert((await anon.handler(req())).status === 401);
  const cliente = fixture({rol: 'usuario'});
  assert((await cliente.handler(req())).status === 403);
  assert(anon.creaciones + cliente.creaciones === 0);
});
Deno.test('mínimos, tipo, teléfono y coordenadas se validan antes de Auth', async () => {
  const f = fixture();
  for (const body of [ {...payload(), nombre: ''}, {...payload(), apellido: ''}, {...payload(), apellido: null}, {...payload(), telefono: '123'},
    {...payload(), direccion: {...payload().direccion, direccion: ''}},
    {...payload(), direccion: {...payload().direccion, latitud: 4}},
    {...payload(), direccion: {...payload().direccion, tipo: 'otra', nombre: 4}},
    {...payload(), request_id: 'incorrecto'} ]) {
    assert((await f.handler(req(body))).status === 400);
  }
  assert(f.creaciones === 0);
});
Deno.test('crea identidad solo con celular sin confirmar y no inicia sesión del cliente', async () => {
  const f = fixture();
  const r = await f.handler(req());
  assert(r.status === 200);
  assert(f.authPayload?.phone === '+573001234567');
  assert(f.authPayload?.phone_confirm === false);
  assert(!('email' in f.authPayload!));
  const final = f.llamadas.find(l => l.name === 'quick_add_finalizar')!;
  assert(final.args.p_telefono === '573001234567');
  assert(final.args.p_operador === 'operador');
  assert(final.args.p_nombre === 'Paola Andrea');
  assert(final.args.p_apellido === 'Ochoa');
});
Deno.test('duplicado devuelve perfil existente sin crear ni modificar', async () => {
  const f = fixture({existente: true});
  const r = await f.handler(req());
  assert((await r.json()).existente === true);
  assert(f.creaciones === 0);
  assert(f.llamadas.length === 1);
});
Deno.test('rechaza identidad previa que no es un alta pendiente recuperable', async () => {
  const f = fixture({identidad: {id: 'ajena', recuperable: false}});
  assert((await f.handler(req())).status === 409);
  assert(f.creaciones === 0);
  assert(!f.llamadas.some(l => l.name === 'quick_add_finalizar'));
});
Deno.test('recupera alta pendiente incluso después de reabrir el modal', async () => {
  const f = fixture({identidad: {id: 'pendiente', request_id: requestId, recuperable: true}});
  const r = await f.handler(req({...payload(), request_id: '22222222-2222-4222-8222-222222222222'}));
  assert(r.status === 200);
  assert(f.creaciones === 0);
  assert(f.llamadas.find(l => l.name === 'quick_add_finalizar')?.args.p_request === requestId);
});
Deno.test('carrera creando la identidad recupera la misma y finaliza una vez', async () => {
  const f = fixture({carrera: true});
  assert((await f.handler(req())).status === 200);
  assert(f.creaciones === 1);
  assert(f.llamadas.filter(l => l.name === 'quick_add_finalizar').length === 1);
});
Deno.test('fallo de persistencia no reporta éxito ni borra una identidad posiblemente confirmada', async () => {
  const f = fixture({fallaFinalizar: true});
  const r = await f.handler(req());
  assert(r.status === 500);
  assert((await r.json()).error.includes('vuelve a guardar'));
});
Deno.test('preflight CORS no requiere sesión', async () => {
  const f = fixture();
  const r = await f.handler(new Request('https://test.invalid', {method: 'OPTIONS'}));
  assert(r.status === 200 && r.headers.has('Access-Control-Allow-Origin'));
});
