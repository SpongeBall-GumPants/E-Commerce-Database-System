INSERT INTO "SHOP_PRODUCT" (s_id, p_id, value, currency, stock)
VALUES ('S00000005', 'P00000002', 300, 'TL', 25);
UPDATE "SHOP_PRODUCT"
SET value = value * 1.1
WHERE currency = 'TL';
DELETE FROM "SHOP_PRODUCT"
WHERE stock = 0;

