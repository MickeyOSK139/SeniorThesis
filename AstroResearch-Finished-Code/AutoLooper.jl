include("AutomaticTester.jl")

function Looper(m, a1, F, P, t="1000P", hParam=0.01, fileSave="AutoSave")
    while a1 <= F
        StabilityFinder(m, a1, P, t, hParam, fileSave)
        a1 = 1.2*a1
    end
end