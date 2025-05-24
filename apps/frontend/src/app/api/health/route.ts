import { NextResponse } from 'next/server';

export async function GET() {
  try {
    // Basic health check
    const healthCheck = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      version: process.env.npm_package_version || '1.0.0',
      services: {
        database: 'unknown', // Will be updated when backend connection is implemented
        cache: 'unknown',
        api: 'unknown'
      }
    };

    // Check if backend is accessible
    try {
      const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://backend:8080';
      const response = await fetch(`${backendUrl}/health`, { 
        signal: AbortSignal.timeout(5000) // 5 second timeout
      });
      
      if (response.ok) {
        healthCheck.services.api = 'healthy';
      } else {
        healthCheck.services.api = 'unhealthy';
        healthCheck.status = 'degraded';
      }
    } catch (error) {
      healthCheck.services.api = 'unreachable';
      healthCheck.status = 'degraded';
    }

    return NextResponse.json(healthCheck, { 
      status: healthCheck.status === 'healthy' ? 200 : 503 
    });
  } catch (error) {
    return NextResponse.json(
      { 
        status: 'unhealthy', 
        error: 'Health check failed',
        timestamp: new Date().toISOString()
      }, 
      { status: 503 }
    );
  }
}
