-- 1) ADDRESSES.u_id → CUSTOMER.id
SELECT a.*
FROM public."ADDRESSES" AS a
LEFT JOIN public."CUSTOMER" AS c
  ON a.u_id = c.id
WHERE c.id IS NULL;


-- 2) AFFILIATE.u_id → CUSTOMER.id
SELECT f.*
FROM public."AFFILIATE" AS f
LEFT JOIN public."CUSTOMER" AS c
  ON f.u_id = c.id
WHERE c.id IS NULL;


-- 3) CATEGORIES.p_id → PRODUCT.id
SELECT cat.*
FROM public."CATEGORIES" AS cat
LEFT JOIN public."PRODUCT" AS p
  ON cat.p_id = p.id
WHERE p.id IS NULL;


-- 4) CCARD.(u_id,p_id) → PAYMENT.(p_u_id,p_id)
SELECT cc.*
FROM public."CCARD" AS cc
LEFT JOIN public."PAYMENT" AS pay
  ON cc.u_id = pay.p_u_id
 AND cc.p_id = pay.p_id
WHERE pay.p_u_id IS NULL;



-- 5) COLLECTION.collector_id → AFFILIATE.u_id
SELECT col.*
FROM public."COLLECTION" AS col
LEFT JOIN public."AFFILIATE" AS a
  ON col.collector_id = a.u_id
WHERE a.u_id IS NULL;


-- 6) COLLECTION.(shop_id,product_id) → SHOP_PRODUCT.(s_id,p_id)
SELECT col.*
FROM public."COLLECTION" AS col
LEFT JOIN public."SHOP_PRODUCT" AS sp
  ON col.shop_id    = sp.s_id
 AND col.product_id = sp.p_id
WHERE sp.s_id IS NULL;


-- 7) LISTS.buyer_id → CUSTOMER.id
SELECT l.*
FROM public."LISTS" AS l
LEFT JOIN public."CUSTOMER" AS c
  ON l.buyer_id = c.id
WHERE c.id IS NULL;


-- 8) LISTS.(shop_id,product_id) → SHOP_PRODUCT.(s_id,p_id)
SELECT l.*
FROM public."LISTS" AS l
LEFT JOIN public."SHOP_PRODUCT" AS sp
  ON l.shop_id    = sp.s_id
 AND l.product_id = sp.p_id
WHERE sp.s_id IS NULL;


-- 9) ORDER.(u_id,address) → ADDRESSES.(u_id,address)
SELECT o.*
FROM public."ORDER" AS o
LEFT JOIN public."ADDRESSES" AS a
  ON o.u_id    = a.u_id
 AND o.address = a.address
WHERE a.u_id IS NULL;


-- 10) ORDER.u_id → CUSTOMER.id
SELECT o.*
FROM public."ORDER" AS o
LEFT JOIN public."CUSTOMER" AS c
  ON o.u_id = c.id
WHERE c.id IS NULL;


-- 11) ORDER.log_id → LOGISTICS.id
SELECT o.*
FROM public."ORDER" AS o
LEFT JOIN public."LOGISTICS" AS l
  ON o.log_id = l.id
WHERE l.id IS NULL;


-- 12) ORDER.(payer_id,pay_id) → PAYMENT.(p_u_id,p_id)
SELECT o.*
FROM public."ORDER" AS o
LEFT JOIN public."PAYMENT" AS p
  ON o.payer_id = p.p_u_id
 AND o.pay_id   = p.p_id
WHERE p.p_u_id IS NULL;


-- 13) ORDER.refer_id → AFFILIATE.aff_code
SELECT o.*
FROM public."ORDER" AS o
LEFT JOIN public."AFFILIATE" AS a
  ON o.refer_id = a.aff_code
WHERE o.refer_id IS NOT NULL
  AND a.aff_code IS NULL;


-- 14) ORDER.(sp_shop_id,sp_id) → SHOP_PRODUCT.(s_id,p_id)
SELECT o.*
FROM public."ORDER" AS o
LEFT JOIN public."SHOP_PRODUCT" AS sp
  ON o.sp_shop_id = sp.s_id
 AND o.sp_id      = sp.p_id
WHERE sp.s_id IS NULL;


