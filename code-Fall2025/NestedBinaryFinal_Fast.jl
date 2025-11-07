# cd("code-fall2025")
using Pkg
# Pkg.add(url="https://github.com/timholy/ProgressMeter.jl.git")
# Pkg.add("ProgressMeter")
# using ProgressMeter
# Pkg.add(url="https://github.com/felipenoris/XLSX.jl.git")
Pkg.add(PackageSpec(url ="https://github.com/timholy/ProgressMeter.jl.git"))
Pkg.add("ProgressMeter")
using ProgressMeter
Pkg.add(PackageSpec(url ="https://github.com/felipenoris/XLSX.jl.git"))
Pkg.add("XLSX")
import XLSX
Pkg.add("PyPlot")
using Plots
using Crayons
using DelimitedFiles

################################################################################
# NestedBinaryFinal_Fast.jl
#
# Fast RK4 integrator for hierarchical triple systems (optionally with a
# massless test particle). This file contains the high-level entry point
# `Master`, the file parser `fileInput`, the integrator `System`, and the
# RK4 implementation `RK4` plus the force component functions f1A..f6D.
#
# Notes:
# - Units are chosen so that the gravitational constant G = 2945.49 (units
#   are consistent with the original project and input files).
# - The code was written to be memory-conscious: different `MemorySave`
#   modes control how much time-series data is retained.
# - Main outputs include stability diagnostics, energy and angular momentum
#   conservation checks, and PNG orbit/diagnostic plots.
################################################################################

const G = 2945.49 # gravitational constant (project-specific units)

#NOTE: old code said it was semi-major axes, but it was separations
"Inputs a file and retrieves the necessary information from the file. This includes the masses of the bodies and their initial conditions."

"""
Master(file, Break=true, fileSave="AutoSave", writeData=0, MemorySave="hybrid") -> (record, dataFileExists, rowNumber, stability)

High-level convenience function. Reads an input configuration file, runs the
integration via `System`, prints stability diagnostics, optionally records
results to a spreadsheet, and saves several diagnostic plots (inner and
outer orbits, inclination vs time, angular momentum components vs time).

Arguments
- file: path to a .txt input describing the system (see README for format)
- Break: boolean controlling some plotting behavior (keeps compatibility with
	older scripts)
- fileSave: optional base name to save a text snapshot of simulation data
- writeData: if 0 (default) attempt to append results to an XLSX workbook
- MemorySave: mode controlling how much time-series data to keep

Returns
- record: whether the run was recorded to the spreadsheet
- dataFileExists: whether the spreadsheet existed prior to saving
- rowNumber: the row in the spreadsheet where the record was written
- stability: integer flag (1 stable, 0 unstable)
"""
function Master(file, Break=true, fileSave="AutoSave", writeData=0, MemorySave="hybrid") #This is the highest level function in this file. Plotting L, E, or positions over time, type "L" or "E" to plot those and type a color to plot the orbits
	#Elist, Llist, lList, Tlist, X1, X2, X3, X4, Y1, Y2, Y3, Y4, Z1, Z2, Z3, Z4, numBodies, hParam, v1x, v1y, v1z, v2x, v2y, v2z, v3x, v3y, v3z, v4x, v4y, v4z, OriginalX, t0, E₁list, E₂list, L₁list, L₂list, periods, timesteps = System(file, fileSave, MemorySave)
	m, OriginalX, numBodies, timeTaken, hParam, t0, periods, timesteps, stability, Emin, Emax, Lmin, LminX, LminY, LminZ, Lmax, LmaxX, LmaxY, LmaxZ, E₁0, E₁min, E₁max, E₂0, E₂min, E₂max, L₁0, L₁min, L₁minX, L₁minY, L₁minZ, L₁max, L₁maxX, L₁maxY, L₁maxZ, L₂0, L₂min, L₂minX, L₂minY, L₂minZ, L₂max, L₂maxX, L₂maxY, L₂maxZ, lmin, lmax, E₁exp, E₂exp, L₁exp, L₂exp, tarr, L₁Xarr, L₁Yarr, L₁Zarr, L₂Xarr, L₂Yarr, L₂Zarr, E₁arr, E₂arr = System(file, fileSave, Break, MemorySave)

	#=stability calculation=#
	println("\n")
	println("$t0 days later...")
	println("The timestep varied from $lmin to $lmax.")
	println("The angular momentum varied by $((Lmin)) to $((Lmax)) while the energy varied by $Emin to $Emax.") #magnitude of angular momentum here for simplicity
	println("This ran in $timeTaken seconds.")
	#println("This took $timesteps timesteps to simulate.")
	println("The inner binary energy was $E₁0 and varied from $E₁min to $E₁max")
	println("The expected inner binary energy is $E₁exp")
	println("The inner binary momentum was $L₁0 and varied from $L₁min to $L₁max")
	println("The expected inner binary momentum is $L₁exp")
	println("The outer binary energy was $E₂0 and varied from $E₂min to $E₂max")
	println("The expected outer binary energy is $E₂exp")
	println("The outer binary momentum was $L₂0 and varied from $L₂min to $L₂max")
	println("The expected outer binary momentum is $L₂exp")
	record = true
	dataFileExists = true
	rowNumber = 0

	if writeData == 0
		XLSX.openxlsx("code-Fall2025/NestedBinaryData_New.xlsx",mode="rw") do xf
			sheet = xf[1]
			i = 1
			while typeof(sheet["A$i"]) != Missing #gets next blank row
				if [sheet["A$i"],sheet["B$i"],sheet["C$i"],sheet["D$i"],sheet["E$i"],sheet["F$i"],sheet["G$i"],sheet["H$i"],sheet["I$i"],sheet["J$i"],sheet["K$i"]] == [m[1],m[2],m[3],OriginalX[1],OriginalX[2],OriginalX[3],OriginalX[4],OriginalX[5],OriginalX[6],t0,hParam] || [sheet["A$i"],sheet["B$i"],sheet["C$i"],sheet["D$i"],sheet["E$i"],sheet["F$i"],sheet["G$i"],sheet["H$i"],sheet["I$i"],sheet["J$i"],sheet["K$i"]] == [m[1],m[2],m[3],OriginalX[1],OriginalX[2],OriginalX[3],OriginalX[4],OriginalX[5],OriginalX[6],"$periods periods",hParam]
					println("Not saving to spreadsheet: This data already has an entry at line $i.")
					record = false
				end
				i += 1
			end
			rowNumber = i
			if record
				sheet["A$i"] = m[1]
				sheet["B$i"] = m[2]
				sheet["C$i"] = m[3]
				sheet["D$i"] = OriginalX[1]
				sheet["E$i"] = OriginalX[2]
				sheet["F$i"] = OriginalX[3]
				sheet["G$i"] = OriginalX[4]
				sheet["H$i"] = OriginalX[5]
				sheet["I$i"] = OriginalX[6]
				sheet["J$i"] = OriginalX[7]
				if periods == true
					sheet["K$i"] = t0
				else
					sheet["K$i"] = string(chop(periods), " periods")
				end
				sheet["L$i"] = hParam
				sheet["M$i"] = "[$Emin,$Emax]"
				sheet["N$i"] = "[[$(LminX),$(LminY),$(LminZ)],[$(LmaxX),$(LmaxY),$(LmaxZ)]]"
				sheet["O$i"] = "[$E₁min,$E₁max]"
				sheet["P$i"] = "[$E₂min,$E₂max]"
				sheet["Q$i"] = "[[$(L₁minX),$(L₁minY),$(L₁minZ)],[$(L₁maxX),$(L₁maxY),$(L₁maxZ)]]"
				sheet["R$i"] = "[[$(L₂minX),$(L₂minY),$(L₂minZ)],[$(L₂maxX),$(L₂maxY),$(L₂maxZ)]]"
				sheet["S$i"] = timeTaken
				sheet["T$i"] = "[$lmin,$lmax]"
				sheet["U$i"] = stability
				sheet["V$i"] = rowNumber
				if Emin<-10.0^-3 || Emax>10.0^-3
					sheet["W$i"] = 0
				else
					sheet["W$i"] = 1
				end
				sheet["X$i"] = timesteps
			end
		end
	end
	if MemorySave=="all"
		dataFileExists = false
	end

	
	# Save tarr and L arrays to CSV file
	
	csv_folder = "code-Fall2025/AngularMomentum_CSV"
	csv_filename = joinpath(csv_folder, "LData_$(rowNumber).csv")
	n = length(tarr)
	if n > 0
		data = [tarr L₁Xarr L₁Yarr L₁Zarr L₂Xarr L₂Yarr L₂Zarr E₁arr E₂arr]
		try
			mkpath(csv_folder)
		catch
		end
		writedlm(csv_filename, data, ',')
	end


	return record, dataFileExists, rowNumber, stability #used for autotester
