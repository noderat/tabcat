# some simple math utilities; not TabCAT-specific

@tabcat ?= {}
tabcat.math = {}


# return x, clamped to between min and max
tabcat.math.clamp = (min, x, max) -> Math.min(max, Math.max(min, x))


# randomly return true or false
tabcat.math.coinFlip = -> Math.random() < 0.5


# randomly return -1 or 1
tabcat.math.randomSign = -> if tabcat.math.coinFlip() then 1 else -1


# return a mod b, but always return a positive value
tabcat.math.mod = (a, b) -> ((a % b) + b) % b


# return a number chosen uniformly at random from [a, b)
tabcat.math.randomUniform = (a, b) -> a + Math.random() * (b - a)
