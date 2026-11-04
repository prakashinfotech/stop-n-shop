FROM node:20-alpine AS build
WORKDIR /app

# API base URL baked into the JS bundle at build time (Vite reads VITE_* during `npm run build`).
#   /api  (default) -> same-origin; the bundled nginx.conf proxies /api to the `api` container.
#   https://<api-host>/api -> split-host deploy (browser calls the API host directly; set AllowedOrigins on the API).
# Shell env vars on the host do NOT reach this stage — pass it as a build arg
# (docker compose does this from VITE_API_URL; see docker-compose*.yml).
ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL

COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
