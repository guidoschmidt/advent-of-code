#!/usr/bin/env python
# -*- coding: utf-8 -*-
import networkx as nx


def parseInput():
    """Parse input and store nodes and links."""
    nodes = set()
    links = {}
    with open("./2024/input/day23.txt") as input_file:
        for line in input_file:
            row = []
            a, b = line.rstrip().split("-")
            nodes.add(a)
            nodes.add(b)
            if a in links:
                links[a].append(b)
            else:
                links[a] = [b]
        input_file.close()

        for u in links:
                print(f"[{u}]: {links[u]}")

        g = nx.Graph()
        for u in links:
                for v in links[u]:
                        g.add_edge(u, v)

        print("Cliques:")
        cliques = nx.find_cliques(g)
        result = sorted(cliques, key=len)[-1]
        print(",".join(sorted(result)))


if __name__ == '__main__':
        parseInput()
