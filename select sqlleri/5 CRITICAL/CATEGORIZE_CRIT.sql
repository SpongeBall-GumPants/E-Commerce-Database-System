SELECT 
    c.category,
    COUNT(DISTINCT p.id) AS product_count,
    ARRAY_AGG(p.name) AS product_names
FROM "CATEGORIES" c
JOIN "PRODUCT" p ON c.p_id = p.id
GROUP BY c.category
ORDER BY product_count DESC;