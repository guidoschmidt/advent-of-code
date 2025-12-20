pub fn lcm(comptime T: type, nums: []const T) T {
    var r: T = nums[0];
    for(1..nums.len) |i| {
        r = nums[i] * r / gcd(T, nums[i], r);
    }
    return r;
}

pub fn gcd(comptime T: type, a: T, b: T) T {
    if (b == 0)
        return a;
    return gcd(T, b, @mod(a, b));
}
