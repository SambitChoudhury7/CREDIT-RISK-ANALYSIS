-- 1. LOAN PORTFOLIO 
CREATE TABLE loan_portfolio (
    loan_id             TEXT PRIMARY KEY,
    origination_date    DATE,
    maturity_date       DATE,
    maturity_months     INT,
    sector              TEXT,
    loan_type           TEXT,
    collateral          TEXT,
    initial_rating      TEXT,
    credit_score        INT,
    ead                 NUMERIC,
    coupon_rate         NUMERIC,
    leverage            NUMERIC,
    interest_coverage   NUMERIC,
    debt_to_equity      NUMERIC,
    pd_annual           NUMERIC,
    lgd                 NUMERIC,
    el                  NUMERIC,
    unexpected_loss     NUMERIC,
    rwa                 NUMERIC,
    defaulted           INT,
    default_date        DATE,
    survival_months     INT,
    recovery_rate       NUMERIC,
    loss_given_default  NUMERIC
);

-- 2. MACRO STRESS SCENARIOS 
CREATE TABLE stress_scenarios (
    scenario                TEXT,
    gdp_shock_pp            NUMERIC,
    unemp_shock_pp          NUMERIC,
    rate_shock_pp           NUMERIC,
    credit_spread_bps       INT,
    sector                  TEXT,
    base_pd                 NUMERIC,
    stressed_pd             NUMERIC,
    pd_uplift_pp            NUMERIC,
    pd_multiplier           NUMERIC,
    base_lgd                NUMERIC,
    stressed_lgd            NUMERIC,
    total_ead               NUMERIC,
    expected_loss_base      NUMERIC,
    expected_loss_stress    NUMERIC,
    el_increase_pct         NUMERIC
);

-- 3. VINTAGE ANALYSIS 
CREATE TABLE vintage_analysis (
    vintage                     TEXT,
    months_on_books             INT,
    n_loans_originated          INT,
    n_active                    INT,
    n_defaulted_cumulative      INT,
    cumulative_default_rate     NUMERIC,
    marginal_default_rate       NUMERIC,
    avg_pd_at_origination       NUMERIC,
    avg_credit_score            NUMERIC
);

-- 4. PORTFOLIO METRICS 
CREATE TABLE portfolio_metrics (
    Dates               DATE PRIMARY KEY,
    n_active_loans      INT,
    total_ead           NUMERIC,
    total_el            NUMERIC,
    total_rwa           NUMERIC,
    el_rate             NUMERIC,
    avg_pd              NUMERIC,
    avg_lgd             NUMERIC,
    var_99              NUMERIC,
    cvar_995            NUMERIC,
    sector_hhi          NUMERIC,
    new_defaults        INT,
    gdp_growth          NUMERIC,
    unemployment        NUMERIC,
    policy_rate         NUMERIC,
    credit_spread_bps   NUMERIC
);

-- 5. CREDIT RATINGS 
CREATE TABLE credit_ratings (
    issuer_id       TEXT,
    sector          TEXT,
    years            INT,
    from_rating     TEXT,
    to_rating       TEXT,
    upgraded        INT,
    downgraded      INT,
    defaulted       INT,
    notches_moved   INT
);

select * from loan_portfolio
select * from stress_scenarios
select * from vintage_analysis
select * from portfolio_metrics
select * from credit_ratings

-------------------------------------------------------------------------------------------
                   ----- HOW HAS EL RATE CHANGED YEAR BY YEAR? -------
-------------------------------------------------------------------------------------------
SELECT EXTRACT(YEAR FROM DATES) AS YEARS , ROUND(AVG(EL_RATE),5) AS AVG_EL_RATE FROM PORTFOLIO_METRICS
GROUP BY YEARS
ORDER BY YEARS

-------------------------------------------------------------------------------------------
                   ----- MOST RISKIEST SECTORS -------
-------------------------------------------------------------------------------------------

--------------------- BY EXPECTED LOSS -----------------------------				   

SELECT SECTOR, AVG(EL), RANK() OVER (ORDER BY AVG(EL) DESC) AS RISK_RANK
FROM LOAN_PORTFOLIO
GROUP BY SECTOR

-------------------- BY PROBABILITY OF DEFAULT ---------------------

