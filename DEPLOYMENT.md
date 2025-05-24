# 🏸 BadmintonEcommerce - Deployment Guide

A modern e-commerce platform for badminton equipment built with Nx monorepo, Next.js, and .NET 9.

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Next.js 15, React 19, TypeScript, Tailwind CSS
- **Backend**: .NET 9, ASP.NET Core Web API
- **Database**: PostgreSQL 16
- **Cache**: Redis 7
- **Message Queue**: RabbitMQ 3.12
- **Object Storage**: MinIO
- **Search**: Elasticsearch 8.11 + Kibana
- **Email**: Mailcatcher (development)
- **Monorepo**: Nx 21.1.1

### Services Overview
- **Frontend**: React-based web application (Port 3000)
- **Backend**: .NET Web API (Port 8080)
- **PostgreSQL**: Primary database (Port 5432)
- **Redis**: Caching and session storage (Port 6379)
- **MinIO**: Object storage for images/files (Ports 9000/9001)
- **Elasticsearch**: Search engine (Port 9200)
- **Kibana**: Search analytics dashboard (Port 5601)
- **RabbitMQ**: Message broker (Ports 5672/15672)
- **Mailcatcher**: Email testing (Ports 1025/1080)

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 20+ (for development)
- .NET 9 SDK (for development)
- Git

### 1. Clone and Setup
```bash
git clone <repository-url>
cd badminton-ecommerce

# Copy environment file
cp .env.example .env

# Make deployment script executable (Linux/Mac)
chmod +x deploy.sh
```

### 2. Development Deployment
```bash
# Full deployment with all services
./deploy.sh development deploy

# Or start services individually
./deploy.sh development start
```

### 3. Production Deployment
```bash
# Set production environment variables in .env first
./deploy.sh production deploy
```

## 📋 Deployment Commands

The `deploy.sh` script provides comprehensive deployment management:

### Basic Commands
```bash
# Development environment
./deploy.sh development [command]

# Production environment  
./deploy.sh production [command]
```

### Available Commands
- `deploy` - Full deployment (default)
- `start` - Start services
- `stop` - Stop services
- `restart` - Restart services
- `status` - Show service status and URLs
- `logs` - Show logs (optional: specify service name)
- `cleanup` - Stop and remove all containers and volumes
- `migrate` - Run database migrations

### Examples
```bash
# Full development deployment
./deploy.sh development deploy

# Start production services
./deploy.sh production start

# View backend logs
./deploy.sh development logs backend

# Check service status
./deploy.sh development status

# Clean up everything
./deploy.sh development cleanup
```

## 🔧 Configuration

### Environment Variables

Key environment variables in `.env`:

```bash
# Database
POSTGRES_PASSWORD=your-secure-password

# Redis
REDIS_PASSWORD=your-redis-password

# MinIO Object Storage
MINIO_ROOT_PASSWORD=your-minio-password

# RabbitMQ
RABBITMQ_PASSWORD=your-rabbitmq-password

# Security
JWT_SECRET=your-super-secret-jwt-key-change-in-production
ENCRYPTION_KEY=your-32-character-encryption-key

# Application URLs
NEXT_PUBLIC_API_URL=http://localhost:8080
```

### Production Security Considerations

For production deployment:

1. **Change all default passwords**
2. **Use strong JWT secrets**
3. **Enable HTTPS with SSL certificates**
4. **Configure firewall rules**
5. **Set up monitoring and logging**
6. **Use secrets management (Kubernetes secrets, etc.)**

## 🏭 Production Deployment

### Docker Compose (Recommended for Single Server)

1. **Prepare environment**:
```bash
# Copy and configure production environment
cp .env.example .env
# Edit .env with production values
```

2. **Deploy**:
```bash
./deploy.sh production deploy
```

3. **Monitor**:
```bash
./deploy.sh production status
./deploy.sh production logs
```

### Kubernetes (Recommended for Scale)

1. **Apply Kubernetes manifests**:
```bash
kubectl apply -f k8s/deployment.yaml
```

2. **Update image references**:
   - Replace `ghcr.io/yourusername/badminton-ecommerce-*` with your actual image URLs
   - Update secrets with production values

3. **Configure ingress**:
   - Update domain names in `k8s/deployment.yaml`
   - Configure SSL certificates

