#!/bin/bash

# Data analysis script for social listening data

# Set database connection from environment
source config/environment.env

echo "=== Podha Protocol Social Listening Analytics ==="
echo ""

# Get date range (last 7 days by default)
START_DATE=${1:-$(date -d '7 days ago' +%Y-%m-%d)}
END_DATE=${2:-$(date +%Y-%m-%d)}

echo "Analyzing data from $START_DATE to $END_DATE"
echo ""

# Overall statistics
echo "=== Overall Statistics ==="
psql -d $DATABASE_NAME -c "
SELECT 
    COUNT(*) as total_posts,
    COUNT(CASE WHEN sentiment = 'positive' THEN 1 END) as positive_posts,
    COUNT(CASE WHEN sentiment = 'negative' THEN 1 END) as negative_posts,
    COUNT(CASE WHEN sentiment = 'neutral' THEN 1 END) as neutral_posts,
    ROUND(AVG(sentiment_score), 2) as avg_sentiment_score
FROM social_listening_data 
WHERE DATE(created_at) BETWEEN '$START_DATE' AND '$END_DATE';
"

echo ""
echo "=== Platform Breakdown ==="
psql -d $DATABASE_NAME -c "
SELECT 
    platform,
    COUNT(*) as total_posts,
    COUNT(CASE WHEN sentiment = 'positive' THEN 1 END) as positive_posts,
    COUNT(CASE WHEN sentiment = 'negative' THEN 1 END) as negative_posts,
    ROUND(AVG(sentiment_score), 2) as avg_sentiment_score
FROM social_listening_data 
WHERE DATE(created_at) BETWEEN '$START_DATE' AND '$END_DATE'
GROUP BY platform
ORDER BY total_posts DESC;
"

echo ""
echo "=== Top Keywords ==="
psql -d $DATABASE_NAME -c "
SELECT 
    keyword,
    COUNT(*) as mentions,
    COUNT(CASE WHEN sentiment = 'positive' THEN 1 END) as positive_mentions,
    COUNT(CASE WHEN sentiment = 'negative' THEN 1 END) as negative_mentions
FROM social_listening_data
CROSS JOIN LATERAL unnest(matched_keywords) as keyword
WHERE DATE(created_at) BETWEEN '$START_DATE' AND '$END_DATE'
GROUP BY keyword
ORDER BY mentions DESC
LIMIT 10;
"

echo ""
echo "=== Recent Negative Posts ==="
psql -d $DATABASE_NAME -c "
SELECT 
    platform,
    title,
    sentiment_score,
    created_at
FROM social_listening_data 
WHERE sentiment = 'negative' 
AND DATE(created_at) BETWEEN '$START_DATE' AND '$END_DATE'
ORDER BY sentiment_score ASC, created_at DESC
LIMIT 5;
"

echo ""
echo "=== Daily Trends ==="
psql -d $DATABASE_NAME -c "
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_posts,
    COUNT(CASE WHEN sentiment = 'positive' THEN 1 END) as positive_posts,
    COUNT(CASE WHEN sentiment = 'negative' THEN 1 END) as negative_posts,
    ROUND(AVG(sentiment_score), 2) as avg_sentiment_score
FROM social_listening_data 
WHERE DATE(created_at) BETWEEN '$START_DATE' AND '$END_DATE'
GROUP BY DATE(created_at)
ORDER BY date DESC;
"

echo ""
echo "=== Alert Summary ==="
psql -d $DATABASE_NAME -c "
SELECT 
    alert_type,
    status,
    COUNT(*) as count
FROM alerts 
WHERE DATE(created_at) BETWEEN '$START_DATE' AND '$END_DATE'
GROUP BY alert_type, status
ORDER BY count DESC;
"

echo ""
echo "Analysis completed!"
echo "To export data to CSV, run:"
echo "  ./scripts/export-data.sh $START_DATE $END_DATE"
