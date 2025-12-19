# Étape 1 : Builder Flutter Web
FROM ghcr.io/cirruslabs/flutter:latest AS build

WORKDIR /app

# Copier les fichiers
COPY . .

# Activer le web (déjà actif normalement)
RUN flutter config --enable-web

# Récupérer les dépendances
RUN flutter pub get

# Build Flutter Web
RUN flutter build web --release

# Étape 2 : servir via Nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
