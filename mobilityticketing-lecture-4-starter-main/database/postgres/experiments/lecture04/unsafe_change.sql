-- Use only your disposable lab database. Predict the failure first.

begin;

-- TODO: Drop tickets.product_code, then run the old reader or writer.

alter table tickets
    drop column product_code;

commit;
-- What information would you need to reconstruct the product links?
-- The existing product_code values should be mapped to the new product_id.

-- rollback;
-- If psql stops on the expected error, the connection closing rolls back
-- this transaction. In an interactive session, issue ROLLBACK yourself.