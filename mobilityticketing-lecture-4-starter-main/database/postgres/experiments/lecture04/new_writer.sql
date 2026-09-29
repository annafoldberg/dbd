-- After expansion, use this query to choose a product ID for your test.
select id, code, price, currency from products order by code;

-- TODO: Write a function or parameterized insert that accepts a product ID.
-- Look up its code and store both references on the ticket.
-- Use old_writer.sql as a guide to the other required ticket fields.
-- Keep the agreed price as an input; do not copy the current catalogue price.
-- Test an unknown ID and a supplied code belonging to another product.
\set ticket_id 'LAB04-NEW-1'
\set ticket_code 'LAB04-CODE-NEW-1'
\set product_id '5419f103-572c-457d-a4c8-778098ee420d'
\set product_code 'SINGLE'
\set price '100.00'

insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_code, product_id,
     valid_from_utc, valid_to_utc, price, currency)
select :'ticket_id', t.user_id, t.trip_id, :'ticket_code', t.status, p.code, p.id,
       t.valid_from_utc, t.valid_to_utc, :'price', t.currency
from tickets t
join products p
    on p.id = :'product_id'::uuid
where t.id = 'TICKET-1';