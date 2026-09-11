-- Copy this file to 021_daily_revenue_trigger.sql and apply it.
-- This is deliberately incomplete. Document the behaviour before extending it.

create table daily_revenue_by_operator (
    operator_id text not null references operators(id),
    revenue_date date not null,
    captured_amount numeric not null default 0,
    captured_payments bigint not null default 0,
    primary key (operator_id, revenue_date)
);

create or replace function add_inserted_payment_to_daily_revenue()
returns trigger
language plpgsql
as $$
declare
    payment_operator_id text;
begin
    -- If payment does not have status Captured, do nothing
    if new.status is distinct from 'Captured' then
        return new;
    end if;
    
    -- Finds operator related to the ticket through trips and routes
    -- and stores its id in a variable payment_operator_id
    select r.operator_id
    into payment_operator_id
    from tickets t
    join trips tr on tr.id = t.trip_id
    join routes r on r.id = tr.route_id
    where t.id = new.ticket_id;

    -- Inserts into daily_revenue_by_operator the payment_operator_id, the utc date,
    -- the payment amount, and sets captured payments to 1.
    insert into daily_revenue_by_operator (
        operator_id, revenue_date, captured_amount, captured_payments
    ) values (
        payment_operator_id, new.created_utc::date, new.amount, 1
    )
    -- If there is a conflict for the operator id and the revenue date,
    -- which means that a summary row for that operator on that date already exists,
    -- instead of inserting, it makes an update where it sets
    -- captured_amount to the opeator's captured amount plus the excluded captured amount
    -- (excluded.captured_amount is PostgreSQL's way of referring to the value that
    -- PostgreSQL tried to insert, but couldn't because a conflicting row already existed)
    -- and the captured_payments to daily_revenue_by_operator's captured_payments + 1.
    on conflict (operator_id, revenue_date)
    do update set
        captured_amount = daily_revenue_by_operator.captured_amount + excluded.captured_amount,
        captured_payments = daily_revenue_by_operator.captured_payments + 1;
    return new;
end;
$$;

-- The trigger is run after a row is inserted into payments
create trigger payments_daily_revenue_after_insert
after insert on payments
for each row
execute function add_inserted_payment_to_daily_revenue();

-- TODO: analyse corrections, refunds, deletes, initial backfill, and duplicate delivery.

-- Corrections: Only INSERT operations are handled, therefore, if a payment changes,
-- the summary is not corrected.

-- Refunds: As only INSERT operations are handled, and only Captured status is taken into account,
-- if a ticket is refunded, it is currently not registered in the summary.

-- Deletes: Not handled, if a captured payment is deleted, its amount and count remain in the summary.

-- Initial backfill: Not handled, the trigger only handles new inserts.

-- Duplicate delivery: Not handled, if the same payment is inserted twice, the trigger adds it twice.

-- Do not add more trigger branches before documenting the behaviour.