#include("NestedBinaryTrial.jl") 
#include("NestedBinary_updated.jl")
include("NestedBinaryFinal_Fast.jl")

function StabilityFinder(m, a1, theta=0, percent=5, precision=2, t="100P", MemorySave="all", hParam=0.01, fileSave="AutoSave", writeData=0, startinga2=0)
    #here, m is an stringed array of the masses while a1 is a Float64 that is the inner separation
    if startinga2==0 #unless told otherwise
        a2=a1*2 #we'll begin with the outer separation being twice as large as the inner separation
    else
        a2=startinga2
    end
    lastUnstablea2=a2
    finala2 = 0
    stability = 0 
    sizeStep = 0 #this determines the amount we'll change a2 by with each test
    counter = 0 #this will help us test more cases, meaning that when a system is stable, we're more confident that we've stepped over that stability condition line
    while sizeStep < precision #This line indicates the number of significant figures that will be evaluated. The higher, the longer the runtime
        x = open("Test_$([m[1],m[2],m[3],a1,a2,theta]).txt","w") #creating the input file
        write(x,"$m"[2:end-1],"\n")
        write(x,"$a1,0,$a2,0,$theta,0\n")
        write(x,"$t,$hParam, $percent")
        close(x)
        println("The parameters here are masses $m, separations $a1 and $a2, with zero eccentricity and inclination, and $theta angular offset.")
        record, dataFileExists, rowNumber, stability = Master("Test_$([m[1],m[2],m[3],a1,a2,theta]).txt",true,"AutoSave_$([m[1],m[2],m[3],a1,a2,theta])", writeData, MemorySave) #run simulation, get stability. Note that we're saving stuff for the heck of it
        rm("Test_$([m[1],m[2],m[3],a1,a2,theta]).txt") #deleting the input .txt file
        if dataFileExists && record #if the data was saved in the spreadsheet, we save the output .txt file with the corresponding row number. If it wasn't, we delete the output .txt file.
            mv("data_files/AutoSave_$([m[1],m[2],m[3],a1,a2,theta]).txt","data_files/$fileSave"*"_$rowNumber"*".txt", force=true)
        elseif dataFileExists
            rm("data_files/AutoSave_$([m[1],m[2],m[3],a1,a2,theta]).txt")#deletes text file if data wasn't recorded in spreadsheet
        end
        if stability == 1 
            if sizeStep > 0 || counter >= 4 #this is the case if we have a stable system after 5 consecutive checks the first time, or the susbsequent searches of stability
                finala2 = lastUnstablea2*(1+0.2*10.0^-sizeStep) #if the loop quits after this, we want to say that this is the smallest stable a2 that we found
                sizeStep += 1 #we're going to narrow our search case
                a2 = lastUnstablea2*(1+0.2*10.0^-sizeStep) #we cancel those 5 checks we had before to get back to the most recent unstable system, then increase increase a2
            else
                a2 *= 1+0.2*10.0^-sizeStep
                counter += 1 #this is still the first time, so we just need to make sure we're not in an island of stability
            end
        else #in this case, we have an unstable system 
            counter = 0 #we reset the number of consecutive stable system we've found
            lastUnstablea2=a2 #and remember that this is the largest unstable a2 that we've found
            a2 *= 1+0.2*10.0^-sizeStep  #we increase a2
        end
    end
    a2 = finala2
    XLSX.openxlsx("StabilityConditions.xlsx",mode="rw") do xf #then we save in this nifty spreadsheet
        sheet = xf[1]
        i = 1
        record = true
        while typeof(sheet["A$i"]) != Missing #gets next blank row
            if [sheet["A$i"],sheet["B$i"],sheet["C$i"],sheet["D$i"],sheet["F$i"],sheet["G$i"],sheet["H$i"]] == [m[1],m[2],m[3],a1,t,hParam,theta]
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
            sheet["D$i"] = a1
            sheet["E$i"] = round(a2;digits=2)
            sheet["F$i"] = t
            sheet["G$i"] = hParam
            sheet["H$i"] = theta
        end
    end
    return round(a2;digits=2)  #returns smallest a2 that is stable, digits denotes the number of sig figs after the decimal evaluated
end

# StabilityFinder([1.5, 1.5, 1], 13, 0)