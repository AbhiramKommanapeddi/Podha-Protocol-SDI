#!/bin/bash

# Setup script for Podha Protocol Social Listening Workflow

echo "Setting up Podha Protocol Social Listening Workflow..."

# Create necessary directories
mkdir -p logs
mkdir -p backups

# Install n8n if not already installed
if ! command -v n8n &> /dev/null; then
    echo "Installing n8n..."
    npm install -g n8n
else
    echo "n8n is already installed"
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL is not installed. Please install PostgreSQL first."
    echo "Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib"
    echo "macOS: brew install postgresql"
    echo "Windows: Download from https://www.postgresql.org/download/"
    exit 1
fi

# Create database and tables
echo "Setting up database..."
if [ -f "config/environment.env" ]; then
    source config/environment.env
    
    # Create database
    createdb $DATABASE_NAME 2>/dev/null || echo "Database already exists"
    
    # Run schema
    psql -d $DATABASE_NAME -f config/database-schema.sql
    
    echo "Database setup completed"
else
    echo "Please create config/environment.env file first"
    exit 1
fi

# Create n8n environment file
echo "Creating n8n environment file..."
cat > .env << EOF
# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=admin123

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=$DATABASE_HOST
DB_POSTGRESDB_PORT=$DATABASE_PORT
DB_POSTGRESDB_DATABASE=$DATABASE_NAME
DB_POSTGRESDB_USER=$DATABASE_USER
DB_POSTGRESDB_PASSWORD=$DATABASE_PASSWORD

# External APIs
NEWS_API_KEY=$NEWS_API_KEY
YOUTUBE_API_KEY=$YOUTUBE_API_KEY

# Email
EMAIL_HOST=$EMAIL_HOST
EMAIL_PORT=$EMAIL_PORT
EMAIL_USER=$EMAIL_USER
EMAIL_PASSWORD=$EMAIL_PASSWORD

# Webhooks
WEBHOOK_URL=$WEBHOOK_URL
WEBHOOK_SECRET=$WEBHOOK_SECRET

# Other settings
N8N_SECURE_COOKIE=false
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168
EOF

echo "Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Update config/environment.env with your API keys"
echo "2. Run 'n8n start' to start the n8n server"
echo "3. Open http://localhost:5678 in your browser"
echo "4. Import the workflow files from the workflows/ directory"
echo "5. Configure the workflow credentials"
echo "6. Start monitoring!"
echo ""
echo "For more information, see docs/setup-guide.md"
