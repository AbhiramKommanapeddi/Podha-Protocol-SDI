# API Documentation - Podha Protocol Social Listening

## Overview
This document provides details about the APIs and data structures used in the social listening workflow.

## Data Structure

### Social Listening Data Object
```json
{
  "platform": "Reddit",
  "source": "r/RealWorldAssets",
  "title": "New RWA Protocol Discussion",
  "content": "Full content of the post or article",
  "url": "https://reddit.com/r/RealWorldAssets/post123",
  "author": "crypto_enthusiast",
  "published": "2025-01-15T10:30:00Z",
  "matched_keywords": ["real world assets", "rwa", "tokenization"],
  "sentiment": "positive",
  "sentiment_score": 2,
  "created_at": "2025-01-15T10:35:00Z"
}
```

### Keyword Trends Object
```json
{
  "keyword": "real world assets",
  "mention_count": 15,
  "positive_mentions": 8,
  "negative_mentions": 2,
  "neutral_mentions": 5,
  "date": "2025-01-15",
  "avg_sentiment_score": 1.2
}
```

### Platform Statistics Object
```json
{
  "platform": "Reddit",
  "total_posts": 45,
  "positive_posts": 20,
  "negative_posts": 8,
  "neutral_posts": 17,
  "date": "2025-01-15"
}
```

## External APIs Used

### 1. Reddit API (Public JSON)
- **Endpoint**: `https://www.reddit.com/r/{subreddit}/new.json`
- **Rate Limit**: 1 request per second
- **Authentication**: None required
- **Response Format**: JSON

#### Example Request:
```bash
curl -H "User-Agent: PodhaProtocol-SocialListener/1.0" \
     https://www.reddit.com/r/RealWorldAssets/new.json
```

#### Response Structure:
```json
{
  "data": {
    "children": [
      {
        "data": {
          "title": "Post title",
          "selftext": "Post content",
          "author": "username",
          "score": 15,
          "num_comments": 3,
          "permalink": "/r/subreddit/comments/...",
          "created_utc": 1642234567,
          "subreddit_name_prefixed": "r/RealWorldAssets"
        }
      }
    ]
  }
}
```

### 2. News API (newsapi.org)
- **Endpoint**: `https://newsapi.org/v2/everything`
- **Rate Limit**: 1000 requests/day (free tier)
- **Authentication**: API Key in header
- **Response Format**: JSON

#### Example Request:
```bash
curl -H "X-API-Key: YOUR_API_KEY" \
     "https://newsapi.org/v2/everything?q=real%20world%20assets&sortBy=publishedAt"
```

#### Response Structure:
```json
{
  "articles": [
    {
      "title": "Article title",
      "description": "Article description",
      "url": "https://example.com/article",
      "source": {
        "name": "Source Name"
      },
      "author": "Author Name",
      "publishedAt": "2025-01-15T10:00:00Z"
    }
  ]
}
```

### 3. YouTube Data API v3
- **Endpoint**: `https://www.googleapis.com/youtube/v3/search`
- **Rate Limit**: 10,000 units/day
- **Authentication**: API Key in query parameter
- **Response Format**: JSON

#### Example Request:
```bash
curl "https://www.googleapis.com/youtube/v3/search?part=snippet&q=real%20world%20assets&type=video&key=YOUR_API_KEY"
```

#### Response Structure:
```json
{
  "items": [
    {
      "id": {
        "videoId": "abc123"
      },
      "snippet": {
        "title": "Video title",
        "description": "Video description",
        "channelTitle": "Channel Name",
        "publishedAt": "2025-01-15T10:00:00Z",
        "thumbnails": {
          "default": {
            "url": "https://i.ytimg.com/vi/abc123/default.jpg"
          }
        }
      }
    }
  ]
}
```

### 4. RSS Feeds
Various RSS feeds are monitored for blog posts and news articles.

#### Medium RSS
- **Endpoint**: `https://medium.com/feed/tag/{tag}`
- **Format**: RSS XML
- **Authentication**: None required

