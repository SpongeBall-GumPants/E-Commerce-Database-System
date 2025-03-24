SELECT 
    p1.id AS product_id,
    p1.name AS product_name,
    p2.id AS variant_id,
    p2.name AS variant_name
FROM "PRODUCT" p1
JOIN "VARIANT" v ON p1.id = v.p_id
JOIN "PRODUCT" p2 ON v.p_vart_id = p2.id
ORDER BY product_name;