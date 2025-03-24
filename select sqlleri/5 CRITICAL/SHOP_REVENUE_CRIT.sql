SELECT 
    s.id AS shop_id,
    s.name AS shop_name,
    DATE_TRUNC('month', o.date) AS month,
    SUM(o.pay_amount) AS total_revenue
FROM "SHOP" s
JOIN "ORDER" o ON s.id = o.sp_shop_id
WHERE o.status = 'completed'
GROUP BY s.id, s.name, DATE_TRUNC('month', o.date)
ORDER BY month DESC, total_revenue DESC;