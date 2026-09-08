## Domain invariants and classification:
Directly enforceable with a column or table constraint (direct constraint)
- Capacity cannot be negative
- Reserved seats cannot be negative or greater than capacity
- Ticket price and payment amount cannot be negative
- ! Product price cannot be negative
- A ticket validity end cannot be earlier than its start
- Status values must come from a known set
- ! Result values must come from a known set
- ! Service date and scheduled departure UTC must be consistently represented

Enforceable with a unique or exclusion rule (unique or exclusion rule)
- Ticket codes must support unambiguous lookup
- An external payment reference should not be recorded twice if it represents one captured payment
- ! User email must support unambiguous lookup

Dependent on more than one row or external system (cross-row or external workflow rule)
- Currency must be present and consistently represented
- A payment must refer to an existing ticket
- A validation must refer to an existing ticket
- ! A ticket must refer to an existing trip
- ! A ticket must refer to an existing product
- ! A validation can only be accepted when the ticket is within its validity period
- ! A validation’s ticket_id and ticket_code must identify the same ticket

Currently ambiguous and requiring a domain decision (unresolved domain decision)
- ! External payment reference might require a constraint to ensure it follows the expected pattern, depending on the external payment system used
- ! Exact possible values for status in trips, tickets, and payments
- ! Exact possible values for result in validations
- ! User email must support unambiguous lookup
- ! Whether scheduled departure date is local or UTC-based
- ! How changes to a trip’s scheduled operation (e.g. early or delayed departure) affect the ticket’s validity period and when the ticket can be validated

> Note: ! marks invariants I have added to the minimum invariants to consider

## Integrity map

