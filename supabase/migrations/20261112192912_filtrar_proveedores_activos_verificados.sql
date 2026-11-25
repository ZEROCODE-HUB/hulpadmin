CREATE OR REPLACE VIEW public.vw_categorias_proveedores AS
SELECT
  c.id AS categoria_id,
  c.nombre AS categoria_nombre,
  count(DISTINCT CASE
    WHEN u.verificado = 'verificado'
     AND au.last_sign_in_at >= (CURRENT_TIMESTAMP - '30 days'::interval)
    THEN u.id
    ELSE NULL::uuid
  END) AS proveedores_activos,
  count(DISTINCT u.id) AS proveedores_totales
FROM categorias AS c
LEFT JOIN subcategorias AS sc ON c.id = sc.categoria_id
LEFT JOIN servicios AS s ON sc.id = s.subcategoria_id
LEFT JOIN profesional_servicios AS ps ON s.id = ps.servicio_id
LEFT JOIN usuarios AS u
  ON ps.usuario_id = u.id
 AND u.rol = 'proveedor'
LEFT JOIN auth.users AS au ON u.id = au.id
WHERE c.estado = 'activo'
GROUP BY c.id, c.nombre
ORDER BY c.nombre;
