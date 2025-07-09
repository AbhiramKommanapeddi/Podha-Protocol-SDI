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
