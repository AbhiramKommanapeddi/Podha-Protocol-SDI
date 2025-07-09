#!/usr/bin/env node

const axios = require('axios');
const cheerio = require('cheerio');

// Demo configuration
const config = {
  filters: [
    'filter:blue_verified min_faves:3 Podha AND ("RWA" OR "Real World Assets" OR "Yield")',
    'filter:blue_verified min_faves:3 Solana AND ("Smart Vaults" OR "Safe Yield" OR "Podha")',
    'filter:blue_verified min_faves:3 Bitcoin AND ("tokenized treasury" OR "credit protocol" OR "RWA on-chain")',
    'filter:blue_verified min_faves:3 DeFi AND ("custodial vault" OR "delta neutral")'
  ],
  nitterInstances: [
    'https://nitter.net',
    'https://nitter.it',
    'https://nitter.42l.fr'
  ]
};

// Mock Discord webhook for demo
const mockDiscordWebhook = process.env.DISCORD_WEBHOOK_URL || 'https://discord.com/api/webhooks/demo';

console.log('🚀 Starting Podha Protocol Twitter Monitor Demo');
console.log('================================================');

async function scrapeTwitterDemo() {
  const allTweets = [];
  
  for (const filter of config.filters) {
    console.log(`\n🔍 Processing filter: ${filter.substring(0, 60)}...`);
    
    for (const nitterInstance of config.nitterInstances) {
      try {
        const searchUrl = `${nitterInstance}/search?q=${encodeURIComponent(filter)}&f=tweets`;
        console.log(`   📡 Trying: ${nitterInstance}`);
        
        const response = await axios.get(searchUrl, {
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
          },
          timeout: 10000
        });
        
        if (response.status === 200) {
          console.log(`   ✅ Successfully connected to ${nitterInstance}`);
          
          // Parse HTML (simplified for demo)
          const $ = cheerio.load(response.data);
          const tweets = $('.timeline-item').slice(0, 3); // Limit for demo
          
          tweets.each((i, element) => {
            const $tweet = $(element);
            const username = $tweet.find('.username').text().trim();
            const tweetText = $tweet.find('.tweet-content').text().trim();
            const tweetLink = $tweet.find('.tweet-link').attr('href');
            
            if (username && tweetText) {
              allTweets.push({
                id: `${username}_${Date.now()}_${i}`,
                username: username,
                text: tweetText.substring(0, 100) + '...',
                url: tweetLink ? `https://twitter.com${tweetLink}` : `https://twitter.com/${username}`,
                likes: Math.floor(Math.random() * 50) + 3, // Mock likes
                isVerified: true,
                filter: filter.split(' ')[2], // Extract main keyword
                timestamp: new Date().toISOString()
              });
            }
          });
          
          console.log(`   📊 Found ${tweets.length} tweets from this instance`);
          break; // Success, no need to try other instances
          
        }
      } catch (error) {
        console.log(`   ❌ Failed to connect to ${nitterInstance}: ${error.message}`);
        continue;
      }
    }
  }
  
  return allTweets;
}

async function sendDiscordNotification(tweet) {
  const embed = {
    title: `🐦 New Tweet from @${tweet.username}`,
    description: tweet.text,
    color: 1942002, // Twitter blue
    fields: [
      {
        name: '📊 Engagement',
        value: `❤️ ${tweet.likes} likes`,
        inline: true
      },
      {
        name: '🔗 Link',
        value: tweet.url,
        inline: true
      },
      {
        name: '🏷️ Filter',
        value: tweet.filter,
        inline: true
      }
    ],
    timestamp: tweet.timestamp,
    footer: {
      text: 'Podha Protocol Twitter Monitor',
      icon_url: 'https://abs.twimg.com/icons/apple-touch-icon-192x192.png'
    }
  };
  
  const discordMessage = {
    username: 'Podha Twitter Monitor',
    embeds: [embed]
  };
  
  console.log(`   📤 Discord notification payload:`);
  console.log(JSON.stringify(discordMessage, null, 2));
  
  // Mock sending to Discord (commented out to prevent actual sends)
  // try {
  //   await axios.post(mockDiscordWebhook, discordMessage);
  //   console.log(`   ✅ Sent Discord notification for @${tweet.username}`);
  // } catch (error) {
  //   console.log(`   ❌ Failed to send Discord notification: ${error.message}`);
  // }
}

async function runDemo() {
  try {
    console.log('\n🎯 Demo Configuration:');
    console.log(`   - Filters: ${config.filters.length} search queries`);
    console.log(`   - Nitter instances: ${config.nitterInstances.length} backup sources`);
    console.log(`   - Discord webhook: ${mockDiscordWebhook.includes('demo') ? 'Mock mode' : 'Real webhook'}`);
    
    console.log('\n🚀 Starting Twitter scraping demo...');
    const tweets = await scrapeTwitterDemo();
    
    console.log(`\n📊 Demo Results:`);
    console.log(`   - Total tweets found: ${tweets.length}`);
    console.log(`   - Unique users: ${new Set(tweets.map(t => t.username)).size}`);
    
    if (tweets.length > 0) {
      console.log('\n📱 Sample tweets found:');
      tweets.forEach((tweet, index) => {
        console.log(`\n   ${index + 1}. @${tweet.username} (${tweet.filter})`);
        console.log(`      "${tweet.text}"`);
        console.log(`      Likes: ${tweet.likes} | URL: ${tweet.url}`);
      });
      
      console.log('\n🔔 Generating Discord notifications...');
      for (const tweet of tweets.slice(0, 2)) { // Limit to 2 for demo
        await sendDiscordNotification(tweet);
      }
    } else {
      console.log('\n⚠️  No tweets found in demo mode.');
      console.log('   This could be due to:');
      console.log('   - Network connectivity issues');
      console.log('   - Nitter instances being down');
      console.log('   - Search filters not matching recent tweets');
    }
    
    console.log('\n✅ Demo completed successfully!');
    console.log('\nTo run the full system:');
    console.log('1. Configure DISCORD_WEBHOOK_URL in environment.env');
    console.log('2. Import the n8n workflows');
    console.log('3. Run: npm run twitter-scrape');
    console.log('4. Set up cron job for hourly execution');
    
  } catch (error) {
    console.error('\n❌ Demo failed:', error.message);
  }
}

// Run the demo
runDemo();
