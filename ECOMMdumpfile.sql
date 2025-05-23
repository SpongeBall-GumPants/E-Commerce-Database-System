PGDMP                          }         	   ecommYENI    14.15    14.15 r    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    17880 	   ecommYENI    DATABASE     i   CREATE DATABASE "ecommYENI" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'Turkish_T�rkiye.1254';
    DROP DATABASE "ecommYENI";
                postgres    false            �            1255    17993    check_premium_order()    FUNCTION     �  CREATE FUNCTION public.check_premium_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."PREMIUM" WHERE u_id = NEW.u_id) THEN
        IF EXISTS (SELECT 1 FROM public."LOGISTICS" WHERE id = NEW.log_id AND premium = TRUE) THEN
            RAISE EXCEPTION 'User % does not have a premium membership, but the associated logistics % is marked as premium.', NEW.u_id, NEW.log_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
 ,   DROP FUNCTION public.check_premium_order();
       public          postgres    false            �            1255    17982    delete_on_zero()    FUNCTION     L  CREATE FUNCTION public.delete_on_zero() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.amount = 0 THEN
        DELETE FROM public."ORDER"
        WHERE u_id = NEW.u_id
          AND log_id = NEW.log_id
          AND sp_id = NEW.sp_id
          AND sp_shop_id = NEW.sp_shop_id;
    END IF;

    RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.delete_on_zero();
       public          postgres    false            �            1255    17827    update_customer_points()    FUNCTION     �   CREATE FUNCTION public.update_customer_points() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE "CUSTOMER"
SET points = points + (NEW.pay_amount / 10) -- 10 TL = 1 puan
WHERE id = NEW.u_id;
RETURN NEW;
END;
$$;
 /   DROP FUNCTION public.update_customer_points();
       public          postgres    false            �            1255    17990    update_payment()    FUNCTION     �  CREATE FUNCTION public.update_payment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    product_price INTEGER;
BEGIN
    
    SELECT value INTO product_price
    FROM public."SHOP_PRODUCT"
    WHERE p_id = NEW.sp_id AND s_id = NEW.sp_shop_id;
    
  IF (TG_OP = 'INSERT') THEN
        IF NEW.pay_amount <> product_price * NEW.amount THEN
            RAISE EXCEPTION 'Pay amount does not match price * amount during insert';
        END IF;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF NEW.pay_amount <> product_price * NEW.amount THEN
            NEW.pay_amount := product_price * NEW.amount;  
        END IF;
 	END IF;
    RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.update_payment();
       public          postgres    false            �            1255    17987    update_product_score()    FUNCTION     �  CREATE FUNCTION public.update_product_score() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- PRODUCT_REVIEW tablosundaki tüm yorumların ortalamasını hesapla
    UPDATE public."SHOP_PRODUCT"
    SET score = (
        SELECT AVG(score)
        FROM public."PRODUCT_REVIEW"
        WHERE shop_id = NEW.shop_id AND product_id = NEW.product_id
    )
    WHERE s_id = NEW.shop_id AND p_id = NEW.product_id;
    
    RETURN NEW;
END;
$$;
 -   DROP FUNCTION public.update_product_score();
       public          postgres    false            �            1255    17985    update_shop_score()    FUNCTION     s  CREATE FUNCTION public.update_shop_score() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- SHOP_REVIEW tablosundaki tüm yorumların ortalamasını hesapla
    UPDATE public."SHOP"
    SET score = (
        SELECT AVG(score)
        FROM public."SHOP_REVIEW"
        WHERE shop_id = NEW.shop_id
    )
    WHERE id = NEW.shop_id;
    
    RETURN NEW;
END;
$$;
 *   DROP FUNCTION public.update_shop_score();
       public          postgres    false            �            1255    17831    update_wallet_balance()    FUNCTION     d  CREATE FUNCTION public.update_wallet_balance() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
-- İşlem miktarını ekleyerek veya çıkararak bakiyeyi güncelle
IF EXISTS (
SELECT 1 FROM "WALLET"
WHERE u_id = NEW.w_u_id AND p_id = NEW.w_p_id
) THEN
-- Bakiyeyi güncelle
UPDATE "WALLET"
SET ammount = ammount + NEW.ammount
WHERE u_id = NEW.w_u_id AND p_id = NEW.w_p_id;
ELSE
-- Eğer cüzdan kaydı yoksa yeni bir cüzdan kaydı oluştur
INSERT INTO "WALLET" (u_id, p_id, ammount, currency)
VALUES (NEW.w_u_id, NEW.w_p_id, NEW.ammount, 'TRY'); -- Varsayılan para birimi TRY
END IF;
RETURN NEW;
END;
$$;
 .   DROP FUNCTION public.update_wallet_balance();
       public          postgres    false            �            1255    17934    validate_order_status()    FUNCTION     9	  CREATE FUNCTION public.validate_order_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
    -- Ensure the initial insert has status 'in_cart'
    IF TG_OP = 'INSERT' THEN
        IF NEW.status <> 'in_cart' THEN
            RAISE EXCEPTION 'Initial status must be in_cart';
        END IF;
    END IF;

    -- Handle updates
    IF TG_OP = 'UPDATE' THEN
        -- transition from in_cart to  completed
		 IF OLD.status = 'in_cart' AND  NEW.status ='completed' THEN
         	UPDATE public."SHOP_PRODUCT"
        	SET stock = stock - NEW.amount
       	    WHERE p_id = NEW.sp_id AND s_id = NEW.sp_shop_id;

        	IF (SELECT stock FROM public."SHOP_PRODUCT"
            	WHERE p_id = NEW.sp_id AND s_id = NEW.sp_shop_id) < 0 THEN
            	RAISE EXCEPTION 'Stock cannot be negative for product % in shop %', NEW.sp_id, NEW.sp_shop_id;
        	
			END IF;
			
			IF EXISTS (SELECT 1 FROM public."ORDER" WHERE pay_id = NEW.pay_id) THEN
                IF (SELECT ammount FROM public."WALLET"
                   WHERE p_id = NEW.pay_id) < NEW.pay_amount THEN
                  RAISE EXCEPTION 'Insufficient balance in WALLET for pay_id %', NEW.pay_id;
                END IF;
				UPDATE public."WALLET"
                SET ammount = ammount - NEW.pay_amount
                WHERE p_id = NEW.pay_id;

                

            END IF;	
			
        END IF;
        IF OLD.status = 'in_cart' AND NOT (NEW.status IN ('canceled', 'completed')) THEN
            RAISE EXCEPTION 'Invalid status transition from in_cart: %', NEW.status;
        END IF;

        -- transition from completed to refunded
		 IF OLD.status = 'completed' AND NEW.status = 'refunded' THEN
            UPDATE public."SHOP_PRODUCT"
        	SET stock = stock + NEW.amount
       	    WHERE p_id = NEW.sp_id AND s_id = NEW.sp_shop_id;

        END IF;
        IF OLD.status = 'completed' AND NEW.status <> 'refunded' THEN
            RAISE EXCEPTION 'Invalid status transition from completed: %', NEW.status;
        END IF;

        -- Prevent any other transitions
        IF NOT (OLD.status = 'in_cart' AND NEW.status IN ('canceled', 'completed'))
           AND NOT (OLD.status = 'completed' AND NEW.status = 'refunded') THEN
            RAISE EXCEPTION 'Invalid status transition from % to %', OLD.status, NEW.status;
        END IF;
    END IF;

    RETURN NEW;
