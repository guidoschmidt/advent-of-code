#!/usr/bin/env python
# -*- coding: utf-8 -*-


def calcPerimeter(region, map):
    border_count = 0
    for tile in region["tiles"]:
        neighbours = [
            [tile[0], tile[1] - 1],
            [tile[0] + 1, tile[1]],
            [tile[0], tile[1] + 1],
            [tile[0] - 1, tile[1]],
        ]
        for n in neighbours:
            if n[0] < 0 or n[1] < 0 or n[0] >= len(map) or n[1] >= len(map[0]):
                border_count += 1
                continue
            if map[n[1]][n[0]] != region["label"]:
                border_count += 1
    return border_count


def calcRegionPrice(region, map):
    area = len(region["tiles"])
    perimeter = calcPerimeter(region, map)
    print(f"Area: {area} × Perimeter {perimeter}")
    return area * perimeter


def printMap(map, progress):
    print("\nMAP:")
    for r in map:
        print("\n", end="")
        for e in r:
            print(f"{e} ", end="")

    print("\nPROGRESS:")
    for r in progress:
        print("\n", end="")
        for e in r:
            v = "X" if e else "."
            print(f"{v} ", end="")

def isNeighbour(region, pos):
    is_neigbour = False
    for tile in region["tiles"]:
        if abs(tile[0] - pos[0]) == 1 or\
           abs(tile[1] - pos[1]) == 1:
            is_neigbour = True
            break
    return is_neigbour


def findRegions(map, progress, regions):
    candidates = []
    candidates.append([0, 0])
    region = None
    while(len(candidates) > 0):
        current = candidates.pop()
        if progress[current[1]][current[0]]:
            continue

        progress[current[1]][current[0]] = True

        if region != None and\
           map[current[1]][current[0]] == region["label"] and\
           isNeighbour(region, current):
            region["tiles"].append(current)
        else:
            regions.insert(0, {
                "label": map[current[1]][current[0]],
                "tiles": [current]
            })
            region = regions[0]

        # printMap(map, progress)
        # input()

        neighbours = [
            [current[0], current[1] - 1],
            [current[0] + 1, current[1]],
            [current[0], current[1] + 1],
            [current[0] - 1, current[1]]
        ]
        for n in neighbours:
            if n[0] < 0 or\
               n[1] < 0 or\
               n[0] >= len(map) or\
               n[1] >= len(map[0]):
                continue

            if progress[n[1]][n[0]]:
                continue

            if map[n[1]][n[0]] == region["label"]:
                candidates.append(n)
            else:
                candidates.insert(0, n)

    total_price = 0
    for region in regions:
        total_price += calcRegionPrice(region, map)

    print(f"Rsult: {total_price}")


def parseInput():
    map = []
    progress = []
    regions = []
    """Parse input and find triples where any name starts with 't'."""
    with open("./2024/input/examples/day12.txt") as input_file:
        for line in input_file:
            row = []
            progress_row = []
            map.append(row)
            progress.append(progress_row)
            for c in line.replace("\n", ""):
                progress_row.append(False)
                row.append(c)
        input_file.close()

    findRegions(map, progress, regions)


if __name__ == '__main__':
    parseInput()
