#!/bin/bash

# Export social listening data to CSV

source config/environment.env

START_DATE=${1:-$(date -d '7 days ago' +%Y-%m-%d)}
END_DATE=${2:-$(date +%Y-%m-%d)}
OUTPUT_DIR="data/exports"

mkdir -p $OUTPUT_DIR

echo "Exporting social listening data from $START_DATE to $END_DATE..."

# Export main data
psql -d $DATABASE_NAME -c "
COPY (
    SELECT 
        platform,
        source,
        title,
        content,
        url,
        author,
        published,
        array_to_string(matched_keywords, ';') as matched_keywords,
        sentiment,
        sentiment_score,
        created_at
    FROM social_listening_data 
    WHERE DATE(created_at) BETWEEN '$START_DATE' AND '$END_DATE'
    ORDER BY created_at DESC
) TO STDOUT WITH CSV HEADER;
" > "$OUTPUT_DIR/social_listening_data_${START_DATE}_to_${END_DATE}.csv"

# Export keyword trends
psql -d $DATABASE_NAME -c "
COPY (
    SELECT 
        keyword,
        mention_count,
        positive_mentions,
        negative_mentions,
        neutral_mentions,
        date
    FROM keyword_trends 
    WHERE date BETWEEN '$START_DATE' AND '$END_DATE'
    ORDER BY date DESC, mention_count DESC
) TO STDOUT WITH CSV HEADER;
" > "$OUTPUT_DIR/keyword_trends_${START_DATE}_to_${END_DATE}.csv"

# Export platform stats
psql -d $DATABASE_NAME -c "
COPY (
    SELECT 
        platform,
        total_posts,
        positive_posts,
        negative_posts,
        neutral_posts,
        date
    FROM platform_stats 
    WHERE date BETWEEN '$START_DATE' AND '$END_DATE'
    ORDER BY date DESC, total_posts DESC
) TO STDOUT WITH CSV HEADER;
" > "$OUTPUT_DIR/platform_stats_${START_DATE}_to_${END_DATE}.csv"

echo "Data exported to $OUTPUT_DIR/"
echo "Files created:"
echo "  - social_listening_data_${START_DATE}_to_${END_DATE}.csv"
echo "  - keyword_trends_${START_DATE}_to_${END_DATE}.csv"
echo "  - platform_stats_${START_DATE}_to_${END_DATE}.csv"
