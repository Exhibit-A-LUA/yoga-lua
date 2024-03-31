local asana = {}
local asanas = {}
local displayAsanas = {}

local currentFont = c_lggf()

local asanasWindowColour = {.6, .6, .9, 1}
local highlightColour = {.2, .2, 1, 1}

local asanasListX = 23
local asanasListY = 25
local asanaNameWidth = 238
local asanaNameHeight = 15

local fieldsStartPosition = 120
local dataPosition = 265

local startAsana = 1
local numDisplayedAsanas= 35
local currentLine = 1

local imageWidth = 200
local imageHeight = 200

local currentAsana = 1
local currentTextField = ''
local currentField = 1
local currentImageNum = 1
local currentImage = nil
local currentImageX = 0
local currentImageY = 600
local currentImageW = 0
local currentImageH = 0

local selectedFieldColour = {1,1,.6,1}
local fieldColour = {.6,1,1,1}
local fieldSeparation = 40


function addAsana(asana)
    asanas[#asanas + 1] = asana
    -- use this to next prev over
    -- every time user makes display selections re-write this array
    displayAsanas[#displayAsanas + 1]=#asanas 
end

function drawImage(nameTbl)
    if nameTbl then 
        currentImage = c_lgni('gfx/'..nameTbl[currentImageNum])
        c_lgsc(1,1,1,1)
        local scale = math.min(imageWidth/currentImage:getWidth(),imageHeight/currentImage:getHeight())
        currentImageX = 142 - currentImage:getWidth()*scale/2
        currentImageW = currentImage:getWidth()*scale
        currentImageH = currentImage:getHeight()*scale
        c_lgd(currentImage, currentImageX, currentImageY, 0, scale, scale)
        c_lgsc(0,0,0,1)
        c_lgpf('Image '..currentImageNum..' of '..#nameTbl,asanasListX, 810, asanaNameWidth, 'center')
    else
        c_lgpf('No Image ',asanasListX, 810, asanaNameWidth, 'center')
    end
end

function drawClassification()
    local current = asanas[currentAsana]
    local classWidth = 150
    local classGap = 12
    local startBoxesX = dataPosition + 140
    c_lgpf('Level',startBoxesX, 60,classWidth,'center')
    c_lgpf('Type',startBoxesX + 1 * (classWidth + classGap), 60,classWidth,'center')
    c_lgpf('Back',startBoxesX + 2 * (classWidth + classGap), 60,classWidth,'center')
    c_lgpf('Class',startBoxesX + 3 * (classWidth + classGap), 60,classWidth,'center')
    c_lgpf('Breath',startBoxesX + 4 * (classWidth + classGap), 60,classWidth,'center')
    c_lgpf('Good For',startBoxesX + 5 * (classWidth + classGap), 60,classWidth,'center')
    c_lgsc(.6,1,.6,1)
    c_lgr('fill',startBoxesX, 80, classWidth, 30)
    c_lgr('fill',startBoxesX + 1 * (classWidth + classGap), 80, classWidth, 30)
    c_lgr('fill',startBoxesX + 2 * (classWidth + classGap), 80, classWidth, 30)
    c_lgr('fill',startBoxesX + 3 * (classWidth + classGap), 80, classWidth, 30)
    c_lgr('fill',startBoxesX + 4 * (classWidth + classGap), 80, classWidth, 30)
    c_lgr('fill',startBoxesX + 5 * (classWidth + classGap), 80, classWidth, 30)
    c_lgsc(0,0,0,1)
    c_lgpf(current.level,startBoxesX, 82,classWidth,'center')
    c_lgpf(current.type,startBoxesX + 1 * (classWidth + classGap), 82,classWidth,'center')
    c_lgpf(current.back,startBoxesX + 2 * (classWidth + classGap), 82,classWidth,'center')
    c_lgpf(current.class,startBoxesX + 3 * (classWidth + classGap), 82,classWidth,'center')
    c_lgpf(current.breath,startBoxesX + 4 * (classWidth + classGap), 82,classWidth,'center')
    c_lgpf(current.goodFor,startBoxesX + 4 * (classWidth + classGap), 82,classWidth,'center')
end

function drawTextVert()
    local current = asanas[currentAsana]
    local classWidth = 120
    local classGap = 10
    if currentField == 1 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10, fieldsStartPosition, classWidth, 20)
    if currentField == 2 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 1 * fieldSeparation, classWidth, 20)
    if currentField == 3 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 2 * fieldSeparation, classWidth, 20)
    if currentField == 4 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 3 * fieldSeparation, classWidth, 20)
    if currentField == 5 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 4 * fieldSeparation, classWidth, 20)
    if currentField == 6 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 5 * fieldSeparation, classWidth, 20)
    if currentField == 7 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 6 * fieldSeparation, classWidth, 20)
    if currentField == 8 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 7 * fieldSeparation, classWidth, 20)
    if currentField == 9 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 8 * fieldSeparation, classWidth, 20)
    if currentField == 10 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 9 * fieldSeparation, classWidth, 20)
    if currentField == 11 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 10 * fieldSeparation, classWidth, 20)
    if currentField == 12 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 11 * fieldSeparation, classWidth, 20)
    if currentField == 13 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 12 * fieldSeparation, classWidth, 20)
    if currentField == 14 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 13 * fieldSeparation, classWidth, 20)
    if currentField == 15 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 14 * fieldSeparation, classWidth, 20)
    if currentField == 16 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 15 * fieldSeparation, classWidth, 20)
    if currentField == 17 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 16 * fieldSeparation, classWidth, 20)
    if currentField == 18 then c_lgsc(selectedFieldColour) else c_lgsc(fieldColour) end
    c_lgr('fill',dataPosition + 10 , fieldsStartPosition + 17 * fieldSeparation, classWidth, 20)

    c_lgsc(0,0,0,1)

    c_lgpf('Description',dataPosition + 10, fieldsStartPosition + 2 + 0 * fieldSeparation,classWidth,'center')
    c_lgpf('Benefits',dataPosition + 10, fieldsStartPosition + 2 + 1 * fieldSeparation,classWidth,'center')
    c_lgpf('Theraputic',dataPosition + 10, fieldsStartPosition + 2 + 2 * fieldSeparation,classWidth,'center')
    c_lgpf('Steps',dataPosition + 10, fieldsStartPosition + 2 + 3 * fieldSeparation,classWidth,'center')
    c_lgpf('Steps Pics',dataPosition + 10, fieldsStartPosition + 2 + 4 * fieldSeparation,classWidth,'center')
    c_lgpf('Follow up',dataPosition + 10, fieldsStartPosition + 2 + 5 * fieldSeparation,classWidth,'center')
    c_lgpf('Contraindications',dataPosition + 10, fieldsStartPosition + 2 + 6 * fieldSeparation,classWidth,'center')
    c_lgpf('Modifications',dataPosition + 10, fieldsStartPosition + 2 + 7 * fieldSeparation,classWidth,'center')
    c_lgpf('Deepen the Pose',dataPosition + 10, fieldsStartPosition + 2 + 8 * fieldSeparation,classWidth,'center')
    c_lgpf('Tips',dataPosition + 10, fieldsStartPosition + 2 + 9 * fieldSeparation,classWidth,'center')
    c_lgpf('Partnering',dataPosition + 10, fieldsStartPosition + 2 + 10 * fieldSeparation,classWidth,'center')
    c_lgpf('Variations',dataPosition + 10, fieldsStartPosition + 2 + 11 * fieldSeparation,classWidth,'center')
    c_lgpf('Prep Asanas',dataPosition + 10, fieldsStartPosition + 2 + 12 * fieldSeparation,classWidth,'center')
    c_lgpf('Counter Asanas',dataPosition + 10, fieldsStartPosition + 2 + 13 * fieldSeparation,classWidth,'center')
    c_lgpf('Follow Up Asanas',dataPosition + 10, fieldsStartPosition + 2 + 14 * fieldSeparation,classWidth,'center')
    c_lgpf('Mantra',dataPosition + 10, fieldsStartPosition + 2 + 15 * fieldSeparation,classWidth,'center')
    c_lgpf('Mudra',dataPosition + 10, fieldsStartPosition + 2 + 16 * fieldSeparation,classWidth,'center')
    c_lgpf('Vinyasa',dataPosition + 10, fieldsStartPosition + 2 + 17 * fieldSeparation,classWidth,'center')
