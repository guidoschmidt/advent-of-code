#!/usr/bin/env python
# -*- coding: utf-8 -*-

def parseInput():
    """Parse input and find triples where any name starts with 't'."""
    computers = set()
    links = {}
    with open("./2024/input/examples/day23.txt") as input_file:
        for line in input_file:
            a = line[0:2]
            b = line[3:-1]
            print(f"{a}-{b}")
            computers.add(a)
            computers.add(b)
            if a in links:
                links[a].append(b)
            else:
                links[a] = [b]
            if b in links:
                links[b].append(a)
            else:
                links[b] = [a]

    print(computers)
    for l in links:
        print(l)
        print(links[l])

    triples = set()

    for a in computers:
        for al in links[a]:
            for bl in links[al]:
                if bl in links[a]:
                    names = sorted([a, al, bl])
                    if names[0][0] == "t" or \
                       names[1][0] == "t" or \
                       names[2][0] == "t":
                        triples.add(",".join(names))

    print(f"Result: {len(triples)}")


if __name__ == '__main__':
    parseInput()
