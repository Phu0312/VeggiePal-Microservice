FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src src
RUN mvn -B clean package -DskipTests

FROM eclipse-temurin:21-jre

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system veggiepal \
    && useradd --system --gid veggiepal --home-dir /app --shell /usr/sbin/nologin veggiepal \
    && mkdir -p /app \
    && chown -R veggiepal:veggiepal /app

WORKDIR /app
COPY --from=build --chown=veggiepal:veggiepal /app/target/*.jar app.jar
USER veggiepal
EXPOSE 8086
ENTRYPOINT ["java", "-jar", "app.jar"]
