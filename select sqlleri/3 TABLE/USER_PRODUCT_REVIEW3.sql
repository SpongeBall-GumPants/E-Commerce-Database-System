SELECT 
    c.id AS user_id,
    c.name || ' ' || c.lname AS customer_name,
    p.id AS product_id,
    p.name AS product_name,
    pr.review,
    pr.score
FROM "CUSTOMER" c
JOIN "PRODUCT_REVIEW" pr ON c.id = pr.reviewer_id
JOIN "SHOP_PRODUCT" sp ON pr.shop_id = sp.s_id AND pr.product_id = sp.p_id
JOIN "PRODUCT" p ON sp.p_id = p.id;