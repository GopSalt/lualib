-- Patrick Star Crafting Automation for ComputerCraft (ATM10)
-- Script controls Turtle that places concrete into Mechanical Crafters.

-- 9x9 Crafting Matrix (1: Pink Concrete, 2: Magenta Concrete, 3: Pink Powder, 4: Magenta Powder, 5: Green Concrete, 6: Green Powder, 7: Lime Concrete)
local patrick_star = {
    {0, 0, 0, 0, 1, 0, 0, 0, 0}, -- y = 1 (Top row)
    {0, 0, 0, 1, 3, 2, 0, 0, 0}, -- y = 2
    {1, 1, 1, 4, 3, 2, 1, 1, 1}, -- y = 3
    {2, 3, 4, 3, 4, 4, 4, 3, 2}, -- y = 4
    {0, 2, 2, 4, 4, 4, 1, 2, 0}, -- y = 5
    {0, 0, 6, 5, 5, 5, 6, 0, 0}, -- y = 6
    {0, 6, 7, 6, 5, 6, 7, 6, 0}, -- y = 7
    {1, 6, 5, 5, 0, 5, 5, 6, 1}, -- y = 8
    {2, 2, 2, 0, 0, 0, 2, 2, 2}  -- y = 9 (Bottom row)
}

-- Item registry names in ATM10 for auto-sorting
local target_names = {
    [1] = "minecraft:pink_concrete",          -- Slot 1: 11 pcs
    [2] = "minecraft:magenta_concrete",       -- Slot 2: 13 pcs
    [3] = "minecraft:pink_concrete_powder",   -- Slot 3: 5 pcs
    [4] = "minecraft:magenta_concrete_powder",-- Slot 4: 8 pcs
    [5] = "minecraft:green_concrete",         -- Slot 5: 8 pcs
    [6] = "minecraft:green_concrete_powder",  -- Slot 6: 8 pcs
    [7] = "minecraft:lime_concrete"           -- Slot 7: 2 pcs
}

-- Helper functions for safe movement with collision handling
local function safe_forward()
    while not turtle.forward() do
        print("Movement blocked! Waiting...")
        sleep(1)
    end
end

local function safe_back()
    while not turtle.back() do
        print("Movement back blocked! Waiting...")
        sleep(1)
    end
end

local function safe_up()
    while not turtle.up() do
        print("Ascent blocked! Waiting...")
        sleep(1)
    end
end

local function safe_down()
    while not turtle.down() do
        print("Descent blocked! Waiting...")
        sleep(1)
    end
end

-- Function to check chest contents to the left of the turtle
local function get_chest_item_count()
    local chest = peripheral.wrap("left")
    if not chest then
        return 0, 0
    end
    
    local list = chest.list()
    local total = 0
    local slots = 0
    
    for _, item in pairs(list) do
        if item then
            total = total + item.count
            slots = slots + 1
        end
    end
    
    return total, slots
end

-- Clear slots 1-15 back into the chest on failure or before sucking (left chest)
local function empty_inventory_to_chest()
    turtle.turnLeft()
    for i = 1, 15 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            turtle.drop()
        end
    end
    turtle.select(1)
    turtle.turnRight()
end

-- Collect resources from chest (left chest)
local function collect_resources()
    empty_inventory_to_chest()
    
    turtle.turnLeft()
    local total = 0
    local slot = 1
    
    while total < 55 do
        turtle.select(slot)
        if turtle.suck() then
            -- Count total items sucked into slots 1-15
            total = 0
            for i = 1, 15 do
                total = total + turtle.getItemCount(i)
            end
            slot = slot + 1
            if slot > 15 then
                slot = 1
            end
        else
            sleep(0.5)
        end
    end
    turtle.select(1)
    turtle.turnRight()
end

