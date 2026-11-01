// Setup type definitions for built-in Supabase Runtime APIs
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { withSupabase } from 'jsr:@supabase/server@^1'

interface ReqPayload {
  usuarioId: string
  telefono: string
  correoElectronico: string
  direccion: string
  ciudad: string
}

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const errorResponse = (error: string, status: number) =>
  Response.json({ error }, { status })

export default {
  // El JWT de una sesión autenticada es obligatorio. `ctx.supabaseAdmin` es
  // provisto por el wrapper y nunca se expone al navegador.
  fetch: withSupabase({ auth: 'user' }, async (req, ctx) => {
    if (req.method !== 'POST') {
      return errorResponse('Método no permitido', 405)
    }

    let payload: ReqPayload
    try {
      payload = await req.json()
    } catch (_) {
      return errorResponse('El cuerpo debe ser JSON válido', 400)
    }

    const usuarioId = payload.usuarioId?.trim()
    const telefono = payload.telefono?.trim() ?? ''
    const correoElectronico = payload.correoElectronico?.trim().toLowerCase()
    const direccion = payload.direccion?.trim() ?? ''
    const ciudad = payload.ciudad?.trim()

    if (!usuarioId || !correoElectronico || !emailPattern.test(correoElectronico)) {
      return errorResponse('Los datos del cliente no son válidos', 400)
    }

    if (!ciudad) {
      return errorResponse('Debes seleccionar una ciudad', 400)
    }

    // El rol se consulta del servidor: nunca se acepta desde el cliente.
    const { data: operador, error: operadorError } = await ctx.supabaseAdmin
      .from('usuarios')
      .select('rol')
      .eq('id', ctx.userClaims!.id)
      .maybeSingle()

    if (operadorError) {
      console.error('No se pudo validar al operador', operadorError)
      return errorResponse('No se pudo validar la sesión', 500)
    }
    if (operador?.rol !== 'administrador') {
      return errorResponse('No tienes permiso para editar clientes', 403)
    }

    const { data: cliente, error: clienteError } = await ctx.supabaseAdmin
      .from('usuarios')
      .select('id, correo_electronico, telefono, direccion, ciudad')
      .eq('id', usuarioId)
      .maybeSingle()

    if (clienteError) {
      console.error('No se pudo consultar al cliente', clienteError)
      return errorResponse('No se pudo consultar el cliente', 500)
    }
    if (!cliente) {
      return errorResponse('Cliente no encontrado', 404)
    }

    const { data: ciudadActiva, error: ciudadError } = await ctx.supabaseAdmin
      .from('ciudades')
      .select('id')
      .eq('nombre', ciudad)
      .eq('activo', true)
      .maybeSingle()

    if (ciudadError) {
      console.error('No se pudo validar la ciudad', ciudadError)
      return errorResponse('No se pudo validar la ciudad', 500)
    }
    if (!ciudadActiva) {
      return errorResponse('La ciudad seleccionada no está activa', 400)
    }

    const correoCambio = cliente.correo_electronico !== correoElectronico
    const telefonoCambio = (cliente.telefono ?? '') !== telefono
    const direccionCambio = (cliente.direccion ?? '') !== direccion
    const ciudadCambio = (cliente.ciudad ?? '') !== ciudad

    if (!correoCambio && !telefonoCambio && !direccionCambio && !ciudadCambio) {
      return Response.json({ ok: true, changed: false })
    }

    // Todo cliente tiene una fila vinculada en Auth. También se sincroniza el
    // correo de los externos para conservar una sola fuente de verdad.
    if (correoCambio) {
      const { error: authError } = await ctx.supabaseAdmin.auth.admin
        .updateUserById(usuarioId, {
          email: correoElectronico,
          email_confirm: true,
        })

      if (authError) {
        // Supabase rechaza también un correo ya asignado a otra cuenta.
        console.warn('No se pudo actualizar el correo de Auth', authError)
        return errorResponse(
          'No se pudo actualizar el correo de acceso. Verifica que no esté en uso.',
          409,
        )
      }
    }

    const { data: clienteActualizado, error: actualizacionError } =
      await ctx.supabaseAdmin
        .from('usuarios')
        .update({
          telefono,
          correo_electronico: correoElectronico,
          direccion,
          ciudad,
        })
        .eq('id', usuarioId)
        .select('id, telefono, correo_electronico, direccion, ciudad')
        .single()

    if (actualizacionError) {
      // Compensación: si Auth ya cambió pero la tabla pública falló, se intenta
      // volver al correo anterior. El fallo de esta compensación debe alertarse.
      if (correoCambio && cliente.correo_electronico) {
        const { error: rollbackError } = await ctx.supabaseAdmin.auth.admin
          .updateUserById(usuarioId, {
            email: cliente.correo_electronico,
            email_confirm: true,
          })
        if (rollbackError) {
          console.error('Auth y usuarios quedaron inconsistentes', rollbackError)
        }
      }
      console.error('No se pudo actualizar el perfil público', actualizacionError)
      return errorResponse('No se pudo guardar el cliente', 500)
    }

    return Response.json({ ok: true, changed: true, cliente: clienteActualizado })
  }),
}