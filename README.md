# cd-productos-api

API CRUD de productos (Node.js + Express) con **pipeline de CI/CD**: pruebas, build multi-stage de Docker, escaneo de vulnerabilidades, publicación en Docker Hub y despliegue automatizado en AWS EC2 con dos entornos (`staging` y `production`).

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/` | Información de la API |
| GET | `/health` | Estado, versión, entorno y commit desplegado |
| GET | `/productos` | Lista productos |
| GET | `/productos/:id` | Obtiene un producto |
| POST | `/productos` | Crea un producto (`nombre`, `precio`, `stock`) |
| PUT | `/productos/:id` | Actualiza un producto |
| DELETE | `/productos/:id` | Elimina un producto |
| GET | `/productos-total` | Total de productos |

## Ejecutar con Docker

```bash
docker build -t cd-productos-api:local .
docker run -d -p 3000:3000 --name app-local cd-productos-api:local
curl http://localhost:3000/health
```

## Ejecutar sin Docker

```bash
npm ci
npm test
npm start
```

## Pipeline de CI/CD

`git push` → **Lint y pruebas** → **Build multi-stage + escaneo Docker Scout + push a Docker Hub** → **Deploy a staging** (EC2 :8080) → **Deploy a production** (EC2 :80, con aprobación manual).

- API en producción: http://32.199.159.225/health
- API en staging: http://32.199.159.225:8080/health
- Imagen: https://hub.docker.com/r/walterjaldin/cd-productos-api

## Documentación del Laboratorio

Puedes encontrar el informe completo con capturas de pantalla y evidencias en el siguiente enlace:

- [Ver informe del laboratorio](./INFORME.md)
