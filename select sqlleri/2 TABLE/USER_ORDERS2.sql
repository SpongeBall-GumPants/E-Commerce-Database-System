SELECT 
    c.id AS customer_id,
    c.name,
    c.lname,
    o.order_id,
    o.status,
    o.date,
    o.pay_amount
FROM "CUSTOMER" c
LEFT JOIN "ORDER" o ON c.id = o.u_id
ORDER BY c.id, o.date;