| | | Invariant | Affected tables and columns | Current protection | Missing protection or limitation | Expected failure behaviour | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | | Capacity cannot be negative | trips.capacity | None | CHECK (capacity >= 0) | Insert/update fails if capacity is negative | UPDATE with negative capacity rejected by `trips_capacity_non_negative` |
| 1 | | Reserved seats cannot be negative or greater than capacity | trips.reserved_seats | Default 0 | CHECK (reserved_seats <= capacity and reserved_seats >= 0) | Insert/update fails if reserved seats are negative or greater than capacity | UPDATE with reserved_seats > capacity rejected by `trips_reserved_seats_valid` |
| 1 | | Ticket price and payment amount cannot be negative | tickets.price, payments.amount | None | CHECK (tickets.price >= 0) and CHECK (payments.amount >= 0) | Insert/update fails if ticket price or payment amount is negative | UPDATE with negative ticket price rejected by `tickets_price_non_negative`, UPDATE with negative payment amount rejected by `payments_amount_non_negative` |
| 1 | ! | Product price cannot be negative | products.price | None | CHECK (products.price >= 0) | Insert/update fails if product price is negative | UPDATE with negative product price rejected by `products_price_non_negative` |
| 1 | | A ticket validity end cannot be earlier than its start | tickets.valid_from_utc, tickets.valid_to_utc | None | CHECK (tickets.valid_from_utc <= tickets.valid_to_utc ) | Insert/update fails if ticket validity end is before start | INSERT with validity end before start rejected by `tickets_validity_start_before_end` |
| 1 | *? | Status values must come from a known set | trips.status, tickets.status, payments.status | trips.status is NOT NULL, otherwise none | CHECK constraint to limit status values and exact allowed known sets must be defined | Insert/update fails if value is not in known set | UPDATE with unknown status rejected by `trips_status_valid`, `tickets_status_valid`, and `payments_status_valid` |
| 1 | ! *? | Result values must come from a known set | validations.result | None | CHECK constraint to limit result values and exact allowed known set must be defined | Insert/update fails if value is not in known set | INSERT with unknown result rejected by `validations_result_valid` |
| 1 | ! *? | Service date and scheduled departure UTC must be consistently represented | trips.service_date, trips.scheduled_departure_utc | Both columns are NOT NULL, service_date is type date, scheduled_departure_utc is timestamptz | CHECK constraint to ensure the dates are consistent, taking into account that one might be local and one is utc | Insert/update fails if inconsistent dates | Not tested, unresolved |
| 2 | | Ticket codes must support unambiguous lookup | tickets.ticket_code, validations.ticket_code | None | UNIQUE constraint | Insert/update fails if duplicate ticket code | INSERT with duplicate ticket code rejected by `tickets_ticket_code_unique` |
| 2 | *? | An external payment reference should not be recorded twice if it represents one captured payment | payments.external_payment_reference, payments.status | None | UNIQUE constraint | Insert/update fails if duplicate external payment reference | INSERT with duplicate external payment reference rejected by `payments_external_payment_reference` |
| 2 | ! *? | User email must support unambiguous lookup | users.email | None | UNIQUE constraint | Insert/update fails if duplicate email | Not tested, unresolved |
| 3 | | Currency must be present and consistently represented | tickets.currency, products.currency, payments.currency | None | NOT NULL constraint, workflow validation to ensure currencies match | Inconsistent currencies are rejected by workflow validation | NULL currency rejected for products, tickets, and payments. Cross-table currency consistency not implemented yet. |
| 3 | | A payment must refer to an existing ticket | payments.ticket_id, tickets | None | NOT NULL constraint, FK must exist as PK in tickets table, deletion of ticket not allowed if referred to by a payment | Insert/update fails if FK is invalid in payments, delete fails in tickets | INSERT referencing unknown ticket rejected by `payments_ticket_fk` |
| 3 | | A validation must refer to an existing ticket | validations.ticket_id, tickets | None | NOT NULL constraint, FK must exist as PK in tickets table, deletion of ticket not allowed if referred to by a validation | Insert/update fails if FK is invalid in validations, delete fails in tickets | INSERT referencing unknown ticket rejected by `validations_ticket_fk` |
| 3 | ! | A ticket must refer to an existing trip | tickets.trip_id, trips | None | NOT NULL constraint, FK must exist as PK in trips table, deletion of trip not allowed if referred to by a ticket | Insert/update fails if FK is invalid in tickets, delete fails in trips | INSERT referencing unknown trip rejected by `tickets_trip_fk` |
| 3 | ! | A ticket must refer to an existing product | tickets.product_code, products | None | NOT NULL constraint, FK must exist as PK in products table, deletion of product not allowed if referred to by a ticket | Insert/update fails if FK is invalid in tickets, delete fails in products | INSERT referencing unknown product rejected by `tickets_product_fk` |
| 3 | ! *? | A validation can only be accepted when the ticket is within its validity period | validations.validated_utc, tickets.valid_from_utc, tickets.valid_to_utc, validations.result | None | Constraint to ensure only valid tickets are accepted | An attempted validation may be recorded, however it must be with result rejected if not within the valid timeframe | Not implemented yet |
| 3 | ! | A validation’s ticket_id and ticket_code must identify the same ticket | validations.ticket_id, validations.ticket_code, tickets.id, tickets.ticket_code | None | Composite foreign key in validations, UNIQUE constraint on tickets(id, ticket_code) | Insert/update fails if ticket_id and ticket_code do not reference the same ticket | INSERT with mismatched ticket_id and ticket_code rejected by `validations_ticket_fk` |
| 4 | ! ? | External payment reference might require a constraint to ensure it follows the expected pattern, depending on the external payment system used | payments.external_payment_reference | None | External payment provider and required reference format are unspecified | Insert/update fails if specific format expected and value doesn't match | Not implemented |
| 4 | ! ? | Exact possible values for status in trips, tickets, and payments | trips.status, tickets.status, payments.status | trips.status is NOT NULL, otherwise none | Exact allowed known sets must be defined | Insert/update fails if value is not in known set | Not implemented |
| 4 | ! ? | Exact possible values for result in validations | validations.result | None | Exact allowed known sets must be defined | Insert/update fails if value is not in known set | Not implemented |
| 4 | ! ? | User email must support unambiguous lookup | users.email | None | Unknown if email must be unique | Insert/update fails if duplicate email | Not implemented |
| 4 | ! ? | Whether scheduled departure date is local or UTC-based | trips.service_date, trips.scheduled_departure_utc | Both columns are NOT NULL, service_date is type date, scheduled_departure_utc is timestamptz | Constraint between the two dates, must be known if service date is UTC or local | Insert/update fails if inconsistent dates | Not implemented |
| 4 | ! ? | How changes to a trip’s scheduled operation (e.g. early or delayed departure) affect the ticket’s validity period and when the ticket can be validated | trips.status, trips.scheduled_departure_utc, tickets.valid_from_utc, tickets.valid_to_utc, validations.validated_utc | None | Rules for early/delayed trips and validation windows must be specified | Cannot be determined until rule is defined | Not implemented |

