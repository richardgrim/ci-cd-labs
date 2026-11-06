# Pruebas de API después del despliegue

La colección `docker-local.json` comprueba GET /, /health y /date contra
http://127.0.0.1:8080. Cada petición valida HTTP 200 y el contenido esperado
(la fecha valida el formato YYYY-MM-DD): seis aserciones en total.

Ejecución local con Node.js 22:

```powershell
npx.cmd --yes newman@6.2.1 run tests/postman/docker-local.json --timeout-request 10000
```

El pipeline azure-deploy-local.yml ejecuta Newman tras el despliegue y publica
JUnit en la pestaña Tests, incluso cuando hay pruebas fallidas. Los informes
usan un directorio por ejecución e intento para evitar resultados antiguos.
Si Newman falla, el pipeline falla. Esta comprobación posterior no activa por
sí sola el rollback: el rollback del script de despliegue sigue dependiendo de
la comprobación /health. Se conservan la aprobación manual y el control de main.