-- Sort turtle inventory into target slots (1-7)
local function sort_inventory()
    for t = 1, 7 do
        local target_name = target_names[t]
        local found_slot = nil
        
        -- Search for slot containing target item
        for s = 1, 16 do
            local detail = turtle.getItemDetail(s)
            if detail and detail.name == target_name then
                found_slot = s
                break
            end
        end
        
        if found_slot then
            if found_slot ~= t then
                -- If target slot is occupied, temporarily move to empty slot (8-15)
                if turtle.getItemCount(t) > 0 then
                    local moved = false
                    for temp = 8, 15 do
                        if turtle.getItemCount(temp) == 0 then
                            turtle.select(t)
                            turtle.transferTo(temp)
                            moved = true
                            break
                        end
                    end
                    if not moved then
                        error("Sort error: no free temp slots!")
                    end
                end
                -- Move found stack to target slot
                turtle.select(found_slot)
                turtle.transferTo(t)
            end
        else
            error("Missing required resource: " .. target_name)
        end
    end
    turtle.select(1)
end

-- Matrix block placement algorithm
local function perform_craft()
    -- Move 2 steps forward to the crafter grid
    safe_forward()
    safe_forward()
    
    -- Zigzag columns (x from 1 to 9)
    for x = 1, 9 do
        if x % 2 == 1 then
            -- Odd column: move bottom-to-top (y from 9 to 1)
            for y = 9, 1, -1 do
                local slot = patrick_star[y][x]
                if slot and slot > 0 then
                    turtle.select(slot)
                    turtle.drop(1)
                end
                if y > 1 then
                    safe_up()
                end
            end
        else
            -- Even column: move top-to-bottom (y from 1 to 9)
            for y = 1, 9 do
                local slot = patrick_star[y][x]
                if slot and slot > 0 then
                    turtle.select(slot)
                    turtle.drop(1)
                end
                if y < 9 then
                    safe_down()
                end
            end
        end
        
        -- Switch to next column if not done (shift right)
        if x < 9 then
            turtle.turnRight()
            safe_forward()
            turtle.turnLeft()
        end
    end
    
    -- Return to base:
    -- Turtle is at (y=1, x=9), facing crafter wall (North).
    
    -- 1. Back up 2 blocks
    safe_back()
    safe_back()
    
    -- 2. Descend to y=9 level (8 blocks down)
    for i = 1, 8 do
        safe_down()
    end
    
    -- 3. Move left to column x=1 (8 blocks left)
    turtle.turnLeft()
    for i = 1, 8 do
        safe_forward()
    end
    turtle.turnRight()
    
    -- Turtle returned to start position, right next to supply chest
end

-- Main program loop
while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("=== Patrick Star Auto-Crafter ===")
    
    -- Check fuel (~100 moves needed per craft)
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then
        print("Fuel: Unlimited")
    else
        print("Fuel: " .. fuel .. " / 150+ recommended")
        if fuel < 150 then
            print("Low fuel! Trying to refuel from slot 16...")
            turtle.select(16)
            if turtle.refuel(1) then
                print("Refuel success! New level: " .. turtle.getFuelLevel())
            else
                print("WARNING: Put fuel in slot 16!")
            end
        end
    end
    
    print("Status: Waiting for 55 blocks in chest...")
    
    -- Wait for 55 blocks in 7 stacks in left chest
    local ready = false
    while not ready do
        local total, slots = get_chest_item_count()
        if total == 55 and slots == 7 then
            ready = true
        else
            term.setCursorPos(1, 6)
            term.clearLine()
            write("Chest: " .. total .. "/55 blocks (" .. slots .. "/7 slots)")
            sleep(1)
        end
    end
    
    print("\n[!] Resources found! Collecting...")
    collect_resources()
    
    print("[-] Sorting inventory...")
    local ok, err = pcall(sort_inventory)
    if not ok then
        print("[Error] Sorting failed: " .. tostring(err))
        print("Returning resources to chest...")
        empty_inventory_to_chest()
        sleep(5)
    else
        print("[+] Starting block placement...")
        perform_craft()
        print("[Success] Craft finished! Waiting for next order...")
        sleep(5)
    end
end
