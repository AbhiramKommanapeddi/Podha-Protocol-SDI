# Setup Guide - Podha Protocol Social Listening Workflow

## Overview
This guide will help you set up and configure the social listening workflow for monitoring Podha Protocol and Real World Assets (RWA) discussions across multiple platforms.

## Prerequisites
- Node.js (v14 or higher)
- PostgreSQL (v12 or higher)
- Basic knowledge of n8n workflows
- API keys for external services

## Quick Start

### 1. Environment Setup
1. Navigate to the project directory
2. Copy the environment template:
   ```bash
   cp config/environment.env .env
   ```
3. Edit `.env` and add your API keys and configuration

### 2. Database Setup
1. Ensure PostgreSQL is running
2. Create the database and tables:
   ```bash
   ./scripts/setup.sh
   ```

### 3. n8n Installation and Configuration
1. Install n8n globally:
   ```bash
   npm install -g n8n
   ```
2. Start n8n:
   ```bash
   n8n start
   ```
3. Open http://localhost:5678 in your browser

### 4. Import Workflows
1. In n8n interface, go to "Workflows"
2. Click "Import from File"
3. Import each workflow file from the `workflows/` directory:
   - `main-social-listening.json`
   - `youtube-social-listening.json`
   - `medium-blog-monitoring.json`

### 5. Configure Credentials
For each workflow, you'll need to configure:

#### News API
- Sign up at https://newsapi.org
- Get your API key
- Add to n8n credentials

#### YouTube API
- Go to Google Cloud Console
- Enable YouTube Data API v3
- Create credentials and get API key
- Add to n8n credentials

#### Email Configuration
- Configure SMTP settings for alert emails
- Test email functionality

#### Database Connection
- Configure PostgreSQL connection in n8n
- Test database connectivity

## Required API Keys

### News API (newsapi.org)
- **Purpose**: Monitor news articles and blog posts
- **Cost**: Free tier available (1000 requests/day)
- **Setup**: 
  1. Visit https://newsapi.org
  2. Sign up for free account
  3. Get API key from dashboard
  4. Add to `NEWS_API_KEY` in environment

### YouTube Data API v3
- **Purpose**: Monitor YouTube videos and comments
- **Cost**: Free tier available (10,000 units/day)
- **Setup**:
  1. Go to Google Cloud Console
  2. Create new project or select existing
  3. Enable YouTube Data API v3
  4. Create credentials (API key)
  5. Add to `YOUTUBE_API_KEY` in environment

### Optional APIs
- **Discord Bot**: For monitoring Discord servers
- **Telegram Bot**: For monitoring Telegram channels
- **LinkedIn API**: For professional network monitoring

## Workflow Configuration

### Main Social Listening Workflow
- **Frequency**: Every 15 minutes
- **Platforms**: Reddit, News APIs
- **Features**: Keyword filtering, sentiment analysis, alerts

### YouTube Monitoring Workflow
- **Frequency**: Every 6 hours
- **Features**: Video search, comment analysis
- **Rate Limits**: Respects YouTube API quotas

### Medium/Blog Monitoring Workflow
- **Frequency**: Every 12 hours
- **Features**: RSS feed monitoring, article analysis
- **Sources**: Medium, CoinTelegraph, CoinDesk

## Monitoring Keywords

### Primary Keywords
- podha protocol
- real world assets
- rwa
- asset tokenization
- tokenized assets
- real estate tokens
- commodity tokenization
- fractional ownership

### Secondary Keywords
- defi protocols
- blockchain real estate
- tokenized commodities
- asset-backed tokens
- digital assets
- tokenization platform

## Data Storage

### Database Schema
The system uses PostgreSQL with the following main tables:
- `social_listening_data`: Main data storage
- `keyword_trends`: Keyword tracking over time
- `platform_stats`: Platform-specific statistics
- `alerts`: Alert management

### Data Retention
- Default: 90 days
- Configurable in `monitoring-config.json`
- Automatic cleanup via scheduled tasks

## Alerts and Notifications

### Email Alerts
- Negative sentiment detection
- High volume spikes
- Keyword trend alerts
- Daily summary reports

### Webhook Integration
- Real-time data push to external systems
- Configurable payload format
- Retry mechanism for failed deliveries

## Security Considerations

### API Key Management
- Store all API keys in environment variables
- Use n8n's credential management system
- Rotate keys regularly

### Database Security
- Use strong passwords
- Limit database access
- Regular backups

### Rate Limiting
- Respect API rate limits
- Implement exponential backoff
- Monitor usage quotas

## Troubleshooting

### Common Issues

#### Database Connection Errors
1. Check PostgreSQL is running
2. Verify connection credentials
3. Ensure database exists
4. Check firewall settings

#### API Rate Limits
1. Review API quotas
2. Adjust workflow frequency
3. Implement request queuing
4. Consider upgrading API plans

#### Missing Data
1. Check workflow execution logs
2. Verify API responses
3. Review keyword filters
4. Check platform availability

### Log Analysis
- n8n execution logs: Available in n8n interface
- Database logs: Check PostgreSQL logs
- Application logs: Created in `logs/` directory

## Performance Optimization

### Database Optimization
- Regular VACUUM and ANALYZE
- Index maintenance
- Query optimization
- Connection pooling

### Workflow Optimization
- Batch processing
- Parallel execution
- Error handling
- Resource monitoring

## Scaling Considerations

### High Volume Scenarios
- Database partitioning
- Caching layer
- Load balancing
- Horizontal scaling

### Multi-Instance Deployment
- Workflow distribution
- Shared database
- Coordination mechanisms
- Monitoring consolidation

## Maintenance

### Regular Tasks
- Database maintenance
- Log rotation
- Backup verification
- Performance monitoring

### Updates
- n8n version updates
- API changes monitoring
- Security patches
- Feature enhancements

## Support

### Resources
- n8n Documentation: https://docs.n8n.io
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- API Documentation: Check individual provider docs

### Common Commands
```bash
# Start n8n
n8n start

# Analyze data
./scripts/analyze-data.sh

# Export data
./scripts/export-data.sh

# Database backup
pg_dump social_listening > backup.sql
```

## Next Steps
1. Complete the setup following this guide
2. Test all workflows manually
3. Configure monitoring and alerts
4. Set up automated backups
5. Document any customizations
6. Train team on system usage
