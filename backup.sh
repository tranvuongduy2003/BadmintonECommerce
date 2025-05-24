#!/bin/bash

# BadmintonEcommerce Backup Script
# This script handles backup and restore operations for the application

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
COMPOSE_FILE="docker-compose.yml"

echo -e "${BLUE}🔄 BadmintonEcommerce Backup Script${NC}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to backup PostgreSQL database
backup_postgres() {
    echo -e "${BLUE}📦 Backing up PostgreSQL database...${NC}"
    
    docker-compose exec -T postgres pg_dump -U postgres -d BadmintonEcommerce > "$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PostgreSQL backup completed: postgres_backup_$TIMESTAMP.sql${NC}"
    else
        echo -e "${RED}❌ PostgreSQL backup failed${NC}"
        exit 1
    fi
}

# Function to backup Redis data
backup_redis() {
    echo -e "${BLUE}📦 Backing up Redis data...${NC}"
    
    # Create Redis backup by saving current state
    docker-compose exec redis redis-cli BGSAVE
    
    # Wait for backup to complete
    sleep 5
    
    # Copy the dump file
    docker cp $(docker-compose ps -q redis):/data/dump.rdb "$BACKUP_DIR/redis_dump_$TIMESTAMP.rdb"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Redis backup completed: redis_dump_$TIMESTAMP.rdb${NC}"
    else
        echo -e "${RED}❌ Redis backup failed${NC}"
        exit 1
    fi
}

# Function to backup MinIO data
backup_minio() {
    echo -e "${BLUE}📦 Backing up MinIO data...${NC}"
    
    # Create MinIO backup directory
    mkdir -p "$BACKUP_DIR/minio_$TIMESTAMP"
    
    # Copy MinIO data
    docker cp $(docker-compose ps -q minio):/data "$BACKUP_DIR/minio_$TIMESTAMP/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ MinIO backup completed: minio_$TIMESTAMP/${NC}"
    else
        echo -e "${RED}❌ MinIO backup failed${NC}"
        exit 1
    fi
}

# Function to backup Elasticsearch data
backup_elasticsearch() {
    echo -e "${BLUE}📦 Backing up Elasticsearch data...${NC}"
    
    # Create Elasticsearch snapshot
    curl -X PUT "localhost:9200/_snapshot/backup_repo" -H 'Content-Type: application/json' -d'
    {
      "type": "fs",
      "settings": {
        "location": "/backup"
      }
    }'
    
    # Create snapshot
    curl -X PUT "localhost:9200/_snapshot/backup_repo/snapshot_$TIMESTAMP?wait_for_completion=true"
    
    # Copy snapshot data
    mkdir -p "$BACKUP_DIR/elasticsearch_$TIMESTAMP"
    docker cp $(docker-compose ps -q elasticsearch):/usr/share/elasticsearch/data "$BACKUP_DIR/elasticsearch_$TIMESTAMP/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Elasticsearch backup completed: elasticsearch_$TIMESTAMP/${NC}"
    else
        echo -e "${RED}❌ Elasticsearch backup failed${NC}"
        exit 1
    fi
}

# Function to restore PostgreSQL database
restore_postgres() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}❌ Backup file not found: $backup_file${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}⚠️ This will restore PostgreSQL database from: $backup_file${NC}"
    echo -e "${YELLOW}⚠️ This will OVERWRITE the current database. Are you sure? (y/N)${NC}"
    read -r confirmation
    
    if [[ $confirmation =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Restoring PostgreSQL database...${NC}"
        
        # Drop existing database and recreate
        docker-compose exec -T postgres psql -U postgres -c "DROP DATABASE IF EXISTS BadmintonEcommerce;"
        docker-compose exec -T postgres psql -U postgres -c "CREATE DATABASE BadmintonEcommerce;"
        
        # Restore from backup
        docker-compose exec -T postgres psql -U postgres -d BadmintonEcommerce < "$backup_file"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ PostgreSQL restore completed${NC}"
        else
            echo -e "${RED}❌ PostgreSQL restore failed${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Restore cancelled${NC}"
        exit 0
    fi
}

# Function to restore Redis data
restore_redis() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}❌ Backup file not found: $backup_file${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}⚠️ This will restore Redis data from: $backup_file${NC}"
    echo -e "${YELLOW}⚠️ This will OVERWRITE the current Redis data. Are you sure? (y/N)${NC}"
    read -r confirmation
    
    if [[ $confirmation =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Restoring Redis data...${NC}"
        
        # Stop Redis, copy backup, and restart
        docker-compose stop redis
        docker cp "$backup_file" $(docker-compose ps -aq redis):/data/dump.rdb
        docker-compose start redis
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Redis restore completed${NC}"
        else
            echo -e "${RED}❌ Redis restore failed${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Restore cancelled${NC}"
        exit 0
    fi
}

# Function to list available backups
list_backups() {
    echo -e "${BLUE}📋 Available backups:${NC}"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR)" ]; then
        echo -e "${YELLOW}No backups found in $BACKUP_DIR${NC}"
        return
    fi
    
    echo -e "${BLUE}PostgreSQL backups:${NC}"
    ls -la "$BACKUP_DIR"/postgres_backup_*.sql 2>/dev/null || echo "  None found"
    
    echo -e "${BLUE}Redis backups:${NC}"
    ls -la "$BACKUP_DIR"/redis_dump_*.rdb 2>/dev/null || echo "  None found"
    
    echo -e "${BLUE}MinIO backups:${NC}"
    ls -la "$BACKUP_DIR"/minio_* 2>/dev/null || echo "  None found"
    
    echo -e "${BLUE}Elasticsearch backups:${NC}"
    ls -la "$BACKUP_DIR"/elasticsearch_* 2>/dev/null || echo "  None found"
}

