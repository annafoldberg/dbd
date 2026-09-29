# Dossier

### 1. Predict what will happen when trying to remove the old reference before updating the application code.
Dropping `tickets.product_code` will break the old reader/writer and we will lose the link between tickets and products.

### 1. Explain how you could lose the link between tickets and products.
If the values are removed before being mapped to `product_id`, we lose information about the existing relationship between tickets and products, which means the relationship can no longer be reconstructed from tickets alone.

### 1. Show which old query or insert breaks.
![Old reader/writer fails](figures/unsafe-change.png)

### 2. Explain what you would need to consider with a much larger table.  
With a much larger table, it's important that we avoid immediately scanning all existing rows when adding the new foreign key. Instead the migration should allow a gradual transition from the old reference to the new one. Backfilling all product ids immediately might also be undesirable for a large table, so it could instead be performed gradually in smaller batches, however this would require us to allow null until completed.

### 3. Write an insert and a query that use only `product_code`, as the old application would. Show that both still work after you add the new columns.
Using `old_reader.sql` and `old_writer.sql`:
![Old reader/writer works](figures/old-reader-writer-product-id.png)

### 4. Test results
Test 1: Give a real product_id and verify that the inserted ticket gets both that id and the corresponding code. Also verify that the ticket gets the supplied price rather than the product's current catalogue price.
![New writer success](figures/new-writer-success.png)

Test 2: Give a UUID that doesn't exist in products. Should insert 0 rows.
![New writer unknown product id](figures/new-writer-unknown-id.png)

Test 3. Give a conflicting product id and product code. Should ignore product code.
![New writer success with conflicting product id and product code](figures/new-writer-success.png)

### 5. Test results
![New reader before backfill](figures/new-reader-before-backfill.png)

### 6. Test results
![Backfill](figures/backfill.png)

![Backfill after old writer](figures/backfill-old-writer.png)

### 7. Compare the original tickets, prices and currencies with your starting data.
![Original tickets](figures/original-tickets.png)

![Verify tickets](figures/verify-tickets.png)

### 7. Try writing a mismatched pair directly in SQL and record whether the database rejects it.
![Deliberate mismatch succeeds](figures/deliberate-mismatch.png)

### 8. Test results
Test 1: Make `product_id` required while one ticket still has a null reference.
![Require product id when null reference exists](figures/require-product-id-failure.png)

Test 2: Old writer fails after applying `032_require_ticket_product.sql`.
![Old writer fails](figures/old-writer-fails.png)

### 9. Test after removing the product code column from tickets
![Final reader/writer](figures/final-reader-writer.png)

### Add a small table showing which inserts and queries work before expansion, after expansion, once the ID is required, and after the old column is removed. Note any query that runs but misses tickets.
| Operation | Before expansion | After expansion | ID required | Old column removed |
|---|---|---|---|---|
| Old writer | Works | Works | Fails because `product_id` is required | Fails because `tickets.product_code` no longer exists |
| New writer | Fails because `product_id` does not exist yet | Works | Works | Fails if it tries to write `tickets.product_code` |
| Final writer | Fails because `product_id` does not exist yet | Fails because `tickets.product_code` is `NOT NULL` | Fails because `tickets.product_code` is `NOT NULL` | Works |
| Old reader | Works | Works | Works | Fails because `tickets.product_code` no longer exists |
| New reader | Not applicable before `product_id` exists | Works | Works | Fails because it refers to `tickets.product_code` |
| Final reader | Fails because `product_id` does not exist yet | Runs, but misses tickets whose `product_id` is still null | Works | Works |

### When would you stop the old writers, and could you still return to the old application version? Support your answer with a result from your tests.
I would stop the old writers once all historical data has been backfilled and the new writers, readers, functions, stored procedures, views, and other dependencies have been updated and verified. Until `product_id` is made required, the database still supports the old writer, so it is possible to return to the old application version. After `product_id` is made `NOT NULL`, the old writer fails because it does not supply a product ID, so rolling back to the old application version would no longer be possible without also rolling back the database change. This is evident by the test results from section 3.