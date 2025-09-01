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
   git clone https://github.com/<your-username>/<your-repo>.git
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
   Username: admin@example.com
   Password: password123
   ```

   > Note: Docker can also be used, but it requires additional configuration not included here.

3. **Install PostgreSQL (if not already installed)**
   
   This demo uses PostgresDB as the database.  
   - Install PostgreSQL on your system.
   - Provide your PostgreSQL credentials in the Postgres nodes inside n8n.

4. **Set Up PostgreSQL Database**
   ```sql
   CREATE DATABASE ad_spend_db;
   ```
   Update the database connection details in n8n workflows with your PostgreSQL credentials:

   ```
   Host: localhost
   Port: 5432
   Database: ad_spend_db
   Username: your_username
   Password: your_password
   ```

5. **Import Workflows into n8n**
   - Go to **Workflows** in the n8n interface
   - Click **Import**
   - Select workflow JSON files from the cloned repository
   - Configure PostgreSQL and LLM nodes with your credentials

6. **Set Up LLM Integration**
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

---

## Part 4 – Agent Demo (Bonus, Optional)

This section demonstrates how a natural-language query can be mapped to SQL and return results using the ingested `ads_spend.csv` dataset.

### Example Natural Language Query

> **"Compare CAC and ROAS for last 30 days vs prior 30 days."**

Test endpoint:
```bash
curl -X POST "http://localhost:5678/webhook-test/agent-demo" -H "Content-Type: application/json" -d '{"question": "Compare CAC and ROAS for last 30 days vs prior 30 days."}'
```