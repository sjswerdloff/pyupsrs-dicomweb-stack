#!/bin/bash

echo "🚀 Setting up DICOMweb Stack with nginx..."

# Check for Docker and Docker Compose
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create .env from example if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
fi

# Load environment variables
set -a
source .env
set +a

# Create necessary directories
mkdir -p nginx

# SSL Certificate Setup
echo "🔒 Checking SSL certificates..."
if [ -f "./nginx/ssl/cert.pem" ] && [ -f "./nginx/ssl/key.pem" ]; then
    echo "✓ Using existing SSL certificates"
else
    echo "No SSL certificates found. Generating self-signed certificate for development..."
    mkdir -p ./nginx/ssl
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ./nginx/ssl/key.pem \
        -out ./nginx/ssl/cert.pem \
        -subj "/C=US/ST=Development/L=Local/O=DICOMweb-Stack/CN=localhost" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ Self-signed certificate generated successfully"
        echo "  ⚠️  Note: Browsers will show security warnings - this is normal for development"
    else
        echo "❌ Failed to generate self-signed certificate"
        exit 1
    fi
fi

# Copy the SSL-enabled nginx configuration
echo "📄 Configuring nginx with SSL support..."
cp ./nginx/nginx-ssl.conf ./nginx/nginx.conf

echo "🚀 Starting services..."
docker-compose -f docker-compose-nginx.yml up -d

echo ""
echo "✅ Setup complete!"
echo ""
echo "🌐 Access your services at:"
echo "   - DICOMweb Base URL (HTTP): http://localhost:${HTTP_PORT:-9080}/dicom-web"
echo "   - DICOMweb Base URL (HTTPS): https://localhost:${HTTPS_PORT:-9443}/dicom-web"
echo "   - Orthanc Web UI: http://localhost:${HTTP_PORT:-9080}/"
echo "   - DIMSE Port: localhost:${DICOM_PORT:-4242}"
echo ""
echo "🔒 SSL Certificate Information:"
if [ -f "./nginx/ssl/cert.pem" ]; then
    CERT_INFO=$(openssl x509 -in ./nginx/ssl/cert.pem -subject -issuer -dates -noout 2>/dev/null)
    if echo "$CERT_INFO" | grep -q "O=DICOMweb-Stack"; then
        echo "   - Using self-signed certificate (development)"
        echo "   - Browsers will show security warnings - this is expected"
        echo "   - Use 'curl -k' to bypass certificate warnings"
    else
        echo "   - Using custom SSL certificate"
    fi
fi
echo ""
echo "🔍 To check service status:"
echo "   docker-compose -f docker-compose-nginx.yml ps"
echo ""
echo "📋 To view logs:"
echo "   docker-compose -f docker-compose-nginx.yml logs -f"