SELECT SECTOR, ROUND(AVG(PD_ANNUAL), 5), RANK() OVER (ORDER BY AVG(PD_ANNUAL) DESC) AS PD_RANK
FROM LOAN_PORTFOLIO
GROUP BY SECTOR

-------------------- BY EXPOSURE AT DEFAULT ------------------------

SELECT SECTOR, ROUND(AVG(EAD), 3), RANK() OVER (ORDER BY AVG(EAD) DESC) AS EAD_RANK
FROM LOAN_PORTFOLIO
GROUP BY SECTOR

-------------------------------------------------------------------------------------------
                   ----- DO OUR CREDIT RATINGS ACTUALLY REFLECT RISK? -------
-------------------------------------------------------------------------------------------
SELECT INITIAL_RATING, ROUND(AVG(PD_ANNUAL),5) AS AVG_PD, ROUND(AVG(EL), 2) AS AVG_EL,
RANK () OVER (ORDER BY AVG(PD_ANNUAL) DESC) AS RISK_RANK
FROM LOAN_PORTFOLIO
GROUP BY INITIAL_RATING
ORDER BY RISK_RANK

-------------------------------------------------------------------------------------------
  ----- DO UNSECURED LOANS ACTUALLY DEFAULT MORE THAN LOANS BACKED BY SOMETHING? -------
-------------------------------------------------------------------------------------------
SELECT LOAN_TYPE, COUNT(*) AS TOTAL_LOANS, SUM(DEFAULTED) AS TOTAL_DEFAULTS,
ROUND(SUM(DEFAULTED):: numeric *100/COUNT(*),2) AS DEFAULT_RATE
FROM LOAN_PORTFOLIO
GROUP BY LOAN_TYPE
ORDER BY DEFAULT_RATE DESC

---------------- BY COLLATERAL----------------------

SELECT COLLATERAL, COUNT(*) AS TOTAL_LOANS, SUM(DEFAULTED) AS TOTAL_DEFAULTS,
ROUND(SUM(DEFAULTED):: numeric *100/COUNT(*),2) AS DEFAULT_RATE
FROM LOAN_PORTFOLIO
GROUP BY COLLATERAL
ORDER BY DEFAULT_RATE DESC

-------------------------------------------------------------------------------------------
               ----- ARE THE SECTORS WE PREDICTED RISKY ACTUALLY RISKY? -------
-------------------------------------------------------------------------------------------
SELECT SECTOR, ROUND(AVG(PD_ANNUAL),3) AS AVG_PD  , ROUND(AVG(DEFAULTED),3) AS ACTUAL_DEFAULTS
FROM LOAN_PORTFOLIO
GROUP BY SECTOR

SELECT ROUND(AVG(MATURITY_MONTHS),1) FROM LOAN_PORTFOLIO

-------------------------------------------------------------------------------------------
               ----- ARE THE SECTORS WE PREDICTED RISKY ACTUALLY RISKY? -------
-------------------------------------------------------------------------------------------
SELECT sector, scenario, el_increase_pct,
RANK() OVER (ORDER BY el_increase_pct DESC) AS worst_hit_rank
FROM stress_scenarios
WHERE scenario = 'severe'  
ORDER BY worst_hit_rank

----------------------------------------------------------------------------------------
     ----- HOW DOES EXPECTED LOSS CHANGE FROM NORMAL TO STRESS, PER SECTOR? -----
----------------------------------------------------------------------------------------
SELECT sector, scenario, expected_loss_base, expected_loss_stress, el_increase_pct
FROM stress_scenarios
ORDER BY sector, el_increase_pct DESC

------------------------------------------------------------------------------------------
            ---- WHICH SCENARIO + SECTOR IS OUR WORST-CASE COMBINATION? -----
------------------------------------------------------------------------------------------
SELECT sector, scenario, pd_multiplier, ROUND(STRESSED_LGD/BASE_LGD,3) AS LGD_MULTIPLIER
FROM stress_scenarios
ORDER BY pd_multiplier DESC, LGD_MULTIPLIER DESC
LIMIT 10

-----------------------------------------------------------------------
         ----- MONTH-OVER-MONTH CHANGE IN EL_RATE -----
