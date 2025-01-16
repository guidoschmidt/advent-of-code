# Advent Of Code 🎄 [zig](https://ziglang.org/) solutions

1. Install [zig 0.13.0](https://ziglang.org/), preferably using [zvm](https://github.com/tristanisham/zvm)
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
