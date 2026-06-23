-- Автоматизация крафта Звезды Патрика для ComputerCraft (ATM10)
-- Скрипт управляет Черепашкой, которая раскладывает бетон в Механические сборщики.

-- Матрица сборки 9x9 (1 - розовый бетон, 2 - пурпурный, 3 - роз. сухой, 4 - пурп. сухой, 5 - зеленый, 6 - зел. сухой, 7 - лаймовый)
local patrick_star = {
    {0, 0, 0, 0, 1, 0, 0, 0, 0}, -- y = 1 (Верхний ряд)
    {0, 0, 0, 1, 3, 2, 0, 0, 0}, -- y = 2
    {1, 1, 1, 4, 3, 2, 1, 1, 1}, -- y = 3
    {2, 3, 4, 3, 4, 4, 4, 3, 2}, -- y = 4
    {0, 2, 2, 4, 4, 4, 1, 2, 0}, -- y = 5
    {0, 0, 6, 5, 5, 5, 6, 0, 0}, -- y = 6
    {0, 6, 7, 6, 5, 6, 7, 6, 0}, -- y = 7
    {1, 6, 5, 5, 0, 5, 5, 6, 1}, -- y = 8
    {2, 2, 2, 0, 0, 0, 2, 2, 2}  -- y = 9 (Нижний ряд)
}

-- Имена предметов в ATM10 для автоматической сортировки
local target_names = {
    [1] = "minecraft:pink_concrete",          -- Слот 1: 11 шт.
    [2] = "minecraft:magenta_concrete",       -- Слот 2: 13 шт.
    [3] = "minecraft:pink_concrete_powder",   -- Слот 3: 5 шт.
    [4] = "minecraft:magenta_concrete_powder",-- Слот 4: 8 шт.
    [5] = "minecraft:green_concrete",         -- Слот 5: 8 шт.
    [6] = "minecraft:green_concrete_powder",  -- Слот 6: 8 шт.
    [7] = "minecraft:lime_concrete"           -- Слот 7: 2 шт.
}

-- Вспомогательные функции безопасного движения с обработкой препятствий
local function safe_forward()
    while not turtle.forward() do
        print("Движение заблокировано! Ожидание...")
        sleep(1)
    end
end

local function safe_back()
    while not turtle.back() do
        print("Движение назад заблокировано! Ожидание...")
        sleep(1)
    end
end

local function safe_up()
    while not turtle.up() do
        print("Подъем заблокирован! Ожидание...")
        sleep(1)
    end
end

local function safe_down()
    while not turtle.down() do
        print("Спуск заблокирован! Ожидание...")
        sleep(1)
    end
end

-- Функция проверки содержимого сундука под черепашкой
local function get_chest_item_count()
    local chest = peripheral.wrap("bottom")
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

-- Очистка слотов 1-15 обратно в сундук в случае сбоя или перед забором
local function empty_inventory_to_chest()
    for i = 1, 15 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            turtle.dropDown()
        end
    end
    turtle.select(1)
end

-- Забор ресурсов из сундука
local function collect_resources()
    empty_inventory_to_chest()
    
    local total = 0
    local slot = 1
    
    while total < 55 do
        turtle.select(slot)
        if turtle.suckDown() then
            -- Пересчитываем сколько всего забрали в слоты 1-15
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
end

-- Сортировка инвентаря черепашки по целевым слотам (1-7)
local function sort_inventory()
    for t = 1, 7 do
        local target_name = target_names[t]
        local found_slot = nil
        
        -- Ищем, в каком слоте лежит нужный предмет
        for s = 1, 16 do
            local detail = turtle.getItemDetail(s)
            if detail and detail.name == target_name then
                found_slot = s
                break
            end
        end
        
        if found_slot then
            if found_slot ~= t then
                -- Если целевой слот занят, временно перемещаем его содержимое в свободный слот (8-15)
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
                        error("Ошибка сортировки: нет свободных временных слотов!")
                    end
                end
                -- Переносим найденный стек в правильный целевой слот
                turtle.select(found_slot)
                turtle.transferTo(t)
            end
        else
            error("Отсутствует необходимый ресурс: " .. target_name)
        end
    end
    turtle.select(1)
end

-- Алгоритм выкладки блоков по матрице
local function perform_craft()
    -- Делаем два шага вперед к плоскости сборщиков
    safe_forward()
    safe_forward()
    
    -- Идем зигзагом по колонкам (x от 1 до 9)
    for x = 1, 9 do
        if x % 2 == 1 then
            -- Нечетная колонка: двигаемся снизу вверх (y от 9 до 1)
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
            -- Четная колонка: двигаемся сверху вниз (y от 1 до 9)
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
        
        -- Если не дошли до конца, переходим на следующую колонку (сдвиг вправо)
        if x < 9 then
            turtle.turnRight()
            safe_forward()
            turtle.turnLeft()
        end
    end
    
    -- Возвращение на базу:
    -- Сейчас черепашка на (y=1, x=9), смотрит на стену (Север).
    
    -- 1. Сдаем назад на 2 блока
    safe_back()
    safe_back()
    
    -- 2. Спускаемся вниз на уровень y=9 (8 блоков вниз)
    for i = 1, 8 do
        safe_down()
    end
    
    -- 3. Летим влево к колонке x=1 (8 блоков влево)
    turtle.turnLeft()
    for i = 1, 8 do
        safe_forward()
    end
    turtle.turnRight()
    
    -- Черепашка вернулась в начальную точку, ровно над сундуком снабжения
end

-- Главный цикл программы
while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("=== Автокрафт Звезды Патрика ===")
    
    -- Проверка топлива (требуется ~100 единиц движения на один крафт)
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then
        print("Топливо: Безлимитное")
    else
        print("Топливо: " .. fuel .. " / 150+ рекомендовано")
        if fuel < 150 then
            print("Низкий уровень топлива! Пробую заправить из слота 16...")
            turtle.select(16)
            if turtle.refuel(1) then
                print("Успешная дозаправка! Новое значение: " .. turtle.getFuelLevel())
            else
                print("ВНИМАНИЕ: Положите уголь/ведро лавы в слот 16!")
            end
        end
    end
    
    print("Статус: Ожидание 55 блоков в сундуке...")
    
    -- Ждем, пока в сундуке под черепашкой не наберется ровно 55 блоков в 7 стаках
    local ready = false
    while not ready do
        local total, slots = get_chest_item_count()
        if total == 55 and slots == 7 then
            ready = true
        else
            term.setCursorPos(1, 6)
            term.clearLine()
            write("Сундук: " .. total .. "/55 блоков (" .. slots .. "/7 слотов)")
            sleep(1)
        end
    end
    
    print("\n[!] Ресурсы обнаружены! Забираю...")
    collect_resources()
    
    print("[-] Сортировка инвентаря...")
    local ok, err = pcall(sort_inventory)
    if not ok then
        print("[Ошибка] Сортировка не удалась: " .. tostring(err))
        print("Возвращаю ресурсы в сундук...")
        empty_inventory_to_chest()
        sleep(5)
    else
        print("[+] Запуск алгоритма выкладки...")
        perform_craft()
        print("[Успех] Крафт завершен! Ожидаю следующий заказ...")
        sleep(5)
    end
end
