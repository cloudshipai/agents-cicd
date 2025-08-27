# INSECURE Dockerfile for Testing Security Scanners

# INSECURE: Using latest tag (not pinned)
FROM node:latest

# INSECURE: Running as root (no USER instruction)

# INSECURE: Hardcoded secrets in environment
ENV API_KEY=sk-1234567890abcdef1234567890abcdef
ENV DATABASE_PASSWORD=supersecret123
ENV JWT_SECRET=my-super-secret-jwt-key

WORKDIR /app

# INSECURE: Installing unnecessary packages that increase attack surface
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    vim \
    git \
    sudo \
    ssh \
    telnet \
    ftp \
    && rm -rf /var/lib/apt/lists/*

# INSECURE: Copying everything (no .dockerignore)
COPY . .

# INSECURE: Installing packages with npm (not npm ci)
RUN npm install

# INSECURE: Installing packages as root with elevated privileges
RUN npm install -g nodemon pm2

# INSECURE: Exposing unnecessary ports
EXPOSE 3000 8080 9000 22

# INSECURE: Running application as root
CMD ["node", "server.js"]