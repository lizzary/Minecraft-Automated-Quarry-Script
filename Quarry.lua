--Global Setting--
--256RPM: 0.25
--112RPM: 0.4
--96RPM: 0.5
PowerAxisUnLockTime = 0.25
RelocationWaittingTime = 4
DrillDownardWaittingTime = 1
--------------------------------
--Cable
OutputCables = {
    ["Gearshift"] = colors.white,
    ["powerAxisUnLock"] = colors.green,
    ["drillDownward"] = colors.orange,
    ["storageInterfaceLock"] = colors.brown
}
InputCables = {
    ["workAxisStartObserver"] = colors.red,
    ["workAxisEndObserver"] = colors.magenta,
    ["powerAxisStartObserver"] = colors.blue,
    ["powerAxisEndObserver"] = colors.purple,
    ["endPointObserver"] = colors.black
}
--Parameter
DirectionOfPowerAxis = ""



function getCurrentOutputCableStage()
    local CableStage = {}
    for key,_ in pairs(OutputCables) do
        CableStage[key] = false
    end


    local OutputCablesColorCode = redstone.getBundledOutput("Back")

    local sortCables = {}
    local keysArray = {}
    for key,_ in pairs(OutputCables) do
        table.insert(keysArray,key)
    end

    local function compareValues(key1,key2)
        return OutputCables[key1] >= OutputCables[key2]
    end

    table.sort(keysArray,compareValues)

    for _,key in pairs(keysArray) do
        if OutputCablesColorCode - OutputCables[key] >= 0 then
            OutputCablesColorCode = OutputCablesColorCode - OutputCables[key]
            CableStage[key] = true
        end
    end
    return CableStage
                
end

function getCurrentInputCableStage()
    local Cables = {}
    for key,_ in pairs(InputCables) do
        Cables[key] = InputCables[key]
    end

    for key,value in pairs(Cables) do
        Cables[key] = redstone.testBundledInput("back",InputCables[key])
    end

    return Cables
end


function OpenWire(outputWire)
    local stage = getCurrentOutputCableStage()

    if stage[outputWire] == true then
        return
    end

    stage[outputWire] = true
    local openCode = 0
    for CablesName,isOpen in pairs(stage) do
        if isOpen == true then
            openCode = openCode + OutputCables[CablesName]
        end
    end
    
    redstone.setBundledOutput("back",openCode)

end

function CloseWire(outputWire)
    local stage = getCurrentOutputCableStage()

    if stage[outputWire] == false then
        return
    end

    stage[outputWire] = false
    local openCode = 0
    for CablesName,isOpen in pairs(stage) do
        if isOpen == true then
            openCode = openCode + OutputCables[CablesName]
        end
    end

    redstone.setBundledOutput("back",openCode)
end

function ChangeWireState(outputWire)
    local stage = getCurrentOutputCableStage()

    if stage[outputWire] == true then
        CloseWire(outputWire)
    end

    if stage[outputWire] == false then
        OpenWire(outputWire)
    end
end

function WaitingInputSignal(name)
    --print("Waiting for the signal from ",name," ......")
    local isActive = false
    while(isActive == false) do
        isActive = getCurrentInputCableStage()[name]
        sleep(0.1)
    end
    --print("Received Signal from ",name," !")
end

