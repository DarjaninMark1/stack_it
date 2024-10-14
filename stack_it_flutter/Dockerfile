# Use the official Flutter image
FROM cirrusci/flutter:latest

# Set the working directory inside the container
WORKDIR /app

# Copy pubspec.yaml and pubspec.lock to install dependencies
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of your application code
COPY . .

# Run the application (this example is for a web app; adjust if you have a different target)
CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]
