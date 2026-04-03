# Stage 1: Build the Flutter web application
FROM ubuntu:24.04 AS build-env

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/usr/local/flutter
ENV FLUTTER_SUPPRESS_ANALYTICS=true
ENV PUB_ENVIRONMENT=docker
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    libglu1-mesa \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_HOME}"

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter config --enable-web \
    && flutter precache --web \
    && flutter pub get

COPY . .
RUN flutter build web --release

# Stage 2: Serve the built files with nginx
FROM nginx:1.27-alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
