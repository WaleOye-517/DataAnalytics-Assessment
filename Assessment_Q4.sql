WITH user_clv AS (
    SELECT
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        TIMESTAMPDIFF(MONTH, u.created_on, CURDATE()) AS tenure_months, -- Calculates the number of full months since the user was created
        COUNT(s.savings_id) AS total_transactions,
        -- Calculates numeric estimated CLV using: 12 * total_amount / months.
		-- Applies combined unit conversion factor (0.1% profit_per_transaction for rate and kobo-to-naira conversion).
        (12 * SUM(s.confirmed_amount) / NULLIF(TIMESTAMPDIFF(MONTH, u.created_on, CURDATE()) * 100000, 0))
        AS estimated_clv_numeric
    FROM
        adashi_staging.savings_savingsaccount AS s
    JOIN
        adashi_staging.users_customuser AS u ON s.owner_id = u.id 
-- Joins savings transactions to user details via owner_id = user ID
    WHERE
        s.transaction_status LIKE '%success%' -- Filters to include only successful transactions.
    GROUP BY
        u.id,
        u.first_name,
        u.last_name,
        u.created_on
)
-- Select the final results, format the CLV for display, and order by the CLV value.
SELECT
    customer_id,
    name,
    tenure_months,
    total_transactions,
-- Format the CLV values for readability
    CONCAT('₦', FORMAT(estimated_clv_numeric, 2)) AS estimated_clv
FROM
    user_clv
ORDER BY
    estimated_clv_numeric DESC; -- Order the final results by the CLV value in descending order.