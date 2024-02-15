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
- Day 18:
  - Part 1: terminal buffer was too small to draw the whole map, used [pgm file format](https://de.wikipedia.org/wiki/Portable_Anymap#Kopfdaten)
  - Part 2: visualize using svg + calculate using [shoelace formula](https://en.wikipedia.org/wiki/Shoelace_formula)
- Day 19:
  - Part 1: should have been easy, but I suffered from a parsing bug to only
    parse '<' values (annoying)
- Day 23:
  - Part 1: relatively easy, just go through all teh possible routes and count
    the steps, then look for the one with the largest step count
- Day 24:
  - Part 1: straight forward, but understanding how to find if an intersection is in
    the past wasn't quite intuitive. If you think about it it's rather easy,
    just subtract the intersection point from the hailstones positiond and
    compare it's sign with the hailstones velocity.
