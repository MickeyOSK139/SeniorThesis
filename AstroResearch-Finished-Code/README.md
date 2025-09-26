# AstroResearch

This program is designed to input a .txt file of parameters and create a triple system and a star. The program is used to simulate accretion of the star by the system.
For just a binary system, use `systemrk.jl`. For more particles, use `Main.jl`. For a nested binary system, use `NestedBinary.jl`.

Masses are in units of solar mass, distances are in the units of solar radii, and time is in the units of days.

## NestedBinaryFinal.jl

  With `NestedBinaryFinal.jl`, the `Master` function will simulate the evolution of a nested binary system of bodies over a desired time period. This function will also determine whether or not the inputed initial conditions are stable. 
  
  ```
  Plot("Input.txt","blue")
  ```
  will yield the plot of the orbits. The color can be changed to any color recognized by matplotlib, and will be the color of one of the orbits.
  
  ```
  julia> Plot("Input.txt","E")
  
  julia> Plot("Input.txt","L")
  
  julia> Plot("Input.txt","EL")
  ```
  will yield the energy vs. time plot, the angular momentum vs. time plot, or both on the same axes, respectively.
  
  ```
  Plot("Input.txt","time")
  ```
  will yield the timestep vs. iteration plot.
  
  

### The .txt file must be in the following format for systemrk.jl:
  
  There are six elements in one line, each seperated by a comma:
  1. Mass of the primary body
  2. Mass of the secondary body
  3. Semi-major axis of the system
  4. Eccentricity
  5. Time that the simulation runs for
     - (if t=0, then the simulation will run for 100 periods)
  6. Timestep parameter, which determines the length of the timestep the program uses
  
  Example (black hole-star system): 
  ```
  1,8,4.20984,0.2,0,0.001
  ```

## AutomaticTester.jl

  With 'AutomaticTester.jl', the 'StabilityFinder' function takes in the masses and the inner binary separation of a desired nested binary configuration and returns the smallest such outer binary separation such that the system remains stable over the desired time period. This time period is defaulted to 100P of the inner binary. This can easily be adjusted by changing this value in the 'AutomaticTester.jl' file and reloading the file.
  
  ```
  StabilityFinder([8,8,1],7.2,5)
  ```
  Would return the the smallest stable outer binary separation for a system consisting of two 8 solar mass objects in the inner binary, a companion object of 1 solar mass, an inner binary separation of 7.2 solar radii and a desired conserved quantity drift of no more than 5 percent.
  

## Autolooper.jl and AutoLooper2.jl

  These two programs are essentially versions of 'AutomaticTester.jl' with an additional loop. This loop is usefull in 
  
  `Plot` also has the option `"none"`, where nothing is plotted.
  
  `NestedBinary` also comes with the `AutomaticTester` function, which  simulates a variety of initial conditions that are typical of observed triple systems. It then saves the data in an Excel spreadsheet, as well as compressed .txt files for later graphing. The .txt files are in the format `Name_n.txt`, where `n` is the Excel row number where that simulation was recorded.
  
  ```
  Plot("Input.txt","none","CoolOrbits.txt")
  ```
  would do the same thing as the above `Main` example.
  
  ```
  AutomaticTester("AutoRun")
  ```
  would produce a spreadsheet of simulations, whose .txt files would have the name `AutoRun_n.txt`.

### The .txt file must be in the following format for NestedBinary.jl:

  The elements are in three lines, each element being seperated by a comma:
  1. The first line is the list of masses of the bodies.
  2. The second line is the list of initial conditions: a₁, e₁, a₂, e₂, i, and Θ.
     - a₁ and e₁ are the semi-major axis and eccentricity of the inner binary's orbit.
     - a₂ and e₂ are the semi-major axis and eccentricity of the outer binary's orbit. 
     - i is the inclination of the third body's orbit. It's measured from the plane formed by the inner binary.
     - Θ is the angle between the line formed by the two inner bodies and the line formed from the inner binary's center of mass to the projection of the third body onto the above mentioned plane. It is also the longitude of the ascending node minus 270 degrees.
  3. The third line consists of the time the simulation should run for and the timestep parameter (see above).

  Example:
  ```
  8,8,1
  2,0,20,0.99,0,0
  10,0.0001
  ```
  
## ExternalPlotter.jl
 
  This contains the function `ExternalPlot`, which can recreate any plot created by `Plot` in `systemrk`, `Main`, or `NestedBinary`. The syntax is the same as `Plot`.
  
  ```
  ExternalPlot("Output.txt","blue")
  ```
  would return the orbits from the simulation that created `Output.txt`.

## Calculations

  The equations we used, along with our derivations that we used in this program, are explained in `Equations.pdf`. The LaTeX file for `Equations.pdf` is also avaliable in `main.tex`.
  
 ## Credits
 This code was produced for Prof. Ann Esin's summer research in astrophysics.
 This code was written by Brennen Quigley (@bquigley528) and Benjamin Khoury (@bbk001).
 Thank you to @timholy for their `ProgressMeter` package and @felipenoris for their `XLSX` package.
