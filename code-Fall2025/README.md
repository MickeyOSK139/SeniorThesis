# AstroResearch

This program is designed to input a .txt file of parameters and create a triple system consisting of two compact objects and a star. The hope is that this program while eventually be used to simulate accretion from the star to the compact binary.

To simulate a nested binary system, use `NestedBinary.jl`. To find stable systems over a desired time frame, use `AutomaticTester.jl` for systems in 2 dimensions or `ThreeD.jl` for systems in 3 dimensions. 

Masses are in units of solar mass, distances are in the units of solar radii, and time is in the units of days.

## NestedBinaryFinal.jl

  With `NestedBinaryFinal.jl`, the `Master` function will simulate the evolution of a nested binary system of bodies over a desired time period. This function will also determine whether or not the inputed initial conditions are stable. 
  
  
  ### The .txt file must be in the following format for NestedBinary.jl:

  The elements are in three lines, each element being seperated by a comma:
  1. The first line is the list of masses of the bodies.
  2. The second line is the list of initial conditions: a₁, e₁, a₂, e₂, i, and Θ.
     - a₁ and e₁ are the semi-major axis and eccentricity of the inner binary's orbit.
     - a₂ and e₂ are the semi-major axis and eccentricity of the outer binary's orbit. 
     - i is the inclination of the third body's orbit. It's measured from the plane formed by the inner binary.
     - Θ is the angle between the line formed by the two inner bodies and the line formed from the inner binary's center of mass to the projection of the third body onto the above mentioned plane. It is also the longitude of the ascending node minus 270 degrees.
  3. The third line consists of the time the simulation should run for and the timestep parameter. This line also includes the percent drift allowed of the consered quantities. That is, 5 here denotes that the conserved quantities are allowed to vary by at most 5%.

  Example:
  ```
  8,8,1
  2,0,20,0.99,0,0
  10,0.0001, 5
  ```
  
  Once a txt file has been created with the above information, simply call 
  ```
  Master(file.txt)
  ```
  to simulate the system.
 
 
## AutomaticTester.jl

  With `AutomaticTester.jl`, the `StabilityFinder` function takes in the masses and the inner binary separation of a desired nested binary configuration and returns the smallest such outer binary separation such that the system remains stable over the desired time period. This time period is defaulted to 100P of the inner binary. This can easily be adjusted by changing this value in the `AutomaticTester.jl` file and reloading the file. This program will also store the stable separation in `StabilityConditions.xlsx`.
  
  For example,
  
  ```
  StabilityFinder([8,8,1],7.2,5)
  ```
  Would return the the smallest stable outer binary separation for a system consisting of two 8 solar mass objects in the inner binary, a companion object of 1 solar mass, an inner binary separation of 7.2 solar radii and a desired conserved quantity drift of no more than 5 percent.
  
 ## ThreeD.jl

  `ThreeD.jl` is the three-dimensional version of `AutomaticTester.jl`. This program takes in the masses of the triple system, the separation of the inner binary, and the initial inclination of the third body relative to the plane of the inner binary. This program will then find the smallest stable separation of the outer binary over a desired time period and store this value in `StabilityConditions.xlsx`. Note: this desired time period is currently defaulting to 100P. This can be easily changed by altering `ThreeD.jl` and then recompiling the file.
  
  For example, after inlcuding this file if one inputs:
  
  ```
  ThreeDSF([8,8,1], 7.2, 25)
  ```
  
  the program will find the smallest separation necessary for a black hole binary system separated by 7.2 solar radii to be stable with a solar mass star angled at 25 degrees relative to the inner binary for 100P of the inner binary.
  
## Autolooper.jl and AutoLooper2.jl

  These two programs are essentially versions of 'AutomaticTester.jl' with an additional loop. This loop is usefull in evaluating numerous systems to explore the dependence of stability on various parameters.
  
  `Autolooper.jl` iterates the inner binary separations of a given system and will compile a list of stable outer binary separations in `StabilityConditions.xlsx`. 
  `Autolooper2.jl` iterates the inner binary separations of a several systems and will also compile the stable outer binary separations in `StabilityConditions.xlsx`. 
  
  These functins can be modified easily to explore the dependence of stability on other quantities.
  
## ExternalPlotter.jl
 
  This contains the function `ExternalPlot`, which can recreate any plot created by `Plot` in `systemrk`, `Main`, or `NestedBinary`. The syntax is the same as `Plot`.
  
  ```
  ExternalPlot("Output.txt","blue")
  ```
  would return the orbits from the simulation that created `Output.txt`.

## Calculations

  The equations we used, along with our derivations that we used in this program, are explained in `Equations.pdf`. The LaTeX file for `Equations.pdf` is also avaliable in `main.tex`.
  
  ### StabilityConditions.jl
  This consists of simple code that calculates the GR and accretion conditions necessary to have an accreting triple system. 
  
  `Differential(5, 2, 7.2, 0)` takes in a system consisting of a 5 and 2 solar mass objects in the inner binary separated by 7.2 solar radii and returns the amount of time before the paths of these objects starts changing significantly. NOTE; the equation here is in terms of semi major axis not separation. However, for systems with no eccentricity it remains accurate if separation is used.
  
  `lagrangian(3, 3, 1, 20)` evaluates the lagrange points of an otter binary consisting of a 6 solar mass object and a 1 solar mass object. 

  
 ## Credits
 This code was produced for Prof. Ann Esin's summer research in astrophysics.
 This code was written by Brennen Quigley (@bquigley528) and Benjamin Khoury (@bbk001).
 Thank you to @timholy for their `ProgressMeter` package and @felipenoris for their `XLSX` package.
