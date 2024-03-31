--[[

Use this to try major changes
just change line

Asana = require("asana")

in main .lua to

Asana = require("asanaNew") 

Major Change 1 = rewrite to use displayAsanas to hold
indexes to asana, where each index refers to a valid
selection from asanas, dependin on user selected values

]]

local asana = {}            -- Module

local asanas = {}           -- to store all the asanas
local displayAsanas = {}    -- to store subset of asanas to display

local currentFont = c_lggf()

-- asanaDetailsColour = {1,.9,1,.9} --{1,.8,.9,.8}
-- asanaListColour = {.7,.9,.9,1} --{.5,.7,.7,1}
-- highlightTextColour = {1,0,0,1} --{.2, .2, 1, 1}
-- asanasWindowColour = {1,1,1,1} --{.6, .6, .9, 1}
-- highlightBackColour = {1,1,1,1} --{.9,.9,.9,1}
-- englishNameColour = {1,1,.6,1} --{.9,.9,.9, 1}
-- linkedAsanaBoxColour = {1,1,1,1}
-- classificationColour = {.6,1,.6,1}
-- classificationTitleColour = {.9,.9,.9,1}
-- searchClassificationTitleColour = {1,.6,.6,1}
-- searchClassificationChoicesColour = {1,.92,.6,1}

local imageBackgroundColour = {1,1,1,1}

local searching = false

local asanasListX = 23
local asanasListY = 10
local asanaNameWidth = 238
local asanaNameHeight = 15
local textScrollLines = 1

local fieldsStartPosition = 120
local dataPosition = 265
local startBoxesX = dataPosition + 140

local startAsana = 1
local numDisplayedAsanas= 35
local selectionString = ''
local selectedLevel = 1
local selectedType = 1
local selectedBack = 1
local selectedClass = 1
local selectedBreath = 1
local selectedGoodFor = 1

-- classification x position
local classWidth = 150
local classGap = 12

local imageWidth = 200
local imageHeight = 200

local stepsPicsWidth = 200
local stepsPicsHeight = 200

local currentAsanaNum = 1
local currentAsana = nil
local currentStepsPics = nil
local currentTextField = ''
local currentField = 0
local currentImageNum = 1
local currentImage = nil
local currentImageX = 0
local currentImageY = 600
local currentImageW = 0
local currentImageH = 0

local selectedFieldColour = {1,1,.6,1}
local restrictionColour = {1,1,.6,1}
local fieldColour = {.6,1,1,1}
local fieldNoDataColour = {.8,.8,.8,1}
local fieldSeparation = 35
local fieldHasData = {}
local maxTextFieldLines = 33
local startLine = 1

-- search criteria
local searchLevel ={0,1,2,3,4,5}
local searchType = {}
local searchBack = {}
local searchClass = {}
local searchBreath = {}
local searchGoodFor = {}

local delayTime = 0.1
local timer = 0

local searchString = ''

