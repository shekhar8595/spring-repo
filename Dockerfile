# FROM openjdk:17-jdk-slim
# ARG JAR_FILE=target/*.jar
# COPY ${JAR_FILE} app.jar
# ENTRYPOINT ["java","-jar","/app.jar"]

# Use a lightweight OpenJDK 17 base image
FROM eclipse-temurin:17-jdk-alpine

# Set a working directory
WORKDIR /app

# Argument for JAR file
ARG JAR_FILE=target/*.jar

# Copy the JAR file from target
COPY ${JAR_FILE} app.jar

# Expose port 8080
EXPOSE 8080

# Use a non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring
USER spring

# Run the JAR
ENTRYPOINT ["java","-jar","/app/app.jar"]
