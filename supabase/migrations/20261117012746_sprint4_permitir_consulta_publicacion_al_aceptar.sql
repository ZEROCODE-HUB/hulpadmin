-- El RPC de aceptación se ejecuta como service_role. Solo necesita
-- comprobar que la solicitud tuvo una publicación abierta.
grant select (solicitud_id) on hulp_ofertas.publicaciones to service_role;
