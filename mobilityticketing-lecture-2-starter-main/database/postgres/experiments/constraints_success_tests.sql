-- Run each statement separately after applying the integrity migration.
-- Every statement below should succeed.

-- 1. Valid capacity and reserved seats.
update trips
set capacity = 100,
    reserved_seats = 50
where id = 'TRIP-M2-20260429-0800';


-- 2. Valid product price and currency.
update products
set price = 36,
    currency = 'DKK'
where code = 'SINGLE';


-- 3. Valid ticket.
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'T-VALID-TEST', 'USER-1', 'TRIP-M2-20260429-0800',
    'CODE-VALID-TEST', 'Active', 'SINGLE',
    '2026-04-29 08:00:00+00', '2026-04-29 09:00:00+00',
    36, 'DKK'
);


-- 4. Valid payment referencing the ticket created above.
insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status
) values (
    'PAYMENT-VALID-TEST', 'USER-1', 'T-VALID-TEST',
    'gateway-capture-valid-test', 36, 'DKK', 'Captured'
);


-- 5. Valid validation where ticket_id and ticket_code
-- identify the same ticket.
insert into validations (
    id, ticket_id, ticket_code, vehicle_id,
    stop_id, device_id, result
) values (
    'VALIDATION-VALID-TEST',
    'T-VALID-TEST', 'CODE-VALID-TEST',
    'TRAIN-M2-01', 'STOP-CENTRAL', 'DEVICE-01', 'Accepted'
);