WITH acount_activity AS (
-- Identifies inactive owners by their latest successful transaction and selects details of the involved plan(s).
-- Note: Only includes the plan(s) from the owner's single most recent transaction, not the latest per plan.
	SELECT
		s.owner_id,
        s.plan_id,
        s.transaction_date,
		TIMESTAMPDIFF(DAY, max(s.transaction_date), CURDATE()) AS inactivity_days
-- Calculates inactivity days based on the latest transaction date
	FROM adashi_staging.savings_savingsaccount AS s
	JOIN (
 -- Subquery to find owners with no successful transactions in the past year (365 days).
		SELECT owner_id, MAX(transaction_date) AS latest_trans_date -- Finds the latest transaction date per owner
		FROM adashi_staging.savings_savingsaccount
		WHERE transaction_status LIKE '%success%' -- Filters to include only successful transactions.
		GROUP BY owner_id
		HAVING TIMESTAMPDIFF(DAY, max(transaction_date), CURDATE()) > 365
-- Filters owners based on the inactivity of their latest successful transaction
) AS latest
-- Retrieves only the savings transactions matching each inactive owner's latest successful transaction date. 
	ON s.owner_id = latest.owner_id
	AND s.transaction_date = latest.latest_trans_date
	GROUP BY
		s.owner_id,
        s.plan_id
)
SELECT
	a.plan_id,
    a.owner_id, 
	CASE
-- Assigns plan type: for regular savings, 'Savings' for fund-based plans, 'Investments'.
		WHEN p.is_regular_savings = 1 THEN 'Savings'
		WHEN p.is_a_fund = 1 THEN 'Investments'
		ELSE 'Others'
    END AS type,
	DATE(a.transaction_date) AS transaction_date, -- The transaction date from the CTE (the owner's overall latest successful transaction date)
    a.inactivity_days   -- The inactivity days calculated in the CTE
FROM
	acount_activity AS a
JOIN
	adashi_staging.plans_plan AS p 
ON
	a.owner_id = p.owner_id AND a.plan_id = p.id -- Joins with plan details to get type
WHERE
	p.is_regular_savings = 1 OR p.is_a_fund = 1 -- Filter to show only savings or investments