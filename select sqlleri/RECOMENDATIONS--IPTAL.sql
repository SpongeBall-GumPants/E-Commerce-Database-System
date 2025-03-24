WITH UserShops AS (
-- Get shops where user has made purchases
SELECT DISTINCT sp_shop_id as shop_id
FROM public."ORDER" o
WHERE o.u_id = 'U00000001' -- Replace with parameter for user_id
AND o.status = 'completed'
),
UserReviews AS (
-- Get products user has reviewed well (>3.0)
SELECT
pr.shop_id,
pr.product_id,
pr.score
FROM public."PRODUCT_REVIEW" pr
WHERE pr.reviewer_id = 'U00000001' -- Replace with parameter for user_id
AND pr.score > 3.0
),
UserPurchases AS (
-- Get products user has already bought
SELECT DISTINCT
sp_id as product_id
FROM public."ORDER"
WHERE u_id = 'U00000001' -- Replace with parameter for user_id
),
WellReviewedProducts AS (
-- Get products with good reviews from shops user has bought from
SELECT DISTINCT
pr.shop_id,
pr.product_id,
AVG(pr.score) as avg_score
FROM public."PRODUCT_REVIEW" pr
JOIN UserShops us ON pr.shop_id = us.shop_id
WHERE NOT EXISTS (
-- Exclude products user has already bought
SELECT 1 FROM UserPurchases up
WHERE up.product_id = pr.product_id
)
GROUP BY pr.shop_id, pr.product_id
HAVING AVG(pr.score) > 3.0
),
ProductVariants AS (
-- Get variants and base products
SELECT
wrp.shop_id,
wrp.product_id as base_product_id,
v.p_vart_id as variant_id,
wrp.avg_score
FROM WellReviewedProducts wrp
LEFT JOIN public."VARIANT" v ON wrp.product_id = v.p_id
),
ProductCategories AS (
-- Get categories matching user's well-reviewed products
SELECT
pv.shop_id,
pv.base_product_id,
pv.variant_id,
pv.avg_score,
c.category
FROM ProductVariants pv
JOIN public."CATEGORIES" c ON c.p_id = pv.base_product_id
WHERE EXISTS (
-- Only include products in categories user has rated highly
SELECT 1
FROM UserReviews ur
JOIN public."CATEGORIES" uc ON ur.product_id = uc.p_id
WHERE uc.category = c.category
)
)
SELECT
pc.shop_id,
s.name as shop_name,
pc.base_product_id,
p1.name as product_name,
pc.variant_id,
p2.name as variant_name,
pc.category,
pc.avg_score,
sp1.value as base_price,
sp2.value as variant_price,
sp1.currency
FROM ProductCategories pc
JOIN public."SHOP" s ON s.id = pc.shop_id
JOIN public."PRODUCT" p1 ON p1.id = pc.base_product_id
LEFT JOIN public."PRODUCT" p2 ON p2.id = pc.variant_id
JOIN public."SHOP_PRODUCT" sp1 ON sp1.s_id = pc.shop_id AND sp1.p_id = pc.base_product_id
LEFT JOIN public."SHOP_PRODUCT" sp2 ON sp2.s_id = pc.shop_id AND sp2.p_id = pc.variant_id
WHERE sp1.stock > 0 -- Only show in-stock items
ORDER BY pc.avg_score DESC, pc.shop_id, pc.base_product_id;