end

"""
    fileInput(file)

fileInput(file) -> (fArray, XArray, mArray, t, hParam, percent, numBodies, notPeriods)

Parses a .txt configuration file and converts it to the internal arrays used
by the integrator. The function returns:
- fArray: array of derivative functions (force/kinematic components)
- XArray: numeric parameters read from the file (orbital elements / angles)
- mArray: mass array (may include a 0 mass for a test particle)
- t: target integration time (in the same time units as the file)
- hParam: timestep scaling parameter
- percent: tolerance used for stability checks (as percentage)
- numBodies: inferred number of bodies (3 or 4)
- notPeriods: boolean or string indicating whether t was provided in periods

This function validates input lengths and converts period notation (e.g.
"10P") into absolute time when needed.
"""
function fileInput(file) #change initial conditions to m1, m2, semi-major axis, e, 
#= This function inputs a .txt file and extracts data from it to get the inputs needed for NestedBinary =#
	fArray = Function[] #we need differential functions to calculate new positions and velocities with each timestep. These functions will be stored in this array. What functions are entered depends on how many bodies we are working with.

	mArray = parse.(Float64,split(readlines(file)[1],",")) #this inputs the masses of the bodies
	XArray = parse.(Float64,split(readlines(file)[2],",")) #this inputs the initial conditions of the bodies

	if length(XArray) != 7 && length(XArray) != 10 #this makes sure that each body has 6 entries: a position and velocity in the x, y, and z direction. 
		error("Invalid input: wrong number of initial conditions; go back and check the input.")
	end

	numBodies = (length(XArray)/7)+2 #this is different than the number of masses, because the test particle counts as a massless body here

	if numBodies == 3 #so, here, we either have three massive bodies or two massive bodies with a test particle
		push!(fArray, f1A, f2A, f3A, f4A, f5A, f6A, f1B, f2B, f3B, f4B, f5B, f6B, f1C, f2C, f3C, f4C, f5C, f6C) #these are the functions we need for that
		if length(mArray) == 2 #test particle with 2 numBodies
			push!(mArray,0) #including the test particle as a third body with zero mass
		end
	elseif numBodies == 4 #NestedBinary.jl cannot handle four massive bodies, so presumably, this is three massive bodies with a test particle
		push!(fArray, f1A, f2A, f3A, f4A, f5A, f6A, f1B, f2B, f3B, f4B, f5B, f6B, f1C, f2C, f3C, f4C, f5C, f6C, f1D, f2D, f3D, f4D, f5D, f6D) #these are the functions we need
	else
		error("Check how many bodies you have. Number of position vectors are $numBodies while number of masses are $(length(mArray)).") #if we only have two bodies, then we run systemrk.jl, so not this. 
	end
	Parse = split(readlines(file)[3],",")
	if Parse[1][end] == "P"[1]
		t = sqrt((XArray[3]/(XArray[4]+1))^3*(4*pi^2)/(G*(mArray[1]+mArray[2]+mArray[3])))*parse(Float64,Parse[1][1:end-1])
		notPeriods = Parse[1]
		println("t1 is ", t)
	else
		t = parse(Float64,Parse[1])
		notPeriods = true	
		println("t2 is ", t)
	end
	hParam = parse.(Float64,split(readlines(file)[3],",")[2]) #these should be the elements of the third line of the .txt file
	percent = parse.(Float64,split(readlines(file)[3],",")[3])
	return fArray, XArray, mArray, t, hParam, percent, numBodies, notPeriods
end

#"Inputs a file (that is a triple system) and numerically calculates the system's energy and angular momentum versus time, as well as the bodies' positions versus time."