#### CoinTelegraph RSS
- **Endpoint**: `https://cointelegraph.com/rss`
- **Format**: RSS XML
- **Authentication**: None required

#### CoinDesk RSS
- **Endpoint**: `https://www.coindesk.com/arc/outboundfeeds/rss/`
- **Format**: RSS XML
- **Authentication**: None required

## Internal API Endpoints

### Webhook Endpoint
The system can send data to external webhooks for real-time integration.

#### Request Format:
```json
{
  "event": "new_post",
  "data": {
    "platform": "Reddit",
    "title": "Post title",
    "sentiment": "positive",
    "matched_keywords": ["rwa", "tokenization"],
    "url": "https://example.com/post"
  },
  "timestamp": "2025-01-15T10:35:00Z"
}
```

### Alert Webhook
Sends alerts for negative sentiment or high-volume events.

#### Request Format:
```json
{
  "event": "alert",
  "alert_type": "negative_sentiment",
  "data": {
    "platform": "Reddit",
    "title": "Concerning post title",
    "sentiment_score": -3,
    "url": "https://example.com/post"
  },
  "timestamp": "2025-01-15T10:35:00Z"
}
```

## Database API

### Query Examples

#### Get Recent Posts
```sql
SELECT * FROM social_listening_data 
WHERE created_at >= NOW() - INTERVAL '24 hours' 
ORDER BY created_at DESC;
```

#### Get Keyword Trends
```sql
SELECT keyword, SUM(mention_count) as total_mentions 
FROM keyword_trends 
WHERE date >= CURRENT_DATE - INTERVAL '7 days' 
GROUP BY keyword 
ORDER BY total_mentions DESC;
```

#### Get Platform Statistics
```sql
SELECT platform, 
       SUM(total_posts) as total_posts,
       SUM(positive_posts) as positive_posts,
       SUM(negative_posts) as negative_posts
FROM platform_stats 
WHERE date >= CURRENT_DATE - INTERVAL '7 days' 
GROUP BY platform;
```

## Rate Limiting

### Implementation Strategy
- **Exponential Backoff**: Implemented for API failures
- **Request Queuing**: Prevents overwhelming APIs
- **Respect Headers**: Follows API rate limit headers
- **Monitoring**: Tracks API usage quotas

### Rate Limits by Platform
- **Reddit**: 1 request per second
- **News API**: 1000 requests/day
- **YouTube**: 10,000 units/day
- **RSS Feeds**: No specific limits (be respectful)

## Error Handling

### Common Error Scenarios
1. **API Rate Limit Exceeded**
   - Response: HTTP 429
   - Action: Exponential backoff and retry

2. **API Key Invalid**
   - Response: HTTP 401/403
   - Action: Alert administrator

3. **Network Timeout**
   - Response: Timeout error
   - Action: Retry with backoff

4. **Database Connection Error**
   - Response: Connection refused
   - Action: Retry and alert

### Error Response Format
```json
{
  "error": true,
  "message": "Rate limit exceeded",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 60,
  "timestamp": "2025-01-15T10:35:00Z"
}
```

## Security Considerations

### API Key Management
- Store in environment variables
- Use n8n credential system
- Rotate keys regularly
- Monitor for unauthorized usage

### Data Privacy
- No personal data collection
- Public data only
- Comply with platform terms
- Respect user privacy

### Rate Limiting Protection
- Implement circuit breakers
- Monitor quotas
- Alert on approaching limits
- Graceful degradation

## Monitoring and Metrics

### Key Metrics
- API response times
- Success/failure rates
- Data volume processed
- Storage usage
- Alert frequency

### Health Checks
- Database connectivity
- API availability
- Workflow execution status
- Data freshness

### Alerting
- API failures
- High error rates
- Storage issues
- Performance degradation

## Future Enhancements

### Additional APIs
- Discord API integration
- Telegram Bot API
- LinkedIn API
- Twitter API alternatives

### Advanced Features
- Machine learning sentiment analysis
- Image/video content analysis
- Real-time streaming
- Advanced analytics

### Scalability Improvements
- Microservices architecture
- Kafka for event streaming
- Redis for caching
- Kubernetes deployment
