# Advent Of Code 🎄 [zig](https://ziglang.org/) solutions

1. Install [zig](https://ziglang.org/) ([.zigversion](./.zigversion)), preferably using [zvm](https://github.com/tristanisham/zvm)
2. Run `zig build run` to select a specific day
3. Run `zig build run -- DAY`, e.g. `zig build run -- 9` to run a specific day 

### AOC_COOKIE
To obtain the puzzle inputs, you need to set the environment variable
`ACO_COOKIE` to the session cookie value from adventofcode.com: 

fish shell:
```fish
set -Ux AOC_COOKIE session=XXX...
```

Powershell:
```pwsh
[System.Environment]::SetEnvironmentVariable("AOC_COOKIE", "session=XXX...")
```

### @TODO
- Use [terminal grahpics
  protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/) via
  [libvaxis](https://github.com/rockorager/libvaxis)
- Implement common re-usable data structures (e.g. 2D map, graph, etc.) and
  algorithms (e.g. depth-first search, dijkstra/A* shortest-path like algorithms
  etc.)
