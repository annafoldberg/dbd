-- TODO: Extend this query to return a resolved_product_id.
-- Join by product_id when present; otherwise look up the product by code.
-- Before backfill, your query should still resolve every original ticket.
select t.id, t.product_code, t.product_id, p.id as resolved_product_id, t.price, t.currency
from tickets t
join products p
    on p.id = t.product_id
    or (
        t.product_id is null
        and p.code = t.product_code
    )
order by t.id;