"""
System(file, fileSave, Break, MemorySave="hybrid") -> many values

Main integration routine. Reads the parsed input from `fileInput`, constructs
the initial positions and velocities for the hierarchical triple (or triple
plus test particle), then integrates forward in time with adaptive-ish
timestep control based on current separations and relative velocities.

Outputs include many diagnostic quantities: energy/angular-momentum extrema,
arrays of positions and inclination angles over time, runtime and stability
flag, and the final state vector.
"""
function System(file, fileSave, Break, MemorySave="hybrid")
	#this is the main function that integrates with RK4 and returns the final positions (as well as arrays with information we can plot)
	#For MemorySave, "none" means it saves all data points, "hybrid" means it saves significant ones, and "all" means it records no data points
	f, x, m, t, hParam, percent, numBodies, periods = fileInput(file) #gets info from file

	if percent>1 #Here, we standardize what percent means
		println(Crayon(foreground=(255,0,0)),"Note that this will run with 0.0"*chop(chop("$percent"))*", not "*"$percent"*", to check for stability.")
		println(Crayon(foreground=(255,255,255)),"")
		percent *= 0.01
	end

	OriginalX = x

	M1 = m[1]
	M2 = m[2]
	M3 = m[3]
	M = M1+M2+M3
	q = (M1+M2)/M

	A1 = x[1]
	A2 = x[3]
	e1 = x[2]
	e2 = x[4]
	ϕi = x[5]
	ϕo = x[6]
	i = x[7]

	X1 = (-(A1*(1 + e1)*M2)/(M1 + M2))*cosd(ϕi)-cosd(ϕo)*cosd(i)*A2*(1+e2)*(M3/M) #keeps track of the first body's x coordinate
	X2 = ((A1*(1 + e1)*M1)/(M1 + M2))*cosd(ϕi)-cosd(ϕo)*cosd(i)*(1+e2)*A2*(M3/M) #similar for these
	X3 = cosd(ϕo)*cosd(i)*A2*(1+e2)*q
	Y1 = (-(A1*(1 + e1)*M2)/(M1 + M2))*sind(ϕi)-sind(ϕo)*A2*(1+e2)*(M3/M)
	Y2 = ((A1*(1 + e1)*M1)/(M1 + M2))*sind(ϕi)-sind(ϕo)*A2*(1+e2)*(M3/M)
	Y3 = sind(ϕo)*A2*(1+e2)*q
	Z1 = -sind(i)*cosd(ϕo)*(1 + e2)*A2*(M3/M)
	Z2 = -sind(i)*cosd(ϕo)*(1 + e2)*A2*(M3/M)
	Z3 = A2*(1 + e2)*sind(i)*cosd(ϕo)*q
	if numBodies == 4
		X4 = x[8]
		Y4 = x[9]
		Z4 = x[10]
	end

	tarr = []
	L₁Xarr = []
	L₁Yarr = []
	L₁Zarr = []
	L₂Xarr = []
	L₂Yarr = []
	L₂Zarr = []
	E₁arr = []
	E₂arr = []
	

	R₁X = X1
	R₁Y = Y1
	R₁Z = Z1
	R₂X = X2
	R₂Y = Y2
	R₂Z = Z2
	R₃X = X3 
	R₃Y = Y3
	R₃Z = Z3
	CM₁₂X = (M1*R₁X+M2*R₂X)/(M1+M2)
	CM₁₂Y = (M1*R₁Y+M2*R₂Y)/(M1+M2)
	CM₁₂Z = (M1*R₁Z+M2*R₂Z)/(M1+M2)
	InitialSep = sqrt((CM₁₂X-R₃X)^2+(CM₁₂Y-R₃Y)^2+(CM₁₂Z-R₃Z)^2)
	R₁₂X = R₁X-R₂X
	R₁₂Y = R₁Y-R₂Y
	R₁₂Z = R₁Z-R₂Z
	R₁₃X = R₁X-R₃X
	R₁₃Y = R₁Y-R₃Y
	R₁₃Z = R₁Z-R₃Z
	R₂₃X = R₂X-R₃X
	R₂₃Y = R₂Y-R₃Y
	R₂₃Z = R₂Z-R₃Z
	velocityM3 = sqrt(G*(M1+M2)^2*(1-e2)/(A2*M*(1+e2))) 
	velocityM1M2 = sqrt((G*(M3^2)*(1-e2))/(A2*M*(1+e2))) #velocity of inner CM
	V₁X = sqrt(G*(M2^2)*(1-e1)/(A1*(M2+M1)*(1+e1)))*sind(ϕi) + velocityM1M2*sind(ϕo)*cosd(i) 
	V₁Y = -sqrt(G*(M2^2)*(1-e1)/(A1*(M2+M1)*(1+e1)))*cosd(ϕi) - velocityM1M2*cosd(ϕo)
	V₁Z = velocityM1M2*sind(ϕo)*sind(i)
	V₂X = -sqrt(G*(M1^2)*(1-e1)/(A1*(M2+M1)*(1+e1)))*sind(ϕi) + velocityM1M2*sind(ϕo)*cosd(i) 
	V₂Y = sqrt(G*(M1^2)*(1-e1)/(A1*(M2+M1)*(1+e1)))*cosd(ϕi) - velocityM1M2*cosd(ϕo)
	V₂Z = velocityM1M2*sind(ϕo)*sind(i)
	V₃X = -velocityM3*cosd(i)*sind(ϕo)
	V₃Y = velocityM3*cosd(ϕo)
	V₃Z = -velocityM3*sind(ϕo)*sind(i)
	if numBodies>3
		V₄X = x[8]
		V₄Y = x[9]
		V₄Z = x[10]
	end

	V₁₂X = V₁X-V₂X
	V₁₂Y = V₁Y-V₂Y
	V₁₂Z = V₁Z-V₂Z
	V₁₃X = V₁X-V₃X
	V₁₃Y = V₁Y-V₃Y
	V₁₃Z = V₁Z-V₃Z
	V₂₃X = V₂X-V₃X
	V₂₃Y = V₂Y-V₃Y
	V₂₃Z = V₂Z-V₃Z
	VINCMX = (m[1]*V₁X+m[2]*V₂X)/(m[1]+m[2]) #velocity of inner center of mass
	VINCMY = (m[1]*V₁Y+m[2]*V₂Y)/(m[1]+m[2]) #velocity of inner center of mass
	VINCMZ = (m[1]*V₁Z+m[2]*V₂Z)/(m[1]+m[2]) #velocity of inner center of mass

	K = .5*m[1]*sqrt(V₁X^2+V₁Y^2+V₁Z^2)^2+.5*m[2]*sqrt(V₂X^2+V₂Y^2+V₂Z^2)^2+.5*m[3]*sqrt(V₃X^2+V₃Y^2+V₃Z^2)^2 #overall kinetic energy
	U = -(G*m[1]*m[2]/sqrt(R₁₂X^2+R₁₂Y^2+R₁₂Z^2)+G*m[1]*m[3]/sqrt(R₁₃X^2+R₁₃Y^2+R₁₃Z^2)+G*m[2]*m[3]/sqrt(R₂₃X^2+R₂₃Y^2+R₂₃Z^2)) #total gravitational potential energy
	E = K + U #total energy 
	LX = m[1]*(R₁Y*V₁Z-R₁Z*V₁Y)+m[2]*(R₂Y*V₂Z-R₂Z*V₂Y)+m[3]*(R₃Y*V₃Z-R₃Z*V₃Y)
	LY = m[1]*(R₁Z*V₁X-R₁X*V₁Z)+m[2]*(R₂Z*V₂X-R₂X*V₂Z)+m[3]*(R₃Z*V₃X-R₃X*V₃Z)
	LZ = m[1]*(R₁X*V₁Y-R₁Y*V₁X)+m[2]*(R₂X*V₂Y-R₂Y*V₂X)+m[3]*(R₃X*V₃Y-R₃Y*V₃X)
	
	E₁ = .5*m[1]*sqrt((V₁X-VINCMX)^2+(V₁Y-VINCMY)^2+(V₁Z-VINCMZ)^2)^2+.5*m[2]*sqrt((V₂X-VINCMX)^2+(V₂Y-VINCMY)^2+(V₂Z-VINCMZ)^2)^2 - G*m[1]*m[2]/sqrt(R₁₂X^2+R₁₂Y^2+R₁₂Z^2)#Energy of inner binary
	E₁exp = -.5*G*m[1]*m[2]/A1
	E₂ = .5*(m[1]+m[2])*sqrt(VINCMX^2+VINCMY^2+VINCMZ^2)^2+.5*m[3]*sqrt(V₃X^2+V₃Y^2+V₃Z^2)^2 - G*(m[1]+m[2])*m[3]/(sqrt((R₃X)^2+(R₃Y)^2+(R₃Z)^2)+sqrt((CM₁₂X)^2+(CM₁₂Y)^2+(CM₁₂Z)^2))#Energy of outer binary
	E₂exp = -.5*G*(m[1]+m[2])*m[3]/A2
	L₁X = m[1]*((R₁Y-CM₁₂Y)*(V₁Z-VINCMZ)-(R₁Z-CM₁₂Z)*(V₁Y-VINCMY))+m[2]*((R₂Y-CM₁₂Y)*(V₂Z-VINCMZ)-(R₂Z-CM₁₂Z)*(V₂Y-VINCMY))
	L₁Y = m[1]*((R₁Z-CM₁₂Z)*(V₁X-VINCMX)-(R₁X-CM₁₂X)*(V₁Z-VINCMZ))+m[2]*((R₂Z-CM₁₂Z)*(V₂X-VINCMX)-(R₂X-CM₁₂X)*(V₂Z-VINCMZ))
	L₁Z = m[1]*((R₁X-CM₁₂X)*(V₁Y-VINCMY)-(R₁Y-CM₁₂Y)*(V₁X-VINCMX))+m[2]*((R₂X-CM₁₂X)*(V₂Y-VINCMY)-(R₂Y-CM₁₂Y)*(V₂X-VINCMX))
	mu12 = m[1]*m[2]/(m[1]+m[2])
	L₁exp = mu12*sqrt(G*(m[1]+m[2])*A1*(1-e1^2))
	L₂X = (m[1]+m[2])*(CM₁₂Y*VINCMZ-CM₁₂Z*VINCMY)+m[3]*(R₃Y*V₃Z-R₃Z*V₃Y)
	L₂Y = (m[1]+m[2])*(CM₁₂Z*VINCMX-CM₁₂X*VINCMZ)+m[3]*(R₃Z*V₃X-R₃X*V₃Z)
	L₂Z = (m[1]+m[2])*(CM₁₂X*VINCMY-CM₁₂Y*VINCMX)+m[3]*(R₃X*V₃Y-R₃Y*V₃X)
	muio = M3*q
	L₂exp = muio*sqrt(G*M*A2*(1-e2^2))

	t0 = 0.0

	Lmax, LmaxX, LmaxY, LmaxZ, Lmin, LminX, LminY, LminZ, Emax, Emin, L₁maxX, L₁maxY, L₁maxZ, L₁minX, L₁minY, L₁minZ, L₂maxX, L₂maxY, L₂maxZ, L₂minX, L₂minY, L₂minZ = zeros(22) #all these extrema are deviations from the original measurement, so they're all originally zero
	
	L0 = sqrt(LX^2+LY^2+LZ^2)
	LX0 = LX
	LY0 = LY
	LZ0 = LZ
	E0 = E
	E₁0 = E₁
	E₂0 = E₂
	E₂min = E₂
	E₂max = E₂
	E₁min = E₁
	E₁max = E₁
	L₁0 = sqrt(L₁X^2+L₁Y^2+L₁Z^2)
	L₁X0 = L₁X
	L₁Y0 = L₁Y
	L₁Z0 = L₁Z
	L₂0 = sqrt(L₂X^2+L₂Y^2+L₂Z^2)
	L₂X0 = L₂X
	L₂Y0 = L₂Y
	L₂Z0 = L₂Z
	L₁max = L₁0
	L₁min = L₁0
	L₂max = L₂0
	L₂min = L₂0

	h1 = sqrt(R₁₂X^2+R₁₂Y^2+R₁₂Z^2)/sqrt(V₁₂X^2+V₁₂Y^2+V₁₂Z^2)
	h2 = sqrt(R₁₃X^2+R₁₃Y^2+R₁₃Z^2)/sqrt(V₁₃X^2+V₁₃Y^2+V₁₃Z^2)
	h3 = sqrt(R₂₃X^2+R₂₃Y^2+R₂₃Z^2)/sqrt(V₂₃X^2+V₂₃Y^2+V₂₃Z^2)
	if h1 < h2
		if h1 < h3
			h = hParam*h1
		else
			h = hParam*h3
		end
	else
		if h2 < h3
			h = hParam*h2
		else
			h = hParam*h3
		end
	end
	
	lmax = h
	lmin = h

	#calculates inner binary period
	Iperiod = sqrt(4*pi^2*A1^3/(1+e1)/G*(M1+M2))

	x=[X1,Y1,Z1,V₁X,V₁Y,V₁Z,X2,Y2,Z2,V₂X,V₂Y,V₂Z,X3,Y3,Z3,V₃X,V₃Y,V₃Z]
	if numBodies>3
		push!(x,X4,Y4,Z4,V₄X,V₄Y,V₄Z)
	end
	#until the desired time has been reached, the code runs RK4
	counter=0
	prog = Progress(convert(Int,ceil(t)),0.5)
	stability = 1.5
	firstTime = time()
	while t0 < t
		#we will add an adaptive timestep later
		x = RK4(f, x, m, h)
		R₁X = x[1]
		R₁Y = x[2]
		R₁Z = x[3]
		V₁X = x[4]
		V₁Y = x[5]
		V₁Z = x[6]
		R₂X = x[7]
		R₂Y = x[8]
		R₂Z = x[9]
		V₂X = x[10]
		V₂Y = x[11]
		V₂Z = x[12]
		R₃X = x[13]
		R₃Y = x[14]
		R₃Z = x[15]
		V₃X = x[16]
		V₃Y = x[17]
		V₃Z = x[18]
		# push!(X1arr, R₁X - (M1*R₁X+M2*R₂X)/(M1+M2)) #Push position into an array
		# push!(Y1arr, R₁Y - (M1*R₁Y+M2*R₂Y)/(M1+M2))
		# push!(Z1arr, R₁Z - (M1*R₁Z+M2*R₂Z)/(M1+M2))
		# push!(X2arr, R₂X - (M1*R₁X+M2*R₂X)/(M1+M2))
		# push!(Y2arr, R₂Y - (M1*R₁Y+M2*R₂Y)/(M1+M2))
		# push!(Z2arr, R₂Z - (M1*R₁Z+M2*R₂Z)/(M1+M2))
		# push!(X3arr, x[13])
		# push!(Y3arr, x[14])
		# push!(Z3arr, x[15])
		R₁₂X = R₁X-R₂X
		R₁₂Y = R₁Y-R₂Y
		R₁₂Z = R₁Z-R₂Z
		R₁₃X = R₁X-R₃X
		R₁₃Y = R₁Y-R₃Y
		R₁₃Z = R₁Z-R₃Z
		R₂₃X = R₂X-R₃X
		R₂₃Y = R₂Y-R₃Y
		R₂₃Z = R₂Z-R₃Z
		V₁₂X = V₁X-V₂X
		V₁₂Y = V₁Y-V₂Y
		V₁₂Z = V₁Z-V₂Z
		V₁₃X = V₁X-V₃X
		V₁₃Y = V₁Y-V₃Y 
		V₁₃Z = V₁Z-V₃Z
		V₂₃X = V₂X-V₃X
		V₂₃Y = V₂Y-V₃Y 
		V₂₃Z = V₂Z-V₃Z
		K = .5*m[1]*(V₁X^2+V₁Y^2+V₁Z^2)+.5*m[2]*(V₂X^2+V₂Y^2+V₂Z^2)+.5*m[3]*(V₃X^2+V₃Y^2+V₃Z^2) #overall kinetic energy
		U = -(G*m[1]*m[2]/sqrt(R₁₂X^2+R₁₂Y^2+R₁₂Z^2)+G*m[1]*m[3]/sqrt(R₁₃X^2+R₁₃Y^2+R₁₃Z^2)+G*m[2]*m[3]/sqrt(R₂₃X^2+R₂₃Y^2+R₂₃Z^2)) #total gravitational potential energy
		Etot = K + U #total energy 
		E = (Etot-E0)/E0 #fractional energy difference
		# push!(Earr, E)
		LX = m[1]*(R₁Y*V₁Z-R₁Z*V₁Y)+m[2]*(R₂Y*V₂Z-R₂Z*V₂Y)+m[3]*(R₃Y*V₃Z-R₃Z*V₃Y)
		LY = m[1]*(R₁Z*V₁X-R₁X*V₁Z)+m[2]*(R₂Z*V₂X-R₂X*V₂Z)+m[3]*(R₃Z*V₃X-R₃X*V₃Z)
		LZ = m[1]*(R₁X*V₁Y-R₁Y*V₁X)+m[2]*(R₂X*V₂Y-R₂Y*V₂X)+m[3]*(R₃X*V₃Y-R₃Y*V₃X)
		Ltot = sqrt(LX^2+LY^2+LZ^2)
		L = (Ltot-L0)/L0 #fractional angular momentum difference
		# push!(Larr, L)
		if L > Lmax
			LmaxX = LX
			LmaxY = LY
			LmaxZ = LZ
			Lmax = L
		elseif L < Lmin
			LminX = LX
			LminY = LY
			LminZ = LZ 
			Lmin = L
		end
		if E > Emax
			Emax = E
		elseif E < Emin
			Emin = E
		end
		t0 = t0 + h #advances time, should this be defined by after the next few lines?
		# push!(tarr, t0)
		h1 = sqrt(R₁₂X^2+R₁₂Y^2+R₁₂Z^2)/sqrt(V₁₂X^2+V₁₂Y^2+V₁₂Z^2)
		h2 = sqrt(R₁₃X^2+R₁₃Y^2+R₁₃Z^2)/sqrt(V₁₃X^2+V₁₃Y^2+V₁₃Z^2)
		h3 = sqrt(R₂₃X^2+R₂₃Y^2+R₂₃Z^2)/sqrt(V₂₃X^2+V₂₃Y^2+V₂₃Z^2)
		if h1 < h2
			if h1 < h3
				h = hParam*h1
			else
				h = hParam*h3
			end
		else
			if h2 < h3
				h = hParam*h2
			else
				h = hParam*h3
			end
		end #this calculates the initial timestep, later this will tie into the energy of the system, once that's implemented
		if L > 10^-3 || L < -10^-3 || E > 10^-3 || E < -10^-3 || h > lmax || h < lmin || E₁ > E₁max || E₁ < E₁min || E₂ > E₂max || E₂ < E₂min || L₁0 < L₁min || L₁0 > L₁max|| L₂0 > L₂max || L₂0 < L₂min
			#println([counter%stepSave==0,L>Lmax,L<Lmin,E>Emax,E<Emin,h>lmax,h<lmin,E₁>E₁max,E₁<E₁min,E₂>E₂max,E₂<E₂min,sqrt(L₁X^2+L₁Y^2+L₁Z^2) > L₁max,sqrt(L₁X^2+L₁Y^2+L₁Z^2) < L₁min,sqrt(L₂X^2+L₂Y^2+L₂Z^2) > L₂max,sqrt(L₂X^2+L₂Y^2+L₂Z^2) < L₂min])
			LX = (LX-LX0)/LX0
			LY = (LY-LY0)/LY0
			LZ = (LZ-LZ0)/LZ0
			VINCMX = (m[1]*V₁X+m[2]*V₂X)/(m[1]+m[2]) #velocity of inner center of mass
			VINCMY = (m[1]*V₁Y+m[2]*V₂Y)/(m[1]+m[2]) #velocity of inner center of mass
			VINCMZ = (m[1]*V₁Z+m[2]*V₂Z)/(m[1]+m[2]) #velocity of inner center of mass
			CM₁₂X = (M1*R₁X+M2*R₂X)/(M1+M2)
			CM₁₂Y = (M1*R₁Y+M2*R₂Y)/(M1+M2)
			CM₁₂Z = (M1*R₁Z+M2*R₂Z)/(M1+M2)
			E₁ = .5*m[1]*sqrt((V₁X-VINCMX)^2+(V₁Y-VINCMY)^2+(V₁Z-VINCMZ)^2)^2+.5*m[2]*sqrt((V₂X-VINCMX)^2+(V₂Y-VINCMY)^2+(V₂Z-VINCMZ)^2)^2 - G*m[1]*m[2]/sqrt(R₁₂X^2+R₁₂Y^2+R₁₂Z^2)#Energy of inner binary
			E₂ = .5*(m[1]+m[2])*sqrt(VINCMX^2+VINCMY^2+VINCMZ^2)^2+.5*m[3]*sqrt(V₃X^2+V₃Y^2+V₃Z^2)^2 - G*(m[1]+m[2])*m[3]/(sqrt((R₃X)^2+(R₃Y)^2+(R₃Z)^2)+sqrt((CM₁₂X)^2+(CM₁₂Y)^2+(CM₁₂Z)^2))#Energy of outer binary we don't normalize these now because we need to determine stability of the system
			push!(E₁arr, E₁)
			push!(E₂arr, E₂)
			#E₁ = (E₁-E₁0)/E₁0
			#E₂ = (E₂-E₂0)/E₂0
			L₁X = m[1]*((R₁Y-CM₁₂Y)*(V₁Z-VINCMZ)-(R₁Z-CM₁₂Z)*(V₁Y-VINCMY))+m[2]*((R₂Y-CM₁₂Y)*(V₂Z-VINCMZ)-(R₂Z-CM₁₂Z)*(V₂Y-VINCMY))
			L₁Y = m[1]*((R₁Z-CM₁₂Z)*(V₁X-VINCMX)-(R₁X-CM₁₂X)*(V₁Z-VINCMZ))+m[2]*((R₂Z-CM₁₂Z)*(V₂X-VINCMX)-(R₂X-CM₁₂X)*(V₂Z-VINCMZ))
			L₁Z = m[1]*((R₁X-CM₁₂X)*(V₁Y-VINCMY)-(R₁Y-CM₁₂Y)*(V₁X-VINCMX))+m[2]*((R₂X-CM₁₂X)*(V₂Y-VINCMY)-(R₂Y-CM₁₂Y)*(V₂X-VINCMX))
			L₂X = (m[1]+m[2])*(CM₁₂Y*VINCMZ-CM₁₂Z*VINCMY)+m[3]*(R₃Y*V₃Z-R₃Z*V₃Y)
			L₂Y = (m[1]+m[2])*(CM₁₂Z*VINCMX-CM₁₂X*VINCMZ)+m[3]*(R₃Z*V₃X-R₃X*V₃Z)
			L₂Z = (m[1]+m[2])*(CM₁₂X*VINCMY-CM₁₂Y*VINCMX)+m[3]*(R₃X*V₃Y-R₃Y*V₃X)
			push!(L₁Xarr, L₁X)
			push!(L₁Yarr, L₁Y)
			push!(L₁Zarr, L₁Z)
			push!(L₂Xarr, L₂X)
			push!(L₂Yarr, L₂Y)
			push!(L₂Zarr, L₂Z)
			L₁ = sqrt(L₁X^2+L₁Y^2+L₁Z^2)
			#L₁ = (L₁-L₁0)/L₁X0
			L₂ = sqrt(L₂X^2+L₂Y^2+L₂Z^2)
			# imutual = acosd((L₁X*L₂X+L₁Y*L₂Y+L₁Z*L₂Z)/(L₁*L₂))
			# imutual = (L₁X*L₂X+L₁Y*L₂Y+L₁Z*L₂Z)/(L₁*L₂)
			# push!(iarr, imutual)
			push!(tarr, t0)
			#L₂ = (L₂-L₂0)/L₂0
			#=L₁X = (L₁X-L₁X0)/L₁X0
			L₁Y = (L₁Y-L₁Y0)/L₁Y0 
			L₁Z = (L₁Z-L₁Z0)/L₁Z0
			L₂X = (L₂X-L₂X0)/L₂X0
			L₂Y = (L₂Y-L₂Y0)/L₂Y0
			L₂Z = (L₂Z-L₂Z0)/L₂Z0=#
			if sqrt((CM₁₂X-R₃X)^2+(CM₁₂X-R₃X)^2+(CM₁₂X-R₃X)^2)>2*InitialSep
				stability = 0
			end
			if h > lmax
				lmax = h
			elseif h < lmin
				lmin = h
			end
			if E₁ > E₁max
				E₁max = E₁
			elseif E₁ < E₁min
				E₁min = E₁
			end
			if E₂ > E₂max
				E₂max = E₂
			elseif E₂ < E₂min
				E₂min = E₂
			end
			if L₁ > L₁max 
				L₁max = L₁
			elseif L₁ < L₁min
				L₁min = L₁
			end
			if L₂ > L₂max
				L₂max = L₂
			elseif L₂ < L₂min 
				L₂min = L₂ 
			end
			if abs(L₂min) > (1.0 + percent)*abs(L₂0) ||  (1.0 + percent)*abs(L₂0) < abs(L₂max)
				println("This is an unstable system! Angular momentum of the outer binary was not conserved.")
				stability = 0
			elseif abs(L₁min) > (1.0 + percent)*abs(L₁0) ||  (1.0 + percent)*abs(L₁0) < abs(L₁max)
				println("This is an unstable system! Angular momentum of the inner binary was not conserved.")
				stability = 0
			elseif abs(E₂min) > (1.0 + percent)*abs(E₂0) ||  (1.0 + percent)*abs(E₂0) < abs(E₂max)
				println("This is an unstable system! Energy of the outer binary was not conserved.")
				stability = 0
			elseif abs(E₁min) > (1.0 + percent)*abs(E₁0) ||  (1.0 + percent)*abs(E₁0) < abs(E₁max)
				println("This is an unstable system! Energy of the inner binary was not conserved.")
				stability = 0
			end
		end
		#=h1 = hParam*(minimum([norm(R₁₂)/norm(V₁₂),norm(R₁₃)/norm(V₁₃),norm(R₂₃)/norm(V₂₃)])) #this calculates the initial timestep, later this will tie into the energy of the system, once that's implemented
		if h != h1
			println([h1,h])
		end=#
		if stability == 0
			break 
		end
		if counter%10000 == 0
			update!(prog,convert(Int64,floor(t0)))
		end
		counter += 1
	end
	if stability != 0
		println("This is a stable system!")
		stability = 1
	end
	NowTime = time()
	return m, OriginalX, numBodies, NowTime-firstTime, hParam, t0, periods, counter, stability, Emin, Emax, Lmin, LminX, LminY, LminZ, Lmax, LmaxX, LmaxY, LmaxZ, E₁0, E₁min, E₁max, E₂0, E₂min, E₂max, L₁0, L₁min, L₁minX, L₁minY, L₁minZ, L₁max, L₁maxX, L₁maxY, L₁maxZ, L₂0, L₂min, L₂minX, L₂minY, L₂minZ, L₂max, L₂maxX, L₂maxY, L₂maxZ, lmin, lmax, E₁exp, E₂exp, L₁exp, L₂exp, tarr, L₁Xarr, L₁Yarr, L₁Zarr, L₂Xarr, L₂Yarr, L₂Zarr, E₁arr, E₂arr
