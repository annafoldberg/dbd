-- TODO: Adapt your new writer to use product_id without tickets.product_code.
-- Keep id, user_id, trip_id, ticket_code, status, validity dates, price and
-- currency in the insert. Use a fresh ticket ID and ticket code.
-- Test after removing the old column. If you try it while that column still
-- exists, check whether its NOT NULL constraint allows the insert.
\set ticket_id 'LAB04-FINAL-1'
\set ticket_code 'LAB04-CODE-FINAL-1'
\set product_id '5419f103-572c-457d-a4c8-778098ee420d'
\set price '100.00'

insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_id,
     valid_from_utc, valid_to_utc, price, currency)
select :'ticket_id', t.user_id, t.trip_id, :'ticket_code', t.status, p.id,
       t.valid_from_utc, t.valid_to_utc, :'price', t.currency
from tickets t
join products p
    on p.id = :'product_id'::uuid
where t.id = 'TICKET-1';