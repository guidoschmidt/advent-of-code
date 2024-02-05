# Advent Of Code 2023
### Solutions with [zig](https://ziglang.org/)

1. Install [zig 0.11.0](https://ziglang.org/), preferably using
   [zvm](https://github.com/tristanisham/zvm)
2. Run `zig build run` to select a specific day
3. Run `zig build run -- DAY`, e.g. `zig build run -- 9` to run a specific day 


### Notes

- Day 13
  - Part 1: Brute force
  - Part 2: Dynamic Programming
- Day 14
  - Part 1: solve using recursion
- Day 16
  - Part 1: nasty bug where /<<< would reflect upwards instead of downwards.
    Need to test the single bits and pieces more carefully
