# Podha Protocol Social Listening Workflow

## Project Overview

This project implements a comprehensive social listening workflow using n8n to monitor discussions about Podha Protocol and Real World Assets (RWA) across multiple platforms without using the Twitter API.

## Features

- Multi-platform monitoring (Reddit, LinkedIn, News APIs, Discord, Telegram)
- Keyword filtering and sentiment analysis
- Real-time data collection and processing
- Automated reporting and alerts
- Data storage and visualization
- Customizable monitoring parameters

## Monitored Platforms

- **Reddit**: Subreddits related to RWA, DeFi, blockchain
- **LinkedIn**: Professional posts and articles
- **News APIs**: Crypto and finance news outlets
- **Discord**: Public channels and announcements
- **Telegram**: Public channels and groups
- **YouTube**: Comments and video descriptions
- **Medium**: Articles and blog posts

## Keywords and Filters

### Primary Keywords

- Podha Protocol
- Real World Assets
- RWA tokenization
- Asset tokenization
- Blockchain real estate
- Commodity tokenization

### Secondary Keywords

- DeFi protocols
- Tokenized assets
- Real estate tokens
- Fractional ownership
- Asset-backed tokens

## Architecture

```
Data Sources → n8n Workflow → Data Processing → Storage → Reporting
```

## Setup Instructions

1. Install n8n
2. Import the workflow files
3. Configure API keys and credentials
4. Set up monitoring schedules
5. Configure notification channels

## File Structure

- `workflows/` - n8n workflow JSON files
- `config/` - Configuration files
- `scripts/` - Helper scripts
- `docs/` - Documentation
- `data/` - Sample data and schemas

## 🐦 Twitter Monitoring (No API Required)

### Advanced Twitter Listening Workflow

This project includes a sophisticated Twitter monitoring solution that tracks Podha Protocol and RWA discussions **without using the Twitter API**.

#### Key Features:

- **No API Dependency**: Uses Nitter proxies and Puppeteer automation
- **Blue Verified Filter**: Only monitors verified accounts with minimum engagement
- **Real-time Discord Notifications**: Rich embeds with engagement metrics
- **Deduplication**: Prevents duplicate tweet notifications
- **Admin Dashboard**: Web-based monitoring interface
- **Fallback Systems**: Multiple scraping methods for reliability

#### Search Filters:

1. `filter:blue_verified min_faves:3 Podha AND ("RWA" OR "Real World Assets" OR "Yield")`
2. `filter:blue_verified min_faves:3 Solana AND ("Smart Vaults" OR "Safe Yield" OR "Podha")`
3. `filter:blue_verified min_faves:3 Bitcoin AND ("tokenized treasury" OR "credit protocol" OR "RWA on-chain")`
4. `filter:blue_verified min_faves:3 DeFi AND ("custodial vault" OR "delta neutral")`

#### n8n Workflows:

- **`twitter-listening-no-api.json`**: Primary Nitter-based scraper
- **`twitter-puppeteer-advanced.json`**: Puppeteer fallback system
- **`twitter-admin-dashboard.json`**: Web dashboard for monitoring

#### Quick Start:

```bash
# Setup Twitter monitoring
./scripts/setup-twitter-monitoring.sh

# Configure environment variables
# Edit config/environment.env and add:
# DISCORD_WEBHOOK_URL=your_webhook_url
# TWITTER_COOKIE=optional_auth_token

# Test the system
node scripts/twitter_scraper.js

# Monitor system status
./scripts/monitor_twitter.sh
```

For detailed setup instructions, see [`docs/twitter-monitoring-guide.md`](docs/twitter-monitoring-guide.md).