end

"""
RK4(f, x, m, h) -> x_next

Classic fourth-order Runge–Kutta integrator. `f` is an array of functions
representing the right-hand side of the system (dx/dt values for each
component). `x` is the current state vector and `m` is the mass array (passed
through to the derivative functions). Returns the state after one step of
size h.
"""
function RK4(f,x,m,h)
#Inputs are initial position array, mass array and step size h

	d=length(f)

#Setting the runge kutta parameters to zero

	k1=zeros(length(x))
	k2=zeros(length(x))
	k3=zeros(length(x))
	k4=zeros(length(x))

#calculating the runge kutta parameters for every function in f

	for i in 1:d
		k1[i]=h*f[i](x, m)
	end
	for i in 1:d
		k2[i]=h*f[i](x+k1/2, m)
	end
	for i in 1:d
		k3[i]=h*f[i](x+k2/2, m)
	end
	for i in 1:d
		k4[i]=h*f[i](x+k3, m)
	end

#returns the desired step
	y=x+(k1+2*k2+2*k3+k4)/6
	return y

end 

"""
Takes a file with the data, then plots what you choose.
Plot(file, object[, fileSave, writeData, equal])
The input file must be a .txt file in the format described in README.md.
The object is what is plotted. If "E" is typed, then the energy will be plotted versus time. If "L" is typed, then angular momentum will be plotted versus time. If "EL" is typed, then both are plotted. "time" plots the timestep of the integration versus iteration. Finally, a color accepted by matplotlib will plot the trajectories of the bodies, one of them having a path with the color specified.
writeData is optional. Unless something other than 0 is its input, it will write the data of the simulation to the NestedBinaryData spreadsheet.
fileSave is optional. However, if a string is entered, for example, "Sample.txt", then a .txt file will be created that will store the system's data. This file can then be plotted using ExternalPlotter.jl without needing to recalculate the system again.
equal is also optional. Plot() equalizes the axes of the trajectories by default. If anything besides 0 is its input, it will not do this.
"""