end


function drawSelectedAsana()
    local current = asanas[currentAsana]
    drawImage(current.img)
    collectgarbage("collect")
    c_lgsc(.9,.9,.9,1)
    c_lgr('fill',dataPosition + 140, 30, c_lgw()-dataPosition-140-35,asanaNameHeight)
    c_lgsc(0,0,0,1)
    c_lgpf( current.english, 
            dataPosition+140, 30, 
            c_lgw()-dataPosition-140-currentFont:getWidth(current.english)/2, 
            'center')
    drawClassification()
    drawTextVert()
    c_lgp(currentTextField,dataPosition + 145,122)
end

function displayAsana(idx) 
    return true -- asanas[idx].level > 0
end


-- Do this!!!!!
-- what about copying all chosen assana indexes into another
-- table and using that table to display
-- that way just have to keep that table updated with
-- used choices and simply display consecutive record 
-- rather than have to manage jumping over un-selected records
function drawAsanas()
    local displayPos = 1
--    local i = 0
    for i = 1, math.min(#asanas,numDisplayedAsanas) do -- may need a while loop
--    while i < #asanas and displayPos < numDisplayedAsanas do
--        i = i + 1
        local thisAsana = i + startAsana - 1 -- thisAsana is the index of the one to display
        if displayAsana(thisAsana) then
            displayPos = displayPos + 1 -- the line to diaplay it on
            c_lgsc(.8,.8,.8,1)
            c_lgr('fill',asanasListX, asanasListY + (displayPos - 1) * asanaNameHeight, asanaNameWidth,asanaNameHeight)
            if thisAsana == currentAsana then
                c_lgsc(.9,.9,.9,1)
                c_lgr('fill',asanasListX, asanasListY + (displayPos - 1) * asanaNameHeight, asanaNameWidth,asanaNameHeight)
                c_lgsc(highlightColour)
            else
                c_lgsc(0,0,0,1)
            end
            if asanas[thisAsana].sanskrit:len() > 30 then
                asanas[thisAsana].sanskrit = asanas[thisAsana].sanskrit:sub(1,30)..'..'
            end
            c_lgpf(asanas[thisAsana].sanskrit, asanasListX, asanasListY + (displayPos - 1) * asanaNameHeight, asanaNameWidth, 'center')
        end
    end
    drawSelectedAsana()
end

function asana.showAsanasWindow(colour)
--    local current = asanas[currentAsana]
    c_lgsc(asanasWindowColour)
    c_lgr('fill',20,20,c_lgw() - 40, c_lgh() - 40)
    c_lgsc(1,.8,.9,.8)

    c_lgr('fill',dataPosition + 140,120,c_lgw() - 40 - dataPosition - 135, c_lgh() - 40 - 120)
    c_lgsc(colour)
    c_lgl(dataPosition,24,dataPosition,825)
    c_lgl(22,590,dataPosition,590)
    c_lgp('Click here to retrict view',60,572)
    c_lgl(22,570,dataPosition,570)
    drawAsanas()
end

function asana.load()
    require('asanaData') -- load the asanaData data file
    currentTextField = asanas[1].description
end

function love.wheelmoved(x, y)
    if y < 0 then asana.doKey('down')
    elseif y > 0 then asana.doKey('up')
    end
end

function asana.doKey(key)
--print('startAsana is '..startAsana)            
--print('currentAsana is '..currentAsana)  -- seems to be tha same as current line
--print('currentLine is '..currentLine)            
    if key == 'up' and currentAsana > 1 then
        currentImageNum = 1
        local saveAsana = currentAsana
        currentAsana = math.max(1,currentAsana - 1)
        while currentAsana > 1 and not displayAsana(currentAsana) do
            currentAsana = currentAsana - 1
        end
        if not displayAsana(currentAsana) then
            currentAsana = saveAsana
        else
            currentLine = math.max(1,currentLine - 1)
        end
        if currentLine < startAsana + numDisplayedAsanas - 1 then
            startAsana = math.max(1,startAsana - 1)
        end
        currentTextField = asanas[currentAsana].description
        currentField = 1
    elseif key == 'down' and currentAsana < #asanas then
        currentImageNum = 1
        local saveAsana = currentAsana
        currentAsana = math.min(#asanas,currentAsana + 1)
        while currentAsana < #asanas and not displayAsana(currentAsana) do
            currentAsana = currentAsana + 1
        end
        if not displayAsana(currentAsana) then -- got to end and not good 1
            currentAsana = saveAsana
        else
            currentLine = currentLine + 1
        end
        if currentLine > startAsana + numDisplayedAsanas - 1 then
            startAsana = startAsana + 1
--print('incement startAsana to '..startAsana)            
        end
        currentTextField = asanas[currentAsana].description
        currentField = 1
    end
end

function showTable(tbl)
    local line = ''
    for i = 1,#tbl do
        line = line..tbl[i]..'\n'
    end
    return line
end

function asana.doMouseClicks(mx, my, button)
    local classWidth = 120
    local classGap = 10
    local current = asanas[currentAsana]

    if button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 0 * fieldSeparation, classWidth, 20) then
        currentField = 1
        if current.description and current.description ~= '' then currentTextField = current.description else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 1 * fieldSeparation, classWidth, 20) then
        currentField = 2
        if current.benefits and current.benefits ~= '' then currentTextField = current.benefits else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 2 * fieldSeparation, classWidth, 20) then
        currentField = 3
        if current.theraputic and current.theraputic ~= '' then currentTextField = current.theraputic else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 3 * fieldSeparation, classWidth, 20) then
        currentField = 4
        if current.steps and current.steps ~= '' then currentTextField = current.steps else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 4 * fieldSeparation, classWidth, 20) then
        currentField = 5
        if current.stepsPics and #current.stepsPics > 0 then currentTextField = 'Show Steps Pics' else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 5 * fieldSeparation, classWidth, 20) then
        currentField = 6
        if current.followInst and current.followInst ~= '' then currentTextField = current.followInst else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 6 * fieldSeparation, classWidth, 20) then
        currentField = 7
        if current.contra and current.contra ~= '' then currentTextField = current.contra else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 7 * fieldSeparation, classWidth, 20) then
        currentField = 8
        if current.mods and current.mods ~= '' then currentTextField = current.mods else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 8 * fieldSeparation, classWidth, 20) then
        currentField = 9
        if current.deepen and current.deepen ~= '' then currentTextField = current.deepen else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 9 * fieldSeparation, classWidth, 20) then
        currentField = 10
        if current.tips and current.tips ~= '' then currentTextField = current.tips else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 10 * fieldSeparation, classWidth, 20) then
        currentField = 11
        if current.pertnering and current.pertnering ~= '' then currentTextField = current.pertnering else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 11 * fieldSeparation, classWidth, 20) then
        currentField = 12
        if current.variations and current.variations ~= '' then currentTextField = current.variations else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 12 * fieldSeparation, classWidth, 20) then
        currentField = 13
        if current.prep and #current.prep > 0 then currentTextField = showTable(current.prep) else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 13 * fieldSeparation, classWidth, 20) then
        currentField = 14
        if current.counter and #current.counter > 0 then currentTextField = showTable(current.counter) else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 14 * fieldSeparation, classWidth, 20) then
        currentField = 15
        if current.followUp and #current.followUp > 0 then currentTextField = showTable(current.followUp) else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 15 * fieldSeparation, classWidth, 20) then
        currentField = 16
        if current.mantra and current.mantra ~= '' then currentTextField = current.mantra else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 16 * fieldSeparation, classWidth, 20) then
        currentField = 17
        if current.mudra and current.mudra ~= '' then currentTextField = current.mudra else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 17 * fieldSeparation, classWidth, 20) then
        currentField = 18
        if current.vinyasa and #current.vinyasa > 0 then currentTextField = showTable(current.vinyasa) else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, currentImageX, currentImageY, currentImageW, currentImageH) then
        if #current.img > currentImageNum then
            currentImageNum = currentImageNum + 1
        else
            currentImageNum = 1
        end
    end
end

function asana.update(dt)
--    print('asana update')
--    collectgarbage("collect")
end

function asana.draw()
end

return asana