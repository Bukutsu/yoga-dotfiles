-- Niri spring damping ratio 1.0, stiffness 1000, mass 1.
hl.curve("niriSpring", {
    type = "spring",
    mass = 1,
    stiffness = 1000,
    dampening = 63.2456,
})
hl.curve("easeOutExpo", {
    type = "bezier",
    points = { { 0.16, 1 }, { 0.3, 1 } },
})
hl.animation({ leaf = "windows", enabled = true, speed = 1, spring = "niriSpring" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, spring = "niriSpring" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "easeOutExpo" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "easeOutExpo" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, spring = "niriSpring" })
hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "easeOutExpo" })