function f0(x::Array{Float64,1}) #DE for Masses
	return 0
end

function f1A(x::Array{Float64,1}, m::Array{Float64,1}) #x1
	return x[4]
end

function f1B(x::Array{Float64,1}, m::Array{Float64,1}) #x2
	return x[10]
end

function f1C(x::Array{Float64,1}, m::Array{Float64,1}) #x3
	return x[16]
end

function f1D(x::Array{Float64,1}, m::Array{Float64,1}) #x4(TestParticle)
	return x[22]
end

function f2A(x::Array{Float64,1}, m::Array{Float64,1}) #y1
	return x[5]
end

function f2B(x::Array{Float64,1}, m::Array{Float64,1}) #y2
	return x[11]
end

function f2C(x::Array{Float64,1}, m::Array{Float64,1}) #y3
	return x[17]
end

function f2D(x::Array{Float64,1}, m::Array{Float64,1}) #y4(TestParticle)
	return x[23]
end	

function f3A(x::Array{Float64,1}, m::Array{Float64,1}) #z1
	return x[6]
end

function f3B(x::Array{Float64,1}, m::Array{Float64,1}) #z2
	return x[12]
end

function f3C(x::Array{Float64,1}, m::Array{Float64,1}) #z3
	return x[18]
end

function f3D(x::Array{Float64,1}, m::Array{Float64,1}) #z4(TestParticle)
	return x[24]
