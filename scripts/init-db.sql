-- Database initialization script for BadmintonEcommerce
-- This script runs when PostgreSQL container starts

-- Create additional schemas for better organization
CREATE SCHEMA IF NOT EXISTS products;
CREATE SCHEMA IF NOT EXISTS orders;
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS inventory;
CREATE SCHEMA IF NOT EXISTS audit;

-- Create extensions that might be useful for ecommerce
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE BadmintonEcommerce TO postgres;
GRANT USAGE ON SCHEMA products TO postgres;
GRANT USAGE ON SCHEMA orders TO postgres;
GRANT USAGE ON SCHEMA users TO postgres;
GRANT USAGE ON SCHEMA inventory TO postgres;
GRANT USAGE ON SCHEMA audit TO postgres;