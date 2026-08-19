# Customer Profitability & Lifetime Value Analytics

PostgreSQL + Excel analysis of 113K+ e-commerce transactions covering customer profitability, RFM segmentation, product/category/regional performance, discount impact, and shipping delays.

## Dataset
Sourced from Kaggle (e-commerce transactions dataset). Contains ~113,270 transactions across 42,047 unique customers.

## Tools Used
- **PostgreSQL** — data cleaning, aggregation, RFM segmentation, KPI calculation
- **Excel** — dashboard, executive summary, and business insights presentation

## Key Findings
- 68.06% of customers are repeat customers
- Champions (top RFM segment) contribute $894,445 in total profit
- At Risk customers still contribute $5.2M in sales and $568,793 in profit — a reactivation opportunity
- Office Supplies is the highest-profit category
- West is the highest-profit region

## Project Structure


├── customer_profitability_analysis.sql
├── Customer_Profitability_Analytics_PostgreSQL_Excel.xlsx
└── screenshots/
    ├── 01_raw_dataset.png
    ├── 02_data_cleaning.png
    ├── 03_customer_profitability.png
    ├── 04_kpi_analysis.png
    ├── 05_rfm_segmentation.png
    ├── 06_category_profitability.png
    ├── 07_monthly_analysis.png
    ├── 08_regional_profitability.png
    ├── 09_discount_analysis.png
    ├── 10_shipping_analysis.png
    └── 11_high_revenue_low_margin.png

## Screenshots
Query outputs from pgAdmin 4, showing each stage of the analysis:

| Step | Screenshot |
|---|---|
| Raw dataset row count | [View Screenshot](screenshots/01_raw_dataset.png) |
| Data cleaning (dates, margins, shipping delay) | [View Screenshot](screenshots/02_data_cleaning.png) |
| Customer profitability table | [View Screenshot](screenshots/03_customer_profitability.png) |
| Overall business KPIs | [View Screenshot](screenshots/04_kpi_analysis.png) |
| RFM segmentation results | [View Screenshot](screenshots/05_rfm_segmentation.png) |
| Category profitability | [View Screenshot](screenshots/06_category_profitability.png) |
| Monthly sales & profit trend | [View Screenshot](screenshots/07_monthly_analysis.png) |
| Regional profitability | [View Screenshot](screenshots/08_regional_profitability.png) |
| Discount bucket analysis | [View Screenshot](screenshots/09_discount_analysis.png) |
| Shipping delay analysis | [View Screenshot](screenshots/10_shipping_analysis.png) |
| High revenue / low margin outliers | [View Screenshot](screenshots/11_high_revenue_low_margin.png) |

## SQL Script Overview
1. Data quality check (missing values, record counts)
2. Data cleaning (date parsing, margin calculation, shipping delay)
3. Customer-level profitability table
4. Overall business KPIs
5. Repeat customer analysis
6. RFM segmentation (Champions, Loyal, At Risk, Lost/Inactive, etc.)
7. Product profitability
8. Category profitability
9. Monthly sales & profit trend (with MoM growth)
10. Regional profitability
11. Discount bucket analysis
12. Shipping type/delay analysis
13. High-revenue/low-margin customer outliers

## Excel Workbook Sheets
Executive Summary · Customer Profitability · RFM Segmentation · Monthly Analysis · Category Analysis · Regional Analysis · Discount Analysis · Shipping Analysis · Top Products · Segment Summary · Dashboard · Business Insights

## How to Run
1. Load the raw dataset into a PostgreSQL table named `ecommerce_raw`
2. Run `customer_profitability_analysis.sql` top to bottom
3. Export results into Excel (or connect Excel to PostgreSQL) to rebuild the dashboard

---

**Done by Raghavan Vagvala**