# Function to create full backup
full_backup() {
    echo -e "${BLUE}🎯 Creating full backup...${NC}"
    
    backup_postgres
    backup_redis
    backup_minio
    backup_elasticsearch
    
    # Create backup manifest
    cat > "$BACKUP_DIR/backup_manifest_$TIMESTAMP.txt" << EOF
BadmintonEcommerce Full Backup
Timestamp: $TIMESTAMP
Date: $(date)

Files:
- postgres_backup_$TIMESTAMP.sql
- redis_dump_$TIMESTAMP.rdb
- minio_$TIMESTAMP/
- elasticsearch_$TIMESTAMP/

To restore:
./backup.sh restore-postgres $BACKUP_DIR/postgres_backup_$TIMESTAMP.sql
./backup.sh restore-redis $BACKUP_DIR/redis_dump_$TIMESTAMP.rdb
EOF
    
    echo -e "${GREEN}✅ Full backup completed successfully!${NC}"
    echo -e "${BLUE}Backup manifest: backup_manifest_$TIMESTAMP.txt${NC}"
}

# Function to cleanup old backups
cleanup_backups() {
    local days=${1:-7}
    
    echo -e "${BLUE}🧹 Cleaning up backups older than $days days...${NC}"
    
    find "$BACKUP_DIR" -type f -name "*.sql" -mtime +$days -delete
    find "$BACKUP_DIR" -type f -name "*.rdb" -mtime +$days -delete
    find "$BACKUP_DIR" -type d -name "minio_*" -mtime +$days -exec rm -rf {} +
    find "$BACKUP_DIR" -type d -name "elasticsearch_*" -mtime +$days -exec rm -rf {} +
    find "$BACKUP_DIR" -type f -name "backup_manifest_*.txt" -mtime +$days -delete
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Main command handling
case "${1:-help}" in
    "backup-postgres")
        backup_postgres
        ;;
    "backup-redis")
        backup_redis
        ;;
    "backup-minio")
        backup_minio
        ;;
    "backup-elasticsearch")
        backup_elasticsearch
        ;;
    "backup-full"|"backup")
        full_backup
        ;;
    "restore-postgres")
        restore_postgres "$2"
        ;;
    "restore-redis")
        restore_redis "$2"
        ;;
    "list")
        list_backups
        ;;
    "cleanup")
        cleanup_backups "$2"
        ;;
    "help"|*)
        echo -e "${BLUE}Usage: $0 [command] [options]${NC}"
        echo -e "${BLUE}Commands:${NC}"
        echo -e "  backup-postgres      - Backup PostgreSQL database"
        echo -e "  backup-redis         - Backup Redis data"
        echo -e "  backup-minio         - Backup MinIO object storage"
        echo -e "  backup-elasticsearch - Backup Elasticsearch data"
        echo -e "  backup-full|backup   - Create full backup of all services"
        echo -e "  restore-postgres <file> - Restore PostgreSQL from backup file"
        echo -e "  restore-redis <file>    - Restore Redis from backup file"
        echo -e "  list                 - List available backups"
        echo -e "  cleanup [days]       - Remove backups older than N days (default: 7)"
        echo -e "\n${BLUE}Examples:${NC}"
        echo -e "  $0 backup-full"
        echo -e "  $0 restore-postgres ./backups/postgres_backup_20231201_120000.sql"
        echo -e "  $0 cleanup 14"
        exit 1
        ;;
esac
