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

echo "🚀 Starting services..."
docker-compose -f docker-compose-nginx.yml up -d

echo ""
echo "✅ Setup complete!"
echo ""
echo "🌐 Access your services at:"
echo "   - DICOMweb Base URL: http://localhost:${HTTP_PORT:-9080}/dicom-web"
echo "   - Orthanc Web UI: http://localhost:${HTTP_PORT:-9080}/"
echo ""
echo "🔍 To check service status:"
echo "   docker-compose -f docker-compose-nginx.yml ps"
echo ""
echo "📋 To view logs:"
echo "   docker-compose -f docker-compose-nginx.yml logs -f"