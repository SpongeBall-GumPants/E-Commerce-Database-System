SELECT 
    p.id AS product_id,
    p.name AS product_name,
    s.id AS shop_id,
    s.name AS shop_name,
    sp.stock
FROM "PRODUCT" p
JOIN "SHOP_PRODUCT" sp ON p.id = sp.p_id
JOIN "SHOP" s ON sp.s_id = s.id
WHERE sp.stock = 0;