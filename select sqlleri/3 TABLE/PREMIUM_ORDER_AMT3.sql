SELECT
sp.p_id AS product_id,
p.name AS product_name,
sp.s_id AS shop_id,
s.name AS shop_name,
SUM(o.amount) AS premium_order_amount
FROM public."ORDER" o
JOIN public."LOGISTICS" l ON o.log_id = l.id
JOIN public."SHOP_PRODUCT" sp ON o.sp_id = sp.p_id AND o.sp_shop_id = sp.s_id
JOIN public."PRODUCT" p ON sp.p_id = p.id
JOIN public."SHOP" s ON s.id = sp.s_id
WHERE l.premium = TRUE
GROUP BY sp.p_id, p.name, sp.s_id, s.name
ORDER BY  premium_order_amount DESC;