> Note: ? marks unresolved domain decisions, while *? marks invariants whose definition or enforcement may be affected by one or more of the unresolved decisions.  
! marks invariants I have added to the minimum invariants to consider.  
Number marks the invariant classification:  
1: Direct constraint  
2: Unique or exclusion rule  
3: Cross-row or external workflow rule  
4: Unresolved domain decision

## Issue register

### Issue 1: Overselling

- Evidence: There are no constraints preventing reserved_seats to be greater than capacity
- Problem: A trip can have more reserved seats than available capacity
- Consequence: A trip might be oversold.
- Specific improvement: Check ensuring reserved_seats between 0 and capacity.
- Open question: What happens if an operator reduces a trip's capacity below the number of already reserved seats?

### Issue 2: Invalid ticket acceptance

- Evidence: There are no constraints preventing an invalid ticket to be accepted by the system.
- Problem: A validation could potentially be accepted outside its validity period.
- Consequence: Invalid tickets could be accepted.
- Specific improvement: Enforce validity during the validation workflow.
- Open question: How should delays or early departures affect the ticket's validity window?

## State-transition trace

### Ticket purchase

1 Customer chooses product -> Ticket is created -> Ticket status is pending  
2 Customer initiates payment -> Payment is created -> Payment status is pending  
3a Payment succeeds -> Payment status is captured -> Ticket status is active  
3b Payment fails -> Payment status is declined -> Ticket status is cancelled

### Ticket validation

1 Customer presents ticket -> Ticket status and validity are checked
2. Ticket is active and valid -> Validation is created -> Validation result is accepted -> Ticket status is validated
3. Ticket is not active or invalid -> Validation is created -> Validation result is declined

### Delete and update behaviour
| Relationship | Delete behaviour | Update behaviour | Reason |
| --- | --- | --- | --- |
| tickets → trips | Restrict | Reject changes to trip_id | A ticket must remain connected to the trip it was purchased for |
| tickets → products | Restrict | Reject changes to product_code | A ticket must remain connected to the product it was purchased as |
| tickets → users | Soft-delete/retention policy | Reject changes to user_id | A ticket must remain connected to the user it was purchased by, on delete user is anonymized and marked as is-deleted. |
| payments → tickets | Restrict | Reject changes to ticket_id | A payment must remain connected to the ticket it was made for |
| payments → users | Soft-delete/retention policy | Reject changes to user_id | A payment must remain connected to the user it was performed by, on delete user is anonymized and marked as is-deleted |
| validations → tickets | Restrict | Reject changes to ticket_id and ticket_code | A validation must remain connected to the ticket that was validated |

> Note: Historical tickets, payments, and validations should not be cascade-deleted, as they may be required for reporting and compliance. Their deletion should instead be restricted or governed by a retention policy.

## Invariants that cannot be solved by a simple constraint
1. Currency must be consistently represented
2. A validation can only be accepted when the ticket is within its validity period