#!/bin/bash

# BadmintonEcommerce Deployment Script
# This script handles deployment for different environments

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default environment
ENVIRONMENT=${1:-development}
COMPOSE_FILE="docker-compose.yml"

echo -e "${BLUE}🚀 BadmintonEcommerce Deployment Script${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker is running${NC}"
}

# Function to check if required files exist
check_prerequisites() {
    local files=("docker-compose.yml" "apps/frontend/Dockerfile" "apps/backend/Dockerfile")
    
    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo -e "${RED}❌ Required file not found: $file${NC}"
            exit 1
        fi
    done
    echo -e "${GREEN}✅ All required files found${NC}"
}

# Function to create environment file if it doesn't exist
setup_environment() {
    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
            echo -e "${YELLOW}⚠️ .env file not found. Copying from .env.example${NC}"
            cp .env.example .env
            echo -e "${YELLOW}⚠️ Please update .env file with your production values${NC}"
        else
            echo -e "${RED}❌ No .env or .env.example file found${NC}"
            exit 1
        fi
    fi
}

# Function to pull latest images (for production)
pull_images() {
    echo -e "${BLUE}📥 Pulling latest base images...${NC}"
    docker-compose -f $COMPOSE_FILE pull postgres redis minio elasticsearch kibana rabbitmq mailcatcher
}

# Function to build application images
build_images() {
    echo -e "${BLUE}🔨 Building application images...${NC}"
    docker-compose -f $COMPOSE_FILE build --no-cache frontend backend
}

# Function to start services
start_services() {
    echo -e "${BLUE}🚀 Starting services...${NC}"
    
    # Start infrastructure services first
    echo -e "${YELLOW}Starting infrastructure services...${NC}"
    docker-compose -f $COMPOSE_FILE up -d postgres redis minio elasticsearch rabbitmq
    
    # Wait for services to be healthy
    echo -e "${YELLOW}Waiting for services to be healthy...${NC}"
    sleep 30
    
    # Start application services
    echo -e "${YELLOW}Starting application services...${NC}"
    docker-compose -f $COMPOSE_FILE up -d backend frontend kibana mailcatcher
    
    echo -e "${GREEN}✅ All services started${NC}"
}

# Function to show service status
show_status() {
    echo -e "${BLUE}📊 Service Status:${NC}"
    docker-compose -f $COMPOSE_FILE ps
    
    echo -e "\n${BLUE}🌐 Service URLs:${NC}"
    echo -e "Frontend: ${GREEN}http://localhost:3000${NC}"
    echo -e "Backend API: ${GREEN}http://localhost:8080${NC}"
    echo -e "PostgreSQL: ${GREEN}localhost:5432${NC}"
    echo -e "Redis: ${GREEN}localhost:6379${NC}"
    echo -e "MinIO Console: ${GREEN}http://localhost:9001${NC}"
    echo -e "Elasticsearch: ${GREEN}http://localhost:9200${NC}"
    echo -e "Kibana: ${GREEN}http://localhost:5601${NC}"
    echo -e "RabbitMQ Management: ${GREEN}http://localhost:15672${NC}"
    echo -e "Mailcatcher: ${GREEN}http://localhost:1080${NC}"
}

# Function to stop services
stop_services() {
    echo -e "${YELLOW}🛑 Stopping services...${NC}"
    docker-compose -f $COMPOSE_FILE down
    echo -e "${GREEN}✅ Services stopped${NC}"
}

# Function to clean up
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    docker-compose -f $COMPOSE_FILE down -v --remove-orphans
    docker system prune -f
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to show logs
show_logs() {
    local service=${2:-""}
    if [[ -n "$service" ]]; then
        docker-compose -f $COMPOSE_FILE logs -f "$service"
    else
        docker-compose -f $COMPOSE_FILE logs -f
    fi
}

# Function to run database migrations (placeholder)
run_migrations() {
    echo -e "${BLUE}🗄️ Running database migrations...${NC}"
    # Add your migration commands here
    # docker-compose -f $COMPOSE_FILE exec backend dotnet ef database update
    echo -e "${GREEN}✅ Migrations completed${NC}"
}

# Set production compose file if needed
if [[ "$ENVIRONMENT" == "production" ]]; then
    COMPOSE_FILE="docker-compose.yml -f docker-compose.prod.yml"
    echo -e "${YELLOW}Using production configuration${NC}"
fi

# Main execution based on command
case "${2:-deploy}" in
    "deploy")
        check_docker
        check_prerequisites
        setup_environment
        if [[ "$ENVIRONMENT" == "production" ]]; then
            pull_images
        fi
        build_images
        start_services
        show_status
        ;;
    "start")
        start_services
        show_status
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        stop_services
        start_services
        show_status
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs "$@"
        ;;
    "cleanup")
        cleanup
        ;;
    "migrate")
        run_migrations
        ;;
    *)
        echo -e "${BLUE}Usage: $0 [environment] [command]${NC}"
        echo -e "${BLUE}Environments: development, production${NC}"
        echo -e "${BLUE}Commands:${NC}"
        echo -e "  deploy   - Full deployment (default)"
        echo -e "  start    - Start services"
        echo -e "  stop     - Stop services"
        echo -e "  restart  - Restart services"
        echo -e "  status   - Show service status"
        echo -e "  logs     - Show logs (optional: specify service name)"
        echo -e "  cleanup  - Stop and remove all containers and volumes"
        echo -e "  migrate  - Run database migrations"
        echo -e "\n${BLUE}Examples:${NC}"
        echo -e "  $0 development deploy"
        echo -e "  $0 production start"
        echo -e "  $0 development logs backend"
        exit 1
        ;;
esac