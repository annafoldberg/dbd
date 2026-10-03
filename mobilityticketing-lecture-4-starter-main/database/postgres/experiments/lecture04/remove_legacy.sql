-- Start only after your ID-only reader and writer are ready.
begin;
set local lock_timeout = '3s';

-- TODO: Inspect views and functions that use tickets.product_code.
-- Update or remove those dependencies deliberately.
-- Drop the column without CASCADE and test your final reader and writer.

select schemaname, viewname, definition
from pg_views
where definition ilike '%product_code%';

select routine_schema, routine_name, routine_definition
from information_schema.routines
where routine_definition ilike '%product_code%';

alter table tickets
    drop column product_code;

rollback;
-- Keep this rehearsal reversible. Record what would need to happen before
-- you committed the same change in a real rollout.