end

function f4A(x::Array{Float64,1}, m::Array{Float64,1}) #v1
	g1 = G * m[2] * (x[7] - x[1])
	g2 = G * m[3] * (x[13] - x[1])
	r1 = ((x[1] - x[7])^2 + (x[2] - x[8])^2 + (x[3] - x[9])^2)^0.5
	r2 = ((x[1] - x[13])^2 + (x[2] - x[14])^2 +(x[3] - x[15])^2)^0.5
	return g1/(r1^3) + g2/(r2^3)
end

function f4B(x::Array{Float64,1}, m::Array{Float64,1}) #v2
	g1 = G * m[1] * (x[1] - x[7])
	g2 = G * m[3] * (x[13] - x[7])
	r1 = ((x[1] - x[7])^2 + (x[2] - x[8])^2 + (x[3] - x[9])^2)^0.5
	r3 = ((x[7] - x[13])^2 + (x[8] - x[14])^2 +(x[9] - x[15])^2)^0.5
	return g1/(r1^3) + g2/(r3^3)
end

function f4C(x::Array{Float64,1}, m::Array{Float64,1}) #v3
	g1 = G * m[1] * (x[1] - x[13])
	g2 = G * m[2] * (x[7] - x[13])
	r2 = ((x[1] - x[13])^2 + (x[2] - x[14])^2 +(x[3] - x[15])^2)^0.5
	r3 = ((x[7] - x[13])^2 + (x[8] - x[14])^2 +(x[9] - x[15])^2)^0.5
	return g1/(r2^3) + g2/(r3^3)