-----------------------------------------------------------------------
SELECT dates, el_rate,
LAG(el_rate) OVER (ORDER BY dates) AS prev_month_el_rate,
el_rate - LAG(el_rate) OVER (ORDER BY dates) AS change_vs_prev_month
FROM portfolio_metrics
ORDER BY dates

--------------------------------------------------------------------------------
      ----- EACH SECTOR'S % SHARE OF TOTAL PORTFOLIO EXPECTED LOSS -----
--------------------------------------------------------------------------------
SELECT sector,
SUM(el) AS sector_el,
ROUND(100.0 * SUM(el) / (SELECT SUM(EL) FROM LOAN_PORTFOLIO), 2) AS pct_of_total_el
FROM loan_portfolio
GROUP BY sector
ORDER BY pct_of_total_el DESC

-----------------------------------------------------------------------------------------
            ----- LOANS WITH PD ABOVE THE OVERALL AVERAGE, BY SECTOR -----
-----------------------------------------------------------------------------------------
WITH abc AS (
SELECT sector, COUNT(*) AS above_avg_loan_count
FROM loan_portfolio
WHERE pd_annual > (SELECT AVG(pd_annual) FROM loan_portfolio)   -- PD (Probability of Default) above the overall average
GROUP BY sector
)
SELECT sector, above_avg_loan_count,
ROUND(100.0 * above_avg_loan_count /
(SELECT COUNT(*) FROM loan_portfolio WHERE loan_portfolio.sector = abc.sector), 2) AS pct_above_avg
FROM abc
ORDER BY pct_above_avg DESC

-------------------------------------------------------------------------------------
  ----- VINTAGES WITH CUMULATIVE DEFAULT RATE ABOVE AVERAGE, AT THE SAME AGE -----
-------------------------------------------------------------------------------------
WITH avg_by_age AS (                      
SELECT months_on_books, AVG(cumulative_default_rate) AS avg_rate
FROM vintage_analysis
GROUP BY months_on_books
)
SELECT v.vintage, COUNT(*) AS months_above_avg        
FROM vintage_analysis v
JOIN avg_by_age a ON v.months_on_books = a.months_on_books
WHERE v.cumulative_default_rate > a.avg_rate
GROUP BY v.vintage                        
ORDER BY months_above_avg DESC       

-------------------------------------------------------------------------------------
     ----- SECTOR RATING DOWNGRADES/DEFAULTS VS ACTUAL LOAN DEFAULT RATE -----
-------------------------------------------------------------------------------------
WITH ratings_summary AS (
SELECT sector,
ROUND(100.0 * SUM(downgraded) / COUNT(*), 2) AS downgrade_rate,
ROUND(100.0 * SUM(defaulted) / COUNT(*), 2) AS rating_default_rate
FROM credit_ratings
GROUP BY sector
),
loans_summary AS (
SELECT sector,
ROUND(100.0 * SUM(defaulted) / COUNT(*), 2) AS loan_default_rate
FROM loan_portfolio
GROUP BY sector
)
SELECT r.sector, r.downgrade_rate, r.rating_default_rate, l.loan_default_rate
FROM ratings_summary r
JOIN loans_summary l ON r.sector = l.sector
ORDER BY l.loan_default_rate DESC

-----------------------------------------------------------------------------------
              ----- DO BORROWERS WITH MORE DEBT HAVE A HIGHER PD -----
-----------------------------------------------------------------------------------
SELECT 
CASE 
WHEN leverage < 2 THEN 'low'
WHEN leverage < 4 THEN 'medium'
ELSE 'high'
END AS leverage_band,
ROUND(AVG(pd_annual), 4) AS avg_pd,
COUNT(*) AS loan_count
FROM loan_portfolio
GROUP BY leverage_band
ORDER BY avg_pd DESC


----------------------------------------------------------------------------------------------
             ----- AVERAGE RECOVERY RATE BY SECTOR, DEFAULTED LOANS ONLY -----
----------------------------------------------------------------------------------------------
SELECT sector, ROUND(AVG(recovery_rate) *100, 2) AS avg_recovery_rate, COUNT(*) AS defaulted_loan_count
FROM loan_portfolio
WHERE defaulted = 1
GROUP BY sector
ORDER BY avg_recovery_rate DESC






