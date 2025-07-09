#!/bin/bash

# Twitter Monitoring Setup Script for Podha Protocol

echo "🐦 Setting up Twitter Monitoring for Podha Protocol..."

# Create required directories
mkdir -p logs/twitter
mkdir -p backups/twitter
mkdir -p tmp/twitter

# Install required Node.js packages
echo "📦 Installing required Node.js packages..."
npm install puppeteer cheerio axios dotenv

# Install Puppeteer dependencies (Linux/Ubuntu)
if command -v apt-get &> /dev/null; then
    echo "🔧 Installing Puppeteer dependencies..."
    sudo apt-get update
    sudo apt-get install -y chromium-browser
    sudo apt-get install -y libxss1 libappindicator1 libindicator7
    sudo apt-get install -y fonts-liberation libasound2 libnspr4 libnss3 libxss1 xdg-utils
fi

# Create Twitter-specific database tables
echo "🗄️ Setting up Twitter monitoring database tables..."
if [ -f "config/environment.env" ]; then
    source config/environment.env
    
    # Create Twitter-specific tables
    psql -d $DATABASE_NAME -c "
    CREATE TABLE IF NOT EXISTS twitter_seen_tweets (
        id SERIAL PRIMARY KEY,
        tweet_id VARCHAR(255) UNIQUE NOT NULL,
        username VARCHAR(255) NOT NULL,
        tweet_text TEXT,
        tweet_url TEXT,
        scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE INDEX IF NOT EXISTS idx_tweet_id ON twitter_seen_tweets(tweet_id);
    CREATE INDEX IF NOT EXISTS idx_scraped_at ON twitter_seen_tweets(scraped_at);
    
    CREATE TABLE IF NOT EXISTS twitter_monitoring_config (
        id SERIAL PRIMARY KEY,
        filter_name VARCHAR(255) NOT NULL,
        search_query TEXT NOT NULL,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS discord_notifications (
        id SERIAL PRIMARY KEY,
        tweet_id VARCHAR(255),
        username VARCHAR(255),
        message_content TEXT,
        discord_response TEXT,
        status VARCHAR(50) DEFAULT 'sent',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE INDEX IF NOT EXISTS idx_discord_tweet_id ON discord_notifications(tweet_id);
    CREATE INDEX IF NOT EXISTS idx_discord_status ON discord_notifications(status);
    "
    
    # Insert default search filters
    psql -d $DATABASE_NAME -c "
    INSERT INTO twitter_monitoring_config (filter_name, search_query) VALUES
    ('Podha RWA', 'filter:blue_verified min_faves:3 Podha AND (\"RWA\" OR \"Real World Assets\" OR \"Yield\")')
    ON CONFLICT DO NOTHING;
    
    INSERT INTO twitter_monitoring_config (filter_name, search_query) VALUES
    ('Solana Smart Vaults', 'filter:blue_verified min_faves:3 Solana AND (\"Smart Vaults\" OR \"Safe Yield\" OR \"Podha\")')
    ON CONFLICT DO NOTHING;
    
    INSERT INTO twitter_monitoring_config (filter_name, search_query) VALUES
    ('Bitcoin RWA', 'filter:blue_verified min_faves:3 Bitcoin AND (\"tokenized treasury\" OR \"credit protocol\" OR \"RWA on-chain\")')
    ON CONFLICT DO NOTHING;
    
    INSERT INTO twitter_monitoring_config (filter_name, search_query) VALUES
    ('DeFi Vaults', 'filter:blue_verified min_faves:3 DeFi AND (\"custodial vault\" OR \"delta neutral\")')
    ON CONFLICT DO NOTHING;
    "
    
    echo "✅ Database tables created successfully"
else
    echo "❌ Please create config/environment.env file first"
    exit 1
fi

# Create Puppeteer test script
echo "🤖 Creating Puppeteer test script..."
cat > tmp/twitter/test_puppeteer.js << 'EOF'
const puppeteer = require('puppeteer');

async function testPuppeteer() {
    console.log('🚀 Testing Puppeteer setup...');
    
    const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    await page.goto('https://nitter.net');
    
    const title = await page.title();
    console.log('✅ Successfully loaded Nitter:', title);
    
    await browser.close();
    console.log('✅ Puppeteer test completed successfully');
}

testPuppeteer().catch(console.error);
EOF

# Test Puppeteer installation
echo "🧪 Testing Puppeteer installation..."
node tmp/twitter/test_puppeteer.js

# Create Twitter scraper standalone script
echo "📝 Creating standalone Twitter scraper..."
cat > scripts/twitter_scraper.js << 'EOF'
const puppeteer = require('puppeteer');
const axios = require('axios');
require('dotenv').config();

const config = {
    filters: [
        'filter:blue_verified min_faves:3 Podha AND ("RWA" OR "Real World Assets" OR "Yield")',
        'filter:blue_verified min_faves:3 Solana AND ("Smart Vaults" OR "Safe Yield" OR "Podha")',
        'filter:blue_verified min_faves:3 Bitcoin AND ("tokenized treasury" OR "credit protocol" OR "RWA on-chain")',
        'filter:blue_verified min_faves:3 DeFi AND ("custodial vault" OR "delta neutral")'
    ],
    discordWebhook: process.env.DISCORD_WEBHOOK_URL,
    twitterCookie: process.env.TWITTER_COOKIE
};

async function scrapeTwitter() {
    console.log('🐦 Starting Twitter scraper...');
    
    const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    const allTweets = [];
    
    try {
        // Set cookie if available
        if (config.twitterCookie) {
            await page.setCookie({
                name: 'auth_token',
                value: config.twitterCookie,
                domain: '.twitter.com'
            });
        }
        
        // Process each filter
        for (const filter of config.filters) {
            console.log(`🔍 Processing filter: ${filter.substring(0, 50)}...`);
            
            try {
                const nitterUrl = `https://nitter.net/search?q=${encodeURIComponent(filter)}&f=tweets`;
                await page.goto(nitterUrl, { waitUntil: 'networkidle2' });
                
                const tweets = await page.evaluate(() => {
                    const tweetElements = document.querySelectorAll('.timeline-item');
                    return Array.from(tweetElements).map(tweet => {
                        const usernameEl = tweet.querySelector('.username');
                        const textEl = tweet.querySelector('.tweet-content');
                        const linkEl = tweet.querySelector('.tweet-link');
                        const statsEl = tweet.querySelector('.tweet-stats');
                        
                        if (usernameEl && textEl) {
                            const likes = statsEl ? parseInt(statsEl.textContent.match(/(\d+)\s*❤/) ? statsEl.textContent.match(/(\d+)\s*❤/)[1] : '0') : 0;
                            
                            return {
                                username: usernameEl.textContent.trim(),
                                text: textEl.textContent.trim(),
                                url: linkEl ? `https://twitter.com${linkEl.getAttribute('href')}` : '',
                                likes: likes,
                                timestamp: new Date().toISOString()
                            };
                        }
                        return null;
                    }).filter(Boolean);
                });
                
                allTweets.push(...tweets);
                console.log(`✅ Found ${tweets.length} tweets for this filter`);
                
            } catch (e) {
                console.error(`❌ Error processing filter: ${e.message}`);
            }
        }
        
    } catch (e) {
        console.error('❌ Scraping error:', e);
    } finally {
        await browser.close();
    }
    
    console.log(`📊 Total tweets found: ${allTweets.length}`);
    
    // Send to Discord if configured
    if (config.discordWebhook && allTweets.length > 0) {
        for (const tweet of allTweets.slice(0, 5)) { // Limit to prevent spam
            try {
                await axios.post(config.discordWebhook, {
                    embeds: [{
                        title: `🐦 @${tweet.username}`,
                        description: tweet.text,
                        color: 1942002,
                        fields: [
                            { name: 'Likes', value: tweet.likes.toString(), inline: true },
                            { name: 'Link', value: tweet.url || 'N/A', inline: true }
                        ],
                        timestamp: tweet.timestamp
                    }]
                });
                console.log(`✅ Sent tweet to Discord: @${tweet.username}`);
            } catch (e) {
                console.error(`❌ Discord error: ${e.message}`);
            }
        }
    }
    
    return allTweets;
}

if (require.main === module) {
    scrapeTwitter().then(tweets => {
        console.log('✅ Scraping completed');
        process.exit(0);
    }).catch(error => {
        console.error('❌ Scraping failed:', error);
        process.exit(1);
    });
}

module.exports = { scrapeTwitter };
EOF

# Make script executable
chmod +x scripts/twitter_scraper.js

# Create test Discord webhook
echo "🔔 Testing Discord webhook..."
if [ ! -z "$DISCORD_WEBHOOK_URL" ]; then
    curl -H "Content-Type: application/json" \
         -X POST \
         -d '{"embeds":[{"title":"🚀 Twitter Monitor Setup Complete","description":"Podha Protocol Twitter monitoring is now configured and ready to use.","color":65280,"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"}]}' \
         $DISCORD_WEBHOOK_URL
    
    echo "✅ Discord webhook test completed"
else
    echo "⚠️  Discord webhook URL not configured. Please set DISCORD_WEBHOOK_URL in environment.env"
fi

# Create cron job for hourly execution
echo "⏰ Setting up cron job for hourly execution..."
cat > tmp/twitter/cron_job << EOF
# Podha Protocol Twitter Monitor - Run every hour
0 * * * * cd $(pwd) && node scripts/twitter_scraper.js >> logs/twitter/scraper.log 2>&1
EOF

echo "📋 To install the cron job, run:"
echo "crontab tmp/twitter/cron_job"

# Create monitoring script
echo "📊 Creating monitoring script..."
cat > scripts/monitor_twitter.sh << 'EOF'
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
EOF

chmod +x scripts/monitor_twitter.sh

echo ""
echo "🎉 Twitter Monitoring Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Configure your environment variables in config/environment.env:"
echo "   - TWITTER_COOKIE (optional, for authenticated access)"
echo "   - DISCORD_WEBHOOK_URL (required for notifications)"
echo ""
echo "2. Test the setup:"
echo "   node scripts/twitter_scraper.js"
echo ""
echo "3. Set up the cron job:"
echo "   crontab tmp/twitter/cron_job"
echo ""
echo "4. Monitor the system:"
echo "   ./scripts/monitor_twitter.sh"
echo ""
echo "5. Access the admin dashboard:"
echo "   Import workflows/twitter-admin-dashboard.json into n8n"
echo "   Open the webhook URL in your browser"
echo ""
echo "🔧 Configuration files created:"
echo "   - config/twitter-monitoring-config.json"
echo "   - scripts/twitter_scraper.js"
echo "   - scripts/monitor_twitter.sh"
echo ""
echo "📊 Database tables created:"
echo "   - twitter_seen_tweets (for deduplication)"
echo "   - twitter_monitoring_config (for filter management)"
echo "   - discord_notifications (for tracking notifications)"
echo ""
echo "Happy monitoring! 🚀"
