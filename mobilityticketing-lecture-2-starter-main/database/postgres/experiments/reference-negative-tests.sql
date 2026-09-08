-- CHECK violation: expected SQLSTATE 23514
update trips
set reserved_seats = capacity + 1
where id = 'TRIP-M2-20260429-0800';

-- FOREIGN KEY violation: expected SQLSTATE 23503
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'T-UNKNOWN-TRIP', 'USER-1', 'NO-SUCH-TRIP', 'UNKNOWN-1',
    'Active', 'SINGLE', now(), now() + interval '1 hour', 36, 'DKK'
);

-- UNIQUE violation: expected SQLSTATE 23505
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
)
select
    'T-DUPLICATE-CODE', user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
from tickets
limit 1;

-- Reversed validity window: expected SQLSTATE 23514
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'T-REVERSED', 'USER-1', 'TRIP-M2-20260429-0800', 'REVERSED-1',
    'Active', 'SINGLE', now(), now() - interval '1 hour', 36, 'DKK'
);