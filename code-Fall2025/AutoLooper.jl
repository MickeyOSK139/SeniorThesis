include("AutomaticTester.jl")

# Finds the smallest stable outer binary separation for the triple
#  with specified masses for a range of inner binary separations
#  between a1 and a1_fin.

# The results are saved in StabilityConditions.xlsx

function Looper(m, a1, a1_fin, percent=5, precision=2, t="100P", MemorySave="all", hParam=0.01, fileSave="AutoSave", writeData=0)
    while a1 <= a1_fin
        StabilityFinder(m, a1, 0, percent, precision, t, MemorySave, hParam, fileSave, writeData)
        a1 = a1+2
    end
end

# Example:  Looper([1.5, 1.5, 1], 2, 40)