end

function f4D(x::Array{Float64,1}, m::Array{Float64,1}) #v4
	g1 = G * m[1] * (x[1] - x[19])
	g2 = G * m[2] * (x[7] - x[19])
	g3 = G * m[3] * (x[13] - x[19])
	r1 = ((x[1] - x[19])^2 + (x[2] - x[20])^2 + (x[3] - x[21])^2)^0.5
	r3 = ((x[19] - x[13])^2 + (x[20] - x[14])^2 +(x[21] - x[15])^2)^0.5
	r2 = ((x[7] - x[19])^2 + (x[8] - x[20])^2 +(x[9] - x[21])^2)^0.5
	return g1/(r1^3) + g2/(r2^3) + g3/(r3^3)
end
	
function f5A(x::Array{Float64,1}, m::Array{Float64,1}) #w1
	g1 = G * m[2] * (x[8] - x[2])
	g2 = G * m[3] * (x[14] - x[2])
	r1 = ((x[1] - x[7])^2 + (x[2] - x[8])^2 + (x[3] - x[9])^2)^0.5
	r2 = ((x[1] - x[13])^2 + (x[2] - x[14])^2 +(x[3] - x[15])^2)^0.5
	return g1/(r1^3) + g2/(r2^3)
end

function f5B(x::Array{Float64,1}, m::Array{Float64,1}) #w2
	g1 = G * m[1] * (x[2] - x[8])
	g2 = G * m[3] * (x[14] - x[8])
	r1 = ((x[1] - x[7])^2 + (x[2] - x[8])^2 + (x[3] - x[9])^2)^0.5
	r3 = ((x[7] - x[13])^2 + (x[8] - x[14])^2 +(x[9] - x[15])^2)^0.5
	return g1/(r1^3) + g2/(r3^3)
