alter table products
    alter column name set not null,
    alter column price set not null,
    alter column currency set not null,
    add constraint products_price_non_negative check (price >= 0),
    add constraint products_currency_iso_length check (char_length(currency) = 3);

alter table trips
    alter column capacity set not null,
    alter column reserved_seats set not null,
    add constraint trips_capacity_non_negative check (capacity >= 0),
    add constraint trips_reserved_seats_valid
        check (reserved_seats between 0 and capacity),
    add constraint trips_status_known
        check (status in ('Scheduled', 'Cancelled', 'Completed'));

alter table users
    alter column email set not null,
    alter column is_disabled set not null,
    add constraint users_email_unique unique (email);

alter table tickets
    alter column user_id set not null,
    alter column trip_id set not null,
    alter column ticket_code set not null,
    alter column status set not null,
    alter column product_code set not null,
    alter column valid_from_utc set not null,
    alter column valid_to_utc set not null,
    alter column price set not null,
    alter column currency set not null,
    add constraint tickets_user_fk foreign key (user_id) references users(id),
    add constraint tickets_trip_fk foreign key (trip_id) references trips(id),
    add constraint tickets_product_fk foreign key (product_code) references products(code),
    add constraint tickets_ticket_code_unique unique (ticket_code),
    add constraint tickets_status_known
        check (status in ('Pending', 'Active', 'Validated', 'Cancelled', 'Expired')),
    add constraint tickets_price_non_negative check (price >= 0),
    add constraint tickets_currency_iso_length check (char_length(currency) = 3),
    add constraint tickets_validity_window_valid
        check (valid_to_utc >= valid_from_utc),
    add constraint tickets_id_code_unique unique (id, ticket_code);

-- The composite validation foreign key prevents a validation from combining the id of one ticket
-- with the code of another. Another valid design is to remove validations.ticket_code
-- and resolve it through ticket_id.