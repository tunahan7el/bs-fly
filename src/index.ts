import express, { Request, Response } from 'express';
import http from 'http';

async function main() {
  // Create an Express app for health checks
  const app = express();
  
  // Add health check endpoint
  app.get('/health', (_: Request, res: Response) => {
    res.json({ status: 'ok' });
  });

  // Create HTTP server
  const server = http.createServer(app);

  // Start server
  server.listen(3000, () => {
    console.log('Server is running on port 3000');
  });

  // Handle shutdown gracefully
  process.on('SIGTERM', () => {
    console.log('Received SIGTERM signal, shutting down...');
    server.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
  });
}

main().catch(error => {
  console.error('Server failed to start up', error);
  process.exit(1);
}); 