function addSLevel(lvl)
    for i = 1,#searchLevel do if searchLevel[i] == lvl then return end end
    searchLevel[#searchLevel + 1] = lvl
end

function addSType(typ)
    for i = 1,#searchType do if searchType[i] == typ then return end end
    searchType[#searchType + 1] = typ
end

function addSBack(bck)
    for i = 1,#searchBack do if searchBack[i] == bck then return end end
    searchBack[#searchBack + 1] = bck
end

function addSClass(cls)
    for i = 1,#searchClass do if searchClass[i] == cls then return end end
    searchClass[#searchClass + 1] = cls
end

function addSBreath(brth)
    for i = 1,#searchBreath do if searchBreath[i] == brth then return end end
    searchBreath[#searchBreath + 1] = brth
end

function addSGoodFor(gf)
    for i = 1,#searchGoodFor do if searchGoodFor[i] == gf then return end end
    searchGoodFor[#searchGoodFor + 1] = gf
end

function addAsana(asana)
    asanas[#asanas + 1] = asana
    addSLevel(asana.level)
    addSType(asana.type)
    if asana.back ~= '' then addSBack(asana.back) end
    for i = 1, #asana.class do if asana.class[i] ~= '' then addSClass(asana.class[i]) end end
    if asana.breath ~= '' then addSBreath(asana.breath) end
    for i = 1, #asana.goodFor do if asana.goodFor[i] ~= '' then addSGoodFor(asana.goodFor[i]) end end
end

function replaceSlashes(name)
    return string.gsub(name, "/", " -or- ")
end

-- Not using this
-- function splitIntoLines(text)
--     for line in string.gmatch(text, "(.-)[\n\r]" ) do
--         print('line '..line)
--     end
-- end

function newSplit(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function split(text, delim)
    -- returns an array of fields based on text and delimiter (one character only)
    local result = {}
    local magic = "().%+-*?[]^$"

    if delim == nil then
        delim = "%s"
    elseif string.find(delim, magic, 1, true) then
        -- escape magic
        delim = "%"..delim
    end

    local pattern = "[^"..delim.."]+"
    for w in string.gmatch(text, pattern) do
        table.insert(result, w)
    end
    return result
end

function drawImage(nameTbl, imgNum, w, h, x, y)
    local currentImage = c_lgni('gfx/'..nameTbl[imgNum])
    c_lgsc(imageBackgroundColour)
    local scale = math.min(w/currentImage:getWidth(),h/currentImage:getHeight())
    local currentImageX = x - currentImage:getWidth()*scale/2
    local currentImageW = currentImage:getWidth()*scale
    local currentImageH = currentImage:getHeight()*scale
    c_lgd(currentImage, currentImageX, y, 0, scale, scale)
    c_lgsc(textColour)
    collectgarbage("collect")
end

-- rewrite to use mod to do it in one line
function displayStepsPics(pics)
    for i = 1, #pics do
        if i < 5 then
            drawImage(pics,i,150, 150, 500 + (i - 1) * 200, 125)
        elseif i < 9 then
            drawImage(pics,i,150, 150, 500 + (i - 5) * 200, 300)
        elseif i < 13 then
            drawImage(pics,i,150, 150, 500 + (i - 9) * 200, 475)
        elseif i < 17 then
            drawImage(pics,i,150, 150, 500 + (i - 13) * 200, 650)
        end
    end
end

function getAsana(name)
    for i = 1, #asanas do
        if asanas[i].sanskrit == name then 
            return(asanas[i]) 
        end
    end
    return(nil)
end

function displayLinkedAsanas(asanaTbl)
    local boxHeight = 108 --110
    local fieldPosY = 127
    local fieldGapY = 20
    local columnSize = 6
    local picWidth = 90
    local picHeight = 90
    if #asanaTbl > 12 then
        boxHeight = 80
        fieldPosY = 125
        fieldGapY = 16
        columnSize = 8
        picWidth = 70
        picHeight = 70
    end
    local gap = 5
    for i = 1, #asanaTbl do
        local linkedAsana = getAsana(asanaTbl[i])
        c_lgsc(linkedAsanaBoxColour)
        local yAdj = ((i % (columnSize + 1)) - 1) * (boxHeight + gap)
        if i > columnSize then yAdj = (i % (columnSize + 1)) * (boxHeight + gap) end
        c_lgr('fill',413 + 477 * math.floor(i / (columnSize + 1)),125 + yAdj, 467, boxHeight)
        c_lgsc(textColour)
        if linkedAsana then
            c_lgp(replaceSlashes(linkedAsana.sanskrit),415 + 477 * math.floor(i / (columnSize + 1)),fieldPosY + yAdj)
            c_lgp(replaceSlashes(linkedAsana.english),415 + 477 * math.floor(i / (columnSize + 1)),fieldPosY + fieldGapY + yAdj)
            c_lgp('Level '..linkedAsana.level,415 + 477 * math.floor(i / (columnSize + 1)),fieldPosY + fieldGapY * 3 + yAdj)
            c_lgp('Type '..linkedAsana.type,415 + 477 * math.floor(i / (columnSize + 1)),fieldPosY + fieldGapY * 4 + yAdj)
            if linkedAsana.img then drawImage(linkedAsana.img,1,picWidth,picHeight,800 + 477 * math.floor(i / (columnSize + 1)),fieldPosY + 10 + yAdj) end
        else
            c_lgp(replaceSlashes(asanaTbl[i])..' Not in database',415 + 477 * math.floor(i / (columnSize + 1)),fieldPosY + yAdj)
        end
    end
end

function drawItsClassification()
    local titleY = 65
    local dataY = 80
    if searching then c_lgsc(searchClassificationTitleColour) else c_lgsc(classificationTitleColour) end
    for i = 0, 5 do
        c_lgr('fill',startBoxesX + i * (classWidth + classGap), titleY, classWidth, 15)
    end

    c_lgsc(textColour)
    c_lgpf('Level',startBoxesX + 0 * (classWidth + classGap), titleY,classWidth,'center')
    c_lgpf('Type',startBoxesX + 1 * (classWidth + classGap), titleY,classWidth,'center')
    c_lgpf('Back',startBoxesX + 2 * (classWidth + classGap), titleY,classWidth,'center')
    c_lgpf('Class',startBoxesX + 3 * (classWidth + classGap), titleY,classWidth,'center')
    c_lgpf('Breath',startBoxesX + 4 * (classWidth + classGap), titleY,classWidth,'center')
    c_lgpf('Good For',startBoxesX + 5 * (classWidth + classGap), titleY,classWidth,'center')

    if searching then c_lgsc(searchClassificationChoicesColour) else c_lgsc(classificationColour) end
    for i = 0, 5 do
        c_lgr('fill',startBoxesX + i * (classWidth + classGap), dataY, classWidth, 30)
    end
    c_lgsc(textColour)
    if searching then
        c_lgpf(searchLevel[selectedLevel],startBoxesX, dataY+2,classWidth,'center')
        c_lgpf(searchType[selectedType],startBoxesX + 1 * (classWidth + classGap), dataY+2,classWidth,'center')
        c_lgpf(searchBack[selectedBack],startBoxesX + 2 * (classWidth + classGap), dataY+2,classWidth,'center')
        c_lgpf(searchClass[selectedClass],startBoxesX + 3 * (classWidth + classGap), dataY+2,classWidth,'center')
        c_lgpf(searchBreath[selectedBreath],startBoxesX + 4 * (classWidth + classGap), dataY+2,classWidth,'center')
        c_lgpf(searchGoodFor[selectedGoodFor],startBoxesX + 5 * (classWidth + classGap), dataY+2,classWidth,'center')
        for i = 1, 6 do
            c_lgr('line',startBoxesX + i * (classWidth + classGap) - 28, 95, 15, 15)
            c_lgp('>',startBoxesX + i * (classWidth + classGap) - 25, 95)
        end
    else
        c_lgpf(currentAsana.level,startBoxesX, dataY+2,classWidth,'center')
        c_lgpf(currentAsana.type,startBoxesX + 1 * (classWidth + classGap), dataY+2,classWidth,'center')
        c_lgpf(currentAsana.back,startBoxesX + 2 * (classWidth + classGap), dataY+2,classWidth,'center')
        if #currentAsana.class > 0 then
            c_lgpf(currentAsana.class[selectedClass],startBoxesX + 3 * (classWidth + classGap), dataY+2,classWidth,'center')
            if #currentAsana.class > 1 then
                c_lgr('line',startBoxesX + 4 * (classWidth + classGap) - 28, 95, 15, 15)
                c_lgp('>',startBoxesX + 4 * (classWidth + classGap) - 25, 95)
            end
        end
        c_lgpf(currentAsana.breath,startBoxesX + 4 * (classWidth + classGap), dataY+2,classWidth,'center')
        if #currentAsana.goodFor > 0 then
            c_lgpf(currentAsana.goodFor[selectedGoodFor],startBoxesX + 5 * (classWidth + classGap), dataY+2,classWidth,'center')
            if #currentAsana.goodFor > 1 then
                c_lgr('line',startBoxesX + 6 * (classWidth + classGap) - 28, 95, 15, 15)
                c_lgp('>',startBoxesX + 6 * (classWidth + classGap) - 25, 95)
            end
        end
    end
end

function drawItsTextFields()
    local classWidth = 120
    local classGap = 10
    for i = 1, 19 do
        if currentField == i or i == 19 then c_lgsc(selectedFieldColour) else 
            if fieldHasData[i] then 
                c_lgsc(fieldColour) 
            else 
                c_lgsc(fieldNoDataColour) 
            end
        end
        c_lgr('fill',dataPosition + 10, fieldsStartPosition + (i - 1) * fieldSeparation, classWidth, 20)
    end

    c_lgsc(textColour)

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
    c_lgpf('Large Image',dataPosition + 10, fieldsStartPosition + 2 + 18 * fieldSeparation,classWidth,'center')
end

function drawLargeImg()
    if currentField > 0 then return end
    local largeImageWidth = windowWidth - 40 - dataPosition - 135
    local largeImageHeight = windowHeight - 40 - 120
    -- local largeImageWidth = windowWidth - 40 - dataPosition - 135
    -- local largeImageHeight = 850 - 40 - 120
    if currentAsana.img and #currentAsana.img > 0 then
        drawImage(currentAsana.img, currentImageNum, largeImageWidth, largeImageHeight, 885,120)
    end
end

function drawItsImg()
    if currentAsana.img and #currentAsana.img > 0 then
        currentImage = c_lgni('gfx/'..currentAsana.img[currentImageNum])
        local scale = math.min(imageWidth/currentImage:getWidth(),imageHeight/currentImage:getHeight())
        currentImageX = 142 - currentImage:getWidth()*scale/2
        currentImageW = currentImage:getWidth()*scale
        currentImageH = currentImage:getHeight()*scale
    
        drawImage(currentAsana.img, currentImageNum, imageWidth, imageHeight, 142, 600)
        c_lgpf('Image '..currentImageNum..' of '..#currentAsana.img,asanasListX, 810, asanaNameWidth, 'center')
    else
        c_lgpf('No Image ',asanasListX, 810, asanaNameWidth, 'center')
    end
--    collectgarbage("collect")
end

function drawItsEnglishName()
    c_lgsc(englishNameColour)
    c_lgr('fill',dataPosition + 140, 30, windowWidth-dataPosition-140-35,asanaNameHeight)
    c_lgr('fill',dataPosition + 140, 810, windowWidth-dataPosition-140-35,asanaNameHeight)
    c_lgsc(textColour)
    c_lgpf( replaceSlashes(currentAsana.english), 
            dataPosition+140, 30, 
            windowWidth-dataPosition-140-currentFont:getWidth(replaceSlashes(currentAsana.english))/2, 
            'center')
    c_lgpf( replaceSlashes(currentAsana.sanskrit), 
    dataPosition+140, 810, 
    windowWidth-dataPosition-140-currentFont:getWidth(replaceSlashes(currentAsana.sanskrit))/2, 
    'center')
end

function drawItsSelectedTextField()
    if currentField > 0 and currentTextField and currentTextField ~= '' then 
--        c_lgp(currentTextField,dataPosition + 145,122) 
--        splitIntoLines(currentTextField) -- TEST

    -- newSplit works better than split but doesn't work with \n\r
        lines = newSplit(currentTextField,'\n') 
--print('number of lines = '..#lines)        
--        startLine = 31
        for i = startLine, startLine + maxTextFieldLines - 1 do
            local line = i - startLine + 1
            if lines[i] then c_lgp(lines[i],dataPosition + 145,122 + ((line-1) * 20)) end
        end
        if #lines > startLine + maxTextFieldLines then
            c_lgr('line',1115,125 + maxTextFieldLines * 20,240,20)
            c_lgp('MORE TEXT BELOW, press Right Arrow',1118,128 + maxTextFieldLines * 20)
        elseif startLine > 1 then
            c_lgp('AT END OF TEXT',1260,130 + maxTextFieldLines * 20)
        end
        if startLine > 1 then
            c_lgr('line',dataPosition + 145,125 + maxTextFieldLines * 20,235,20)
            c_lgp('MORE TEXT ABOVE, press Left Arrow',dataPosition + 150,128 + maxTextFieldLines * 20)
        elseif #lines > maxTextFieldLines then
            c_lgp('AT START OF TEXT',dataPosition + 145,130 + maxTextFieldLines * 20)
        end
    end
end

function drawItsStepsPics()
    if currentField == 5 and currentStepsPics and #currentStepsPics > 0 then
        displayStepsPics(currentStepsPics)
    end
end

function drawItsPrepAsanas()
    if currentField == 13 and currentAsana.prep and #currentAsana.prep > 0 then 
        displayLinkedAsanas(currentAsana.prep)
    end
end

function drawItsCounterAsanas()
    if currentField == 14 and currentAsana.counter and #currentAsana.counter > 0 then 
        displayLinkedAsanas(currentAsana.counter)
    end
end

function drawItsFollowUpAsanas()
    if currentField == 15 and currentAsana.followUp and #currentAsana.followUp > 0 then 
        displayLinkedAsanas(currentAsana.followUp)
    end
end

function drawItsVinyasaAsanas()
    if currentField == 18 and currentAsana.vinyasa and #currentAsana.vinyasa > 0 then 
        displayLinkedAsanas(currentAsana.vinyasa)
    end
end

function drawSelectedAsana()
    currentAsana = asanas[displayAsanas[currentAsanaNum]]
    setFieldHasData()
    drawItsImg()
    drawLargeImg()
    drawItsEnglishName()
    drawItsClassification()
    drawItsTextFields()
    drawItsSelectedTextField()
    drawItsStepsPics()
    drawItsPrepAsanas()
    drawItsCounterAsanas()
    drawItsFollowUpAsanas()
    drawItsVinyasaAsanas()
end

function drawAsanas()
    local displayPos = 1
    if #displayAsanas == 0 then return end
    for i = 1, math.min(#displayAsanas,numDisplayedAsanas) do -- may need a while loop
        local thisAsana = i + startAsana - 1 -- thisAsana is the index of the one to display
        displayPos = displayPos + 1 -- the line to display it on
        c_lgsc(asanaListColour)
        c_lgr('fill',asanasListX, asanasListY + (displayPos - 1) * asanaNameHeight, asanaNameWidth,asanaNameHeight)
        if thisAsana == currentAsanaNum then
            c_lgsc(highlightBackColour)
            c_lgr('fill',asanasListX, asanasListY + (displayPos - 1) * asanaNameHeight, asanaNameWidth,asanaNameHeight)
            c_lgsc(highlightTextColour)
        else
            c_lgsc(textColour)
        end
        if asanas[displayAsanas[thisAsana]].sanskrit:len() > 30 then
            local shortName = asanas[displayAsanas[thisAsana]].sanskrit:sub(1,30)..'..'
            c_lgpf(shortName, asanasListX, asanasListY + (displayPos - 1) * asanaNameHeight, asanaNameWidth, 'left')
        else
            c_lgpf(asanas[displayAsanas[thisAsana]].sanskrit, asanasListX, asanasListY + (displayPos - 1) * asanaNameHeight, asanaNameWidth, 'left')
        end
    end
    drawSelectedAsana()
end

function asana.writeAsanaJSON()
    local fileToWrite = io.open(compDir..'asanaData.json', 'w')
    fileToWrite:write('[\n')            
    for i = 1, #asanas do
        local line = '\t{\n'
        if asanas[i].sanskrit then line = line .. '\t\t"sanskrit":"'..asanas[i].sanskrit..'",\n' 
        else line = line .. '\t\t"sanskrit":"",\n' end
        if asanas[i].english then line = line .. '\t\t"english":"'..asanas[i].english..'",\n' 
        else line = line .. '\t\t"english":"",\n' end
        if asanas[i].level then line = line .. '\t\t"level":"'..asanas[i].level..'",\n' 
        else line = line .. '\t\t"level":"",\n' end
        if asanas[i].type then line = line .. '\t\t"type":"'..asanas[i].type..'",\n' 
        else line = line .. '\t\t"type":"",\n' end
        if asanas[i].back then line = line .. '\t\t"back":"'..asanas[i].back..'",\n' 
        else line = line .. '\t\t"back":"",\n' end
        if asanas[i].breath then line = line .. '\t\t"breath":"'..asanas[i].breath..'",\n' 
        else line = line .. '\t\t"breath":"",\n' end
        if asanas[i].web then line = line .. '\t\t"web":"'..asanas[i].web..'",\n' 
        else line = line .. '\t\t"web":"",\n' end

        if asanas[i].class then
            line = line .. '\t\t"class":['
            for j = 1, #asanas[i].class do
                line = line..'"'..asanas[i].class[j]..'"'
                if j < #asanas[i].class then line = line .. ',' end
            end
            line = line ..'],\n'
        else
            line = line .. '\t\t"class":[],\n'
        end

        if asanas[i].img then
            line = line .. '\t\t"img":['
            for j = 1, #asanas[i].img do
                line = line..'"'..asanas[i].img[j]..'"'
                if j < #asanas[i].img then line = line .. ',' end
            end
            line = line ..'],\n' 
        else
            line = line .. '\t\t"img":[],\n'
        end

        if asanas[i].goodFor then
            line = line .. '\t\t"goodFor":['
            for j = 1, #asanas[i].goodFor do
                line = line..'"'..asanas[i].goodFor[j]..'"'
                if j < #asanas[i].goodFor then line = line .. ',' end
            end
            line = line ..'],\n' 
        else
            line = line .. '\t\t"goodFor":[],\n'
        end
                    
        if asanas[i].vinyasa then
            line = line .. '\t\t"vinyasa":['
            for j = 1, #asanas[i].vinyasa do
                line = line..'"'..asanas[i].vinyasa[j]..'"'
                if j < #asanas[i].vinyasa then line = line .. ',' end
            end
            line = line ..'],\n' 
        else
            line = line .. '\t\t"vinyasa":[],\n'
        end

        if asanas[i].stepsPics then
            line = line .. '\t\t"stepsPics":['
            for j = 1, #asanas[i].stepsPics do
                line = line..'"'..asanas[i].stepsPics[j]..'"'
                if j < #asanas[i].stepsPics then line = line .. ',' end
            end
            line = line ..'],\n' 
        else
            line = line .. '\t\t"stepsPics":[],\n'
        end

        if asanas[i].prep then
            line = line .. '\t\t"prep":['
            for j = 1, #asanas[i].prep do
                line = line..'"'..asanas[i].prep[j]..'"'
                if j < #asanas[i].prep then line = line .. ',' end
            end
            line = line ..'],\n' 
        else
            line = line .. '\t\t"prep":[],\n'
        end

        if asanas[i].counter then
            line = line .. '\t\t"counter":['
            for j = 1, #asanas[i].counter do
                line = line..'"'..asanas[i].counter[j]..'"'
                if j < #asanas[i].counter then line = line .. ',' end
            end
            line = line ..'],\n' 
        else
            line = line .. '\t\t"counter":[],\n'
        end

        if asanas[i].followUp then
            line = line .. '\t\t"followUp":['
            for j = 1, #asanas[i].followUp do
                line = line..'"'..asanas[i].followUp[j]..'"'
                if j < #asanas[i].followUp then line = line .. ',' end
            end
            line = line ..'],\n' 
        else
            line = line .. '\t\t"followUp":[],\n'
        end

        if asanas[i].description then 
            line = line .. '\t\t"description":[\n'
            splitLines = newSplit(asanas[i].description,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"description":[],\n' 
        end

        if asanas[i].benefits then 
            line = line .. '\t\t"benefits":[\n'
            splitLines = newSplit(asanas[i].benefits,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"benefits":[],\n' 
        end

        if asanas[i].steps then 
            line = line .. '\t\t"steps":[\n'
            splitLines = newSplit(asanas[i].steps,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"steps":[],\n' 
        end

        if asanas[i].mods then 
            line = line .. '\t\t"mods":[\n'
            splitLines = newSplit(asanas[i].mods,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"mods":[],\n' 
        end

        if asanas[i].tips then 
            line = line .. '\t\t"tips":[\n'
            splitLines = newSplit(asanas[i].tips,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"tips":[],\n' 
        end

        if asanas[i].contra then 
            line = line .. '\t\t"contra":[\n'
            splitLines = newSplit(asanas[i].contra,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"contra":[],\n' 
        end

        if asanas[i].partnering then 
            line = line .. '\t\t"partnering":[\n'
            splitLines = newSplit(asanas[i].partnering,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"partnering":[],\n' 
        end

        if asanas[i].deepen then 
            line = line .. '\t\t"deepen":[\n'
            splitLines = newSplit(asanas[i].deepen,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"deepen":[],\n' 
        end


        if asanas[i].theraputic then 
            line = line .. '\t\t"theraputic":[\n'
            splitLines = newSplit(asanas[i].theraputic,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"theraputic":[],\n' 
        end

        if asanas[i].followInst then 
            line = line .. '\t\t"followInst":[\n'
            splitLines = newSplit(asanas[i].followInst,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t],\n'
        else 
            line = line .. '\t\t"followInst":[],\n' 
        end

        if asanas[i].variations then 
            line = line .. '\t\t"variations":[\n'
            splitLines = newSplit(asanas[i].variations,'\n') 
            -- print('Splitline ...'..splitLines[1])
            for j = 1, #splitLines do
                line = line .. '\t\t\t"'..splitLines[j]..'"' 
                if j < #splitLines then line = line .. ',\n' else line = line .. '\n'end
            end
            line = line .. '\t\t]\n'
        else 
            line = line .. '\t\t"variations":[]\n' 
        end

        line = line .. '\t}'
        if i == #asanas then line = line..'\n' else line = line..',\n' end
        fileToWrite:write(line..'\n')            
    end
    fileToWrite:write(']')            
    io.close(fileToWrite)
end

function asana.showAsanasWindow()
    c_lgsc(asanasWindowColour)
    c_lgr('fill',20,20,windowWidth - 40, windowHeight - 40)

    c_lgsc(asanaDetailsColour)
    c_lgr('fill',dataPosition + 140,120,windowWidth - 40 - dataPosition - 135, windowHeight - 40 - 120)

    c_lgsc(textColour)
    c_lgl(dataPosition,24,dataPosition,825)
    c_lgl(22,555,dataPosition,555)
    c_lgl(22,590,dataPosition,590)

    c_lgsc(restrictionColour)
    c_lgr('fill',23,557,asanaNameWidth,30)
    c_lgsc(textColour)
    c_lgpf(selectionString,25,557,asanaNameWidth+2,'center')

    if #displayAsanas == #asanas then
        c_lgpf(#asanas..' asanas',25,572,asanaNameWidth,'center')
    else
        c_lgpf(#displayAsanas..' shown. Click here to show all '..#asanas,25,572,asanaNameWidth,'center')
    end
    c_lgsc(searchClassificationChoicesColour)
    c_lgr('fill',285,50,100,50)
    c_lgsc(textColour)
    if searching then
        c_lgp('SEARCH',308,57)
    else
        c_lgp('VIEW',315,57)
    end
    c_lgp('MODE',315,77)

    drawAsanas()
--    c_lgp(searchString,10,8)

end

function setFieldHasData()
    for i = 1, 19 do fieldHasData[i] = true end
    if not (currentAsana.description and currentAsana.description ~= '' and currentAsana.description ~= 'None') then fieldHasData[1] = false end
    if not (currentAsana.benefits and currentAsana.benefits ~= '' and currentAsana.benefits ~= 'None') then fieldHasData[2] = false end
    if not (currentAsana.theraputic and currentAsana.theraputic ~= '' and currentAsana.theraputic ~= 'None') then fieldHasData[3] = false end
    if not (currentAsana.steps and currentAsana.steps ~= '' and currentAsana.steps ~= 'None') then fieldHasData[4] = false end
    if not (currentAsana.stepsPics and #currentAsana.stepsPics > 0) then fieldHasData[5] = false end
    if not (currentAsana.followInst and currentAsana.followInst ~= '' and currentAsana.followInst ~= 'None') then fieldHasData[6] = false end
    if not (currentAsana.contra and currentAsana.contra ~= '' and currentAsana.contra ~= 'None') then fieldHasData[7] = false end
    if not (currentAsana.mods and currentAsana.mods ~= '' and currentAsana.mods ~= 'None') then fieldHasData[8] = false end
    if not (currentAsana.deepen and currentAsana.deepen ~= '' and currentAsana.deepen ~= 'None') then fieldHasData[9] = false end
    if not (currentAsana.tips and currentAsana.tips ~= '' and currentAsana.tips ~= 'None') then fieldHasData[10] = false end
    if not (currentAsana.partnering and currentAsana.partnering ~= '' and currentAsana.partnering ~= 'None') then fieldHasData[11] = false end
    if not (currentAsana.variations and currentAsana.variations ~= '' and currentAsana.variations ~= 'None') then fieldHasData[12] = false end
    if not (currentAsana.prep and #currentAsana.prep > 0) then fieldHasData[13] = false end
    if not (currentAsana.counter and #currentAsana.counter > 0) then fieldHasData[14] = false end
    if not (currentAsana.followUp and #currentAsana.followUp > 0) then fieldHasData[15] = false end
    if not (currentAsana.mantra and currentAsana.mantra ~= '' and currentAsana.mantra ~= 'None') then fieldHasData[16] = false end
    if not (currentAsana.mudra and currentAsana.mudra ~= '' and currentAsana.mudra ~= 'None') then fieldHasData[17] = false end
    if not (currentAsana.vinyasa and #currentAsana.vinyasa > 0) then fieldHasData[18] = false end
end

-- sorts the asanas data structure
-- called from asana.load
function sort_asanas(a)
    table.sort(asanas, function(u,v) return u[a] < v[a] end)
end
    
function asana.load()
    require('asanaData') -- load the asanaData data file
    sort_asanas('sanskrit')
    selectionString='Showing All asanas'
    resetSelection() -- need this to ensure birthday asana only included if birthday
    currentAsanaNum = 1
    currentAsana = asanas[displayAsanas[currentAsanaNum]]
    currentTextField = currentAsana.description
    setFieldHasData()
--    for i = 1, #searchType do print(i..' = '..searchType[i]) end
end

function love.wheelmoved(x, y)
    local mx,my = love.mouse.getPosition()
    mx = mx/myScale
    my = my/myScale
    -- if on left of screen ie asana side then scroll asanas
    if mx < 260 then
        if y < 0 then 
            if reverseMouseWheelDirection then prevAsana() else nextAsana() end
        elseif y > 0 then 
            if reverseMouseWheelDirection then nextAsana() else prevAsana() end
        end
    -- if on right of screen ie text side then scroll text if on a text field
    elseif mx > 400 then
        if y < 0 and currentField > 0 and currentTextField and currentTextField ~= '' then
            if reverseMouseWheelDirection then
                if startLine > 1 then startLine = startLine - textScrollLines end
            else
                if startLine + maxTextFieldLines < #lines then startLine = startLine + textScrollLines end
            end
        elseif y > 0 and currentField > 0 and currentTextField and currentTextField ~= '' then
            if reverseMouseWheelDirection then
                if startLine + maxTextFieldLines < #lines then startLine = startLine + textScrollLines end
            else
                if startLine > 1 then startLine = startLine - textScrollLines end
            end
        end
    end
end

function resetAsanas()
    currentTextField = asanas[displayAsanas[currentAsanaNum]].description
    currentImageNum = 1
    currentField = 0
    startLine = 1

    selectedLevel = 1
    selectedType = 1
    selectedBack = 1
    selectedClass = 1
    selectedBreath = 1
    selectedGoodFor = 1

end

function nextAsana()
    if currentAsanaNum < #displayAsanas then
        currentAsanaNum = math.min(#displayAsanas,currentAsanaNum + 1)
        if currentAsanaNum > startAsana + numDisplayedAsanas - 1 then
            startAsana = startAsana + 1
        end
        resetAsanas()
    end
end

function prevAsana()
    if currentAsanaNum > 1 then
        currentAsanaNum = math.max(1,currentAsanaNum - 1)
        if currentAsanaNum < startAsana --[[+ numDisplayedAsanas - 1]] then
            startAsana = math.max(1,startAsana - 1)
        end
        resetAsanas()
    end
end

-- does not work yet
-- function love.textInput(t)
--     print(t)
--     searchString = searchString .. t
-- end

function asana.doKey(key)
    if key == 'right' and currentField > 0 and currentTextField and currentTextField ~= '' then
        if startLine + maxTextFieldLines < #lines then startLine = startLine + textScrollLines end
    elseif key == 'left' and currentField > 0 and currentTextField and currentTextField ~= '' then
        if startLine > 1 then startLine = startLine - textScrollLines end
    elseif key == 'up' then prevAsana()
    elseif key == 'down' then nextAsana()
    elseif key == 'z' and not birthday then 
        birthday = true
        searchString = '' 
        resetSelection()
    elseif key == 'backspace' then 
        searchString = '' 
        resetSelection()
    elseif key:match("%w") then -- alphanumeric
        if key == 'space' then key = ' ' end
        searchString = searchString .. key
        showMatch()
    end
end

function showTable(tbl)
    local line = ''
    for i = 1,#tbl do
        line = line..tbl[i]..'\n'
    end
    return line
end

function resetList()
    startAsana = 1
    currentAsanaNum = 1
    currentAsana = asanas[displayAsanas[currentAsanaNum]]
    startLine = 1
end

function resetSelection()
    displayAsanas = {}
    for i = 1, #asanas do 
        -- only add 1st asana if birthday
        if i > 1 or (i == 1 and birthday) then
            displayAsanas[#displayAsanas+1] = i 
        end
    end
    selectionString='Showing All asanas'
    searchString = ''
    resetList()
end

function showMatch()
    displayAsanas = {}
    for i = 1, #asanas do
        -- only add 1st asana if birthday
        if i > 1 or (i == 1 and birthday) then
            if string.find(asanas[i].sanskrit:upper(),searchString:upper(),1,true) then 
                displayAsanas[#displayAsanas+1] = i 
            end
        end
    end
    selectionString='Contains '..searchString
    resetList()
end

function showLevel(lvl) 
    displayAsanas = {}
    for i = 1, #asanas do
        -- only add 1st asana if birthday
        if i > 1 or (i == 1 and birthday) then
            if asanas[i].level == lvl then displayAsanas[#displayAsanas+1] = i end
        end
    end
    selectionString='Level = '..lvl
    resetList()
end

function showType(typ) 
    displayAsanas = {}
    for i = 1, #asanas do
        -- only add 1st asana if birthday
        if i > 1 or (i == 1 and birthday) then
            if i == 1 then print('birthday type added') end
            if asanas[i].type == typ then displayAsanas[#displayAsanas+1] = i end
        end
    end
    selectionString='Type = '..typ
    resetList()
end

function showBack(bck) 
    displayAsanas = {}
    for i = 1, #asanas do
        if asanas[i].back == bck then
            displayAsanas[#displayAsanas+1] = i
        end
    end
    if bck == '' then bck = 'BLANK' end
    selectionString='Back = '..bck
    resetList()
end

function showClass(cls) 
    displayAsanas = {}
    local classStr = 'BLANK'
    if #cls > 0 then
        for i = 1, #asanas do
            for j = 1,#asanas[i].class do
                if asanas[i].class[j] == cls[selectedClass] then
                    displayAsanas[#displayAsanas+1] = i
                end
            end
        end
        classStr = 'Class = '..cls[selectedClass]
    else
        for i = 1, #asanas do
            if #asanas[i].class == 0 then
                displayAsanas[#displayAsanas+1] = i
            end
        end
        classStr = 'Class = BLANK'
    end
    selectionString=classStr
    resetList()
end

function showBreath(brth) 
    displayAsanas = {}
    for i = 1, #asanas do
        if asanas[i].breath == brth then
            displayAsanas[#displayAsanas+1] = i
        end
    end
    if brth == '' then brth = 'BLANK' end
    selectionString='Breath = '..brth
    resetList()
end

function showGoodFor(gf) 
    displayAsanas = {}
    local goodForStr = 'BLANK'
    if #gf > 0 then
        for i = 1, #asanas do
            for j = 1,#asanas[i].goodFor do
                if asanas[i].goodFor[j] == gf[selectedGoodFor] then
                    displayAsanas[#displayAsanas+1] = i
                end
            end
        end
        goodForStr = 'Good For = '..gf[selectedGoodFor]
    else
        for i = 1, #asanas do
            if #asanas[i].goodFor == 0 then
                displayAsanas[#displayAsanas+1] = i
            end
        end
        goodForStr = 'Good For = BLANK'
    end
    selectionString=goodForStr
    resetList()
end

function asana.doMouseClicks(mx, my, button)
    local fieldWidth = 120
    local classGap = 10

    if button == 1 and U.mouse_in_rect(mx, my, asanasListX, asanasListY + asanaNameHeight, asanaNameWidth, numDisplayedAsanas * asanaNameHeight) then
        local asanaNum = math.floor((my - (asanasListY + asanaNameHeight)) / asanaNameHeight) + startAsana
        if asanaNum <= #displayAsanas then 
            currentAsanaNum = asanaNum 
            resetAsanas()
        end

    elseif button == 1 and U.mouse_in_rect(mx, my, asanasListX, 557, asanaNameWidth, 30) then
        resetSelection()
    elseif button == 1 and U.mouse_in_rect(mx, my, 285, 50, 100, 50) then
        searching = not searching
        if not searching then
            selectedLevel = 1
            selectedType = 1
            selectedBack = 1
            selectedClass = 1
            selectedBreath = 1
            selectedGoodFor = 1
        end
    elseif button == 1 and searching and U.mouse_in_rect(mx, my, startBoxesX + 1 * (classWidth + classGap) - classGap - 16, 93, 15, 15) then
        selectedLevel = selectedLevel + 1
        if selectedLevel > #searchLevel then selectedLevel = 1 end
    elseif button == 1 and searching and U.mouse_in_rect(mx, my, startBoxesX + 2 * (classWidth + classGap) - classGap - 16, 93, 15, 15) then
        selectedType = selectedType + 1
        if selectedType > #searchType then selectedType = 1 end
    elseif button == 1 and searching and U.mouse_in_rect(mx, my, startBoxesX + 3 * (classWidth + classGap) - classGap - 13, 93, 15, 15) then
        selectedBack = selectedBack + 1
        if selectedBack > #searchBack then selectedBack = 1 end
    elseif button == 1 and searching and U.mouse_in_rect(mx, my, startBoxesX + 4 * (classWidth + classGap) - classGap - 11, 93, 15, 15) then
        selectedClass = selectedClass + 1
        if selectedClass > #searchClass then selectedClass = 1 end
    elseif button == 1 and searching and U.mouse_in_rect(mx, my, startBoxesX + 5 * (classWidth + classGap) - classGap - 10, 93, 15, 15) then
        selectedBreath = selectedBreath + 1
        if selectedBreath > #searchBreath then selectedBreath = 1 end
    elseif button == 1 and searching and U.mouse_in_rect(mx, my, startBoxesX + 6 * (classWidth + classGap) - classGap - 7, 93, 15, 15) then
        selectedGoodFor = selectedGoodFor + 1
        if selectedGoodFor > #searchGoodFor then selectedGoodFor = 1 end
    elseif button == 1 and U.mouse_in_rect(mx, my, 1024, 93, 15, 15) then
        if #currentAsana.class > 1 then
            selectedClass = selectedClass + 1
            if selectedClass > #currentAsana.class then selectedClass = 1 end
        end
    elseif button == 1 and U.mouse_in_rect(mx, my, 1349, 93, 15, 15) then
        if #currentAsana.goodFor > 1 then
            selectedGoodFor = selectedGoodFor + 1
            if selectedGoodFor > #currentAsana.goodFor then selectedGoodFor = 1 end
        end
    elseif button == 1 and U.mouse_in_rect(mx, my, startBoxesX + 0 * (classWidth + classGap), 80, classWidth, 30) then
        if searching then showLevel(searchLevel[selectedLevel]) else showLevel(currentAsana.level) end
    elseif button == 1 and U.mouse_in_rect(mx, my, startBoxesX + 1 * (classWidth + classGap), 80, classWidth, 30) then
        if searching then showType(searchType[selectedType]) else showType(currentAsana.type) end
    elseif button == 1 and U.mouse_in_rect(mx, my, startBoxesX + 2 * (classWidth + classGap), 80, classWidth, 30) then
        if searching then showBack(searchBack[selectedBack]) else showBack(currentAsana.back) end
    elseif button == 1 and U.mouse_in_rect(mx, my, startBoxesX + 3 * (classWidth + classGap), 80, classWidth, 30) then
        if searching then showClass(searchClass) else showClass(currentAsana.class) end
    elseif button == 1 and U.mouse_in_rect(mx, my, startBoxesX + 4 * (classWidth + classGap), 80, classWidth, 30) then
        if searching then showBreath(searchBreath[selectedBreath]) else showBreath(currentAsana.breath) end
    elseif button == 1 and U.mouse_in_rect(mx, my, startBoxesX + 5 * (classWidth + classGap), 80, classWidth, 30) then
        if searching then showGoodFor(searchGoodFor) else showGoodFor(currentAsana.goodFor) end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 0 * fieldSeparation, fieldWidth, 20) then
        currentField = 1
        startLine = 1
        if currentAsana.description and currentAsana.description ~= '' then currentTextField = currentAsana.description else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 1 * fieldSeparation, fieldWidth, 20) then
        currentField = 2
        startLine = 1
        if currentAsana.benefits and currentAsana.benefits ~= '' then currentTextField = currentAsana.benefits else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 2 * fieldSeparation, fieldWidth, 20) then
        currentField = 3
        startLine = 1
        if currentAsana.theraputic and currentAsana.theraputic ~= '' then currentTextField = currentAsana.theraputic else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 3 * fieldSeparation, fieldWidth, 20) then
        currentField = 4
        startLine = 1
        if currentAsana.steps and currentAsana.steps ~= '' then currentTextField = currentAsana.steps else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 4 * fieldSeparation, fieldWidth, 20) then
        currentField = 5
        if currentAsana.stepsPics and #currentAsana.stepsPics > 0 then 
            currentStepsPics = currentAsana.stepsPics
            currentTextField = '' 
        else 
            currentStepsPics = nil
            currentTextField = 'None' 
        end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 5 * fieldSeparation, fieldWidth, 20) then
        currentField = 6
        startLine = 1
        if currentAsana.followInst and currentAsana.followInst ~= '' then currentTextField = currentAsana.followInst else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 6 * fieldSeparation, fieldWidth, 20) then
        currentField = 7
        startLine = 1
        if currentAsana.contra and currentAsana.contra ~= '' then currentTextField = currentAsana.contra else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 7 * fieldSeparation, fieldWidth, 20) then
        currentField = 8
        startLine = 1
        if currentAsana.mods and currentAsana.mods ~= '' then currentTextField = currentAsana.mods else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 8 * fieldSeparation, fieldWidth, 20) then
        currentField = 9
        startLine = 1
        if currentAsana.deepen and currentAsana.deepen ~= '' then currentTextField = currentAsana.deepen else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 9 * fieldSeparation, fieldWidth, 20) then
        currentField = 10
        startLine = 1
        if currentAsana.tips and currentAsana.tips ~= '' then currentTextField = currentAsana.tips else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 10 * fieldSeparation, fieldWidth, 20) then
        currentField = 11
        startLine = 1
        if currentAsana.partnering and currentAsana.partnering ~= '' then currentTextField = currentAsana.partnering else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 11 * fieldSeparation, fieldWidth, 20) then
        currentField = 12
        startLine = 1
        if currentAsana.variations and currentAsana.variations ~= '' then currentTextField = currentAsana.variations else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 12 * fieldSeparation, fieldWidth, 20) then
        currentField = 13
        if currentAsana.prep and #currentAsana.prep > 0 then 
            currentTextField = '' 
        else 
            currentTextField = 'None' 
        end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 13 * fieldSeparation, fieldWidth, 20) then
        currentField = 14
        if currentAsana.counter and #currentAsana.counter > 0 then 
            currentTextField = '' 
        else 
            currentTextField = 'None' 
        end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 14 * fieldSeparation, fieldWidth, 20) then
        currentField = 15
        if currentAsana.followUp and #currentAsana.followUp > 0 then 
            currentTextField = '' 
        else 
            currentTextField = 'None' 
        end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 15 * fieldSeparation, fieldWidth, 20) then
        currentField = 16
        startLine = 1
        if currentAsana.mantra and currentAsana.mantra ~= '' then currentTextField = currentAsana.mantra else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 16 * fieldSeparation, fieldWidth, 20) then
        currentField = 17
        startLine = 1
        if currentAsana.mudra and currentAsana.mudra ~= '' then currentTextField = currentAsana.mudra else currentTextField = 'None' end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 17 * fieldSeparation, fieldWidth, 20) then
        currentField = 18
        if currentAsana.vinyasa and #currentAsana.vinyasa > 0 then 
            currentTextField = '' 
        else 
            currentTextField = 'None' 
        end
    elseif button == 1 and U.mouse_in_rect(mx, my, dataPosition + 10, fieldsStartPosition + 18 * fieldSeparation, fieldWidth, 20) then
        currentField = 0
        currentTextField = ''
    elseif button == 1 and U.mouse_in_rect(mx, my, currentImageX, currentImageY, currentImageW, currentImageH) then
        if #currentAsana.img > currentImageNum then
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