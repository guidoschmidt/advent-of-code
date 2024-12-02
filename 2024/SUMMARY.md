# AoC 2024
### Notes & Comments

## Day 1
**Part 1:** Sort the lists (needs to be array, can't sort @Vector in zig), subtract them,
use `@reduce` to find the sum of the differences. Make sure to use `@abs`,
as the puzzle input could also include rows with left numbers being larger
than the right numbers leading to negative distances.

Key insight: use Vectors with `@splat(0)` because `0` will not change the result.

**Part 2:** Find similarities count with a double for-loop, then do the
multiplication of the left list with the count list and calculate the result
with `@reduce` again, like in part 1.

## Day 2
**Part 1:** 
- Pitfall: assuming that the puzzle input had only 5 numbers per report
- All increasing or decreasing: Calculate the sum of signs and check if it
  matches the number of 

**Part 2:** Create a new vector and initialize it with the numbers from the row,
just leave out a single number and re-test if the adjusted number is safe.
