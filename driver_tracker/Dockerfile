# Use an official nginx image as the base image
FROM nginx:alpine

# Copy the static HTML files to the nginx default public directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
