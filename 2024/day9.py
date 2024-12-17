#!/usr/bin/env python
# -*- coding: utf-8 -*-

def printMap(m):
    print()
    for i in m:
        print(i, end='')


def parseInput():
    disk_map = []
    with open("./2024/input/day9.txt") as input_file:
        for i in input_file.read():
            if '\n' in i:
                break
            disk_map.append(int(i))
        input_file.close()
    print(disk_map)

    block_map = []
    idx = 0;
    for i, e in enumerate(disk_map):
        if i % 2 == 1:
            for x in range(e):
                print(f"{x} -> .")
                block_map.append('.')
            idx += 1
        else:
            for x in range(e):
                print(f"{x} -> {idx}")
                block_map.append(idx)

    printMap(block_map)

    s = 0
    e = len(block_map) - 1
    while s < e:
        if block_map[s] == '.':
            block_map[s] = block_map[e]
            block_map[e] = '.'
            e -= 1
        else:
            s += 1

    printMap(block_map)

    cksm = 0
    for i, e in enumerate(block_map):
        if e == '.':
            break
        cksm += i * e

    print()
    print(f"Disk Map size: {len(disk_map)}")
    print(f"Block Map size: {len(block_map)}")
    print(f"Result: {cksm}")


if __name__ == '__main__':
    parseInput()
