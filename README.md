# DICOMweb Stack

A complete DICOMweb implementation with Orthanc and UPS-RS support, all behind a unified nginx proxy. This setup provides a single-command installation with automatic configuration.

## Features

- **Orthanc**: Full DICOMweb server (QIDO-RS, WADO-RS, STOW-RS) with DIMSE support
- **pyupsrs**: UPS-RS (Unified Procedure Step) implementation 
- **PostgreSQL**: Database backend for Orthanc
- **Nginx**: High-performance reverse proxy with unified access point
- **One-command setup**: Everything is configured automatically

## Prerequisites

- Docker and Docker Compose installed
- 4GB+ RAM available
- Ports 9080, 4242 available (configurable)

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/pyupsrs-dicomweb-stack.git
   cd pyupsrs-dicomweb-stack
   ```

2. Run the setup script:
   ```bash
   ./setup-nginx.sh
   ```

That's it! The script will:
- Start all services
- Configure nginx routing automatically
- Set up both DICOMweb and DIMSE interfaces

## Access Points

Once setup is complete:

- **DICOMweb Base URL**: http://localhost:9080/dicom-web
- **DIMSE Port**: localhost:4242 (AE Title: ORTHANC)
- **Orthanc Web UI**: http://localhost:9080/

## API Examples

### DICOMweb Operations

#### Query Studies (QIDO-RS)
```bash
curl http://localhost:9080/dicom-web/studies
```

#### Upload DICOM Files (STOW-RS)
```bash
# Using curl
curl -X POST http://localhost:9080/dicom-web/studies \
  -H "Content-Type: multipart/related; type=application/dicom" \
  --data-binary @study.dcm

