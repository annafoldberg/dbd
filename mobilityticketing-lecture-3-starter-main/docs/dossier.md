## Test results
Test results inserted as `rows: amount / count`.  
Each row represents the result after the test case. The preceding row represents the state before the change.  
For materialized view, before and after refresh are split by `;`. 

| Test | Base query | Function | Trigger summary | Materialized view |
|---|---|---|---|---|
| Baseline | 2: 36/1, 36/1 | 1: 36/1 | 0 (nothing triggered yet) | (not created yet) ; 1: 36/1 |
| Captured insert | 2: 36/1, 72/2 | 1: 72/2 | 1: 36/1 | 1: 36/1 ; 1: 72/2 |
| Failed insert | 2: 36/1, 72/2 | 1: 72/2 | 1: 36/1 | 1: 72/2 ; 1: 72/2 |
| Failed → Captured | 2: 36/1, 122/3 | 1: 122/3 | 1: 86/2 | 1: 72/2 ; 1: 122/3 |
| Captured → Refunded | 2: 36/1, 86/2 | 1: 86/2 | 1: 50/2 | 1: 122/3 ; 1: 86/2 |
| Delete | 2: 36/1, 36/1 | 1: 36/1 | 1: 0/0 | 1: 86/2 ; 1: 36/1 |
| Duplicate reference | 2: 36/1, 72/2 | 1: 72/2 | 36/1 | 1: 36/1 ; 1: 72/2 |

### Disagreement example
One captured example where two approaches disagree is after the captured payment insert. Here, the base query returns 72/2 on the affected row, while the materialized view returned 36/1. This is because the query reads the current base data, while the materialized view only updates when refreshed.

## Side-effect trace

For one `INSERT INTO payments`:

1. Constraints/references checked:  
On `INSERT INTO payments`, it's only checked if the primary key is unique, since no constraints have been applied to the table.  

2. Trigger executed:  
The AFTER INSERT trigger on `payments` executes.  

3. Summary-table write:  
Since the AFTER INSERT trigger on `payments` executes and assuming the payment is of status `Captured`, the trigger adds 36 to `captured_amount` and 1 to `captured_payments`.

4. Rows/locks touched:  
A new `payments` row is written and a `daily_revenue_by_operator` row is either written or updated.

5. Commit/rollback:  
In PostgreSQL, triggers execute as part of the same transaction as the INSERT. Therefore, they are committed or rolled back together.  

6. Reports become current:
   - Base query: Current after the payment is committed
   - Function: Current after the payment is committed
   - Trigger summary: Current as part of the same transaction
   - Materialized view: Current only after refresh

7. Application can observe:  
After commit, the application can observe the new payment through the base query and function, and the updated trigger summary. The materialized view still returns its previous state until refresh.


## Responsibility matrix
| Approach | Correctness | Freshness | Write cost | Read cost | Hidden side effects | Rebuildability | Operational complexity |
|---|---|---|---|---|---|---|---|
| Base query | High as it calculates directly from the current base tables | Current at query time | Low, no extra work on payment writes | High, joins and aggregation are done on every read | None beyond executing the query | High as nothing is stored, results can always be recalculated from base tables | Low, simple standalone query that can be run anytime |
| Function | High as it calculates directly from the current base tables | Current at query time | Low, no extra work on payment writes | High, as it still performs the same joins and aggregation on every call | None beyond executing the function | High as nothing is stored, and the result can always be recalculated from base tables | Low, it mainly centralises the query logic in one reusable function |
| Trigger summary | High if all relevant inserts, updates and deletes are handled correctly | Current as part of the same transaction as the payment change | High as each relevant payment write may also cause a write to the summary table | Low as the aggregated result is already stored and can be read directly | Payment writes automatically execute trigger logic and may write to the summary table | Medium as the summary is derived data but needs a backfill/rebuild query from the base tables if it becomes incorrect | High as correctness depends on the trigger logic covering all relevant changes and being maintained correctly |
| Materialized view | High after refresh, but may be stale before refresh | Current only after refresh | Low for normal payment writes, as they do not update the materialized view | Low as the aggregated result is already stored | Refreshing the view is an additional operation and must happen for the report to become current | High as it can be rebuilt at any time by refreshing it from the base tables | Medium as the query logic is simple but it is necessary to consider refresh management |

**Authority:**  
The base tables, specifically `payments`, is the source of truth. Everything else is derived.  

**Freshness rule:**  
The base query and function are current at query time. The trigger is performed as part of the same transaction. The materialized view is only current once refreshed.

**Rebuild path:**  
The base query and function need no rebuild because they do not store derived data. The trigger summary can be rebuilt by recalculating and backfilling it from the base tables. The materialized view can be rebuilt with `REFRESH MATERIALIZED VIEW daily_captured_revenue;`.

## Issue register

**Issue:**  
1. Data in the materialized view is stale.
2. Trigger summary has no initial backfill.
3. Trigger correctness is highly dependent on covering every type of change.

**Evidence:**  
1. The tests showed that changes to payments were not reflected in the materialized view until it was refreshed.
2. The tests showed that the baseline had 0 rows in the trigger summary even though the base query already contained captured revenue.
3. The original trigger handled inserts but not update or deletes.

**Impact:**  
1. If proper refresh management is lacking, an operator may be presented with stale data.
2. Creating the summary mechanism on an existing database produces incomplete reporting unless data is backfilled.
3. Refunds, corrections, or deletions could leave the summary inconsistent with the base data if not careful to cover every type of change.

## Decision

**Chosen approach:**  
I would suggest using the materialized view for reporting.

**Why:**  
The materialized view has low read costs and does not add extra work to individual payment writes. It is highly rebuildable through a refresh. The main disadvantage of the materialized view is that it contains stale data between refreshes, however, since the report itself may be delayed, this is an acceptable trade-off.

**Authority:**  
Payments.

**Freshness rule:**  
The materialized view is only current once refreshed.

**Rebuild path:**  
The materialized view can be rebuilt with `REFRESH MATERIALIZED VIEW daily_captured_revenue;`.

## SQL definitions

- Base query: `base_revenue.sql`
- Function: `020_reporting_function.sql`
- Trigger summary: `021_daily_revenue_trigger_extended.sql`
- Materialized view: `022_daily_captured_revenue.sql`