end

function f5C(x::Array{Float64,1}, m::Array{Float64,1}) #w3
	g1 = G * m[1] * (x[2] - x[14])
	g2 = G * m[2] * (x[8] - x[14])
	r2 = ((x[1] - x[13])^2 + (x[2] - x[14])^2 +(x[3] - x[15])^2)^0.5
	r3 = ((x[7] - x[13])^2 + (x[8] - x[14])^2 +(x[9] - x[15])^2)^0.5
	return g1/(r2^3) + g2/(r3^3)
end

function f5D(x::Array{Float64,1}, m::Array{Float64,1}) #w4
	g1 = G * m[1] * (x[2] - x[20])
	g2 = G * m[2] * (x[8] - x[20])
	g3 = G * m[3] * (x[14] - x[20])
	r1 = ((x[1] - x[19])^2 + (x[2] - x[20])^2 + (x[3] - x[21])^2)^0.5
	r3 = ((x[19] - x[13])^2 + (x[20] - x[14])^2 +(x[21] - x[15])^2)^0.5
	r2 = ((x[7] - x[19])^2 + (x[8] - x[20])^2 +(x[9] - x[21])^2)^0.5
	return g1/(r1^3) + g2/(r2^3) + g3/(r3^3)
end

function f6A(x::Array{Float64,1}, m::Array{Float64,1}) #u1
	g1 = G * m[2] * (x[9] - x[3])
	g2 = G * m[3] * (x[15] - x[3])
	r1 = ((x[1] - x[7])^2 + (x[2] - x[8])^2 + (x[3] - x[9])^2)^0.5
	r2 = ((x[1] - x[13])^2 + (x[2] - x[14])^2 +(x[3] - x[15])^2)^0.5
	return g1/(r1^3) + g2/(r2^3)
end

function f6B(x::Array{Float64,1}, m::Array{Float64,1}) #u2
	g1 = G * m[1] * (x[3] - x[9])
	g2 = G * m[3] * (x[15] - x[9])
	r1 = ((x[1] - x[7])^2 + (x[2] - x[8])^2 + (x[3] - x[9])^2)^0.5
	r3 = ((x[7] - x[13])^2 + (x[8] - x[14])^2 +(x[9] - x[15])^2)^0.5
	return g1/(r1^3) + g2/(r3^3)
end

function f6C(x::Array{Float64,1}, m::Array{Float64,1}) #u3
	g1 = G * m[1] * (x[3] - x[15])
	g2 = G * m[2] * (x[9] - x[15])
	r2 = ((x[1] - x[13])^2 + (x[2] - x[14])^2 +(x[3] - x[15])^2)^0.5
	r3 = ((x[7] - x[13])^2 + (x[8] - x[14])^2 +(x[9] - x[15])^2)^0.5
	return g1/(r2^3) + g2/(r3^3)
end

function f6D(x::Array{Float64,1}, m::Array{Float64,1}) #w4
	g1 = G * m[1] * (x[3] - x[21])
	g2 = G * m[2] * (x[9] - x[21])
	g3 = G * m[3] * (x[15] - x[21])
	r1 = ((x[1] - x[19])^2 + (x[2] - x[20])^2 + (x[3] - x[21])^2)^0.5
	r2 = ((x[7] - x[19])^2 + (x[8] - x[20])^2 +(x[9] - x[21])^2)^0.5
	r3 = ((x[19] - x[13])^2 + (x[20] - x[14])^2 +(x[21] - x[15])^2)^0.5
	return g1/(r1^3) + g2/(r2^3) + g3/(r3^3)
end

Master("code-fall2025/sample.txt")