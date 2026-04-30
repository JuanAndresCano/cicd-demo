FROM eclipse-temurin:21-jre-alpine
VOLUME /tmp
COPY target/cicd-demo-*.jar app.jar
ENTRYPOINT ["java", "--add-opens=java.base/java.lang=ALL-UNNAMED", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app.jar"]