-- 15) PAYMENT.p_u_id → CUSTOMER.id
SELECT pay.*
FROM public."PAYMENT" AS pay
LEFT JOIN public."CUSTOMER" AS c
  ON pay.p_u_id = c.id
WHERE c.id IS NULL;


-- 16) PREMIUM.u_id → CUSTOMER.id
SELECT prem.*
FROM public."PREMIUM" AS prem
LEFT JOIN public."CUSTOMER" AS c
  ON prem.u_id = c.id
WHERE c.id IS NULL;


-- 17) PRODUCT_REVIEW.reviewer_id → CUSTOMER.id
SELECT pr.*
FROM public."PRODUCT_REVIEW" AS pr
LEFT JOIN public."CUSTOMER" AS c
  ON pr.reviewer_id = c.id
WHERE c.id IS NULL;


-- 18) PRODUCT_REVIEW.(shop_id,product_id) → SHOP_PRODUCT.(s_id,p_id)
SELECT pr.*
FROM public."PRODUCT_REVIEW" AS pr
LEFT JOIN public."SHOP_PRODUCT" AS sp
  ON pr.shop_id    = sp.s_id
 AND pr.product_id = sp.p_id
WHERE sp.s_id IS NULL;


-- 19) SHOP_PRODUCT.p_id → PRODUCT.id
SELECT sp.*
FROM public."SHOP_PRODUCT" AS sp
LEFT JOIN public."PRODUCT" AS p
  ON sp.p_id = p.id
WHERE p.id IS NULL;


-- 20) SHOP_PRODUCT.s_id → SHOP.id
SELECT sp.*
FROM public."SHOP_PRODUCT" AS sp
LEFT JOIN public."SHOP" AS s
  ON sp.s_id = s.id
WHERE s.id IS NULL;


-- 21) SHOP_REVIEW.reviewer_id → CUSTOMER.id
SELECT sr.*
FROM public."SHOP_REVIEW" AS sr
LEFT JOIN public."CUSTOMER" AS c
  ON sr.reviewer_id = c.id
WHERE c.id IS NULL;


-- 22) SHOP_REVIEW.shop_id → SHOP.id
SELECT sr.*
FROM public."SHOP_REVIEW" AS sr
LEFT JOIN public."SHOP" AS s
  ON sr.shop_id = s.id
WHERE s.id IS NULL;


-- 23) SNA.buyer_id → CUSTOMER.id
SELECT sna.*
FROM public."SNA" AS sna
LEFT JOIN public."CUSTOMER" AS c
  ON sna.buyer_id = c.id
WHERE c.id IS NULL;


-- 24) SNA.(shop_id,product_id) → SHOP_PRODUCT.(s_id,p_id)
SELECT sna.*
FROM public."SNA" AS sna
LEFT JOIN public."SHOP_PRODUCT" AS sp
  ON sna.shop_id    = sp.s_id
 AND sna.product_id = sp.p_id
WHERE sp.s_id IS NULL;


-- 25) TRANSACTION.(cc_u_id,cc_p_id) → CCARD.(u_id,p_id)
SELECT t.*
FROM public."TRANSACTION" AS t
LEFT JOIN public."CCARD" AS cc
  ON t.cc_u_id = cc.u_id
 AND t.cc_p_id = cc.p_id
WHERE cc.u_id IS NULL;


-- 26) TRANSACTION.(w_u_id,w_p_id) → WALLET.(u_id,p_id)
SELECT t.*
FROM public."TRANSACTION" AS t
LEFT JOIN public."WALLET" AS w
  ON t.w_u_id = w.u_id
 AND t.w_p_id = w.p_id
WHERE w.u_id IS NULL;


-- 27) VARIANT.p_id → PRODUCT.id
SELECT v.*
FROM public."VARIANT" AS v
LEFT JOIN public."PRODUCT" AS p
  ON v.p_id = p.id
WHERE p.id IS NULL;


-- 28) VARIANT.p_vart_id → PRODUCT.id
SELECT v.*
FROM public."VARIANT" AS v
LEFT JOIN public."PRODUCT" AS p
  ON v.p_vart_id = p.id
WHERE p.id IS NULL;
