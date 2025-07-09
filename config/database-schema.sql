-- Social Listening Database Schema
-- PostgreSQL Database Setup

-- Create database
CREATE DATABASE social_listening;

-- Use the database
\c social_listening;

-- Create main table for social listening data
CREATE TABLE social_listening_data
(
    id SERIAL PRIMARY KEY,
    platform VARCHAR(50) NOT NULL,
    source VARCHAR(255) NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    url TEXT,
    author VARCHAR(255),
    published TIMESTAMP,
    matched_keywords TEXT
    [],
    sentiment VARCHAR
    (20) DEFAULT 'neutral',
    sentiment_score INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

    -- Create indexes for better performance
    CREATE INDEX idx_platform ON social_listening_data(platform);
    CREATE INDEX idx_sentiment ON social_listening_data(sentiment);
    CREATE INDEX idx_published ON social_listening_data(published);
    CREATE INDEX idx_created_at ON social_listening_data(created_at);
    CREATE INDEX idx_keywords ON social_listening_data USING GIN
    (matched_keywords);

    -- Create table for tracking keyword trends
    CREATE TABLE keyword_trends
    (
        id SERIAL PRIMARY KEY,
        keyword VARCHAR(255) NOT NULL,
        mention_count INTEGER DEFAULT 0,
        positive_mentions INTEGER DEFAULT 0,
        negative_mentions INTEGER DEFAULT 0,
        neutral_mentions INTEGER DEFAULT 0,
        date DATE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Create index for keyword trends
    CREATE INDEX idx_keyword_date ON keyword_trends(keyword, date);

    -- Create table for platform statistics
    CREATE TABLE platform_stats
    (
        id SERIAL PRIMARY KEY,
        platform VARCHAR(50) NOT NULL,
        total_posts INTEGER DEFAULT 0,
        positive_posts INTEGER DEFAULT 0,
        negative_posts INTEGER DEFAULT 0,
        neutral_posts INTEGER DEFAULT 0,
        date DATE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Create index for platform stats
    CREATE INDEX idx_platform_date ON platform_stats(platform, date);

    -- Create table for alerts
    CREATE TABLE alerts
    (
        id SERIAL PRIMARY KEY,
        alert_type VARCHAR(50) NOT NULL,
        message TEXT NOT NULL,
        data_id INTEGER REFERENCES social_listening_data(id),
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        resolved_at TIMESTAMP
    );

    -- Create index for alerts
    CREATE INDEX idx_alert_status ON alerts(status);
    CREATE INDEX idx_alert_created ON alerts(created_at);

    -- Create view for daily summary
    CREATE VIEW daily_summary
    AS
        SELECT
            DATE(created_at) as date,
            platform,
            COUNT(*) as total_posts,
            COUNT(CASE WHEN sentiment = 'positive' THEN 1 END) as positive_posts,
            COUNT(CASE WHEN sentiment = 'negative' THEN 1 END) as negative_posts,
            COUNT(CASE WHEN sentiment = 'neutral' THEN 1 END) as neutral_posts,
            AVG(sentiment_score) as avg_sentiment_score
        FROM social_listening_data
        GROUP BY DATE(created_at), platform
        ORDER BY date DESC, platform;

    -- Create view for keyword analysis
    CREATE VIEW keyword_analysis
    AS
        SELECT
            keyword,
            COUNT(*) as total_mentions,
            COUNT(CASE WHEN sentiment = 'positive' THEN 1 END) as positive_mentions,
            COUNT(CASE WHEN sentiment = 'negative' THEN 1 END) as negative_mentions,
            COUNT(CASE WHEN sentiment = 'neutral' THEN 1 END) as neutral_mentions,
            AVG(sentiment_score) as avg_sentiment_score
        FROM social_listening_data
CROSS JOIN LATERAL unnest(matched_keywords)
    as keyword
GROUP BY keyword
ORDER BY total_mentions DESC;

    -- Create function to update trends
    CREATE OR REPLACE FUNCTION update_keyword_trends
    ()
RETURNS TRIGGER AS $$
    BEGIN
        -- Update keyword trends for today
        INSERT INTO keyword_trends
            (keyword, mention_count, positive_mentions, negative_mentions, neutral_mentions, date)
        SELECT
            keyword,
            1,
            CASE WHEN NEW.sentiment = 'positive' THEN 1 ELSE 0 END,
            CASE WHEN NEW.sentiment = 'negative' THEN 1 ELSE 0 END,
            CASE WHEN NEW.sentiment = 'neutral' THEN 1 ELSE 0 END,
            CURRENT_DATE
        FROM unnest(NEW.matched_keywords) as keyword
        ON CONFLICT
        (keyword, date) DO
        UPDATE SET
        mention_count = keyword_trends.mention_count + 1,
        positive_mentions = keyword_trends.positive_mentions + CASE WHEN NEW.sentiment = 'positive' THEN 1 ELSE 0 END,
        negative_mentions = keyword_trends.negative_mentions + CASE WHEN NEW.sentiment = 'negative' THEN 1 ELSE 0 END,
        neutral_mentions = keyword_trends.neutral_mentions + CASE WHEN NEW.sentiment = 'neutral' THEN 1 ELSE 0 END;

        -- Update platform stats
        INSERT INTO platform_stats
            (platform, total_posts, positive_posts, negative_posts, neutral_posts, date)
        VALUES
            (
                NEW.platform,
                1,
                CASE WHEN NEW.sentiment = 'positive' THEN 1 ELSE 0 END,
                CASE WHEN NEW.sentiment = 'negative' THEN 1 ELSE 0 END,
                CASE WHEN NEW.sentiment = 'neutral' THEN 1 ELSE 0 END,
                CURRENT_DATE
    )
        ON CONFLICT
        (platform, date) DO
        UPDATE SET
        total_posts = platform_stats.total_posts + 1,
        positive_posts = platform_stats.positive_posts + CASE WHEN NEW.sentiment = 'positive' THEN 1 ELSE 0 END,
        negative_posts = platform_stats.negative_posts + CASE WHEN NEW.sentiment = 'negative' THEN 1 ELSE 0 END,
        neutral_posts = platform_stats.neutral_posts + CASE WHEN NEW.sentiment = 'neutral' THEN 1 ELSE 0 END;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    -- Create trigger
    CREATE TRIGGER update_trends_trigger
    AFTER
    INSERT ON
    social_listening_data
    FOR
    EACH
    ROW
    EXECUTE FUNCTION update_keyword_trends
    ();

    -- Create unique constraints
    ALTER TABLE keyword_trends ADD CONSTRAINT unique_keyword_date UNIQUE (keyword, date);
    ALTER TABLE platform_stats ADD CONSTRAINT unique_platform_date UNIQUE (platform, date);

    -- Insert sample data for testing
    INSERT INTO social_listening_data
        (platform, source, title, content, url, author, published, matched_keywords, sentiment, sentiment_score)
    VALUES
        ('Reddit', 'r/RealWorldAssets', 'New RWA Protocol Launch', 'Excited about this new real world assets protocol', 'https://reddit.com/r/RealWorldAssets/post1', 'crypto_enthusiast', '2025-01-01 10:00:00', '{"real world assets", "rwa"}', 'positive', 2),
        ('Medium', 'Medium', 'The Future of Asset Tokenization', 'Asset tokenization is revolutionizing finance', 'https://medium.com/post1', 'blockchain_writer', '2025-01-01 11:00:00', '{"asset tokenization", "tokenized assets"}', 'positive', 3),
        ('News', 'CoinTelegraph', 'RWA Market Concerns', 'Some concerns about the RWA market stability', 'https://cointelegraph.com/news1', 'news_reporter', '2025-01-01 12:00:00', '{"real world assets", "rwa"}', 'negative', -1),
        ('Twitter', 'PodhaBot', 'Exciting developments in RWA', 'The RWA space is evolving rapidly!', 'https://twitter.com/PodhaBot/status/1', 'podha_bot', '2025-01-01 09:00:00', '{"RWA", "Real World Assets"}', 'positive', 4),
        ('Twitter', 'SolanaBot', 'Solana\'
    s Smart Vaults are live', 'Check out Solana\'s new smart vaults for RWAs', 'https://twitter.com/SolanaBot/status/1', 'solana_bot', '2025-01-01 08:30:00', '{"Solana", "Smart Vaults"}', 'positive', 5),
    ('Twitter', 'DeFiWatcher', 'DeFi custodial vaults explained', 'Understanding the basics of custodial vaults in DeFi', 'https://twitter.com/DeFiWatcher/status/1', 'defi_expert', '2025-01-01 07:45:00', '{"DeFi", "custodial vault"}', 'neutral', 0),
    ('Twitter', 'CryptoNews', 'Bitcoin RWA on-chain', 'How Bitcoin is enabling RWAs on-chain', 'https://twitter.com/CryptoNews/status/1', 'crypto_news', '2025-01-01 06:00:00', '{"Bitcoin", "RWA on-chain"}', 'positive', 3),
    ('Twitter', 'YieldGuru', 'Maximizing yield with Podha', 'Strategies for yield farming with Podha', 'https://twitter.com/YieldGuru/status/1', 'yield_strategist', '2025-01-01 05:30:00', '{"Podha", "Yield"}', 'positive', 4),
    ('Twitter', 'MarketInsights', 'RWA market stability concerns', 'Analyzing the stability of the RWA market', 'https://twitter.com/MarketInsights/status/1', 'market_analyst', '2025-01-01 04:00:00', '{"RWA", "market stability"}', 'negative', -2),
    ('Twitter', 'FinanceDaily', 'The rise of tokenized treasuries', 'Tokenized treasuries are gaining traction', 'https://twitter.com/FinanceDaily/status/1', 'finance_daily', '2025-01-01 03:15:00', '{"tokenized treasury", "RWA"}', 'positive', 3),
    ('Twitter', 'WealthSimple', 'Delta neutral strategies in DeFi', 'Exploring delta neutral strategies', 'https://twitter.com/WealthSimple/status/1', 'wealth_simple', '2025-01-01 02:45:00', '{"delta neutral", "DeFi"}', 'neutral', 0),
    ('Twitter', 'CryptoSavvy', 'Understanding RWA risks', 'What you need to know about RWA risks', 'https://twitter.com/CryptoSavvy/status/1', 'crypto_savvy', '2025-01-01 01:30:00', '{"RWA", "risks"}', 'negative', -1),
    ('Twitter', 'InvestSmart', 'Long-term potential of RWAs', 'RWAs as a long-term investment', 'https://twitter.com/InvestSmart/status/1', 'investor', '2025-01-01 00:00:00', '{"RWA", "investment"}', 'positive', 2);

    -- Create table for tracking seen tweets (for deduplication)
    CREATE TABLE twitter_seen_tweets
    (
        id SERIAL PRIMARY KEY,
        tweet_id VARCHAR(255) UNIQUE NOT NULL,
        username VARCHAR(255) NOT NULL,
        tweet_text TEXT,
        tweet_url TEXT,
        scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Create index for fast lookups
    CREATE INDEX idx_tweet_id ON twitter_seen_tweets(tweet_id);
    CREATE INDEX idx_scraped_at ON twitter_seen_tweets(scraped_at);

    -- Create table for Twitter monitoring configuration
    CREATE TABLE twitter_monitoring_config
    (
        id SERIAL PRIMARY KEY,
        filter_name VARCHAR(255) NOT NULL,
        search_query TEXT NOT NULL,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Insert default Twitter search filters
    INSERT INTO twitter_monitoring_config
        (filter_name, search_query)
    VALUES
        ('Podha RWA', 'filter:blue_verified min_faves:3 Podha AND ("RWA" OR "Real World Assets" OR "Yield")'),
        ('Solana Smart Vaults', 'filter:blue_verified min_faves:3 Solana AND ("Smart Vaults" OR "Safe Yield" OR "Podha")'),
        ('Bitcoin RWA', 'filter:blue_verified min_faves:3 Bitcoin AND ("tokenized treasury" OR "credit protocol" OR "RWA on-chain")'),
        ('DeFi Vaults', 'filter:blue_verified min_faves:3 DeFi AND ("custodial vault" OR "delta neutral")');

    -- Create table for Discord notifications log
    CREATE TABLE discord_notifications
    (
        id SERIAL PRIMARY KEY,
        tweet_id VARCHAR(255),
        username VARCHAR(255),
        message_content TEXT,
        discord_response TEXT,
        status VARCHAR(50) DEFAULT 'sent',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Create index for Discord notifications
    CREATE INDEX idx_discord_tweet_id ON discord_notifications(tweet_id);
    CREATE INDEX idx_discord_status ON discord_notifications(status);
