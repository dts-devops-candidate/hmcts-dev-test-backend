# Build stage: compile and package with the project's pinned Gradle wrapper.
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app
COPY . .
# bootJar only: tests run in CI, not in the image build.
RUN ./gradlew --no-daemon bootJar

# Runtime stage: slim JRE, runs as a non-root user.
# curl is installed for the container healthcheck (see docker-compose.yml).
FROM eclipse-temurin:21-jre-jammy AS runtime
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1001 spring
USER spring

COPY --from=build /app/build/libs/test-backend.jar app.jar

EXPOSE 4000
ENTRYPOINT ["java", "-jar", "app.jar"]
