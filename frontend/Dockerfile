FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build apk --release

FROM scratch AS export
COPY --from=build /app/build/app/outputs/flutter-apk/app-release.apk /app-release.apk
