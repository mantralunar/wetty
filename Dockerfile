# Use a small, modern Node base image
FROM node:20-alpine

# Install build dependencies (needed for some npm modules)
RUN apk add --no-cache make python3 build-base

# Install wetty globally
RUN npm install -g wetty

# Create a non-root user for safety
RUN adduser -D wetty
USER wetty
WORKDIR /home/wetty

# Default environment
ENV PORT=3000
EXPOSE 3000

# Default command
# You can pass options via environment or docker run arguments
CMD ["wetty", "--base", "/", "--port", "3000"]
