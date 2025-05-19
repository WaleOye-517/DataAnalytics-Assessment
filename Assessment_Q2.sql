WITH user_trans AS (
   -- Calculates the count of successful transactions per user and their monthly transaction rate.
	SELECT 
		u.id,
		COUNT(s.savings_id) / NULLIF(TIMESTAMPDIFF(MONTH, u.created_on, CURDATE()), 0) AS transactions_per_month
    -- Monthly rate (successful transactions / months), NULL if months since creation = 0
	FROM 
		adashi_staging.users_customuser AS u
	JOIN
		adashi_staging.savings_savingsaccount AS s 
	ON
		u.id = s.owner_id -- Links users to their savings account transactions via owner_id
	WHERE
		s.transaction_status LIKE '%success%' -- Filters to include only successful transactions.
	GROUP BY
		u.id) -- Groups results by user to aggregate transaction counts per user

SELECT 
	CASE
    -- Assigns a frequency category based on the calculated monthly transaction rate.
		WHEN transactions_per_month >= 10 THEN 'High Frequency'
		WHEN transactions_per_month <= 2 THEN 'Low Frequency'
		ELSE 'Medium Frequency'
	END AS frequency_category,
	COUNT(id) AS customer_count, -- Counts the number of users within each frequency category
	ROUND(AVG(transactions_per_month), 1) AS avg_transactions_per_month
FROM
	user_trans -- Uses the results from the CTE
GROUP BY
	frequency_category; -- Groups the final results by the determined frequency category