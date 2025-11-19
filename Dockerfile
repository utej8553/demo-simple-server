
FROM eclipse-temurin:17-jre-jammy AS runtime

ARG JAR_FILE=target/*.jar
RUN useradd -m appuser
WORKDIR /app

COPY ${JAR_FILE} app.jar

EXPOSE 8080

USER appuser

ENTRYPOINT ["java","-jar","/app/app.jar"]
