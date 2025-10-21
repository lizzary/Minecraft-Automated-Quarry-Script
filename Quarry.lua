
--名词解释：
--起重机杆：机械动力中用于承载起重机的杆子
--采矿头/起重机：由起重机、滑轮绳索、机壳、箱子和钻头组成的采矿主体部分
--采矿框架：采矿头+起重机杆
--可编程齿轮箱、反转齿轮箱、无线信号终端、手摇曲柄：机械动力中的中的物品
--末影调制调解器：cc电脑中的物品

--使用说明：
--本代码中，顺时针（"clockwise")定义为在不打开反转齿轮箱的情况下，起重机杆朝北（原点/动力输入 朝南）：
--直接转动手摇曲柄时：
--采矿头向动力输入的方向移动
--采矿头下移
--采矿框架向远离动力输入的方向移动
--逆时针（"counterclockwise")定义为在不打开反转齿轮箱的情况下，起重机杆朝北（原点/动力输入 朝南）：
--按住shift转动手摇曲柄时：
--起重机向远离动力输入的方向移动
--采矿头上移
--采矿框架向动力输入的方向移动

--重要：动力输入至少需要64rpm以上
--重要：动力输入时需要确保旋转方向**在未启动程序之前**，元件的运动符合顺时针("clockwise")和逆时针("counterclockwise")的定义
--重要：采矿框架的移动不会根据起重机杆的朝向进行自适应，应修改可编程齿轮箱内的旋转方向使其符合顺时针（"clockwise")和逆时针("counterclockwise")的定义
--      且采矿框架只会固定朝远离动力源的方向移动，如果需要收回采矿框架，需使用手摇曲柄

--注意事项：
--无论起重机杆朝向哪边，直接转动手摇曲柄时起重机都会向动力输入的方向移动
--可编程齿轮箱并不精确，连接可编程齿轮箱的转速不要过快，推荐100rpm以内

--必填参数
--起重机杆的长度，单位：格
gantry_shaft_length = 12
--采矿头（需要是正方形）边长，单位：格
mining_head_size = 3
--起重机杆朝向，选项为：north, south, west, east
direction = 'north'
--采矿头下挖等待时间，单位：秒
mining_time = 5
--采矿头上升等待时间，单位：秒
rising_time = 5
--采矿框架长度（活塞杆的长度）
mining_frame_length = 10
----------------------------
--选填参数，元件红石与电脑连接的方向，取决于 无线信号终端/红石线路 的摆放，选项为对于电脑六个面的：top,back,left,right
--起重机杆可编程齿轮箱控制位于电脑左边
gantry_shaft_switch = "left"
--采矿头上下移动离合器位于电脑右边
mining_head_clutch = "right"
--反转齿轮箱控制位于电脑上方
reverser = "top"
--采矿头动力输入位于电脑后方
mining_head_power_switch = "back"
--采矿框架移动可编程齿轮箱
mining_frame_switch = "front"
--本机通信频道，用于在调制条机器网络中指定自己
local_modem_channel = 99
--无线通信频道，用于向指定端口的调制调解器广播字符串
modem_channel = 0


--代码部分：
--辅助函数
--反转齿轮箱控制
function reverser_control(action)
    --action：字符串，"on"为激活指定位置的红石信号，"off"为关闭指定位置的红石信号
    if action == "on" then
        redstone.setOutput(reverser, true)
    elseif action == "off" then
        redstone.setOutput(reverser, false)
    end
end
--起重机杆可编程齿轮箱控制
function gantry_shaft_switch_control(action)
    --action：字符串，"on"为激活指定位置的红石信号，"off"为关闭指定位置的红石信号
    if action == "on" then
        redstone.setOutput(gantry_shaft_switch, true)
    elseif action == "off" then
        redstone.setOutput(gantry_shaft_switch, false)
    end
end
--采矿头上下移动离合器控制
function mining_head_movement_clutch_control(action)
    --action：字符串，"on"为激活指定位置的红石信号，"off"为关闭指定位置的红石信号
    if action == "on" then
        redstone.setOutput(mining_head_clutch, true)
    elseif action == "off" then
        redstone.setOutput(mining_head_clutch, false)
    end
end
--采矿头动力输入控制
function mining_head_power_switch_control(action)
    --action：字符串，"on"为激活指定位置的红石信号，"off"为关闭指定位置的红石信号
    if action == "on" then
        redstone.setOutput(mining_head_power_switch, true)
    elseif action == "off" then
        redstone.setOutput(mining_head_power_switch, false)
    end
end
--采矿框架可编程齿轮箱控制
function mining_frame_switch_control(action)
    --action：字符串，"on"为激活指定位置的红石信号，"off"为关闭指定位置的红石信号
    if action == "on" then
        redstone.setOutput(mining_frame_switch, true)
    elseif action == "off" then
        redstone.setOutput(mining_frame_switch, false)
    end
end
--
function log(msg)
    --msg：字符串

    --在本地打印信息
    print(msg)

    --如果有连接调制调解器，则向modem_channel指定的频道发送该消息
    local modem = peripheral.find("modem")
    if modem ~= nil then
        modem.open(local_modem_channel)
        modem.transmit(modem_channel,local_modem_channel,msg)
    end