# Using dicomweb-client
dicomweb_client --url http://localhost:9080/dicom-web \
  store instances /path/to/dicom/files/*.dcm
```

#### Query Workitems (UPS-RS)
```bash
curl http://localhost:9080/dicom-web/workitems
```

#### Create Workitem (UPS-RS)
```bash
curl -X POST http://localhost:9080/dicom-web/workitems \
  -H "Content-Type: application/dicom+json" \
  -d @workitem.json
```

### DIMSE Operations

```bash
# C-ECHO test
echoscu -aec ORTHANC localhost 4242

# C-STORE to send DICOM files
storescu -aec ORTHANC localhost 4242 your_dicom_file.dcm

# C-FIND query
findscu -P -aec ORTHANC -k QueryRetrieveLevel=STUDY localhost 4242
```

### WebSocket Operations

```javascript
const ws = new WebSocket('ws://localhost:9080/dicom-web/ws/subscribers/{subscriber_id}');

ws.onopen = () => {
    console.log('Connected to UPS notifications');
};

ws.onmessage = (event) => {
    console.log('UPS notification:', event.data);
};
```

## API Endpoints

### DICOMweb (Orthanc)
| Service | Endpoint | Description |
|---------|----------|-------------|
| QIDO-RS | `/dicom-web/studies` | Query studies |
| QIDO-RS | `/dicom-web/studies/{studyUID}/series` | Query series |
| QIDO-RS | `/dicom-web/studies/{studyUID}/series/{seriesUID}/instances` | Query instances |
| WADO-RS | `/dicom-web/studies/{studyUID}` | Retrieve study |
| WADO-RS | `/dicom-web/studies/{studyUID}/series/{seriesUID}` | Retrieve series |
| WADO-RS | `/dicom-web/studies/{studyUID}/series/{seriesUID}/instances/{instanceUID}` | Retrieve instance |
| STOW-RS | `/dicom-web/studies` | Store instances |
| STOW-RS | `/dicom-web/studies/{studyUID}` | Store to specific study |

### UPS-RS (pyupsrs)
| Endpoint | Description |
|----------|-------------|
| `/dicom-web/workitems` | Create/search workitems |
| `/dicom-web/workitems/{workitem_uid}` | Get/update/delete specific workitem |
| `/dicom-web/workitems/{workitem_uid}/state` | Get/update workitem state |
| `/dicom-web/workitems/{workitem_uid}/cancelrequest` | Request workitem cancellation |
| `/dicom-web/workitems/{workitem_uid}/subscribers/{aetitle}` | Manage subscription |
| `/dicom-web/workitems/1.2.840.10008.5.1.4.34.5/subscribers/{aetitle}/suspend` | Suspend global subscription |
| `/dicom-web/workitems/1.2.840.10008.5.1.4.34.5.1/subscribers/{aetitle}/suspend` | Suspend filtered subscription |
| `/dicom-web/ws/subscribers/{subscriber_id}` | WebSocket endpoint for UPS notifications |

## Configuration

### Environment Variables

The `.env.example` file contains available configuration options:

```env
# Ports
HTTP_PORT=9080          # DICOMweb/HTTP access port
DICOM_PORT=4242         # DIMSE port

# Database
POSTGRES_PASSWORD=orthanc  # PostgreSQL password
```

To customize, copy `.env.example` to `.env` and edit before running setup.

### Default Credentials

- **Orthanc**: Authentication is disabled by default for ease of use
- To enable authentication, modify the Orthanc environment variables in `docker-compose-nginx.yml`

## Development Setup

### Using pyupsrs from GitHub

To use pyupsrs from a GitHub repository instead of PyPI:

1. Copy the GitHub Dockerfile:
   ```bash
   cp pyupsrs/Dockerfile.github pyupsrs/Dockerfile
   ```

2. Edit `pyupsrs/Dockerfile` to set your repository:
   ```dockerfile
   ARG GITHUB_REPO="https://github.com/yourusername/pyupsrs.git"
   ARG GITHUB_BRANCH="main"
   ```

3. Rebuild:
   ```bash
   docker-compose build pyupsrs
   docker-compose up -d
   ```

### Using Local pyupsrs Source

For local development with a cloned pyupsrs repository:

1. Clone pyupsrs locally:
   ```bash
   git clone https://github.com/yourusername/pyupsrs.git /path/to/pyupsrs
   ```

2. Use the local Dockerfile:
   ```bash
   cp pyupsrs/Dockerfile.local pyupsrs/Dockerfile
   ```

3. Update docker-compose-nginx.yml:
   ```yaml
   pyupsrs:
     build:
       context: /path/to/pyupsrs
       dockerfile: /path/to/dicomweb-stack/pyupsrs/Dockerfile
   ```

4. Rebuild and run:
   ```bash
   docker-compose build pyupsrs
   docker-compose up -d
   ```

## Architecture

```
Client Request → Nginx → http://localhost:9080/dicom-web/*
  ├── /dicom-web/workitems/* → pyupsrs:8000/workitems/*
  ├── /dicom-web/ws/subscribers/* → pyupsrs:8000/ws/subscribers/* (WebSocket)
  └── /dicom-web/* → orthanc:8042/dicom-web/*

DIMSE Request → http://localhost:4242 → orthanc:4242
```

The DICOMweb base URL follows the standard convention where all services (studies, series, instances, workitems) are accessed as paths under the base URL.

## Important Notes

- UPS-RS returns 404 when no workitems exist (this is correct behavior per DICOM standard)
- pyupsrs must bind to 0.0.0.0 (not 127.0.0.1) to be accessible from nginx container
- The nginx configuration handles URL rewriting to strip the `/dicom-web` prefix when forwarding to pyupsrs

## Management Commands

Start services:
```bash
docker-compose -f docker-compose-nginx.yml up -d
```

Stop services:
```bash
docker-compose -f docker-compose-nginx.yml down
```

View logs:
```bash
docker-compose -f docker-compose-nginx.yml logs -f
```

Check status:
```bash
docker-compose -f docker-compose-nginx.yml ps
```

Restart services:
```bash
docker-compose -f docker-compose-nginx.yml restart
```

Clean up everything:
```bash
docker-compose -f docker-compose-nginx.yml down -v
rm -rf postgres-data orthanc-storage
```

## Troubleshooting

### Services won't start
Check if ports are already in use:
```bash
netstat -tulpn | grep -E '9080|4242'
```

### Cannot access DICOMweb endpoints
Test internal connectivity:
```bash
docker exec dicomweb-nginx ping orthanc
docker exec dicomweb-nginx ping pyupsrs
```

### 502 Bad Gateway errors
Check if pyupsrs is binding to the correct interface:
```bash
docker logs dicomweb-pyupsrs | grep "Uvicorn running"
# Should show: Uvicorn running on http://0.0.0.0:8000
```

### Reset everything
```bash
docker-compose -f docker-compose-nginx.yml down -v
rm -rf postgres-data orthanc-storage
./setup-nginx.sh
```

## Files Included

- `docker-compose-nginx.yml` - Main service definitions
- `nginx/nginx.conf` - Nginx routing configuration
- `.env.example` - Environment variables template
- `setup-nginx.sh` - Setup script
- `pyupsrs/Dockerfile` - Dockerfile for pyupsrs (using PyPI)
- `pyupsrs/Dockerfile.github` - Alternative Dockerfile for GitHub source
- `pyupsrs/Dockerfile.local` - Alternative Dockerfile for local development
- `README.md` - This file

## License

MIT License - see LICENSE file for details.

## Contributing

Pull requests welcome! Please read CONTRIBUTING.md first.

## Support

For issues and feature requests, please use the GitHub issue tracker.