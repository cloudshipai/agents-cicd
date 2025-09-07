# Stage 1: Intentionally suboptimal Dockerfile for Station agent guidance

# Station agent should suggest using specific version tags
FROM python:latest

# Station agent should suggest non-root user
# Running as root - security issue

# Station agent should suggest setting working directory first
COPY . /app
WORKDIR /app

# Station agent should suggest combining RUN commands and cleanup
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y vim
RUN pip install --upgrade pip

# Station agent should suggest using requirements.txt with --no-cache-dir
RUN pip install -r requirements.txt

# Station agent should suggest not exposing unnecessary ports
EXPOSE 5000 8080

# Station agent should suggest proper environment variables
ENV FLASK_ENV=development
ENV FLASK_DEBUG=1

# Station agent should suggest using exec form and non-root user
CMD python app.py