function AutoInitSetting()
    print("--------------------")
    print("The automatic initialization is in progress...")

    CloseWire("Gearshift")
    CloseWire("powerAxisUnLock")
    CloseWire("drillDownward")
    OpenWire("storageInterfaceLock")

    local SettingFile = io.open("InitSetting.txt", "r")
    if not SettingFile then
        SettingFile = io.open("InitSetting.txt","w")
    else
        print("InitSetting.txt found! Perform Fast resetting ...")

        local ChangeWire = SettingFile:read()
        local PowerAxisDir = SettingFile:read()
        
        if ChangeWire == "ChangeWireState=true" then
            if PowerAxisDir == "DirectionOfPowerAxis=NorthOrEast" then
                print("Reset the location of the drill in power axis ...")
                OpenWire("powerAxisUnLock")
                ChangeWireState("Gearshift")
                sleep(RelocationWaittingTime)

                print("Reset the location of the drill in working axis ...")
                CloseWire("powerAxisUnLock")
                ChangeWireState("Gearshift")
                sleep(RelocationWaittingTime)
                DirectionOfPowerAxis = "NorthOrEast"
                print("Reset done!")
            end

            if PowerAxisDir == "DirectionOfPowerAxis=SouthOrWest" then
                print("Reset the location of the drill in power axis ...")
                OpenWire("powerAxisUnLock")
                ChangeWireState("Gearshift")
                sleep(RelocationWaittingTime)

                print("Reset the location of the drill in working axis ...")
                CloseWire("powerAxisUnLock")
                sleep(RelocationWaittingTime)
                DirectionOfPowerAxis = "SouthOrWest"
                
                print("Reset done!")
            end

        end

        if ChangeWire == "ChangeWireState=false" then

            if PowerAxisDir == "DirectionOfPowerAxis=SouthOrWest" then
                print("Reset the location of the drill in power axis ...")
                OpenWire("powerAxisUnLock")
                sleep(RelocationWaittingTime)

                print("Reset the location of the drill in working axis ...")
                CloseWire("powerAxisUnLock")
                sleep(RelocationWaittingTime)
                DirectionOfPowerAxis = "SouthOrWest"

                print("Reset done!")
            elseif PowerAxisDir == "DirectionOfPowerAxis=NorthOrEast" then
                print("Reset the location of the drill in power axis ...")
                OpenWire("powerAxisUnLock")
                sleep(RelocationWaittingTime)

                print("Reset the location of the drill in working axis ...")
                CloseWire("powerAxisUnLock")
                ChangeWireState("Gearshift")
                sleep(RelocationWaittingTime)
                DirectionOfPowerAxis = "NorthOrEast"

                print("Reset done!")
            else
                print("Fast resetting wrong! Perform automatic initialization")
            end
        end
        print("The Automatic Initialization / Fast Resetting is done !")
        return
    end

    
    --Locate the drill in powerAxis
    print("Locate the drill in power axis")
    OpenWire("powerAxisUnLock")
    sleep(RelocationWaittingTime)
    ChangeWireState("Gearshift")
    sleep(0.2)
    ChangeWireState("Gearshift")

    local powerAxisStartObserver = false
    local powerAxisEndObserver = false
    while(true) do 
        powerAxisStartObserver = getCurrentInputCableStage()["powerAxisStartObserver"]
        powerAxisEndObserver = getCurrentInputCableStage()["powerAxisEndObserver"]
        if powerAxisStartObserver == true or powerAxisEndObserver == true then
            break
        end
        sleep(0.1)
    end

    --Locate the drill in workAxis
    print("Locate the drill in working axis")
    CloseWire("powerAxisUnLock")
    sleep(RelocationWaittingTime)
    ChangeWireState("Gearshift")
    sleep(0.2)
    ChangeWireState("Gearshift")
    
    local workAxisStartObserver = false
    local workAxisEndObserver = false
    while(true) do
        workAxisStartObserver = getCurrentInputCableStage()["workAxisStartObserver"]
        workAxisEndObserver = getCurrentInputCableStage()["workAxisEndObserver"]
        if workAxisStartObserver == true or workAxisEndObserver == true then
            break
        end
        sleep(0.1)
    end


    --Reset the drill to the starting point
    if powerAxisStartObserver == false then

        if workAxisStartObserver == true then
            print("result: Pow. Axis -> END  Wk. Axis -> START")
            OpenWire("powerAxisUnLock")
            ChangeWireState("Gearshift")
            WaitingInputSignal("powerAxisStartObserver")
            CloseWire("powerAxisUnLock")
            ChangeWireState("Gearshift")
            SettingFile:write("ChangeWireState=true\n")
            SettingFile:write("DirectionOfPowerAxis=NorthOrEast\n")
            SettingFile:close()
            DirectionOfPowerAxis = "NorthOrEast"
        end

        if workAxisStartObserver == false then
            print("result: Pow. Axis -> END  Wk. Axis -> END")
            OpenWire("powerAxisUnLock")
            ChangeWireState("Gearshift")
            WaitingInputSignal("powerAxisStartObserver")
            CloseWire("powerAxisUnLock")
            WaitingInputSignal("workAxisStartObserver")
            SettingFile:write("ChangeWireState=true\n")
            SettingFile:write("DirectionOfPowerAxis=SouthOrWest\n")
            SettingFile:close()
            DirectionOfPowerAxis = "SouthOrWest"
        end
    end

    if powerAxisStartObserver == true then

        if workAxisStartObserver == true then
            print("result: Pow. Axis -> START  Wk. Axis -> START")
            SettingFile:write("ChangeWireState=false\n")
            SettingFile:write("DirectionOfPowerAxis=SouthOrWest\n")
            SettingFile:close()
            DirectionOfPowerAxis = "SouthOrWest"
        end

        if workAxisStartObserver == false then
            print("result: Pow. Axis -> START  Wk. Axis -> END")
            ChangeWireState("Gearshift")
            WaitingInputSignal("workAxisStartObserver")
            SettingFile:write("ChangeWireState=false\n")
            SettingFile:write("DirectionOfPowerAxis=NorthOrEast\n")
            SettingFile:close()
            DirectionOfPowerAxis = "NorthOrEast"
        end
    end

    print("The automatic initialization is done!")
end

