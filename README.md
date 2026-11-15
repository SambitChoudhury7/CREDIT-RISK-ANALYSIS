# CREDIT-RISK-ANALYSIS

## Overview

An end-to-end analysis of a synthetic bank loan portfolio using PostgreSQL and Power BI.

The project analyzes 50,000 loans to understand where credit risk sits, how it changes over time, and how much worse losses could get in a recession.

The dataset is synthetic, and the risk numbers (PD, LGD, expected loss) came pre-calculated. The project analyzes those risk outputs; it does not build risk models.

## Tools

Excel (first look at the files) → PostgreSQL (14 business questions and KPI calculations) → Power BI (dashboard and visualization)

## Data

Synthetic credit risk dataset with five tables:

- Loans: 50,000 loans with sector, rating, loan size, PD, LGD, expected loss, and default outcome
- Monthly portfolio metrics: 120 months (2015 to 2024)
- Stress scenarios: 6 scenarios x 10 sectors
- Vintages (loan batches): 36 batches tracked for 60 months each
- Credit ratings: 17,939 yearly grade checks on companies

The dataset is included in this repository.

## Key Terms

- **PD (Probability of Default):** chance a borrower stops paying
- **EAD (Exposure at Default):** money still owed when they stop paying
- **LGD (Loss Given Default):** share of that amount the bank never recovers
- **EL (Expected Loss):** PD x LGD x EAD

## Methodology

- Reviewed the files for blanks, duplicates, and inconsistencies, and documented the data quirks found
- Wrote 14 SQL questions in PostgreSQL covering trends, risk by segment, stress scenarios, and loan batches
- Used GROUP BY, window functions (RANK, LAG), subqueries, CTEs, JOINs, and CASE
- Compared normal vs recession (stress) scenarios
- Built a one-page Power BI dashboard to present the key findings

## Key Findings

### Overall Risk

- Total exposure (EAD): 164.93bn; total expected loss: 1.92bn (EL rate 1.17%)
- 13.9% of loans defaulted
- The monthly EL rate stayed between about 1.1% and 1.25%, rose for 10 straight months in 2020 (peak 1.26% in Dec 2020), and slowly fell to 1.13% by end of 2024

### Where the Risk Comes From

- Credit rating is what separates default risk: average PD is 0.018% for AAA and 14.2% for CCC (about 786x), rising with no reversals
- Sector, collateral, and leverage barely change default odds: PD by sector is 2.15% to 2.36%, default rate by collateral type is 13.8% to 14.0%, and PD by leverage band is about 2.2% to 2.3%
- About 24% of loans in every sector have above-average PD, so risky loans are not concentrated in one industry
- Financials has the highest expected loss (16.4% of the total; top three sectors about 43%) because its loans are much larger (about 6.0M average vs 0.8M in Retail), not because its borrowers default more

### Predicted vs Actual Defaults

- Predicted one-year PD is about 2.3%, but about 14% of loans actually defaulted
- Loans last 54 months on average, and 2.3% x 4.5 years is roughly 10%, so most of the gap is a time-window difference rather than a broken model

### Recession (Stress) Scenarios

- Under the COVID-like scenario, expected loss rises 129% to 193% by sector; Financials goes from about $316M to $925M
- Financials, Real Estate, Telecom, and Energy are the most sensitive
- PD multiplies 2.3x to 2.8x, while LGD rises only 1.1x to 1.17x and exposure does not change, so the damage comes mostly from more defaults

### Loan Batches (Vintages)

- Loans issued from 2019Q1 to 2020Q1 were the weakest batches: worse than the age-matched average in 50 to 60 of 60 months, reaching about 19% to 22% cumulative default by month 60 versus a 13.1% average
- Batches from 2021 onward were rarely above average

### Recovery After Default

- Recovery varies a lot by sector: Real Estate 54.5% and Utilities 53.1% at the top, Technology 35.0% and Retail 36.7% at the bottom
- Sector-level rating downgrades did not line up with loan default rates, so they did not work as an early-warning signal in this data

## Recommendations

These are based on this synthetic dataset.

- Use credit rating as the main lever for pricing and limits, since it is what separates default risk in this portfolio
- Watch concentration in Financials and consider loan-size limits, because its risk comes from size rather than borrower quality
- For capital planning, focus on Financials, Real Estate, Telecom, and Energy, which are the most sensitive to a recession
- Assume lower recoveries for Technology, Retail, and Consumer loans when estimating losses
- Review lending standards for loans issued in 2019 to early 2020
- Compare predicted PD with default rates over the same time horizon, so a one-year forecast is not judged against a lifetime outcome

## Dashboard

The Power BI dashboard includes:

- Total EAD
- Total EL
- EL Rate
- Default Rate
- EL Rate by Month
- Average PD by Credit Rating
- Total EL by Sector
- EL Base vs Stress by Sector
- Vintages Above Average at the Same Age
- Sector and Scenario slicers

### Dashboard Preview

![Credit Risk Dashboard](https://github.com/user-attachments/assets/2b695690-9744-4731-ba42-65ae35ac58b6)



## Limitations

- The data is synthetic, so patterns reflect how it was generated
- PD, LGD, and expected loss were pre-calculated; this project analyzes them and does not build risk models
- `maturity_date` is capped at 2024-12-31 for about 39% of loans, which makes some defaults appear after maturity
- Base expected loss in the stress table does not match its own PD x LGD x EAD, so baseline scenario rows show small negative increases and were ignored
- Recovery rate equals 1 minus LGD for every defaulted loan, so recovery results are not an independent test of the LGD estimates
- Recent loan batches have rows past 2024, so some late-age values may be modelled (not verified)
- Ratings and loans cannot be linked per borrower, only by sector, and they use different time units, so only sector order is compared
- No statistical significance testing was done; small differences are hints, not proven differences
