#!/usr/bin/env python
# -*- coding: utf-8 -*-
from collections import Counter

def part2(stones):
    stone_counter = Counter(stones)
    print(stone_counter)


def parseInput():
    stones = []
    """Parse input and find triples where any name starts with 't'."""
    with open("./2024/input/examples/day11.txt") as input_file:
        for line in input_file:
            stones = line.rstrip().split(" ")

        part2(stones)


if __name__ == '__main__':
    parseInput()
