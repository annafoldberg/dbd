-- Extension based on analysis below:

-- Corrections: Only INSERT operations are handled, therefore, if a payment changes,
-- the summary is not corrected.

-- Refunds: As only INSERT operations are handled, and only Captured status is taken into account,
-- if a ticket is refunded, it is currently not registered in the summary.

-- Deletes: Not handled, if a captured payment is deleted, its amount and count remain in the summary.

-- Initial backfill: Not handled, the trigger only handles new inserts.

-- Duplicate delivery: Not handled, if the same payment is inserted twice, the trigger adds it twice.

create table daily_revenue_by_operator (
    operator_id text not null references operators(id),
    revenue_date date not null,
    captured_amount numeric not null default 0,
    captured_payments bigint not null default 0,
    primary key (operator_id, revenue_date)
);

-- Provided trigger (INSERT INTO)
-- Extended to cover:
-- Duplicate delivery: Not handled, if the same payment is inserted twice, the trigger adds it twice.
create or replace function add_inserted_payment_to_daily_revenue()
returns trigger
language plpgsql
as $$
declare
    payment_operator_id text;
begin
    if new.status is distinct from 'Captured' then
        return new;
    end if;

    select r.operator_id
    into payment_operator_id
    from tickets t
    join trips tr on tr.id = t.trip_id
    join routes r on r.id = tr.route_id
    where t.id = new.ticket_id;

    insert into daily_revenue_by_operator (
        operator_id, revenue_date, captured_amount, captured_payments
    ) values (
        payment_operator_id, new.created_utc::date, new.amount, 1
    )
    on conflict (operator_id, revenue_date)
    do update set
        captured_amount = daily_revenue_by_operator.captured_amount + excluded.captured_amount,
        captured_payments = daily_revenue_by_operator.captured_payments + 1;

    return new;
end;
$$;

create trigger payments_daily_revenue_after_insert
after insert on payments
for each row
execute function add_inserted_payment_to_daily_revenue();

-- New trigger: UPDATE
-- Covers:
-- Corrections: Only INSERT operations are handled, therefore, if a payment changes,
-- the summary is not corrected.
-- Refunds: As only INSERT operations are handled, and only Captured status is taken into account,
-- if a ticket is refunded, it is currently not registered in the summary.
create or replace function update_payment_in_daily_revenue()
returns trigger
language plpgsql
as $$
declare
    old_payment_operator_id text;
    new_payment_operator_id text;
begin
    -- If the old version was Captured, remove its old contribution
    if old.status = 'Captured' then
        select r.operator_id
        into old_payment_operator_id
        from tickets t
        join trips tr on tr.id = t.trip_id
        join routes r on r.id = tr.route_id
        where t.id = old.ticket_id;

        update daily_revenue_by_operator
        set captured_amount = captured_amount - old.amount,
            captured_payments = captured_payments - 1
        where operator_id = old_payment_operator_id
          and revenue_date = old.created_utc::date;
    end if;

    -- If the new version is Captured, add its new contribution
    if new.status = 'Captured' then
        select r.operator_id
        into new_payment_operator_id
        from tickets t
        join trips tr on tr.id = t.trip_id
        join routes r on r.id = tr.route_id
        where t.id = new.ticket_id;

        insert into daily_revenue_by_operator (operator_id,
            revenue_date,
            captured_amount,
            captured_payments
        ) values (
            new_payment_operator_id, new.created_utc::date, new.amount, 1
        )
        on conflict (operator_id, revenue_date)
        do update set
            captured_amount = daily_revenue_by_operator.captured_amount + excluded.captured_amount,
            captured_payments = daily_revenue_by_operator.captured_payments + 1;
    end if;
    return new;
end;
$$;

create trigger update_payment_in_daily_revenue
after update on payments
for each row
execute function update_payment_in_daily_revenue();

-- New trigger: DELETE
-- Deletes: Not handled, if a captured payment is deleted, its amount and count remain in the summary.
create or replace function delete_payment_from_daily_revenue()
returns trigger
language plpgsql
as $$
declare
    old_payment_operator_id text;
begin
    -- If the old version was not Captured, do nothing
    if old.status is distinct from 'Captured' then
        return old;
    end if;

    -- Remove payment
    select r.operator_id
    into old_payment_operator_id
    from tickets t
    join trips tr on tr.id = t.trip_id
    join routes r on r.id = tr.route_id
    where t.id = old.ticket_id;

    update daily_revenue_by_operator
    set captured_amount = captured_amount - old.amount,
        captured_payments = captured_payments - 1
    where operator_id = old_payment_operator_id
        and revenue_date = old.created_utc::date;
    return old;
end;
$$;

create trigger delete_payment_from_daily_revenue
after delete on payments
for each row
execute function delete_payment_from_daily_revenue();

-- None cover:
-- Initial backfill: Not handled, the trigger only handles new inserts.
-- This is more appropriate for a query than a trigger.