end
--如果需要有设备远程接收log方法的消息，使用以下代码将信息打印到该电脑上以及与其连接的显示器（如有）
--receive_host.lua：
--function receive(local_channel)
--    --local_channel：整数，表示主机监听哪个频道
--    local modem = peripheral.find("modem") or error("No modem attached", 0)
--    modem.open(local_channel)
--
--    while true do
--        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
--        print(message)
--        --在显示器上打印信息（如有）
--        local monitor = peripheral.find("monitor")
--        if monitor ~= nil then
--            local width,height = monitor.getSize()
--            local cursor_x,cursor_y = monitor.getCursorPos()
--            if cursor_y >= height then
--                monitor.clear()
--                monitor.setCursorPos(1, 1)
--                cursor_x = 1
--                cursor_y = 1
--            end
--            monitor.write(message)
--            monitor.setCursorPos(1, cursor_y + 1)
--        end
--    end
--end
--receive(<监听频道号>)


--行为定义：

--采矿头沿着起重机杆移动，移动的格数取决于可编程齿轮箱里的设置（推荐设置为和mining_head_size相同的值）
function mining_head_move_along_gantry_shaft(rotate)
    --rotate：字符串，"clockwise"为顺时针方向移动，"counterclockwise"为逆时针方向移动，其他值则不进行任何操作

    --开启上下移动离合器
    mining_head_movement_clutch_control("on")
    --关闭采矿头动力输入
    mining_head_power_switch_control("off")
    sleep(0.2)

    if rotate == "clockwise" then
        reverser_control("off")
    elseif rotate == "counterclockwise" then
        reverser_control("on")
    end

    sleep(0.2)
    gantry_shaft_switch_control("on")
    sleep(0.3)
    gantry_shaft_switch_control("off")
    sleep(mining_head_size*1)

end

--采矿头上下移动
function mining_head_move_up_and_down(rotate)
    --rotate：字符串，"clockwise"为顺时针方向移动，"counterclockwise"为逆时针方向移动，其他值则不进行任何操作

    --开启上下移动离合器
    mining_head_movement_clutch_control("on")
    --关闭采矿头动力输入
    mining_head_power_switch_control("off")
    sleep(0.2)

    if rotate == "clockwise" then
        if direction == 'north' or direction == 'east' then
            --关闭反转齿轮箱
            reverser_control("off")
        elseif direction == 'south' or direction == 'west' then
            --开启反转齿轮箱
            reverser_control("on")
        end
        sleep(0.2)
        --开启采矿头动力输入
        mining_head_power_switch_control("on")
        sleep(0.2)
        --关闭上下移动离合器
        mining_head_movement_clutch_control("off")
        sleep(mining_time)
        mining_head_movement_clutch_control("on")
        mining_head_power_switch_control("off")
    elseif rotate == "counterclockwise" then
        if direction == 'north' or direction == 'east' then
            --开启反转齿轮箱
            reverser_control("on")
        elseif direction == 'south' or direction == 'west' then
            --关闭反转齿轮箱
            reverser_control("off")
        end
        sleep(0.2)
        mining_head_power_switch_control("on")
        sleep(0.2)
        mining_head_movement_clutch_control("off")
        sleep(rising_time)
        mining_head_movement_clutch_control("on")
        mining_head_power_switch_control("off")
    end

end

--采矿框架移动，移动的格数取决于可编程齿轮箱里的设置（推荐设置为和mining_head_size相同的值）
function mining_frame_move_forward()
    --开启上下移动离合器
    mining_head_movement_clutch_control("on")
    --关闭采矿头动力输入
    mining_head_power_switch_control("off")
    sleep(0.2)
    mining_frame_switch_control("on")
    sleep(0.2)
    mining_frame_switch_control("off")
end

--主循环：
function run()
    --开启上下移动离合器
    mining_head_movement_clutch_control("on")
    --关闭采矿头动力输入
    mining_head_power_switch_control("off")
    sleep(0.2)

    --动作循环：采矿头下降 -> 采矿头上升 -> 向前移动mining_head_size格
    loop_count = math.floor(gantry_shaft_length / mining_head_size + 1)
    for i = 1,loop_count do
        log("mining - (" .. tostring(i*mining_head_size) .. "/" .. tostring(gantry_shaft_length) .. ")")
        mining_head_move_up_and_down("clockwise")
        sleep(0.2)
        log("reset mining head")
        mining_head_move_up_and_down("counterclockwise")
        sleep(0.2)
        log("mining head moving...")
        mining_head_move_along_gantry_shaft("counterclockwise")
    end

    --归位
    for i = 1,loop_count do
        mining_head_move_along_gantry_shaft("clockwise")
    end

    --采矿框架移动
    mining_frame_move_forward()



end

--运行循环：
function START()
    loop_count = math.floor(mining_frame_length/mining_head_size) + 1
    log("Start, parameters: ")
    log("gantry_shaft_length: " .. tostring(gantry_shaft_length))
    log("mining_head_size: " .. tostring(mining_head_size))
    log("direction: " .. tostring(direction))
    log("mining_time: " .. tostring(mining_time))
    log("rising_time: " .. tostring(rising_time))
    log("mining_frame_length: " .. tostring(mining_frame_length))
    log("total round: " .. tostring(loop_count))
    log("----------------")
    for i = 1,loop_count do
        log( "(" .. tostring(i) .. "/" .. tostring(loop_count) .. ")" .. " round start:")
        run()
        sleep(0.2)
        log("end")
        log("----------------")
    end
end
--测试
----开启上下移动离合器
--mining_head_movement_clutch_control("on")
----关闭采矿头动力输入
--mining_head_power_switch_control("off")
--sleep(0.2)
--
--mining_head_move_up_and_down("counterclockwise")
START()
