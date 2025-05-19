WITH plans_count AS (
    -- Calculates the number of savings and investment plans per owner.
    -- Filters to include only owners who have at least one of each plan type.
    SELECT
        owner_id,
        COUNT(CASE WHEN is_regular_savings = 1 THEN 1 END) AS savings_count, -- Counts savings plans
        COUNT(CASE WHEN is_a_fund = 1 THEN 1 END) AS investment_count -- Counts investment plans
    FROM
        adashi_staging.plans_plan
    GROUP BY
        owner_id
    HAVING
        COUNT(CASE WHEN is_regular_savings = 1 THEN 1 END) > 0 -- Has at least one savings plan
        AND COUNT(CASE WHEN is_a_fund = 1 THEN 1 END) > 0 -- Has at least one investment plan
),
total_deposits_per_owner AS (
    -- Aggregates the sum of confirmed amounts for successful transactions per owner.
    -- Filters out transactions where transaction_status is not successful.
    SELECT
        owner_id,
        SUM(confirmed_amount) AS total_confirmed_amount
    FROM
        adashi_staging.savings_savingsaccount
    WHERE 
		confirmed_amount IS NOT NULL  -- Filters out transactions with null amounts
        AND transaction_status LIKE '%success%' -- Filters to include transactions with 'success' in the status string
    GROUP BY
        owner_id
)
-- Selects the final results by joining plan counts, user info, and total successful deposits.
SELECT
    pc.owner_id,
    CONCAT(u.first_name, ' ', u.last_name) as name, -- Concatenates first and last name
    pc.savings_count,
    pc.investment_count,
    CONCAT('₦', FORMAT(td.total_confirmed_amount / 100, 2)) as total_deposits -- Formats total deposits and converts unit from kobo to naira
FROM
    plans_count AS pc -- Results for owners with both plan types and their counts
JOIN
    total_deposits_per_owner AS td ON pc.owner_id = td.owner_id -- Joins with pre-aggregated successful deposits
JOIN
    adashi_staging.users_customuser AS u ON pc.owner_id = u.id -- Joins with user details
ORDER BY
    td.total_confirmed_amount DESC; -- Orders results by the total successful deposits descending