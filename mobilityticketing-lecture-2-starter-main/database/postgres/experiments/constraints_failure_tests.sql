-- 11. Negative ticket price. Expected: CHECK violation.
update tickets
set price = -1
where id = 'TICKET-1';


-- 12. Negative payment amount. Expected: CHECK violation.
update payments
set amount = -1
where id = 'PAYMENT-1';


-- 13. Missing product currency. Expected: NOT NULL violation.
update products
set currency = null
where code = 'SINGLE';


-- 14. Missing ticket currency. Expected: NOT NULL violation.
update tickets
set currency = null
where id = 'TICKET-1';


-- 15. Missing payment currency. Expected: NOT NULL violation.
update payments
set currency = null
where id = 'PAYMENT-1';


-- 16. Unknown product referenced by ticket. Expected: FOREIGN KEY violation.
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'T-INVALID-PRODUCT', 'USER-1', 'TRIP-M2-20260429-0800',
    'CODE-INVALID-PRODUCT', 'Active', 'NO-SUCH-PRODUCT',
    '2026-04-29 08:00:00+00', '2026-04-29 09:00:00+00',
    36, 'DKK'
);


-- 17. Unknown validation result. Expected: CHECK violation.
insert into validations (
    id, ticket_id, ticket_code, vehicle_id,
    stop_id, device_id, result
) values (
    'VALIDATION-INVALID-RESULT',
    'TICKET-1', 'CODE-M2-0001',
    'TRAIN-M2-01', 'STOP-CENTRAL', 'DEVICE-01', 'Unknown'
);

-- 18. Unknown trip status. Expected: CHECK violation.
update trips
set status = 'Unknown'
where id = 'TRIP-M2-20260429-0800';

-- 19. Unknown payment status. Expected: CHECK violation.
update payments
set status = 'Unknown'
where id = 'PAYMENT-1';

-- 20. Validation for an unknown ticket. Expected: FOREIGN KEY violation.
insert into validations (
    id, ticket_id, ticket_code, vehicle_id, stop_id, device_id, result
) values (
    'VALIDATION-UNKNOWN-TICKET',
    'NO-SUCH-TICKET',
    'NO-SUCH-CODE',
    'BUS-5C-01',
    'STOP-CENTRAL',
    'DEVICE-01',
    'Accepted'
);