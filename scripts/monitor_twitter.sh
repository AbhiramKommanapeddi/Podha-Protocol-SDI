#!/bin/bash

echo "🔍 Twitter Monitor Status Check"
echo "================================"

# Check if processes are running
echo "Process Status:"
if pgrep -f "twitter_scraper.js" > /dev/null; then
    echo "✅ Twitter scraper process is running"
else
    echo "❌ Twitter scraper process is not running"
fi

# Check recent log entries
echo ""
echo "Recent Log Entries:"
if [ -f "logs/twitter/scraper.log" ]; then
    tail -n 10 logs/twitter/scraper.log
else
    echo "❌ No log file found"
fi

# Check database for recent tweets
echo ""
echo "Recent Tweet Count:"
if command -v psql &> /dev/null; then
    source config/environment.env
    psql -d $DATABASE_NAME -c "SELECT COUNT(*) as tweets_last_24h FROM twitter_seen_tweets WHERE scraped_at >= NOW() - INTERVAL '24 hours';"
else
    echo "❌ PostgreSQL not available"
fi

# Check Discord webhook
echo ""
echo "Discord Webhook Test:"
if [ ! -z "$DISCORD_WEBHOOK_URL" ]; then
    curl -s -H "Content-Type: application/json" \
         -X POST \
         -d '{"embeds":[{"title":"🔍 Monitor Status Check","description":"Twitter monitor status check completed.","color":3447003,"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"}]}' \
         $DISCORD_WEBHOOK_URL > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Discord webhook is working"
    else
        echo "❌ Discord webhook test failed"
    fi
else
    echo "⚠️  Discord webhook URL not configured"
fi

echo ""
echo "Status check completed!"
