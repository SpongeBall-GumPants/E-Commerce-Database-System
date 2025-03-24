
INSERT INTO public."ORDER" (u_id, log_id, sp_id, sp_shop_id, order_id, status, date, address, payer_id, pay_id, pay_amount, refer_id, coupon, amount) 
VALUES ('U00000001', 'L00000001', 'P00000001', 'S00000001', 'O00000003', 'in_cart', '2025-01-13', '6399sk,No:10,Daire:8,Yalı Mah.', 'U00000001', 'PY0000001', 1000, 'AFF123456', 'DISCOUNT10', 2);

UPDATE "ORDER"
SET status = 'canceled'
WHERE order_id = 'O00000003';


UPDATE "ORDER"
SET status = 'completed'
WHERE order_id = 'O00000003';


UPDATE "ORDER"
SET status = 'refunded'
WHERE order_id = 'O00000003';

DELETE FROM "ORDER"
WHERE status = 'canceled';