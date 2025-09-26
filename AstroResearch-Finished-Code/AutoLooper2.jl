include("AutomaticTester.jl")

function Looper(a1::Int64, F::Int64, t="100P", hParam=0.01, fileSave="AutoSave")
    m = [0]
    for x = 1::3
        if x == 1
            m = [1.5, 1.5, 1]
            while a1 <= F
                StabilityFinder(m, a1, t, hParam, fileSave)
                a1 += 1
            end
        elseif x == 2
            m = [8, 1.5, 1]
            while a1 <= F
                StabilityFinder(m, a1, t, hParam, fileSave)
                a1 += 1
            end
        else
            m = [8, 8, 1]
            while a1 <= F
                StabilityFinder(m, a1, t, hParam, fileSave)
                a1 += 1
            end
        end
    end
end