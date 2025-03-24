SELECT 
    p.id AS product_id,
    p.name AS product_name,
    DATE_TRUNC('month', o.date) AS month,
    COUNT(o.order_id) AS order_count,
    SUM(o.amount) AS total_units_sold
FROM "PRODUCT" p
JOIN "ORDER" o ON p.id = o.sp_id
WHERE o.status = 'completed'
AND DATE_TRUNC('month', o.date) = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY p.id, p.name, DATE_TRUNC('month', o.date)
ORDER BY total_units_sold DESC
LIMIT 1;