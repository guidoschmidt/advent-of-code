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

## Day 3
**Part 1:** Make use of `std.mem.window` as a sliding window over the
input. Advance needs to be as long as a maximum possible instruction, which is
`mul(XXX,XXX)`. Then just try to find the beginning of a valid instruction
`mul(` with that sliding window and once a beginning was found, try to find the
ending paranthesis `)` and try to parse the numbers between the brackets by
spliting the slice on `,`. Add the multiplication to a `@Vector` with sufficient
size. Also make sure the same instruction is not counted
multiple times by checking, if the multiplication is the same as the previous
one:
```
const mult = num_a * num_b;
if (mult == vec_mult[i -| 1]) {
    continue;
}
```
Finally use `@reduce(.Add, vec_mult)` to add together all the multiplications.

**Part 2:** Add searching for `do` in the sliding window and match for `do()`
and `don't`. Maintain a `bool` variable that enables or disables adding the
multiplication result to the result vector and set it to `true/false`
respectively when entcountering a `do()` or a `don't()`.
