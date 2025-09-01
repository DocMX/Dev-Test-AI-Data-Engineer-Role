# Ads Spend Analytics

This project implements a workflow for ingesting, transforming, and querying ad spending data using **PostgresDB**, **n8n**, and an LLM agent (Claude) to answer questions in natural language.

## Prerequisites

- Node.js and npm installed
- PostgreSQL installed locally

---

## Setup Instructions

I used a **local environment** for this demo. Follow these steps to reproduce:

1. **Clone the repository**
   ```bash
   git clone https://github.com/DocMX/Dev-Test-AI-Data-Engineer-Role.git
   cd <your-repo>
   ```

   Use a local environment to run these tests. Docker is omitted here, although it can be used with a different configuration not shared in this guide.

2. **Install and Run n8n**
   ```bash
   npm install -g n8n
   n8n
   ```

   Open [http://localhost:5678/](http://localhost:5678/) and log in with your credentials, or use the demo credentials:

   ```
   Username:jorgelvegahdz@gmail.com
   Password:19n8BN8760JF2Ggh91h
   ```

   > Note: Docker can also be used, but it requires additional configuration not included here.

3. **Install PostgreSQL (if not already installed)**
   
   This demo uses PostgresDB as the database.  
   - Install PostgreSQL on your system.
   - Provide your PostgreSQL credentials in the Postgres nodes inside n8n.

4. **Set Up PostgreSQL Database**
   ```sql
   CREATE DATABASE ads_db;
   ```
   Update the database connection details in n8n workflows with your PostgreSQL credentials:

   ```
   Host: localhost
   Port: 5432
   Database: ads_db
   Username: your_username
   Password: your_password
   ```

5. **Import Workflows into n8n**
   - Go to **Workflows** in the n8n interface
   - Click **Import**
   - Select workflow JSON files from the cloned repository or you can use my session with my account.
   - Configure PostgreSQL and LLM nodes with your credentials

6. **Set Up LLM Integration**
    If you're not using my pre-configured session, you will need to provide your own API credentials:
   - Obtain API credentials for your preferred LLM service (Claude)
   - Add these credentials to the appropriate nodes in the n8n workflows

---

## 📂 Dataset

File: `ads_spend.csv`  
Included columns:

- `date`
- `platform`
- `account`
- `campaign`
- `country`
- `device`
- `spend`
- `clicks`
- `impressions`
- `conversions`

---

## ⚙️ Part 1 – Ingestion (Foundation)

1. Install dependencies
2. Load `ads_spend.csv` into PostgreSQL
3. Configure n8n nodes to ingest and transform the data

---

## Part 2 – KPI Modeling (SQL)

Build queries (or dbt models) to compute:


- CAC = spend / conversions
- ROAS = (revenue / spend), assuming revenue = conversions × 100

Analysis:

- Compare last 30 days vs prior 30 days
- Show results in a compact table with absolute values and deltas (% change) 

#### The result is shown in the image named output.jpg.

---

## Part 3 – Analyst Access

Expose the metrics in one simple way:

- Provide a SQL script with parameters (date ranges)  
**OR**  
- Create a tiny API endpoint `/metrics?start&end` returning JSON  

Test endpoint:  
```
http://localhost:5678/webhook-test/metrics?start=2025-06-01&end=2025-06-30
```
 the output with the test endpoint is: 
[
  {
    "summary": "Análisis Comparativo de 30 Días",
    "table": [
      {
        "metric": "Spend",
        "last_30_days": "297128.25",
        "prev_30_days": "270325.35",
        "pct_change": "9.92"
      },
      {
        "metric": "Conversions",
        "last_30_days": "9934",
        "prev_30_days": "8388",
        "pct_change": "18.43"
      },
      {
        "metric": "CAC",
        "last_30_days": "29.91",
        "prev_30_days": "32.23",
        "pct_change": "-7.19"
      },
      {
        "metric": "ROAS",
        "last_30_days": "3.34",
        "prev_30_days": "3.10",
        "pct_change": "7.75"
      }
    ],
    "timestamp": "2025-09-01T23:47:24.397Z"
  }
]

---

# Part 4 – Agent Demo (Bonus, Optional)

This demo shows how a natural-language question can be mapped to SQL and produce results using your ingested `ads_spend.csv` data in PostgreSQL.

---

## Example Natural Language Question

> "Compare CAC and ROAS for last 30 days vs prior 30 days."

---

## n8n Workflow Setup

1. **Webhook Node** (`agent-demo-webhook`)
   - Method: `POST`
   - Path: `/webhook-test/agent-demo`
   - This node receives the natural-language question as JSON:
     ```json
     {
       "question": "Compare CAC and ROAS for last 30 days vs prior 30 days."
     }
     ```

2. **LLM Node** (`claude-agent`)
   - Purpose: Interpret the question and identify required metrics and date ranges.
   - Input: `{{$json["question"]}}`
   - Output: A structured instruction or template SQL query (see below).

3. **Postgres Node** (`execute-query`)
   - Purpose: Execute the SQL query against the PostgreSQL database containing `ads_spend.csv`.
   - Example SQL Template:
     ```sql
     WITH date_ranges AS (
       SELECT
         CURRENT_DATE AS max_date,
         CURRENT_DATE - INTERVAL '30 days' AS last_30_start,
         CURRENT_DATE - INTERVAL '60 days' AS prev_30_start
     ),
     metrics AS (
       SELECT
         SUM(CASE WHEN date >= dr.last_30_start THEN spend ELSE 0 END) AS spend_30,
         SUM(CASE WHEN date >= dr.last_30_start THEN conversions ELSE 0 END) AS conv_30,
         SUM(CASE WHEN date >= dr.prev_30_start AND date < dr.last_30_start THEN spend ELSE 0 END) AS spend_60,
         SUM(CASE WHEN date >= dr.prev_30_start AND date < dr.last_30_start THEN conversions ELSE 0 END) AS conv_60
       FROM ads_base
       CROSS JOIN date_ranges dr
     )
     SELECT
       'CAC' AS metric,
       ROUND(spend_30 / NULLIF(conv_30, 0), 2) AS last_30,
       ROUND(spend_60 / NULLIF(conv_60, 0), 2) AS prev_30,
       ROUND(((spend_30 / NULLIF(conv_30, 0)) - (spend_60 / NULLIF(conv_60, 0))) /
             NULLIF((spend_60 / NULLIF(conv_60, 0)),0) * 100, 2) AS pct_change
     FROM metrics
     UNION ALL
     SELECT
       'ROAS',
       ROUND((conv_30*100) / NULLIF(spend_30,0),2),
       ROUND((conv_60*100) / NULLIF(spend_60,0),2),
       ROUND((((conv_30*100) / NULLIF(spend_30,0)) - ((conv_60*100)/NULLIF(spend_60,0))) /
             NULLIF(((conv_60*100)/NULLIF(spend_60,0)),0) * 100, 2)
     FROM metrics;
     ```

4. **Response Node** (`send-response`)
   - Purpose: Return the query results as JSON to the user.
   - Example Output JSON:
     ```json
     {
       "summary": "Comparative Analysis of Last 30 Days",
       "table": [
         {
           "metric": "CAC",
           "last_30_days": 29.91,
           "prev_30_days": 32.23,
           "pct_change": -7.19
         },
         {
           "metric": "ROAS",
           "last_30_days": 3.34,
           "prev_30_days": 3.10,
           "pct_change": 7.75
         }
       ],
       "timestamp": "2025-09-01T23:47:24.397Z"
     }
     ```

---

## Test Endpoint

You can test the agent workflow with:

```bash
curl -X POST "http://localhost:5678/webhook-test/agent-demo" \
-H "Content-Type: application/json" \
-d '{"question": "Compare CAC and ROAS for last 30 days vs prior 30 days."}'
