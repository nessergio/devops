# Use official nginx alpine image for smaller size
FROM nginx:alpine

# Standardized OCI labels for author information
LABEL org.opencontainers.image.authors="Serhii Nesterenko <ser@nesterenko.net>"

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy our custom HTML page to nginx html directory
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
