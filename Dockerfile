# -------- Build Stage --------
FROM maven:3.9.1-eclipse-temurin-17 AS build

# Set working directory
WORKDIR /app

# Copy pom and download dependencies first (caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy the source code
COPY src ./src

# Build the JAR
RUN mvn clean package -DskipTests

# -------- Run Stage --------
FROM eclipse-temurin:17-jdk-alpine

# Set working directory
WORKDIR /app

# Copy the JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring

# JVM options for production (optional)
ENTRYPOINT ["java","-Xms256m","-Xmx512m","-Djava.security.egd=file:/dev/./urandom","-jar","/app/app.jar"]