function CleaningEdges()
    print("--------------------")
    print("Cleaning Edges ...")
    if DirectionOfPowerAxis == "SouthOrWest" then   
        --Cleaning powerAxis edge
        ChangeWireState("Gearshift")
        OpenWire("powerAxisUnLock")
        CloseWire("storageInterfaceLock")--Unlock interface to Output Items
        WaitingInputSignal("powerAxisEndObserver")
        OpenWire("storageInterfaceLock")--lock interface
    
        --Cleaning opposite edge of power axis
        CloseWire("powerAxisUnLock")
        WaitingInputSignal("workAxisEndObserver")

        --Cleaning opposite edge of working axis
        ChangeWireState("Gearshift")
        OpenWire("powerAxisUnLock")
        WaitingInputSignal("powerAxisStartObserver")

        --Cleaning working edge
        CloseWire("powerAxisUnLock")
        WaitingInputSignal("workAxisStartObserver")
    end

    if DirectionOfPowerAxis == "NorthOrEast" then   
        
        --Cleaning powerAxis edge
        OpenWire("powerAxisUnLock")
        CloseWire("storageInterfaceLock")--Unlock interface to Output Items
        WaitingInputSignal("powerAxisEndObserver")
        OpenWire("storageInterfaceLock")--lock interface
        
        --Cleaning opposite edge of power axis
        CloseWire("powerAxisUnLock")
        sleep(0.1)--wait for the drill physicalization
        ChangeWireState("Gearshift")
        WaitingInputSignal("workAxisEndObserver")
            
        --Cleaning opposite edge of working axis
        OpenWire("powerAxisUnLock")
        WaitingInputSignal("powerAxisStartObserver")

        --Cleaning opposite edge of working axis
        CloseWire("powerAxisUnLock")
        sleep(0.1)--wait for the drill physicalization
        ChangeWireState("Gearshift")
        WaitingInputSignal("workAxisStartObserver")
    end

    print("Done!")
end

--axisDirection: "SouthOrWest" or "NorthOrEast" the direction of power axis point at (relative to starting point)
--movingDirection: "leaving" or "return"
function MoveAlongWorkingAxis(axisDirection,movingDirection)

    if axisDirection == "SouthOrWest" then

        if movingDirection == "leaving" then
            OpenWire("powerAxisUnLock")
            sleep(PowerAxisUnLockTime)
            CloseWire("powerAxisUnLock")
        end

        if movingDirection == "return" then
            ChangeWireState("Gearshift")
            OpenWire("powerAxisUnLock")
            sleep(PowerAxisUnLockTime+0.1)
            CloseWire("powerAxisUnLock")
            ChangeWireState("Gearshift")
        end
    end

    if axisDirection == "NorthOrEast" then

        if movingDirection == "leaving" then
            ChangeWireState("Gearshift")
            OpenWire("powerAxisUnLock")
            sleep(PowerAxisUnLockTime+0.1)
            CloseWire("powerAxisUnLock")
            ChangeWireState("Gearshift")
        end

        if movingDirection == "return" then
            OpenWire("powerAxisUnLock")
            sleep(PowerAxisUnLockTime)
            CloseWire("powerAxisUnLock")
        end
    end
end


function Run()
    --!!The drill should be near to the power(in running state),use AutoInitSetting() to reset the drill to the starting point
    CloseWire("powerAxisUnLock")
    ChangeWireState("Gearshift")

    --far away (For Work Axis)
    local isWorkAxisEndObserverOpen = false
    WaitingInputSignal("workAxisEndObserver")
    if DirectionOfPowerAxis == "SouthOrWest" then
        MoveAlongWorkingAxis("SouthOrWest","leaving")
    else
        MoveAlongWorkingAxis("NorthOrEast","leaving")
    end
    
    --check if end
    sleep(0.5)--wait for the ending observer signal
    isEnd = getCurrentInputCableStage()["endPointObserver"]
    if isEnd == true then
        return false
    end
    ChangeWireState("Gearshift")
    sleep(PowerAxisUnLockTime+0.5)--shield the signal due to moving


    --close to (For Work Axis)
    WaitingInputSignal("workAxisStartObserver")
    if DirectionOfPowerAxis == "SouthOrWest" then
        MoveAlongWorkingAxis("SouthOrWest","return")
    else
        MoveAlongWorkingAxis("NorthOrEast","return")
    end
    --check if end
    sleep(PowerAxisUnLockTime+0.5)--shield the signal due to moving & wait for the ending observer signal
    isEnd = getCurrentInputCableStage()["endPointObserver"]
    if isEnd == true then
        return false
    end

    return true


end


function Main()
    CleaningEdges()
    print("--------------------")
    print("Working ...")
    while(true) do
        local canRunNext = Run()
        if canRunNext == false then
            break
        end
    end
end

function DrillDownward()
    OpenWire("drillDownward")
    sleep(DrillDownardWaittingTime)
    CloseWire("drillDownward")

end

function checkTermination()
end

function test()
    AutoInitSetting()
    Main()
    AutoInitSetting()
    DrillDownward()
    sleep(0.1)
    print("finish!")
end

function START()
    AutoInitSetting()
    while(true) do
        Main()
        AutoInitSetting()
        DrillDownward()
        sleep(0.1)
    end
end

START()










    









