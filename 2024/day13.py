#!/usr/bin/env python
# -*- coding: utf-8 -*-

def parseInput():
    with open("./2024/input/day13.txt") as input_file:
        data = input_file.read().rstrip()
        data = data.split("\n\n")
        part2(data)

def part2(data):
    machines = data #("\n".join(data)).split("\n\n")
    # print(machines)
    coins = 0

    for machine in machines:
        # print("----")
        # print(machine.split("\n"))
        btn_a, btn_b, prize = machine.split("\n")

        btn_a = [*map(lambda i: int(i[2:]), btn_a.split(": ")[1].split(", "))]
        btn_b = [*map(lambda i: int(i[2:]), btn_b.split(": ")[1].split(", "))]
        prize = [*map(lambda i: int(i[2:]) + 10000000000000, prize.split(": ")[1].split(", "))]

        """
        s = z3.Solver()
        times_a, times_b = z3.Ints("times_a times_b")
        s.add(btn_a[0] * times_a + btn_b[0] * times_b == prize[0])
        s.add(btn_a[1] * times_a + btn_b[1] * times_b == prize[1])
        if s.check() == z3.sat:
            coins += s.model()[times_a].as_long() * 3 + s.model()[times_b].as_long()
        """

        times_b = (prize[1] * btn_a[0] - prize[0] * btn_a[1]) / (btn_b[1] * btn_a[0] - btn_b[0] * btn_a[1])
        times_a = (prize[0] - btn_b[0] * times_b) / btn_a[0]

        print(btn_a, btn_b, prize)
        print(times_b, times_b.is_integer())
        print(times_a, times_a.is_integer())

        if times_a.is_integer() and times_b.is_integer():
            coins += int(times_a) * 3 + int(times_b)

    print(coins)


if __name__ == '__main__':
    parseInput()
