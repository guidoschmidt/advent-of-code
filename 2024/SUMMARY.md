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
