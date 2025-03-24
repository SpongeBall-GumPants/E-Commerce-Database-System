SELECT
	p.name AS product_name,
	o.sp_id AS product_id,
    s.id AS shop_id,
    s.name AS shop_name,
    COUNT(o.order_id) AS return_count
FROM "SHOP" s
JOIN "ORDER" o ON s.id = o.sp_shop_id
JOIN "PRODUCT" p ON p.id = o.sp_id
WHERE o.status = 'refunded' AND s.id='S00000001'
GROUP BY s.id, s.name,sp_id,p.name
ORDER BY return_count DESC;
