-- Copy to 030_expand_product_identity.sql and complete it.
-- Add a stored UUID to each product and a unique key.
-- Add the nullable ticket reference and a NOT VALID foreign key.
-- Keep the original product code contract usable.

begin;
-- use a short lock timeout
set local lock_timeout = '3s';

-- TODO: migration DDL.

-- add unique stored uuid to each product
-- with a default so existing application inserts
-- remain usable without supplying an id
alter table products
    add column id uuid default gen_random_uuid(),
    add constraint products_id_unique unique (id);

-- generate and set id to random uuid
update products
set id = gen_random_uuid()
where id is null;

-- require column id is not null
alter table products
    alter column id set not null;

-- add nullable column product_id to tickets;
-- making it nullable ensures we can continue
-- using the old product_code reference 
-- alongside the new product_id and apply the switch gradually.
alter table tickets
    add column product_id uuid;

-- add the fk constraint as not valid;
-- not valid ensures that PostgreSQL doesn't
-- scan all existing rows to validate them.
alter table tickets
    add constraint tickets_product_id_fk foreign key (product_id) references products(id)
    not valid;

commit;