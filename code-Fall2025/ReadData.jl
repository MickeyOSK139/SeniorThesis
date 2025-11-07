using Pkg
Pkg.add(PackageSpec(url ="https://github.com/felipenoris/XLSX.jl.git"))
Pkg.add("XLSX")
Pkg.add("CSV")
Pkg.add("DataFrames")
using DataFrames, CSV, XLSX, Plots

const G = 2945.49 # gravitational constant (project-specific units)

"""
    getdata(rowNumber::Int)
    Reads data from an Excel file and a corresponding CSV file based on the provided row number.
"""
function getdata(rowNumber::Int)
    XLSX.openxlsx("code-Fall2025/NestedBinaryData_New.xlsx",mode="rw") do xf
        sheet = xf["Sheet1"]
        data = sheet[rowNumber, 1:10] 

        
    df = CSV.read("code-Fall2025/AngularMomentum_CSV/LData_$(rowNumber).csv", DataFrame)
    tarray = df[:, 1]
    L1xarray = df[:, 2]
    L1yarray = df[:, 3]
    L1zarray = df[:, 4]
    L2xarray = df[:, 5]
    L2yarray = df[:, 6]
    L2zarray = df[:, 7]
    E1array = df[:, 8]
    E2array = df[:, 9]
        return data, tarray, L1xarray, L1yarray, L1zarray, L2xarray, L2yarray, L2zarray, E1array, E2array
    end
end

"""
    makeplot(rowNumber::Int)
    Generates and saves plots for angular momentum inclinations and longitudes based on the provided row number.
"""
function makeplot(rowNumber::Int)
    
    data, tarray, L1xarray, L1yarray, L1zarray, L2xarray, L2yarray, L2zarray, E1array, E2array = getdata(rowNumber)
    m1 = data[1]
    m2 = data[2]
    m3 = data[3]
    A1 = data[4]
	A2 = data[5]
	e1 = data[6]
	e2 = data[7]
	ϕi = data[8]
	ϕo = data[9]
	i = data[10]
    L1array = sqrt.(L1xarray .^ 2 .+ L1yarray .^ 2 .+ L1zarray .^ 2)
    L2array = sqrt.(L2xarray .^ 2 .+ L2yarray .^ 2 .+ L2zarray .^ 2)
    i1array = acosd.(L1zarray ./ L1array) # inclination of L1
    i2array = acosd.(L2zarray ./ L2array) # inclination of L2
    imutualarray = acosd.((L1xarray .* L2xarray .+ L1yarray .* L2yarray .+ L1zarray .* L2zarray) ./ (L1array .* L2array))   # mutual inclination between L1 and L2
    iplot = plot(tarray, [i1array i2array imutualarray], labels = ["i1 (deg)" "i2 (deg)" "imutual (deg)"], xlabel = "Time (days)", ylabel = "Angles (deg)", title = "Angular Momenta Inclinations for Row $(rowNumber)")
    #savefig(iplot, "code-Fall2025/Plots/Inclinations_Row$(rowNumber).png")
    phi1array = atand.(L1yarray, L1xarray)
    phi2array = atand.(L2yarray, L2xarray)
    phiplot = plot(tarray, [phi1array phi2array], labels = ["phi1 (deg)" "phi2 (deg)"], xlabel = "Time (days)", ylabel = "Longitude of Ascending Node (deg)", title = "Angular Momenta Longitudes for Row $(rowNumber)")
    #savefig(phiplot, "code-Fall2025/Plots/Longitudes_Row$(rowNumber).png")
    A1arr = - G*m1*m2 ./ (2 .* E1array)
    A2arr = - G*(m1 + m2)*m3 ./ (2 .* E2array)
    Aplot = plot(tarray, [A1arr A2arr], labels = ["A1 (Solar Radii)" "A2 (Solar Radii)"], xlabel = "Time (days)", ylabel = "Semi-Major Axes (Solar Radii)", title = "Semi-Major Axes for Row $(rowNumber)")
    mu12 = m1*m2/(m1+m2)
    M=m1+m2+m3
    q = (m1+m2)/M
    mutotal = m3* q
    
    e1array = sqrt.(1 .- (L1array .^ 2) ./ (G * (m1 + m2) * mu12^2 * A1arr))
    e2array = sqrt.(1 .- (L2array .^ 2) ./ (G * M * mutotal^2 * A2arr))
    eplot = plot(tarray, [e1array e2array], labels = ["e1" "e2"], xlabel = "Time (days)", ylabel = "Eccentricities", title = "Eccentricities for Row $(rowNumber)")
    EandLplot = plot(tarray, [E1array E2array L1array L2array], labels = ["E1" "E2" "L1" "L2"], xlabel = "Time (days)", ylabel = "Energies and Angular Momenta", title = "Energies and Angular Momenta for Row $(rowNumber)")
    EtotArray = E1array .+ E2array
    LxtotArray = L1xarray .+ L2xarray
    LytotArray = L1yarray .+ L2yarray
    LztotArray = L1zarray .+ L2zarray
    totplot = plot(tarray, [EtotArray LxtotArray LytotArray LztotArray], labels = ["Etotal" "Lxtotal" "Lytotal" "Lztotal"], xlabel = "Time (days)", ylabel = "Total Energy and Angular Momentum Components", title = "Total Energy and Angular Momentum Components for Row $(rowNumber)")
    finalplot = plot(iplot, phiplot, Aplot, eplot, EandLplot, totplot, layout = (3,2), size = (1200, 1800), title = "Angular Momenta and Orbital Elements for Row $(rowNumber)")
    savefig("code-Fall2025/Plots/AngularMomenta_Row$(rowNumber).png")
    
end

makeplot(36)