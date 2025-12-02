# Advent of Code 2025
### Summary


# Day 01
### Part 1
Easy start. Some tipps:
- Parse `L` and `R` into `-1` and `1`
- Use `@mod` for the rotational arithmetic of the dial
- Don't forget to initialise the dial to `50`!

### Part 2
Somehow tried to be smart and calculate the amount of rotations first with:
```zig
const rotation_count = @abs(@divTrunc(dial, change));
```
