# Use an official Node.js runtime as a parent image
# Upgraded to 20-slim (Active LTS)
FROM node:20-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package.json ./

# Install dependencies and clean up in a single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends dumb-init && \
    rm -rf /var/lib/apt/lists/* && \
    npm install --omit=dev && \
    npm cache clean --force

# Bundle app source
# Change ownership of the files to the 'node' user
COPY --chown=node:node . .

# Switch to the non-root 'node' user for security
USER node

# Your app binds to port 8080, so expose it
EXPOSE 8080

# Use dumb-init as the entrypoint
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Define the command to run your app
CMD [ "node", "server.js" ]