END;$$;
 .   DROP FUNCTION public.validate_order_status();
       public          postgres    false            �            1259    17534 	   ADDRESSES    TABLE     q   CREATE TABLE public."ADDRESSES" (
    u_id character(9) NOT NULL,
    address character varying(255) NOT NULL
);
    DROP TABLE public."ADDRESSES";
       public         heap    postgres    false            �            1259    17554 	   AFFILIATE    TABLE     �   CREATE TABLE public."AFFILIATE" (
    u_id character(9) NOT NULL,
    aff_code character(9) NOT NULL,
    CONSTRAINT "AFFILIATE_CODE_FORMAT" CHECK ((aff_code ~ '^AFF\d{6}$'::text))
);
    DROP TABLE public."AFFILIATE";
       public         heap    postgres    false            �            1259    17569 
   CATEGORIES    TABLE     r   CREATE TABLE public."CATEGORIES" (
    p_id character(9) NOT NULL,
    category character varying(31) NOT NULL
);
     DROP TABLE public."CATEGORIES";
       public         heap    postgres    false            �            1259    17497    CCARD    TABLE     �   CREATE TABLE public."CCARD" (
    u_id character(9) NOT NULL,
    p_id character(9) NOT NULL,
    name character varying NOT NULL,
    ccv character(3) NOT NULL,
    ccnumber character(16) NOT NULL,
    exp_date numeric(4,2) NOT NULL
);
    DROP TABLE public."CCARD";
       public         heap    postgres    false            �            1259    17769 
   COLLECTION    TABLE     �   CREATE TABLE public."COLLECTION" (
    shop_id character(9) NOT NULL,
    product_id character(9) NOT NULL,
    collector_id character(9) NOT NULL,
    collection_id character(9) NOT NULL
);
     DROP TABLE public."COLLECTION";
       public         heap    postgres    false            �            1259    17366    CUSTOMER    TABLE       CREATE TABLE public."CUSTOMER" (
    id character(9) NOT NULL,
    name character varying(50) NOT NULL,
    minit character(1),
    lname character varying(50) NOT NULL,
    country character varying(60) NOT NULL,
    points integer DEFAULT 0 NOT NULL,
    phone character(11) NOT NULL,
    bdate date NOT NULL,
    sex character(1) NOT NULL,
    CONSTRAINT "AGELIMIT" CHECK ((EXTRACT(year FROM bdate) <= (EXTRACT(year FROM CURRENT_DATE) - (18)::numeric))),
    CONSTRAINT "USER_ID_FORMAT" CHECK ((id ~ '^U\d{8}$'::text))
);
    DROP TABLE public."CUSTOMER";
       public         heap    postgres    false            �            1259    17721    LISTS    TABLE       CREATE TABLE public."LISTS" (
    shop_id character(9) NOT NULL,
    product_id character(9) NOT NULL,
    buyer_id character(9) NOT NULL,
    list_id character(9) NOT NULL,
    name character(9) NOT NULL,
    CONSTRAINT "LIST_ID_FORMAT" CHECK ((list_id ~ '^LIST\d{5}$'::text))
);
    DROP TABLE public."LISTS";
       public         heap    postgres    false            �            1259    17421 	   LOGISTICS    TABLE     #  CREATE TABLE public."LOGISTICS" (
    id character(9) NOT NULL,
    name character varying(50) NOT NULL,
    type character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    premium boolean DEFAULT false NOT NULL,
    CONSTRAINT "LOGID_FORMAT" CHECK ((id ~ '^L\d{8}$'::text))
);
    DROP TABLE public."LOGISTICS";
       public         heap    postgres    false            �            1259    17939    ORDER    TABLE     ?  CREATE TABLE public."ORDER" (
    u_id character(9) NOT NULL,
    log_id character(9) NOT NULL,
    sp_id character(9) NOT NULL,
    sp_shop_id character(9) NOT NULL,
    order_id character(9) NOT NULL,
    status character varying(20) NOT NULL,
    date date NOT NULL,
    address character varying(255) NOT NULL,
    payer_id character(9) NOT NULL,
    pay_id character(9) NOT NULL,
    pay_amount integer DEFAULT 0 NOT NULL,
    refer_id character(9),
    coupon character varying(255),
    amount integer DEFAULT 1 NOT NULL,
    CONSTRAINT "ORDER_ID_FORMAT" CHECK ((order_id ~ '^O\d{8}$'::text)),
    CONSTRAINT chk_status_valid CHECK (((status)::text = ANY (ARRAY[('in_cart'::character varying)::text, ('canceled'::character varying)::text, ('completed'::character varying)::text, ('refunded'::character varying)::text])))
);
    DROP TABLE public."ORDER";
       public         heap    postgres    false            �            1259    17796    PAYMENT    TABLE     �   CREATE TABLE public."PAYMENT" (
    p_u_id character(9) NOT NULL,
    p_id character(9) NOT NULL,
    CONSTRAINT "PAY_ID_FORMAT" CHECK ((p_id ~ '^PY\d{7}$'::text))
);
    DROP TABLE public."PAYMENT";
       public         heap    postgres    false            �            1259    17549    PREMIUM    TABLE     v   CREATE TABLE public."PREMIUM" (
    u_id character(9) NOT NULL,
    s_date date NOT NULL,
    e_date date NOT NULL
);
    DROP TABLE public."PREMIUM";
       public         heap    postgres    false            �            1259    17409    PRODUCT    TABLE     �   CREATE TABLE public."PRODUCT" (
    id character(9) NOT NULL,
    name character varying(50) NOT NULL,
    tr_flag boolean DEFAULT false NOT NULL,
    CONSTRAINT "PID_FORMAT" CHECK ((id ~ '^P\d{8}$'::text))
);
    DROP TABLE public."PRODUCT";
       public         heap    postgres    false            �            1259    17753    PRODUCT_REVIEW    TABLE     &  CREATE TABLE public."PRODUCT_REVIEW" (
    shop_id character(9) NOT NULL,
    product_id character(9) NOT NULL,
    reviewer_id character(9) NOT NULL,
    review character varying(255),
    score numeric(2,1) DEFAULT 0 NOT NULL,
    CONSTRAINT "REVIEW_LIMIT" CHECK ((score <= (5)::numeric))
);
 $   DROP TABLE public."PRODUCT_REVIEW";
       public         heap    postgres    false            �            1259    17375    SHOP    TABLE     �  CREATE TABLE public."SHOP" (
    id character(9) NOT NULL,
    name character varying(50) NOT NULL,
    email character varying(127) NOT NULL,
    address character varying(255) NOT NULL,
    country character varying(127) NOT NULL,
    woman_ent_flag boolean DEFAULT false NOT NULL,
    score numeric(2,1) DEFAULT 0 NOT NULL,
    CONSTRAINT "SCORE_LIMIT" CHECK ((score <= (5)::numeric)),
    CONSTRAINT "S_ID_FORMAT" CHECK ((id ~ '^S\d{8}$'::text))
);
    DROP TABLE public."SHOP";
       public         heap    postgres    false            �            1259    17428    SHOP_PRODUCT    TABLE     C  CREATE TABLE public."SHOP_PRODUCT" (
    s_id character(9) NOT NULL,
    p_id character(9) NOT NULL,
    value integer DEFAULT 0 NOT NULL,
    currency character varying(15) NOT NULL,
    stock integer DEFAULT 0 NOT NULL,
    score numeric(2,1) DEFAULT 0.0 NOT NULL,
    CONSTRAINT "NEGATIVE_STOCK" CHECK ((stock >= 0))
);
 "   DROP TABLE public."SHOP_PRODUCT";
       public         heap    postgres    false            �            1259    17510    SHOP_REVIEW    TABLE     �   CREATE TABLE public."SHOP_REVIEW" (
    shop_id character(9) NOT NULL,
    reviewer_id character(9) NOT NULL,
    review text,
    score numeric(2,1) DEFAULT 0 NOT NULL,
    CONSTRAINT "SCORE_LIMIT" CHECK ((score <= (5)::numeric))
);
 !   DROP TABLE public."SHOP_REVIEW";
       public         heap    postgres    false            �            1259    17738    SNA    TABLE     �   CREATE TABLE public."SNA" (
    shop_id character(9) NOT NULL,
    product_id character(9) NOT NULL,
    buyer_id character(9) NOT NULL,
    setdate date NOT NULL
);
    DROP TABLE public."SNA";
       public         heap    postgres    false            �            1259    17612    TRANSACTION    TABLE     !  CREATE TABLE public."TRANSACTION" (
    w_u_id character(9) NOT NULL,
    w_p_id character(9) NOT NULL,
    cc_u_id character(9) NOT NULL,
    cc_p_id character(9) NOT NULL,
    ammount integer DEFAULT 0 NOT NULL,
    date date NOT NULL,
    CONSTRAINT "NEGATIVE" CHECK ((ammount > 0))
);
 !   DROP TABLE public."TRANSACTION";
       public         heap    postgres    false            �            1259    17579    VARIANT    TABLE     g   CREATE TABLE public."VARIANT" (
    p_id character(9) NOT NULL,
    p_vart_id character(9) NOT NULL
);
    DROP TABLE public."VARIANT";
       public         heap    postgres    false            �            1259    17486    WALLET    TABLE     �   CREATE TABLE public."WALLET" (
    u_id character(9) NOT NULL,
    p_id character(9) NOT NULL,
    ammount integer DEFAULT 0 NOT NULL,
    currency character varying(20) NOT NULL,
    CONSTRAINT "NEGATIVE" CHECK ((ammount > 0))
);
    DROP TABLE public."WALLET";
       public         heap    postgres    false            �          0    17534 	   ADDRESSES 
   TABLE DATA           4   COPY public."ADDRESSES" (u_id, address) FROM stdin;
    public          postgres    false    217   �       �          0    17554 	   AFFILIATE 
   TABLE DATA           5   COPY public."AFFILIATE" (u_id, aff_code) FROM stdin;
    public          postgres    false    219   x�       �          0    17569 
   CATEGORIES 
   TABLE DATA           6   COPY public."CATEGORIES" (p_id, category) FROM stdin;
    public          postgres    false    220   ѭ       �          0    17497    CCARD 
   TABLE DATA           L   COPY public."CCARD" (u_id, p_id, name, ccv, ccnumber, exp_date) FROM stdin;
    public          postgres    false    215   ��       �          0    17769 
   COLLECTION 
   TABLE DATA           X   COPY public."COLLECTION" (shop_id, product_id, collector_id, collection_id) FROM stdin;
    public          postgres    false    226   ��       �          0    17366    CUSTOMER 
   TABLE DATA           `   COPY public."CUSTOMER" (id, name, minit, lname, country, points, phone, bdate, sex) FROM stdin;
    public          postgres    false    209   8�       �          0    17721    LISTS 
   TABLE DATA           O   COPY public."LISTS" (shop_id, product_id, buyer_id, list_id, name) FROM stdin;
    public          postgres    false    223   ��       �          0    17421 	   LOGISTICS 
   TABLE DATA           >   COPY public."LOGISTICS" (id, name, type, premium) FROM stdin;
    public          postgres    false    212   i�       �          0    17939    ORDER 
   TABLE DATA           �   COPY public."ORDER" (u_id, log_id, sp_id, sp_shop_id, order_id, status, date, address, payer_id, pay_id, pay_amount, refer_id, coupon, amount) FROM stdin;
    public          postgres    false    228   �       �          0    17796    PAYMENT 
   TABLE DATA           1   COPY public."PAYMENT" (p_u_id, p_id) FROM stdin;
    public          postgres    false    227   ĵ       �          0    17549    PREMIUM 
   TABLE DATA           9   COPY public."PREMIUM" (u_id, s_date, e_date) FROM stdin;
    public          postgres    false    218   !�       �          0    17409    PRODUCT 
   TABLE DATA           6   COPY public."PRODUCT" (id, name, tr_flag) FROM stdin;
    public          postgres    false    211   ��       �          0    17753    PRODUCT_REVIEW 
   TABLE DATA           [   COPY public."PRODUCT_REVIEW" (shop_id, product_id, reviewer_id, review, score) FROM stdin;
    public          postgres    false    225   ��       �          0    17375    SHOP 
   TABLE DATA           Z   COPY public."SHOP" (id, name, email, address, country, woman_ent_flag, score) FROM stdin;
    public          postgres    false    210   ��       �          0    17428    SHOP_PRODUCT 
   TABLE DATA           S   COPY public."SHOP_PRODUCT" (s_id, p_id, value, currency, stock, score) FROM stdin;
    public          postgres    false    213   s�       �          0    17510    SHOP_REVIEW 
   TABLE DATA           L   COPY public."SHOP_REVIEW" (shop_id, reviewer_id, review, score) FROM stdin;
    public          postgres    false    216   ��       �          0    17738    SNA 
   TABLE DATA           G   COPY public."SNA" (shop_id, product_id, buyer_id, setdate) FROM stdin;
    public          postgres    false    224   +�       �          0    17612    TRANSACTION 
   TABLE DATA           X   COPY public."TRANSACTION" (w_u_id, w_p_id, cc_u_id, cc_p_id, ammount, date) FROM stdin;
    public          postgres    false    222   ^�       �          0    17579    VARIANT 
   TABLE DATA           4   COPY public."VARIANT" (p_id, p_vart_id) FROM stdin;
    public          postgres    false    221   ھ       �          0    17486    WALLET 
   TABLE DATA           A   COPY public."WALLET" (u_id, p_id, ammount, currency) FROM stdin;
    public          postgres    false    214   �       �           2606    17867    ADDRESSES ADDRESSES_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public."ADDRESSES"
    ADD CONSTRAINT "ADDRESSES_pkey" PRIMARY KEY (u_id, address);
 F   ALTER TABLE ONLY public."ADDRESSES" DROP CONSTRAINT "ADDRESSES_pkey";
       public            postgres    false    217    217            �           2606    17558    AFFILIATE AFFILIATE_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public."AFFILIATE"
    ADD CONSTRAINT "AFFILIATE_pkey" PRIMARY KEY (u_id);
 F   ALTER TABLE ONLY public."AFFILIATE" DROP CONSTRAINT "AFFILIATE_pkey";
       public            postgres    false    219            �           2606    17573    CATEGORIES CATEGORIES_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public."CATEGORIES"
    ADD CONSTRAINT "CATEGORIES_pkey" PRIMARY KEY (p_id, category);
 H   ALTER TABLE ONLY public."CATEGORIES" DROP CONSTRAINT "CATEGORIES_pkey";
       public            postgres    false    220    220            �           2606    17503    CCARD CCARD_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public."CCARD"
    ADD CONSTRAINT "CCARD_pkey" PRIMARY KEY (u_id, p_id);
 >   ALTER TABLE ONLY public."CCARD" DROP CONSTRAINT "CCARD_pkey";
       public            postgres    false    215    215            �           2606    17620    CCARD CC_IDS 
   CONSTRAINT     Q   ALTER TABLE ONLY public."CCARD"
    ADD CONSTRAINT "CC_IDS" UNIQUE (u_id, p_id);
 :   ALTER TABLE ONLY public."CCARD" DROP CONSTRAINT "CC_IDS";
       public            postgres    false    215    215            �           2606    17790    AFFILIATE CODE 
   CONSTRAINT     Q   ALTER TABLE ONLY public."AFFILIATE"
    ADD CONSTRAINT "CODE" UNIQUE (aff_code);
 <   ALTER TABLE ONLY public."AFFILIATE" DROP CONSTRAINT "CODE";
       public            postgres    false    219            �           2606    17996    COLLECTION COLLCTN_ID_Format    CHECK CONSTRAINT     }   ALTER TABLE public."COLLECTION"
    ADD CONSTRAINT "COLLCTN_ID_Format" CHECK ((collection_id ~ '^C\d{8}$'::text)) NOT VALID;
 E   ALTER TABLE public."COLLECTION" DROP CONSTRAINT "COLLCTN_ID_Format";
       public          postgres    false    226    226            �           2606    17773    COLLECTION COLLECTION_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public."COLLECTION"
    ADD CONSTRAINT "COLLECTION_pkey" PRIMARY KEY (shop_id, product_id, collector_id, collection_id);
 H   ALTER TABLE ONLY public."COLLECTION" DROP CONSTRAINT "COLLECTION_pkey";
       public            postgres    false    226    226    226    226            �           2606    17370    CUSTOMER CUSTOMER_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public."CUSTOMER"
    ADD CONSTRAINT "CUSTOMER_pkey" PRIMARY KEY (id);
 D   ALTER TABLE ONLY public."CUSTOMER" DROP CONSTRAINT "CUSTOMER_pkey";
       public            postgres    false    209            �           2606    17725    LISTS LISTS_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public."LISTS"
    ADD CONSTRAINT "LISTS_pkey" PRIMARY KEY (shop_id, product_id, buyer_id, list_id);
 >   ALTER TABLE ONLY public."LISTS" DROP CONSTRAINT "LISTS_pkey";
       public            postgres    false    223    223    223    223            �           2606    17727    LISTS LIST_NAME 
   CONSTRAINT     N   ALTER TABLE ONLY public."LISTS"
    ADD CONSTRAINT "LIST_NAME" UNIQUE (name);
 =   ALTER TABLE ONLY public."LISTS" DROP CONSTRAINT "LIST_NAME";
       public            postgres    false    223            �           2606    17427    LOGISTICS LOGISTICS_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public."LOGISTICS"
    ADD CONSTRAINT "LOGISTICS_pkey" PRIMARY KEY (id);
 F   ALTER TABLE ONLY public."LOGISTICS" DROP CONSTRAINT "LOGISTICS_pkey";
       public            postgres    false    212            �           2606    17807    PAYMENT PAYMENT_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public."PAYMENT"
    ADD CONSTRAINT "PAYMENT_pkey" PRIMARY KEY (p_u_id, p_id);
 B   ALTER TABLE ONLY public."PAYMENT" DROP CONSTRAINT "PAYMENT_pkey";
       public            postgres    false    227    227            �           2606    17948    ORDER PK 
   CONSTRAINT     q   ALTER TABLE ONLY public."ORDER"
    ADD CONSTRAINT "PK" PRIMARY KEY (u_id, log_id, sp_id, sp_shop_id, order_id);
 6   ALTER TABLE ONLY public."ORDER" DROP CONSTRAINT "PK";
       public            postgres    false    228    228    228    228    228            �           2606    17553    PREMIUM PREMIUM_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public."PREMIUM"
    ADD CONSTRAINT "PREMIUM_pkey" PRIMARY KEY (u_id);
 B   ALTER TABLE ONLY public."PREMIUM" DROP CONSTRAINT "PREMIUM_pkey";
       public            postgres    false    218            �           2606    17758 "   PRODUCT_REVIEW PRODUCT_REVIEW_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public."PRODUCT_REVIEW"
    ADD CONSTRAINT "PRODUCT_REVIEW_pkey" PRIMARY KEY (shop_id, product_id, reviewer_id);
 P   ALTER TABLE ONLY public."PRODUCT_REVIEW" DROP CONSTRAINT "PRODUCT_REVIEW_pkey";
       public            postgres    false    225    225    225            �           2606    17414    PRODUCT PRODUCT_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public."PRODUCT"
    ADD CONSTRAINT "PRODUCT_pkey" PRIMARY KEY (id);
 B   ALTER TABLE ONLY public."PRODUCT" DROP CONSTRAINT "PRODUCT_pkey";
       public            postgres    false    211            �           2606    17444    SHOP_PRODUCT SHOP_PRODUCT_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public."SHOP_PRODUCT"
    ADD CONSTRAINT "SHOP_PRODUCT_pkey" PRIMARY KEY (s_id, p_id);
 L   ALTER TABLE ONLY public."SHOP_PRODUCT" DROP CONSTRAINT "SHOP_PRODUCT_pkey";
       public            postgres    false    213    213            �           2606    17517    SHOP_REVIEW SHOP_REVIEW_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public."SHOP_REVIEW"
    ADD CONSTRAINT "SHOP_REVIEW_pkey" PRIMARY KEY (shop_id, reviewer_id);
 J   ALTER TABLE ONLY public."SHOP_REVIEW" DROP CONSTRAINT "SHOP_REVIEW_pkey";
       public            postgres    false    216    216            �           2606    17382    SHOP SHOP_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public."SHOP"
    ADD CONSTRAINT "SHOP_pkey" PRIMARY KEY (id);
 <   ALTER TABLE ONLY public."SHOP" DROP CONSTRAINT "SHOP_pkey";
       public            postgres    false    210            �           2606    17742    SNA SNA_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY public."SNA"
    ADD CONSTRAINT "SNA_pkey" PRIMARY KEY (shop_id, product_id, buyer_id);
 :   ALTER TABLE ONLY public."SNA" DROP CONSTRAINT "SNA_pkey";
       public            postgres    false    224    224    224            �           2606    17617    TRANSACTION TRANSACTION_pkey 
   CONSTRAINT     |   ALTER TABLE ONLY public."TRANSACTION"
    ADD CONSTRAINT "TRANSACTION_pkey" PRIMARY KEY (w_u_id, w_p_id, cc_u_id, cc_p_id);
 J   ALTER TABLE ONLY public."TRANSACTION" DROP CONSTRAINT "TRANSACTION_pkey";
       public            postgres    false    222    222    222    222            �           2606    17622    TRANSACTION TR_IDS 
   CONSTRAINT     m   ALTER TABLE ONLY public."TRANSACTION"
    ADD CONSTRAINT "TR_IDS" UNIQUE (w_u_id, w_p_id, cc_u_id, cc_p_id);
 @   ALTER TABLE ONLY public."TRANSACTION" DROP CONSTRAINT "TR_IDS";
       public            postgres    false    222    222    222    222            �           2606    17583    VARIANT VARIANT_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public."VARIANT"
    ADD CONSTRAINT "VARIANT_pkey" PRIMARY KEY (p_id, p_vart_id);
 B   ALTER TABLE ONLY public."VARIANT" DROP CONSTRAINT "VARIANT_pkey";
       public            postgres    false    221    221            �           2606    17491    WALLET WALLET_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public."WALLET"
    ADD CONSTRAINT "WALLET_pkey" PRIMARY KEY (u_id, p_id);
 @   ALTER TABLE ONLY public."WALLET" DROP CONSTRAINT "WALLET_pkey";
       public            postgres    false    214    214                       2620    17984    ORDER delete_on_zero    TRIGGER     t   CREATE TRIGGER delete_on_zero AFTER UPDATE ON public."ORDER" FOR EACH ROW EXECUTE FUNCTION public.delete_on_zero();
 /   DROP TRIGGER delete_on_zero ON public."ORDER";
       public          postgres    false    230    228                        2620    17994    ORDER order_premium_check    TRIGGER     �   CREATE TRIGGER order_premium_check BEFORE INSERT OR UPDATE ON public."ORDER" FOR EACH ROW EXECUTE FUNCTION public.check_premium_order();
 4   DROP TRIGGER order_premium_check ON public."ORDER";
       public          postgres    false    246    228            !           2620    17991    ORDER trigger_update_payment    TRIGGER     �   CREATE TRIGGER trigger_update_payment BEFORE INSERT OR UPDATE ON public."ORDER" FOR EACH ROW EXECUTE FUNCTION public.update_payment();
 7   DROP TRIGGER trigger_update_payment ON public."ORDER";
       public          postgres    false    228    236            #           2620    17979    ORDER trigger_update_points    TRIGGER     �   CREATE TRIGGER trigger_update_points AFTER INSERT ON public."ORDER" FOR EACH ROW EXECUTE FUNCTION public.update_customer_points();
 6   DROP TRIGGER trigger_update_points ON public."ORDER";
       public          postgres    false    228    243                       2620    17988 +   PRODUCT_REVIEW trigger_update_product_score    TRIGGER     �   CREATE TRIGGER trigger_update_product_score AFTER INSERT OR UPDATE ON public."PRODUCT_REVIEW" FOR EACH ROW EXECUTE FUNCTION public.update_product_score();
 F   DROP TRIGGER trigger_update_product_score ON public."PRODUCT_REVIEW";
       public          postgres    false    231    225                       2620    17986 %   SHOP_REVIEW trigger_update_shop_score    TRIGGER     �   CREATE TRIGGER trigger_update_shop_score AFTER INSERT OR UPDATE ON public."SHOP_REVIEW" FOR EACH ROW EXECUTE FUNCTION public.update_shop_score();
 @   DROP TRIGGER trigger_update_shop_score ON public."SHOP_REVIEW";
       public          postgres    false    216    229                       2620    17832 )   TRANSACTION trigger_update_wallet_balance    TRIGGER     �   CREATE TRIGGER trigger_update_wallet_balance AFTER INSERT ON public."TRANSACTION" FOR EACH ROW EXECUTE FUNCTION public.update_wallet_balance();
 D   DROP TRIGGER trigger_update_wallet_balance ON public."TRANSACTION";
       public          postgres    false    232    222            "           2620    17980 #   ORDER validate_order_status_trigger    TRIGGER     �   CREATE TRIGGER validate_order_status_trigger BEFORE INSERT OR UPDATE ON public."ORDER" FOR EACH ROW EXECUTE FUNCTION public.validate_order_status();
 >   DROP TRIGGER validate_order_status_trigger ON public."ORDER";
       public          postgres    false    247    228                       2606    17949    ORDER ADDRESS    FK CONSTRAINT     �   ALTER TABLE ONLY public."ORDER"
    ADD CONSTRAINT "ADDRESS" FOREIGN KEY (address, u_id) REFERENCES public."ADDRESSES"(address, u_id) MATCH FULL ON UPDATE CASCADE ON DELETE RESTRICT;
 ;   ALTER TABLE ONLY public."ORDER" DROP CONSTRAINT "ADDRESS";
       public          postgres    false    228    228    3298    217    217                       2606    17748 	   SNA BUYER    FK CONSTRAINT     �   ALTER TABLE ONLY public."SNA"
    ADD CONSTRAINT "BUYER" FOREIGN KEY (buyer_id) REFERENCES public."CUSTOMER"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 7   ALTER TABLE ONLY public."SNA" DROP CONSTRAINT "BUYER";
       public          postgres    false    3280    224    209                       2606    17632    TRANSACTION CC_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."TRANSACTION"
    ADD CONSTRAINT "CC_ID" FOREIGN KEY (cc_u_id, cc_p_id) REFERENCES public."CCARD"(u_id, p_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 ?   ALTER TABLE ONLY public."TRANSACTION" DROP CONSTRAINT "CC_ID";
       public          postgres    false    222    215    215    3292    222                       2606    17779    COLLECTION COLLECTOR_AFF    FK CONSTRAINT     �   ALTER TABLE ONLY public."COLLECTION"
    ADD CONSTRAINT "COLLECTOR_AFF" FOREIGN KEY (collector_id) REFERENCES public."AFFILIATE"(u_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 F   ALTER TABLE ONLY public."COLLECTION" DROP CONSTRAINT "COLLECTOR_AFF";
       public          postgres    false    219    226    3302                       2606    17728    LISTS CUSTOMER    FK CONSTRAINT     �   ALTER TABLE ONLY public."LISTS"
    ADD CONSTRAINT "CUSTOMER" FOREIGN KEY (buyer_id) REFERENCES public."CUSTOMER"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 <   ALTER TABLE ONLY public."LISTS" DROP CONSTRAINT "CUSTOMER";
       public          postgres    false    3280    223    209                       2606    17954    ORDER CUSTOMERKEY    FK CONSTRAINT     �   ALTER TABLE ONLY public."ORDER"
    ADD CONSTRAINT "CUSTOMERKEY" FOREIGN KEY (u_id) REFERENCES public."CUSTOMER"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 ?   ALTER TABLE ONLY public."ORDER" DROP CONSTRAINT "CUSTOMERKEY";
       public          postgres    false    228    209    3280                       2606    17523    SHOP_REVIEW CUSTOMER_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."SHOP_REVIEW"
    ADD CONSTRAINT "CUSTOMER_ID" FOREIGN KEY (reviewer_id) REFERENCES public."CUSTOMER"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 E   ALTER TABLE ONLY public."SHOP_REVIEW" DROP CONSTRAINT "CUSTOMER_ID";
       public          postgres    false    216    3280    209                       2606    17544    ADDRESSES CUSTOMER_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."ADDRESSES"
    ADD CONSTRAINT "CUSTOMER_ID" FOREIGN KEY (u_id) REFERENCES public."CUSTOMER"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 C   ALTER TABLE ONLY public."ADDRESSES" DROP CONSTRAINT "CUSTOMER_ID";
       public          postgres    false    3280    217    209                       2606    17559    AFFILIATE CUSTOMER_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."AFFILIATE"
    ADD CONSTRAINT "CUSTOMER_ID" FOREIGN KEY (u_id) REFERENCES public."CUSTOMER"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 C   ALTER TABLE ONLY public."AFFILIATE" DROP CONSTRAINT "CUSTOMER_ID";
       public          postgres    false    219    209    3280                       2606    17564    PREMIUM CUSTOMER_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."PREMIUM"
    ADD CONSTRAINT "CUSTOMER_ID" FOREIGN KEY (u_id) REFERENCES public."CUSTOMER"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 A   ALTER TABLE ONLY public."PREMIUM" DROP CONSTRAINT "CUSTOMER_ID";
       public          postgres    false    3280    218    209                       2606    17959    ORDER LOGISTIC_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."ORDER"
    ADD CONSTRAINT "LOGISTIC_ID" FOREIGN KEY (log_id) REFERENCES public."LOGISTICS"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 ?   ALTER TABLE ONLY public."ORDER" DROP CONSTRAINT "LOGISTIC_ID";
       public          postgres    false    228    212    3286                       2606    17813    CCARD PAYMENT    FK CONSTRAINT     �   ALTER TABLE ONLY public."CCARD"
    ADD CONSTRAINT "PAYMENT" FOREIGN KEY (u_id, p_id) REFERENCES public."PAYMENT"(p_u_id, p_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 ;   ALTER TABLE ONLY public."CCARD" DROP CONSTRAINT "PAYMENT";
       public          postgres    false    227    3324    215    215    227                       2606    17964    ORDER PAYMENT    FK CONSTRAINT     �   ALTER TABLE ONLY public."ORDER"
    ADD CONSTRAINT "PAYMENT" FOREIGN KEY (payer_id, pay_id) REFERENCES public."PAYMENT"(p_u_id, p_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 ;   ALTER TABLE ONLY public."ORDER" DROP CONSTRAINT "PAYMENT";
       public          postgres    false    227    228    228    3324    227                       2606    17808    WALLET PAYMENT_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."WALLET"
    ADD CONSTRAINT "PAYMENT_ID" FOREIGN KEY (u_id, p_id) REFERENCES public."PAYMENT"(p_u_id, p_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 ?   ALTER TABLE ONLY public."WALLET" DROP CONSTRAINT "PAYMENT_ID";
       public          postgres    false    227    214    214    227    3324            �           2606    17461    SHOP_PRODUCT PRODUCT_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."SHOP_PRODUCT"
    ADD CONSTRAINT "PRODUCT_ID" FOREIGN KEY (p_id) REFERENCES public."PRODUCT"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 E   ALTER TABLE ONLY public."SHOP_PRODUCT" DROP CONSTRAINT "PRODUCT_ID";
       public          postgres    false    213    3284    211                       2606    17574    CATEGORIES PRODUCT_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."CATEGORIES"
    ADD CONSTRAINT "PRODUCT_ID" FOREIGN KEY (p_id) REFERENCES public."PRODUCT"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 C   ALTER TABLE ONLY public."CATEGORIES" DROP CONSTRAINT "PRODUCT_ID";
       public          postgres    false    211    220    3284            	           2606    17584    VARIANT PRODUCT_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."VARIANT"
    ADD CONSTRAINT "PRODUCT_ID" FOREIGN KEY (p_id) REFERENCES public."PRODUCT"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 @   ALTER TABLE ONLY public."VARIANT" DROP CONSTRAINT "PRODUCT_ID";
       public          postgres    false    211    221    3284                       2606    17969    ORDER REFFERAL    FK CONSTRAINT     �   ALTER TABLE ONLY public."ORDER"
    ADD CONSTRAINT "REFFERAL" FOREIGN KEY (refer_id) REFERENCES public."AFFILIATE"(aff_code) ON UPDATE SET NULL ON DELETE SET NULL;
 <   ALTER TABLE ONLY public."ORDER" DROP CONSTRAINT "REFFERAL";
       public          postgres    false    228    219    3304                       2606    17764    PRODUCT_REVIEW REVIEWER    FK CONSTRAINT     �   ALTER TABLE ONLY public."PRODUCT_REVIEW"
    ADD CONSTRAINT "REVIEWER" FOREIGN KEY (reviewer_id) REFERENCES public."CUSTOMER"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 E   ALTER TABLE ONLY public."PRODUCT_REVIEW" DROP CONSTRAINT "REVIEWER";
       public          postgres    false    3280    225    209                        2606    17471    SHOP_PRODUCT SHOP_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."SHOP_PRODUCT"
    ADD CONSTRAINT "SHOP_ID" FOREIGN KEY (s_id) REFERENCES public."SHOP"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 B   ALTER TABLE ONLY public."SHOP_PRODUCT" DROP CONSTRAINT "SHOP_ID";
       public          postgres    false    213    3282    210                       2606    17518    SHOP_REVIEW SHOP_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."SHOP_REVIEW"
    ADD CONSTRAINT "SHOP_ID" FOREIGN KEY (shop_id) REFERENCES public."SHOP"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 A   ALTER TABLE ONLY public."SHOP_REVIEW" DROP CONSTRAINT "SHOP_ID";
       public          postgres    false    216    210    3282                       2606    17733    LISTS SP    FK CONSTRAINT     �   ALTER TABLE ONLY public."LISTS"
    ADD CONSTRAINT "SP" FOREIGN KEY (shop_id, product_id) REFERENCES public."SHOP_PRODUCT"(s_id, p_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 6   ALTER TABLE ONLY public."LISTS" DROP CONSTRAINT "SP";
       public          postgres    false    223    213    213    3288    223                       2606    17743    SNA SP    FK CONSTRAINT     �   ALTER TABLE ONLY public."SNA"
    ADD CONSTRAINT "SP" FOREIGN KEY (shop_id, product_id) REFERENCES public."SHOP_PRODUCT"(s_id, p_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 4   ALTER TABLE ONLY public."SNA" DROP CONSTRAINT "SP";
       public          postgres    false    213    224    3288    213    224                       2606    17759    PRODUCT_REVIEW SP    FK CONSTRAINT     �   ALTER TABLE ONLY public."PRODUCT_REVIEW"
    ADD CONSTRAINT "SP" FOREIGN KEY (shop_id, product_id) REFERENCES public."SHOP_PRODUCT"(s_id, p_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 ?   ALTER TABLE ONLY public."PRODUCT_REVIEW" DROP CONSTRAINT "SP";
       public          postgres    false    3288    225    213    213    225                       2606    17774    COLLECTION SP    FK CONSTRAINT     �   ALTER TABLE ONLY public."COLLECTION"
    ADD CONSTRAINT "SP" FOREIGN KEY (shop_id, product_id) REFERENCES public."SHOP_PRODUCT"(s_id, p_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 ;   ALTER TABLE ONLY public."COLLECTION" DROP CONSTRAINT "SP";
       public          postgres    false    226    213    213    3288    226                       2606    17974 
   ORDER SPID    FK CONSTRAINT     �   ALTER TABLE ONLY public."ORDER"
    ADD CONSTRAINT "SPID" FOREIGN KEY (sp_id, sp_shop_id) REFERENCES public."SHOP_PRODUCT"(p_id, s_id) MATCH FULL;
 8   ALTER TABLE ONLY public."ORDER" DROP CONSTRAINT "SPID";
       public          postgres    false    3288    228    213    213    228                       2606    17840    PAYMENT USER    FK CONSTRAINT     �   ALTER TABLE ONLY public."PAYMENT"
    ADD CONSTRAINT "USER" FOREIGN KEY (p_u_id) REFERENCES public."CUSTOMER"(id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 :   ALTER TABLE ONLY public."PAYMENT" DROP CONSTRAINT "USER";
       public          postgres    false    3280    227    209            
           2606    17589    VARIANT VARIANT_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."VARIANT"
    ADD CONSTRAINT "VARIANT_ID" FOREIGN KEY (p_vart_id) REFERENCES public."PRODUCT"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 @   ALTER TABLE ONLY public."VARIANT" DROP CONSTRAINT "VARIANT_ID";
       public          postgres    false    3284    211    221                       2606    17637    TRANSACTION W_ID    FK CONSTRAINT     �   ALTER TABLE ONLY public."TRANSACTION"
    ADD CONSTRAINT "W_ID" FOREIGN KEY (w_u_id, w_p_id) REFERENCES public."WALLET"(u_id, p_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 >   ALTER TABLE ONLY public."TRANSACTION" DROP CONSTRAINT "W_ID";
       public          postgres    false    222    222    3290    214    214            �   I  x�U�[N�0E��U��*�6�_�!�PQZ����X�I����v�`_L)���5s5����=��$�%O��s����o����+,���W�0�B*˚��T[i���t�	vNuXK�8MɌ̺vȖ�|lv�+�z~�$����N��0r2}�\�J'0?��F@&�BX�|�ti;ɐ������FcqS�U^��D1�0��`%-6�*�G���Y%ja�iڳ��z.Ku����VbM�r�Cc�=�F�T?�R��F��^�`{��X��U�X�\T���R����Bn1'���r���K%`f8\���Z�{��8�7?݈y      �   I   x�=ȩ� @A�-&oX@�����H�#g�ǮgN�(5e��\��\�Wϥr��8�:���9S�ʾE�F'�      �   �   x�u��
�0E���H2}鲈BwE7nj��6%M�^b��x��f2�\LG�]�Jktw+��)A��'U���(�Bh�,���s��muۏV�bh�,���WS��c�	tvtO����'�pKn��+aG��۪�N0��@!H��� �����h��^�/�k����|�Y�?�8�O!���      �     x�]��J�0F�_�"OP���o�BuPp�Bô��3>�/�٪�Y�C��_8���~�|d_��u�s��J*Md���(�+v�H��M�D��©��$����*�2�
?Ϯ�p�4H�@���JI�؟��=���:�́+�N�J����#ۜ붭I�@�{uR-��[j6e�B��f�΁Y��:��\XW�t8_����.�γy�c!I�Lh����z�؏c�6ds`W��S�)p�g���o�i�n��r ����(�oq�      �   p   x�}�=
�0@��F��/���Pܼ�9,h�[3=�G���N�N�/_).�t���%\�%��2��2.�
��
.�*�pWp�qWq�.�����?w���Wܩ��s���E�A�R�      �   N  x�U�Mn�0��/wq�ۉ��4��O(�Jl�6�TT��z�:�ZwV�|�޼Y��(��m]!��Ou�Q'�TJ��I3r��̄�%��aZc3Ǻ�1����MIݠ��L	i0�e,���c�q�m���jb	�Y��N	�q$s}�����j</����1Ȭ��G���(1i?���y,��ښ�B� �������Ū�4�0�f�c2,'(�O�1k�!C���K�P�QT��	V�O�弻Թ�9���bKהN^�AAh��k���~_�øک�Qk�T�l�p�}o���|�,0+�4ʅs8~�ROr�?��%I���{�      �   �   x�U��
�0���>A�ts����4��f��A*���R�ֹ���v�aU2WJ�H�ӱ��T��8�mT-�"���\��ƺ"�`DFj}��OA�"���N�zR6��`�T�j
! 8'�gcƿ�
	Q@�4n�6�!V�&B��z3�a	��	!�~}�@��WAW���Sի�}��m�(z�lp      �   �   x�m̻�0���y
� ��Q/0d�Բ������8E-O��|�����PT���Xg�?0�ܞ�^�)�;-��E)�6W��H�9`Ϳ*|�hz-��o�e�-!�<�A��CB�G�`	�!���BG�ut4�l����X)�5�Z      �   �  x����N�P�߇��Tsfη�)����Kb�!�UK7��׵�����v[�%cN��<yg�e��?���t�~RlD׆t�-�=MW���3I*�� ���A?]��%Y$�0���8��$�/�s�q���N������J��X�ΖI0�������K�}��=+���գ^PH�X���@$�$�$�$�$�*QL 7ӟ�$���*}[o�e�e��3�a��m
q�rxg������),)lUa۷�xH�Ɏ�M� �#��B\�ƀ��q�ƃ�*�Q���s����Ԯ' �ɲ�|�MM����	�'��y|Ԏ�=��@�=A��\9�O�Tw��Ȯ���@����C	4��V����s��i��z��aw:[%6�L�x��9˫d`��R�u�G���ྴ�u*A*�T�Tp�J�V�Ź���I�H���U��QyI�H��E� ad5zJ���5���-w�;H~�t5��	�d���0l?L��=�0�#eu�� � ��0ui�� aw�Q�%F�f��3VX!�R��,?�I�?�JN++����q.,|/(��T���V�8���=�JN�q��h��r�ӓ� ��+koY���֜�%ǥ\���w�mޑ.yЅMC�XZF��h�O8^�؆e�j#�<�t5<"�;��?���      �   M   x�mϻ�@��v��]�\p��A L�F/�{��)͏X���%�`�X�V��5l`�57l`�p�B�.��/�      �   W   x��α�0�Zv��@�:H:���B���Pq��@�]�(��O+�&��u��qT6��� ��y�A~��������?///?W"� }�:j      �      x�]��R�0���)�wtH�^�T�2��vt�h�.aBX��u��	�b0�,�/��9I`� �!�����Y����N����W_s�J�j*}ǁ��іKV���Ȥ�5�\�G(y��5�JԚ�F.ϸ��C�$h�ŐLa���i�v�G5��I�ܡ����XB:s�D����4L�+E����B��7��m�'(�^`�)�Y�AB�@"5R���L�v�h��cs�a��`/�8~�	�Ԁ�&���'�E
�I�Ӑ?tq����8��~|ں�oW�a�XQ��      �   �  x�}�O��0���)��^VQ�@B��Z��R�6mO�3�cS{�o߁$^Z�A��{~���i}y6�s���>���5���*Hz�d�<=]�F�n!zt(|'��d� mJA�����?VY��&��pe�<<�p@v4X%�j�(ϣ��숮�)Ӏ=��\0����sTk�կ���Yt�G�,y���*'��]A��N��2����5-%��|y�;D�<�*J��ug�̭��[��P�����%*��1s(ok&�"sS��1�T�E~H����$�
~�/!�wY˪��u�0�j��Z�8#����=^�seP�����o-�Ɖ����?�n֗C�4f�6j�QS,J{��
�Gq�c� 57��hp��EU?H� Y���@N�3�����-nZ���ӧ�����_��̼�N���E?9kZ�w�����S��n����/��Ĭdݵ�X�J��4_�}�c���o�#      �   �  x�E��r�0�ח��$lBv��������%ۊ��J��A���d�^�5ڝ#�;�:yt^1�:�:��
�?$7������+�Xv�ZkZ�#L'qd��W}w���7�6�;(!��(�`g�֊i����P�Li{I���|�]j�H����<!�Ӂp��@��VT
l��L�-,*|Hv��$O�y�F�VKa��ҁP���`�A[	���?��6HRz���c��~�`Qr�9���~�'�~w� �����B+a��˫A��9J��Oڐ$�e⯄����lQA����e�������Н����	�lCz<�M��?K=�5�sz�U0(���]�3���IE�X��kS�עآ�s�gǳ�[mo��@��]�	�D"�hO}��� ����J��K,�״P~TU������f3��^z�AG��?���7      �   !  x���An� E��0�mL�t_ʹ�J��9j0��N� O���~�=�v2�	ߏ��@�l�o"Aл�Ǐ2 GH�4�.��mt��T&F&�Cd�[P��j���c��館�~�����WC_~-�J�+U3оry�\�4�k��8y��e%�l*�%���lgR��&B���=IJi�H�B�Z��a�.$) m ��;�.-Yk����DM�1^W6�s�`Զ�fCA�)�ǁ�@N8{����5�<j�琦�}W)ȵ�y�85$(�;��p������p��γJ      �   w  x�m�Kr�0���)�4������M7�#�'N�p�����MVY賤��n�s�N�s�U������j�^XϢݭ|�� K�5H�L}�]��F���+����,Ak�=��yS��@dIHJH�6���X��W�ڜhP��k�2�R��
୰
���=>`� ��69{�P�P�� �BFy�����T��-�_�!h\�|��IL\�d�㘺�zJȣ8����	\�u(��m�@��@�0dӁ�ψ]ߤ ��Z�I�?i�fd���=:��X�KT2:����̌vYM�] 6��V
(8��GD���5���^�@�uwP���L��tS³�
[�𽱼25\��?�(�~ K��      �   #   x�6� C� 8+�2202�50�54������ ��.      �   l   x�m�K
�0E�q�^�$6���I��_�HI,؎��]�y<���R���0���Ʋ��'��fo�ulXm�RX�bS����YX!�+XM�rX%ѹ�Xm�JX�:g��?�?i      �   0   x�0� C� (ˈ�2����Ōa�b�0��X�r��qqq �K      �   h   x�]�K
� ��x��h�ݢ��z�s�b��o&i4�q��y�[V�d�,d�p�����H/��b�^?
8�<tCQL�d�Q5���&�2��{r�9�     