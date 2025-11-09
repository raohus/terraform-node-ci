# Use official Node.js LTS image
FROM node:18-alpine

# Accept environment argument during build
ARG ENV
ENV NODE_ENV=$ENV

# Set working directory inside the container
WORKDIR /usr/src/app

# Copy package files first (for caching)
COPY node-app/package*.json ./

# Install dependencies
RUN npm install --production

# Copy the rest of the app source code
COPY node-app/ .

# Expose app port
EXPOSE 3000

# Start the Node.js app
CMD ["node", "index.js"]