## 📊 Service URLs

After deployment, access the following services:

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | Main web application |
| Backend API | http://localhost:8080 | REST API endpoints |
| Database | localhost:5432 | PostgreSQL (internal) |
| Redis | localhost:6379 | Cache (internal) |
| MinIO Console | http://localhost:9001 | Object storage management |
| Elasticsearch | http://localhost:9200 | Search engine API |
| Kibana | http://localhost:5601 | Search analytics |
| RabbitMQ Management | http://localhost:15672 | Message queue management |
| Mailcatcher | http://localhost:1080 | Email testing interface |

### Default Credentials

**Database**: 
- Username: `postgres`
- Password: `postgres123` (change in production)

**MinIO**:
- Username: `minioadmin`
- Password: `minioadmin123` (change in production)

**RabbitMQ**:
- Username: `admin`
- Password: `admin123` (change in production)

## 🔍 Monitoring & Health Checks

### Health Check Endpoints

- **Frontend**: `GET /api/health`
- **Backend**: `GET /health`
- **Backend Ready**: `GET /health/ready`

### Log Management

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Using deploy script
./deploy.sh development logs backend
```

### Performance Monitoring

The setup includes:
- **Health checks** for all services
- **Resource limits** in production
- **Restart policies** for reliability
- **Volume persistence** for data

## 🚧 Development

### Local Development Setup

1. **Install dependencies**:
```bash
# Install Node.js dependencies
yarn install

# Restore .NET dependencies
yarn nx affected -t restore
```

2. **Start development services**:
```bash
# Start infrastructure services only
docker-compose up -d postgres redis minio elasticsearch rabbitmq mailcatcher

# Start applications in development mode
yarn nx serve backend
yarn nx dev frontend
```

3. **Run tests**:
```bash
yarn nx affected -t test
yarn nx affected -t lint
```

### Building for Production

```bash
# Build all applications
yarn nx affected -t build

# Build specific application
yarn nx build frontend
yarn nx build backend
```

## 🔒 Security

### Production Security Checklist

- [ ] Change all default passwords
- [ ] Use environment variables for secrets
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Configure firewall rules
- [ ] Set up monitoring and alerting
- [ ] Implement backup strategies
- [ ] Use secrets management system
- [ ] Enable audit logging
- [ ] Configure rate limiting
- [ ] Set up intrusion detection

### Container Security

- All images use non-root users where possible
- Multi-stage builds for minimal attack surface
- Regular security scanning with Trivy
- Resource limits to prevent abuse

## 📈 Scaling

### Horizontal Scaling

The architecture supports horizontal scaling:

- **Frontend**: Stateless, can run multiple instances
- **Backend**: Stateless API, can run multiple instances  
- **Database**: PostgreSQL with read replicas
- **Cache**: Redis Cluster for high availability
- **Message Queue**: RabbitMQ clustering

### Performance Tuning

- **Database**: Connection pooling, indexing, query optimization
- **Cache**: Redis memory optimization, TTL settings
- **API**: Response compression, pagination
- **Frontend**: Code splitting, image optimization, CDN

## 🆘 Troubleshooting

### Common Issues

1. **Port conflicts**: Check if ports are already in use
2. **Permission issues**: Ensure Docker has proper permissions
3. **Memory issues**: Adjust resource limits in docker-compose files
4. **Database connection**: Verify PostgreSQL is healthy before starting apps

### Debug Commands

```bash
# Check service health
docker-compose ps
docker-compose logs [service-name]

# Inspect containers
docker exec -it [container-name] /bin/bash

# Check resource usage
docker stats

# Verify network connectivity
docker-compose exec backend ping postgres
```

## 📝 CI/CD Pipeline

The project includes GitHub Actions for:

- **Testing**: Automated tests on PR/push
- **Building**: Docker images for all services
- **Security**: Vulnerability scanning with Trivy
- **Deployment**: Automated deployment to staging/production

### Pipeline Stages

1. **Test**: Lint, test, and build verification
2. **Build**: Create and push Docker images
3. **Security**: Vulnerability scanning
4. **Deploy**: Automated deployment to environments

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `yarn nx affected -t test`
5. Submit a pull request

## 📄 License

[Your License Here]

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

**Happy Coding! 🏸**
