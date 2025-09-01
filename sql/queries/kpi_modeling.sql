WITH date_ranges AS (
    SELECT 
        MAX(date) as max_date,
        MAX(date) - INTERVAL '30 days' as last_30_start,
        MAX(date) - INTERVAL '60 days' as prev_30_start
    FROM ads_base
),
metrics AS (
    SELECT
        -- Últimos 30 días
        SUM(CASE WHEN ab.date >= dr.last_30_start THEN ab.spend ELSE 0 END)::numeric as spend_30,
        SUM(CASE WHEN ab.date >= dr.last_30_start THEN ab.conversions ELSE 0 END)::numeric as conv_30,
        
        -- Previos 30 días
        SUM(CASE WHEN ab.date >= dr.prev_30_start AND ab.date < dr.last_30_start 
                THEN ab.spend ELSE 0 END)::numeric as spend_60,
        SUM(CASE WHEN ab.date >= dr.prev_30_start AND ab.date < dr.last_30_start 
                THEN ab.conversions ELSE 0 END)::numeric as conv_60
    FROM ads_base ab
    CROSS JOIN date_ranges dr
    WHERE ab.date >= dr.prev_30_start
)
SELECT 
    'Spend' as metric,
    ROUND(spend_30, 2) as last_30_days,
    ROUND(spend_60, 2) as prev_30_days,
    ROUND(((spend_30 - spend_60) / NULLIF(spend_60, 0)) * 100, 2) as pct_change
FROM metrics
UNION ALL
SELECT 
    'Conversions',
    conv_30,
    conv_60,
    ROUND(((conv_30 - conv_60) / NULLIF(conv_60, 0)) * 100, 2)
FROM metrics
UNION ALL
SELECT 
    'CAC',
    ROUND(spend_30 / NULLIF(conv_30, 0), 2),
    ROUND(spend_60 / NULLIF(conv_60, 0), 2),
    ROUND(((spend_30 / NULLIF(conv_30, 0)) - (spend_60 / NULLIF(conv_60, 0))) / 
          NULLIF((spend_60 / NULLIF(conv_60, 0)), 0) * 100, 2)
FROM metrics
UNION ALL
SELECT 
    'ROAS',
    ROUND((conv_30 * 100) / NULLIF(spend_30, 0), 2),
    ROUND((conv_60 * 100) / NULLIF(spend_60, 0), 2),
    ROUND((((conv_30 * 100) / NULLIF(spend_30, 0)) - ((conv_60 * 100) / NULLIF(spend_60, 0))) / 
          NULLIF(((conv_60 * 100) / NULLIF(spend_60, 0)), 0) * 100, 2)
FROM metrics;