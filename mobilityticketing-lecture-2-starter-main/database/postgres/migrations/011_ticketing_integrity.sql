-- Copy this file to 011_ticketing_integrity.sql and complete it from your integrity map.
-- Keep the starter DDL unchanged.

begin;

-- Trip capacity cannot be negative
-- Reserved seats cannot be negative or greater than capacity
-- Status values must come from a known set
alter table trips
    alter column capacity set not null,
    alter column reserved_seats set not null,
    alter column status set not null,
    add constraint trips_capacity_non_negative
        check (capacity >= 0),
    add constraint trips_reserved_seats_valid
        check (reserved_seats between 0 and capacity),
    add constraint trips_status_valid
        check (status in ('Scheduled', 'On-time', 'Delayed', 'Early', 'Cancelled'));

-- A ticket must refer to an existing trip
-- Ticket price cannot be negative
-- Ticket codes must support unambiguous lookup
-- A ticket validity end cannot be earlier than its start
-- ! A ticket must refer to an existing product
-- Currency must be present
-- Status values must come from a known set
alter table tickets
    alter column trip_id set not null,
    alter column product_code set not null,
    alter column price set not null,
    alter column ticket_code set not null,
    alter column currency set not null,
    alter column status set not null,
    add constraint tickets_user_fk
        foreign key (user_id) references users(id),
    add constraint tickets_trip_fk
        foreign key (trip_id) references trips(id),
    add constraint tickets_product_fk
        foreign key (product_code) references products(code),
    add constraint tickets_price_non_negative
        check (price >= 0),
    add constraint tickets_ticket_code_unique
        unique (ticket_code),
    add constraint tickets_validity_start_before_end
        check (valid_from_utc <= valid_to_utc),
    add constraint tickets_id_ticket_code_unique
        unique (id, ticket_code),
    add constraint tickets_status_valid
        check (status in ('Pending', 'Active', 'Validated', 'Cancelled', 'Expired'));

-- Payment amount cannot be negative
-- A payment must refer to an existing ticket
-- An external payment reference should not be recorded twice
-- if it represents one captured payment
-- Currency must be present
-- Status values must come from a known set
alter table payments
    alter column ticket_id set not null,
    alter column amount set not null,
    alter column currency set not null,
    alter column status set not null,
    add constraint payments_ticket_fk
        foreign key (ticket_id) references tickets(id),
    add constraint payments_amount_non_negative
        check (amount >= 0),
    add constraint payments_external_payment_reference
        unique (external_payment_reference),
    add constraint payments_status_valid
        check (status in ('Pending', 'Captured', 'Declined'));

-- A validation must refer to an existing ticket
-- ! A validation’s ticket_id and ticket_code must identify the same ticket
-- ! Result values must come from a known set
alter table validations
    alter column ticket_id set not null,
    alter column ticket_code set not null,
    alter column result set not null,
    add constraint validations_ticket_fk
        foreign key (ticket_id, ticket_code) references tickets(id, ticket_code),
    add constraint validations_result_valid
        check (result in ('Accepted', 'Declined'));

-- Product price cannot be negative
-- Currency must be present
alter table products
    alter column price set not null,
    alter column currency set not null,
    add constraint products_price_non_negative
        check (price >= 0);

-- TODO: product reference, ticket-code identity, status, price,
-- currency, validity window and remaining foreign keys.
-- Decide how duplicated validations.ticket_code should be protected.
-- Name every constraint so tests and later migrations can identify it.

commit;

-- I have generally not implemented constraints that I have identified personally
-- but instead remained focused on implementing the minimum invariants to consider
-- together with the constraints specified in the TODO