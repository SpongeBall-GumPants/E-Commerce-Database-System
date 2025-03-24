SELECT p.*
FROM public."PRODUCT" p
JOIN public."CATEGORIES" c ON p.id = c.p_id
WHERE c.category = (
    SELECT category
    FROM public."CATEGORIES"
    WHERE p_id = 'P00000001'  -- Buraya spesifik product'ın p_id'si gelecek
)
AND p.id != 'P00000001'  -- Bu satır, spesifik ürünü hariç tutmak için
AND p.id NOT IN (
    SELECT p_vart_id
    FROM public."VARIANT"
    WHERE p_id = 'P00000001'
);
