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

## Day 4
**Part 1:** parse the input and when encounter an `X`, save the position in a
candidate list. Then go through all the `X` candidate and check for all
directions, if the word `XMAS` is in the buffer in this direction.

**Part 2:** parse the input like in part 1, but save `A` as candidates. Then
check all candidates for diagonals using offsets `@Vector`:
```
.{-1, 1} and .{ 1, -1}
.{ 1, 1} and .{-1, -1}
```
Make sure to check the word `MAS` in reverse. One particular pitfall was a copy-paste
bug where I was using `pos + @Vector(2, isize){1, 1}` and `pos - @Vector(2,
isize){-1, -1}` which is the same thing.

## Day 7
**Part1:** parse the equations and use recursion to check if any of the options
is valid.

**Part2:**

## Day 8
**Part1:** Make sure to allow overriding antennas with antinodes, if their
letter is different from the current antenna.

## Day 9
**Part 1:** Learning to use `std.ascii.isDigit(c)` to only take digit characters
from the input.
parsing u8, but converting to usize afterwards and checking for '.' (== 46)
interferred with idx = 46! Had to code a python version to understand.

## Day 10
**Part 1:** Find all 0s in the input and store as trail. A trail has an `id`
(which is the number of it's input starting zero, e.g. the first zero in the input
creates trails with `id = 0`, the second `0` in the input creates trails with
`id=1`). Every trail also has a height (in range `[0, 9]`).
Go through eath starting trail and find it's neighbors (`[-1, 0]`, `[0, -1]`,
`[1, 0]` and `[0, 1]` respectively West, North, East and Sounth). If the height
of a neighbour is `+1` of the current trail, create a new trail from that
position.

To ensure each `9` is only reached once, use a hash map that stores all
previously visited nines and check before adding to the result.

**Part 2:** This was easy, just had to remove the part where it checks for
previously visited `9`s.
