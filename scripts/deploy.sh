#!/bin/bash
# Despliegue con health check y rollback automatico.
# Variables requeridas: IMAGE, CONTAINER, PUBLIC_PORT, CHECK_PORT, APP_ENV
set -u
NEW="${CONTAINER}-new"
STATE="$HOME/.${CONTAINER}.previous"

echo ">> [$APP_ENV] Desplegando $IMAGE en puerto $PUBLIC_PORT"
docker pull "$IMAGE" || exit 1

# 1. Levantar la nueva version en un puerto de validacion
docker rm -f "$NEW" >/dev/null 2>&1 || true
docker run -d --name "$NEW" -e APP_ENV="$APP_ENV" -p "$CHECK_PORT:3000" "$IMAGE" >/dev/null

# 2. Health check con reintentos (max ~30s)
ok=0
for i in $(seq 1 10); do
  sleep 3
  if curl -sf "http://localhost:$CHECK_PORT/health"; then ok=1; echo; break; fi
  echo "   intento $i/10: aun no responde..."
done
docker rm -f "$NEW" >/dev/null 2>&1 || true

if [ "$ok" -ne 1 ]; then
  echo "!! Health check FALLIDO. Se cancela el despliegue; la version anterior sigue activa."
  exit 1
fi
echo ">> Health check exitoso. Activando nueva version..."

# 3. Guardar la imagen actual (para rollback) y reemplazar el contenedor
PREV=$(docker inspect --format '{{.Config.Image}}' "$CONTAINER" 2>/dev/null || true)
[ -n "$PREV" ] && echo "$PREV" > "$STATE" && echo ">> Version anterior registrada: $PREV"
docker stop "$CONTAINER" >/dev/null 2>&1 || true
docker rm "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --name "$CONTAINER" --restart unless-stopped \
  -e APP_ENV="$APP_ENV" -p "$PUBLIC_PORT:3000" "$IMAGE" >/dev/null

# 4. Verificacion final en el puerto publico; si falla, rollback automatico
sleep 4
if ! curl -sf "http://localhost:$PUBLIC_PORT/health"; then
  echo "!! La version nueva no responde en :$PUBLIC_PORT. Rollback automatico a $PREV"
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  [ -n "$PREV" ] && docker run -d --name "$CONTAINER" --restart unless-stopped \
    -e APP_ENV="$APP_ENV" -p "$PUBLIC_PORT:3000" "$PREV" >/dev/null
  exit 1
fi
echo
echo ">> Despliegue completado en $APP_ENV"
docker ps --filter "name=^${CONTAINER}$" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
docker image prune -f >/dev/null
