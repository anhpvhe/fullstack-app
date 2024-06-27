# Use a base image with Java and Maven
FROM maven:3.8.5-openjdk-17-slim AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven Wrapper files (if present)
COPY .mvn/ .mvn/

# Copy the project configuration file (pom.xml for Maven projects)
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline

# Copy the source code
COPY src/ src/

# Run Maven clean and package commands to build the Spring Boot application into a JAR file
RUN mvn clean package -DskipTests

# Use a lighter weight base image for the final image
FROM eclipse-temurin:17-jdk-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the JAR file from the builder stage to the final image
COPY --from=builder /app/target/*.jar /app/backend.jar

# Define the entry point for running the Spring Boot application
ENTRYPOINT ["java", "-jar", "backend.jar"]