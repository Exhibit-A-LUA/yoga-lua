--[[

Still to do

    2. stretch class - DONE - TO DO #1 deal with collisions?
    6. add stats/graphs
    8. add student details and notes
    9. add class notes
    10. change click to only MOVE top most class when 2 overlap

    99. rewrite using classes!
    101 open an editor to make notes : os.execute('nameofthe.exe') -or- io.popen(prog)

    require 'os';
    if package.loaded['os'] and type(package.loaded['os']) == "table" then
        local os = package.loaded['os']
        --from here use the local os variable to call anything inside os.
        --main block of code
    end

]]

require("constants")

local DEBUG = false

-- colour themes
local theme = 1
local colourSchemeName = ""

function loadColours()
    if theme == 1 then 
        dofile(compDir.."myColours.lua")
        colourSchemeName = "myColours.lua"
    elseif theme == 2 then 
        dofile(compDir.."myColoursB&W.lua")
        colourSchemeName = "myColoursB&W.lua"
    elseif theme == 3 then 
        dofile(compDir.."myColoursTry01.lua")
        colourSchemeName = "myColoursTry01.lua"
    elseif theme == 4 then 
        dofile(compDir.."myColoursTry02.lua")
        colourSchemeName = "myColoursTry02.lua"
    end
--    print('load '..colourSchemeName)
end

-- to display current time
local currentHour = 0
local currentMinute = 0
local currentMonth = 0
local currentDate = 0

-- for scrolling text
local scrolling = true
local scrollIndex = 1
local delay = 0

-- States
local classes, statistics, asanas = 1,2,3
local state = classes

-- global flags
local changingColours = false
local tweensOn = true
local showAllStudents = false
local showFinancialInfo = false
local saveShowMoney = showFinancialInfo 
local overAnyStudent = false
local mouseOverClass = nil
local financialYear = false

-- Year Calendar default display year, this year
local yearCalYear = D.getCalendarYear()

-- global totals
local thisWeekNum = 0
local totalDataWeeks = 0 -- stores total number of weeks since 7/10/2018
local totalDataDays = 0 -- stores total number of days worked since 7/10/2018
local totalNumClasses = 0 -- stores total number of active classes for all time
local yearTakingsTotals = {} -- [2020][1] = monthly takings .. [2020][13] = yearTotalTakings

-- stored 'bests' for statistics window
local bestDay = 0
local bestWeek = 0
local bestMonth = 0
local bestYear = 0

-- variable for moving a class with mouse
local mouseOffsetX, mouseOffsetY = 0,0
local mouseStartX, mouseStartY = 0,0
local leftMouseClicked = false
local rightMouseClicked = false
local movingClass = false
local moveTheClass = false
local classMoved = false -- flag to know when class has moved so can re create the week structure after class moved
local classToMove = nil -- stores the class being moved, nil if not moving any class
local addingNewStudent = false

-- constants for displaying the active week and its classes
local classBoxWidth = 120
local classBoxHeight = 40
local daySummaryBoxHeight = 40
local classBoxPadY = 2
local classBoxPadX = 10

local startX = 400 -- x position of week display
local startY = 90 -- y position of week display
local graphX = 380 -- all time takings graph x position
local startHour = 5
local numEvents = 15
local dayY = startY - 55 -- 50
local rectCorner = 6 -- how round the corners of the class box is

-- tween constants
local tweenTime = 0.4
local tweenType = Tween.back_out

-- Month Calendar position
local calendarX = startX - 225
local calendarY = 70

-- Student Names position
local studentNamesX = 25
local studentNamesY = 215
local maxStudentY = 0

-- Year Calendar position
local yearCalX = 35
local yearCalY = 250 

local weekOffset = 0 -- offset from current system date

-- Edit Student positions
local editButtonWidth = 85
local editButtonHeight = 15
local editButtonXGap = 10
local editStartLine = 710
local editLineIncrement = 20
local setPaymentLine = 0
local payAdjustAmount = 0
local setStartLine = 0

-- Menu position
local menuX = 25
local menuY = 40

local menuButtonWidth = 135
local menuButtonHeight = 20
local menuGap = 10

-- menu button positions
local newWeekButtonY = menuY
local newWeekButtonX = menuX

local studentDisplayToggleY = menuY + 1 * (menuButtonHeight + menuGap)
local studentDisplayToggleX = menuX

local financialInfoToggleY = menuY + 2 * (menuButtonHeight + menuGap)
local financialInfoToggleX = menuX

local financialYearToggleY = menuY + 3 * (menuButtonHeight + menuGap)
local financialYearToggleX = menuX

local showAsanasWindowY = menuY + 3 * (menuButtonHeight + menuGap)
local showAsanasWindowX = menuX

local showStatsWindowY = menuY + 4 * (menuButtonHeight + menuGap)
local showStatsWindowX = menuX

local changingColoursY = menuY + 5 * (menuButtonHeight + menuGap)
local changingColoursX = menuX

-- colour change window position and size
local colourWindowxPos = 25
local colourWindowyPos = 490
local colourWindowWidth = 320
local colourWindowHeight = 330


-- stores the actual x and y positions of class positions on screen
local positionsY = {}
local positionsX = {}
for i = 1, 1 + (numEvents-1) * 4 do -- for each 15min block
    positionsY[#positionsY+1] = startY + math.floor((i-1) / 4) * (classBoxHeight + classBoxPadY) + (classBoxHeight / 4 * ((i-1) % 4))
end

-- for i = 1, #positionsY do
--     printIfDebug('Pos Y '..i..' = '..positionsY[i])
-- end

for i = 1, 7 do
    positionsX[#positionsX+1] = startX + (i-1) * (classBoxWidth + classBoxPadX)
-- printIfDebug('x position = '..positionsX[#positionsX])    
end

-- data structures to store all data files
local week = {} -- used to store all classes for active week for display eg week[1][2].name
local dayClass = {} -- all data from classData.lua is read into dayClass
local student = {} -- all data from studentData.lua is read into student
local memories = {} -- all data from memories.lua is read into memories
local reminders = {} -- all data from reminderData.lua is read into reminders
local thisWeekReminders = {} -- reminders for this week ie thisWeekReminders[1..7][1] = text1, [1..7][2] = text2 etc
local currentReminderNumber = {1,1,1,1,1,1,1} -- stores the current reminder number to display

--local asanas = {} -- all data from asanas.lua is read into asanas, now done in asanaNew class

local classNumbers = {} -- used to store all class number info
-- classNumbers = {studentName='name', classList={{yr=2020,mth=10,date=1,hour=10,class=1,package=12,status=0,paid=0},{yr=2020,mth=3,date=31,class=2,package=12}}}

local chosenStudentData = {} -- used to store current weeks data for chosenStudent
-- chosenStudentData = {day=Monday,day=1,year=2020,month=11,date=26,hour=10,status=0,clsNum=3,pkg=12,paid=12000,start=1}

local weekHighlights = {} -- used to store student events current week

local selectedStudentName = '' -- stores the name selected for the new student added
local chosenStudent = nil -- points to the student record of the student being edited/viewed 

-- variables for showing memories
local foundMemoryDate = {}
local memoryDay = 0
local lastMemoryDay = 8
local randomMemory = 0
local showMemories = true
local testPhoto = 0 -- used to ba able to step through all memory pics to ensure they work correctly

local exactMemory = false
local numFoundMemories = 0

-- data structures to maintain totals
local monthTotals = {} -- stores number of classes for each month (month 13 is year total)
-- local weekTotals = {} -- stores number of active classes for each week 
local newWeekTotals = {} -- REPLACED weekTotals .. stores number of active classes for each weekday (day 8 is week total)
-- newWeekTotals[week][day], where day 8 = total for the week
local weekDayTotals = {0,0,0,0,0,0,0} -- stores total num class on each day mon to sun
local dayRecords = {0,0,0,0,0,0,0,0} -- stores the best num classes for each day mon to sun. 8 stores Best Week
local classesPerDay = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

-- for editing student class pattern and package
local weekTbl = {}
local weekTblX = 75
local packageX = 350

-- set to Sunday before first day of recorded classes calculated in addClass
local startYear = 0
local startMonth = 0
local startDay = 0

-- set to first day of any data in classData calculated in addClass
local firstYear = 0
local firstMonth = 0
local firstDay = 0

-- calculated in addClass
local numYears = 0
local numMonths = 0

-- colour constants user can change, now in myColours,myColoursB&W,myColoursTry01,myColoursTry02
--local textColour = {0, 0, 0, 1} 

--local backgroundColour = {.8,.8, 1, 1} 

--local classesWindowColour = {0,.36,.68,1} --{.7, .7, .9, .9}
--local daySummaryBoxColour = {.3, .9, .9, 1}
--local todaySummaryBoxColour = {.2, 1, .4, 1}

--local statisticsWindowColour = {.5, .5, .9, .9}
--local statsDataColour = {1, 1, 1, 1}
--local yearCalColour = {1,1,1,1}

--local normalButtonColour = {.8,1,1,1}
--local highlightButtonColour = {1,1,0,1}
--local graphColour = {1,1,.6,1}

-- colour constants
local buttonTextColour = {0, 0, 0, 1} 
local daySummaryTextColour = {0, 0, 0, 1} 
local todaySummaryTextColour = {0, 0, 0, 1} 
local studentNameTextColour = {0, 0, 0, 1} 
local changeColoursTextColour = {0, 0, 0, 1} 
local statisticsTextColour = {0, 0, 0, 1} 
local yearCalTextColour = {0, 0, 0, 1} 

local gridLineColour = {1, 1, 1, .4}
local highlightClassBorderColour = {1,0,0,1}
local highlightClassColour = {1,1,.1,1}
local classBorderColour = {0,0,0,.3}
local classNextSessionStartBorderColour = {0,0,1,1}
local classStatusBorderColour = {0,0,0,1}
local statusBlobActiveColour = {0,1,0,1}
local statusBlobStudentCancelColour = {.7,0,0,1}
local statusBlobNishCancelColour = {0,0,.7,1}

local blue = {0,0,1,1}
local red = {1,0,0,1}
local green = {0,1,0,1}
local yellow = {1,1,0,1}
local purple = {1,.5,1,1}
local paleYellow = {1,1,.8,1}
local lightBlue = {.5,1,1,1}
local vLightBlue = {.8,1,1,1}
local white = {1,1,1,1}
local black = {0,0,0,1}

-- button's definitions, not local because needed in date.lua
buttons = {
    ['clearChosenStudent'] = {x=235,y=785,w=80,h=15},
    ['prevWeek'] = {x=startX-47,y=dayY+22,w=15,h=15},
    ['nextWeek'] = {x=startX-23,y=dayY+22,w=15,h=15},
    ['prevMonth'] = {x=calendarX+118,y=calendarY-20,w=15,h=15},
    ['nextMonth'] = {x=calendarX+140,y=calendarY-20,w=15,h=15},
    ['prevYear'] = {x=yearCalX+50,y=yearCalY-20,w=15,h=15},
    ['nextYear'] = {x=yearCalX+157,y=yearCalY-20,w=15,h=15},
    ['editPackage'] = {x=packageX,y=810,w=25,h=15},
    ['animations'] = {x=92,y=windowHeight - 19,w=16,h=16},
    ['thisWeek'] = {x=startX - 47,y=dayY - 10,w=40,h=25},
    ['gotoAsanas'] = {x=showAsanasWindowX,y=showAsanasWindowY,w=menuButtonWidth,h=menuButtonHeight},
    ['allStudents'] = {x=studentDisplayToggleX,y=studentDisplayToggleY,w=menuButtonWidth,h=menuButtonHeight},
    ['financialInfo'] = {x=financialInfoToggleX,y=financialInfoToggleY,w=menuButtonWidth,h=menuButtonHeight},
    ['newWeek'] = {x=newWeekButtonX,y=newWeekButtonY,w=menuButtonWidth,h=menuButtonHeight},
    ['showStats'] = {x=showStatsWindowX,y=showStatsWindowY,w=menuButtonWidth,h=menuButtonHeight},
    ['financialYearToggle'] = {x=financialYearToggleX,y=financialYearToggleY,w=menuButtonWidth,h=menuButtonHeight},
    ['changeColours'] = {x=changingColoursX,y=changingColoursY,w=menuButtonWidth,h=menuButtonHeight},
    ['classArea'] = {x=startX,y=startY,w=7 * (classBoxWidth + classBoxPadX),h=numEvents * (classBoxHeight + classBoxPadY)},
    ['reminderMon'] = {x=startX + (1 - 1) * (classBoxWidth + classBoxPadX) + 1,y=dayY + 40,w=classBoxWidth + classBoxPadX,h=14},
    ['reminderTue'] = {x=startX + (2 - 1) * (classBoxWidth + classBoxPadX) + 1,y=dayY + 40,w=classBoxWidth + classBoxPadX,h=14},
    ['reminderWed'] = {x=startX + (3 - 1) * (classBoxWidth + classBoxPadX) + 1,y=dayY + 40,w=classBoxWidth + classBoxPadX,h=14},
    ['reminderThu'] = {x=startX + (4 - 1) * (classBoxWidth + classBoxPadX) + 1,y=dayY + 40,w=classBoxWidth + classBoxPadX,h=14},
    ['reminderFri'] = {x=startX + (5 - 1) * (classBoxWidth + classBoxPadX) + 1,y=dayY + 40,w=classBoxWidth + classBoxPadX,h=14},
    ['reminderSat'] = {x=startX + (6 - 1) * (classBoxWidth + classBoxPadX) + 1,y=dayY + 40,w=classBoxWidth + classBoxPadX,h=14},
    ['reminderSun'] = {x=startX + (7 - 1) * (classBoxWidth + classBoxPadX) + 1,y=dayY + 40,w=classBoxWidth + classBoxPadX,h=14}
}

function showButton(btn,txt)
    button(btn.x,btn.y,btn.w,btn.h,txt)
end

-- record the dates on which a student had a class in the active month
-- used to display student classes on month calendar
local studentClassesThisMonth = {}
for i = 1,31 do studentClassesThisMonth[i] = -1 end

local fileToWrite = nil -- stores name of data files to write

function printIfDebug(text)
    if DEBUG then print(text) end
end

-- used to ensure mouse positions work if program is scaled
function getScaledMousePos()
    local mx, my = love.mouse.getPosition()
    return mx/myScale, my/myScale
end

-- constructs each line to be written to classData.lua
-- called from writeWeek
function writeLine(day,class)
    local line =    'addClass{year='..week[day][class].year..
                    ',month='..week[day][class].month..
                    ',date='..week[day][class].date..
                    ',hour='..week[day][class].hour..
                    ',min='..week[day][class].min..
                    ',slot='..week[day][class].slot..
                    ',length='..week[day][class].length..
                    ',name=\''..week[day][class].name..
                    '\',status='..week[day][class].status..
                    ',paid='..week[day][class].paid
    if week[day][class].class then
        line = line ..  ',class='..week[day][class].class
        if week[day][class].pkg then
            line = line .. ',pkg='..week[day][class].pkg
        end
    end
    if week[day][class].wasClass1 then
        line = line .. ',wasClass1=true'
    end
    line = line..'}'
    return line
end

-- returns the week number of the date passed, week 1 is the week of the first recorded class
-- called from addClass and processData
function weekNumSinceStart(endYear, endMonth, endDay)
    local startTime = os.time({year=startYear,month=startMonth,day=startDay})
    local endTime = os.time({year=endYear,month=endMonth,day=endDay})
    local dayDif = os.difftime(startTime,endTime) / (3600 * 24)
    local weekNum = math.abs(math.floor(dayDif / 7))
    return weekNum
end

local NEW_CLASS_NUM_VERSION = true

-- returns the student record of the student name passed if found, otherwise returns nil
-- called from many places TO DO #3 (if bothered) - check if it should be used elsewhere
function findStudent(stu)
    for i = 1,#student do
        if student[i].name == stu then 
            return student[i]
        end
    end
    return nil
end

-- ensures new package chosen is updated in current week
-- called from editPackage
function setPackage(cls)
    local s = findStudent(cls.name)
    for day = 1, 7 do
        for classIdx = 1, #week[day] do
            thisClass = week[day][classIdx]
            if thisClass.name == cls.name and 
                s.startYr == thisClass.year and
                s.startMth == thisClass.month and
                s.startDay == thisClass.date then
                thisClass.pkg = cls.package
                return
            end
        end
    end
end

-- chose a new package for student being edited
-- called from settingWeekPackage
function editPackage()
    if chosenStudent.package == 0 then chosenStudent.package = 8
    elseif chosenStudent.package == 8 then chosenStudent.package = 12
    elseif chosenStudent.package == 12 then chosenStudent.package = 16
    elseif chosenStudent.package == 16 then chosenStudent.package = 20
    elseif chosenStudent.package == 20 then chosenStudent.package = 0
    end
    setPackage(chosenStudent) -- to ensure package updated correctly 
end

-- change the weekly class pattern for student being edited
-- called from settingWeekPattern
function editWeekDays(key)
    weekTbl = chosenStudent.wk
    local removedIt = false
    if #weekTbl > 0 then
        for i = 1, #weekTbl do
            if weekTbl[i] == key then
                table.remove(weekTbl,i)
                removedIt = true
                break
            end
        end
    end
    -- if not there then add it --> toggle
    if not removedIt then table.insert(weekTbl,key) end
    table.sort(weekTbl)
end

-- displays the weekly class pattern for student being edited
-- called from drawWeek
function showWeekDays()
    weekTbl = chosenStudent.wk
    local dayTbl = {'Mo','Tu','We','Th','Fr','Sa','Su'}
    local tmpDay = {}
    if #weekTbl > 0 then
        for i = 1,#weekTbl do table.insert(tmpDay,dayTbl[weekTbl[i]]) end
    else
        -- removed this Dec 02 2020 so that students with empty wk={} start with blank
        -- weekTbl = {1,2,3,4,5,6,7} 
        -- tmpDay = dayTbl
    end

    -- draw 'Pattern' button
    c_lgp('Pattern',25,buttons.clearChosenStudent.y + 25)
    for i = 1, 7 do c_lgr('line',weekTblX + (i - 1) * 30,buttons.clearChosenStudent.y + 25,25,15) end
    
    for i = 1, 7 do
        if i <= #weekTbl then 
            button(weekTblX + (weekTbl[i] - 1) * 30,buttons.clearChosenStudent.y + 25,25,15,tmpDay[i])
        end
    end

    -- draw 'Package' button
    c_lgp('Package',packageX - 55,buttons.clearChosenStudent.y + 25)
    showButton(buttons.editPackage,chosenStudent.package)
end

-- adds event details into classNumbers
-- TO DO #4:REWRITE to set class to 1 when event.class = 1
-- maybe could set class to 1 on the payment class if class is before current session start date and use class == 1 if after
-- this would be a problem if we set start date before we set payment --    AAAARRRRRGHHH too nasty
-- better to use a hard date like if before jan 1 2021 then use payment if after, use class == 1

-- called from reCalculateClassNumbers and addClass
function addClassNumbers(event)
    -- classNumbers = {studentName='name', curPkg=12, classList={{yr=2020,mth=10,date=1,hour=10,class=1,package=12,status=0,paid=0},{},...}}

    -- write new version as follows (once class=1 and package=?? set in classData)
    -- class=1 and package will be stored in classData.lua when 1st class of session
    -- so   if event.class == 1 then record it and package, and set classNumbers[i].curPkg to event.package
    --      if event.class == nil then set class to prev class + 1, set package classNumbers[i-1].curPkg

    if event.name == 'new class' then return end

    local classNum = 1
    local pack = 0
    local paymentReceived = false
    
    local studentIndex = 0
    -- if student already added, find it's index
    for i = 1, #classNumbers do
        if classNumbers[i].studentName == event.name then
            studentIndex = i
        end
    end

    -- if student not yet added, add student and create first class
    if studentIndex == 0 then
        studentIndex = #classNumbers + 1
        classNumbers[studentIndex] = {}
        classNumbers[studentIndex].studentName = event.name
        classNumbers[studentIndex].classList = {}
    end

    -- shortcut to new classNumbers record
    local thisStudent = classNumbers[studentIndex]

    -- create thisStudent record
    thisStudent.classList[#thisStudent.classList + 1] = {}

    -- add thisStudent new class details
    local newClass = thisStudent.classList[#thisStudent.classList]
    newClass.yr = event.year
    newClass.mth = event.month
    newClass.date = event.date 
    newClass.hour = event.hour -- NOV 29th added hour in case 2 clases on 1 day
    newClass.status = event.status
    newClass.paid = event.paid
    -- IMPORTANT!! should set to event.class if class is set in classData!!!
    -- its ok to set to 0 here so that non-active classes get class set to 0
    -- need to ensure that class is set to event.class if one exists in the "if event.status" == 0 block
    newClass.class = 0 
    newClass.package = 0

    if event.status == 0 then -- Only active classes have a class number assigned

        -- work out this class number
        -- new - should set to event.class if it exists, and do nothing else
        -- otherwise,   if payment made or its the first class for this student then classNum = 1, 
                        -- (this is a problem when moving away from "if payment then class = 1")
        --              otherwise this class number is one more than previous class number

        paymentReceived = event.paid > 0 -- payment received this class note: could be cancelled

        if not paymentReceived then
            -- payment could have been made on previous 'cancelled' class, so look at previous cancelled classes 
            -- until you find one on which payment was made or one that was not cancelled
            -- TESTED AND WORKS
            i = #thisStudent.classList 
            while i > 1 do 
                local cls = thisStudent.classList[i-1]
                if cls.paid > 0 then
                    paymentReceived = cls.status ~= 0 
if paymentReceived then printIfDebug('Payment Received on cancelled class for '..event.name..' paid date '..cls.date..'/'..cls.mth..'/'..cls.yr) end
                    break
                elseif cls.status == 0 then break -- to ensure this payment wasn't in a previous session
                end
                i = i - 1
            end
if paymentReceived then printIfDebug('Payment Received on cancelled class for '..event.name..' class date '..event.date..'/'..event.month..'/'..event.year) end
        end

        -- BUG -    if there is a class == 1 then should not set class to 1 if payment found
        --          not necessarily on this class, last class could be 1 so should not set this to be 1 too!
        if paymentReceived or event.class == 1 then -- 27th nov added class == 1
            classNum = 1
            -- now go and find the package 
            if #thisStudent.classList > 1 then 
                -- package is set to the class number of the last non cancelled class
                -- so find last non-cancelled class
                i = #thisStudent.classList - 1
                while i > 1 and thisStudent.classList[i].status ~= 0 do
                    i = i - 1
                end
                -- another version
                -- while i > 1 do
                --     if thisStudent.classList[i].status == 0 then break end
                --     i = i - 1
                -- end

                pack = thisStudent.classList[i].class
printIfDebug('payment received, pack = '..pack)                
                -- set all previous classes packages to pack
                for i = #thisStudent.classList, #thisStudent.classList-pack, -1 do
                    thisStudent.classList[i].package = pack 
                end
                -- reset pack to 0 so we get the pack from students.lua for this class
                -- ie set all previous classes packs to calculated but set new sessions pack to one in student
                -- will this work for previous session or just for latest session???
                -- this doesn't really work
                pack = 0
            end
        elseif #thisStudent.classList == 1 then classNum = 1
        else 
            -- set the class number to one more than the previous class number
            i = #thisStudent.classList - 1
            while i > 1 and thisStudent.classList[i].status ~= 0 do
                i = i - 1
            end
            classNum = thisStudent.classList[i].class + 1
        end
        newClass.class = classNum
printIfDebug('name = '..event.name..' package = '..newClass.package)                

        -- read package from students
        if pack == 0 then 
            newClass.package = findStudent(event.name).package
        end
    end
end

-- if student is not nil, will delete student from classNumbers and re-add student back into classNumbers
-- if student is nill, will re-create the complete classNumbers for all students
-- called when  1) add a new week, 
--              2) set a students start session, 
--              3) set a student's package 
--              4) change student's status to and from active, 
--              5) delete active class, 
--              6) move a class (active or not), 
--              7) add a new class
function reCalculateClassNumbers(student)
    if student then
        -- delete student from classNumbers
        for i = 1, #classNumbers do
            if classNumbers[i].studentName == student then
                table.remove(classNumbers,i)
                break
            end
        end
    else
        classNumbers = {}
    end
    for i = 1, #dayClass do
        if student == nil or student == dayClass[i].name then
            if dayClass[i].delete ~= 1 then addClassNumbers(dayClass[i]) end
        end
    end
end

-- returns class number and package for class passed
-- called from displayStudentDetails and drawClass and createChosenStudentData
function findClassNumber(thisClass)
    for i = 1, #classNumbers do
        if classNumbers[i].studentName == thisClass.name then
            for j = 1, #classNumbers[i].classList do
                thisOne = classNumbers[i].classList[j]
                if thisOne.yr == thisClass.year and 
                    thisOne.mth == thisClass.month and 
                    thisOne.date == thisClass.date and
                    thisOne.hour == thisClass.hour then
                    return thisOne.class, thisOne.package
                end
            end
        end
    end
    return 0, 0
end

-- adds class details into dayClass structure
-- called from classData.lua and addNewClass
function addClass(event)
    
    dayClass[#dayClass+1] = event

    --set first data date
    if #dayClass == 1 then
        firstYear = event.year
        firstMonth = event.month
        firstDay = event.date
    end

    if event.status >= 0 and startYear == 0 then
        local yr,mth,day = event.year,event.month,event.date
        day,mth,yr = nextDay(day,mth,yr,-1)
        local dayOfWeek = D.get_day_of_week(day,mth,yr) - 1
        if dayOfWeek == 0 then dayOfWeek = 7 end
        if dayOfWeek < 7 then 
            day,mth,yr = nextDay(day,mth,yr,-dayOfWeek)
        end

        -- set global constants
        startYear = yr
        startMonth = mth
        startDay = day

        numYears = D.getCalendarYear() - startYear + 1
        numMonths = D.currentMonthNum() + (numYears - 2) * 12 + (12 - startMonth + 1)
    end
    
    local y = startY + 
                (dayClass[#dayClass].hour - startHour) * (classBoxHeight + classBoxPadY) + 
                math.floor(classBoxHeight / 4) * math.floor(dayClass[#dayClass].min / 15)
    dayClass[#dayClass].y = y

    -- add to totals

    if not yearTakingsTotals[event.year] then yearTakingsTotals[event.year] = {} end
    if not yearTakingsTotals[event.year][event.month] then yearTakingsTotals[event.year][event.month] = 0 end
    if not yearTakingsTotals[event.year][13] then yearTakingsTotals[event.year][13] = 0 end

    yearTakingsTotals[event.year][event.month] = yearTakingsTotals[event.year][event.month] + event.paid
    yearTakingsTotals[event.year][13] = yearTakingsTotals[event.year][13] + event.paid

    -- student can record payment even if class was cancelled
    for i = 1,#student do
        if student[i].name == event.name then
            student[i].totalPaid = student[i].totalPaid + event.paid
            break
        end
    end

    -- only add to counts if class was not cancelled
    -- UPDATE HERE - DONE - ONLY ADD TO TOTALS IF NEW CLASS Student package > 0
    for i = 1,#student do
        if student[i].name == event.name then
            if zeroPackage(event.name) then 
                event.status = -1
            else
                if event.status == 0 then 
                    student[i].numClasses = student[i].numClasses + 1
                end
            end
            break
        end
    end

    addClassNumbers(event)

    local thisWeekNum = 0

    if event.status == 0 then
        -- for i = 1,#student do
        --     if student[i].name == event.name then
        --         student[i].numClasses = student[i].numClasses + 1
        --         break
        --     end
        -- end


        totalNumClasses = totalNumClasses + 1

        if monthTotals[event.year] == nil then monthTotals[event.year] = {0,0,0,0,0,0,0,0,0,0,0,0,0} end
        monthTotals[event.year][event.month] = monthTotals[event.year][event.month] + 1
        monthTotals[event.year][13] = monthTotals[event.year][13] + 1

        thisWeekNum = weekNumSinceStart(event.year,event.month,event.date)
        local dayOfWeek = D.get_day_of_week(event.date,event.month,event.year) - 1
        if dayOfWeek == 0 then dayOfWeek = 7 end

        weekDayTotals[dayOfWeek] = weekDayTotals[dayOfWeek] + 1
        -- if weekTotals[thisWeekNum] == nil then weekTotals[thisWeekNum] = 0 end 
        -- weekTotals[thisWeekNum] = weekTotals[thisWeekNum] + 1
-- new test using newWeekTotals -- IT WORKS
        if newWeekTotals[thisWeekNum] == nil then newWeekTotals[thisWeekNum] = {0,0,0,0,0,0,0,0,0} end 
        newWeekTotals[thisWeekNum][dayOfWeek] = newWeekTotals[thisWeekNum][dayOfWeek] + 1
        newWeekTotals[thisWeekNum][8] = newWeekTotals[thisWeekNum][8] + 1
    end
--    add all classes (cancelled or not) to newWeekTotals[thisWeekNum][9] -- see TO DO #14 - DONE
    if --[[event.status > -1 and]] #newWeekTotals > 0 then 
        thisWeekNum = weekNumSinceStart(event.year,event.month,event.date)
        if newWeekTotals[thisWeekNum] == nil then newWeekTotals[thisWeekNum] = {0,0,0,0,0,0,0,0,0} end 
        newWeekTotals[thisWeekNum][9] = newWeekTotals[thisWeekNum][9] + 1
    end
end

-- returns true if student's (passed in s) weekly pattern includes the day of week of the passed date
-- called from calculatePostponedStart (and setNextSessionStart only in older version)
function classUsuallyScheduledFor(s,day,month,year)
--    local s = student[#student] -- 9th december changed this to have s passed, otherwise always looks at last student

    local dayOfWeek = D.get_day_of_week(day,month,year) - 1
    if dayOfWeek == 0 then dayOfWeek = 7 end

    -- if student has wk={} then any weekday is ok 
    if #s.wk == 0 then return true end -- changed 9th dec to be just return true ie if no schedule then any day is ok

    -- we know student has at least 1 day in wk={}
    for i = 1, #s.wk do
        if dayOfWeek == s.wk[i] then
            return true
        end
    end
    return false
end

-- returns the day after the date passed, or the day before if incr = -1
-- called from calculatePostponedStart and addClass
function nextDay(day,month,year,incr)
    local offset = 1
    if incr then offset = incr end
    local nxtDay = day + offset
    local nxtMonth = month
    local nxtYear = year
    if nxtDay > D.get_days_in_month(month,year) then
        nxtDay = 1
        nxtMonth = nxtMonth + 1
        if nxtMonth == 13 then
            nxtMonth = 1
            nxtYear = nxtYear + 1
        end
    end
    if nxtDay < 1 then
        nxtMonth = nxtMonth - 1
        if nxtMonth == 0 then
            nxtMonth = 12
            nxtYear = nxtYear - 1
        end
        nxtDay = D.get_days_in_month(nxtMonth,nxtYear)
    end
    return nxtDay, nxtMonth, nxtYear
end

-- returns true if student's name passed has a class on date passed
-- called from calculatePostponedStart and (and setNextSessionStart only in and older version)
function classOnDay(name,d,m,y)
    for i = 1, #dayClass do
        if  dayClass[i].name == name and
            dayClass[i].date == d and
            dayClass[i].month == m and
            dayClass[i].year == y then
            return true
        end
    end
    return false
end

-- returns the class found if student's name passed has a class on date passed, otherwise returns nil
-- called from calculatePostponedStart
function getClassOnDay(name,d,m,y)
    for i = 1, #dayClass do
        if  dayClass[i].name == name and
            dayClass[i].date == d and
            dayClass[i].month == m and
            dayClass[i].year == y then
            return dayClass[i]
        end
    end
    return nil
end

-- returns true is student's name passed has a class after the date passed
-- called from calculatePostponedStart
function classAfter(name,d,m,y)
    for i = 1, #dayClass do
        if  dayClass[i].name == name and
            D.before(y,m,d,dayClass[i].year,dayClass[i].month,dayClass[i].date) then
            return true
        end
    end
    return false
end

-- calculates next session start date for each student
-- ONLY called from love.load 
function setAllStudentsNextSession()
    for i = 1, #student do 
        if student[i].package > 0 and student[i].startDay > 0 then 
            setNextSessionStart(student[i]) 
        end
    end
end

-- returns true if thisClass is the first active class on or after the due date for the next session
-- and its before the actual postponed start
-- called from drawClass if this class is active and falls on the due date for the next session
-- so it can be marked with yellow lines to indicate that the due date has been postponed
function postponedClass(thisClass)
    for i = 1, #student do 
        if student[i].name == thisClass.name and student[i].classesNishCancelled > 0 and
           D.before(student[i].startYr,student[i].startMth,student[i].startDay,
                    thisClass.year,thisClass.month,thisClass.date) then 
                return true
        end
    end
    return false
end

-- version 1 - true if this class falls on the postponed start date
-- version 2 - true if this class falls on or after the postponed start date
-- NOTE - BUG #1 do it like startSessionAniversary!!! - YES to ensure ONLY true for 1st class on or after postponed date
-- call it postponedSessionAniversary

-- NOTE DEC 04 - trialling postponedSessionAniversary() instead of this
-- CURRENTLY NOT USED
function postponedClassStart(thisClass)
    for i = 1, #student do 
        if student[i].name == thisClass.name and student[i].classesNishCancelled > 0 then 
            local d,m,y = nextDay(student[i].postponedStartDay,student[i].postponedStartMth,student[i].postponedStartYr,-1)

            --vesion 2
            if D.before(y,m,d, thisClass.year,thisClass.month,thisClass.date) then

            -- version 1
            -- if student[i].postponedStartDay == thisClass.date and
            -- student[i].postponedStartMth == thisClass.month and
            -- student[i].postponedStartYr == thisClass.year then

            return true
            end
        end
    end
    return false
end

-- returns true if class is AFTER current session start date
-- called from drawClass when status is changed to and from postponed
function classAfterSessionStart(thisClass)
    for i = 1, #student do 
        if student[i].name == thisClass.name then 
            return D.before(student[i].startYr,student[i].startMth,student[i].startDay,
                            thisClass.year,thisClass.month,thisClass.date)
        end
    end
    return false
end

-- returns the student record for thisClass
-- called from drawClass as parameter for calculatePostponedStart when status is changed to and from postponed
function getStudent(thisClass)
    for i = 1, #student do 
        if student[i].name == thisClass.name then 
            return student[i]
        end
    end
    return nil
end

-- sets the postponedStartDay for the student 's' passed

-- called from setNextSessionStart either at start of program or after we set a new session start
-- called from drawClass when status is changed to and from postponed

function calculatePostponedStart(s)

    local firstActiveClass = nil
    local numCancelledClasses = 0
    local step = 0
    
    local d,m,y = s.nextStartDay,s.nextStartMth,s.nextStartYr
    
    -- ensure this is the actual first class of session    
    if not classOnDay(s.name,d,m,y) and classAfter(s.name,d,m,y) then
        while not classOnDay(s.name,d,m,y) do
            d,m,y = nextDay(d,m,y)
        end
    end

    local firstClass = getClassOnDay(s.name,d,m,y)
    
    -- count number cancelled classes on and after next start day until first active class
    -- and store firstActiveClass

    -- 1. TO DO #7 - More testing needed

    if firstClass and firstClass.status == 1 then numCancelledClasses = 1 end -- the fix for checking class ON start date

    if s.classesNishCancelled > numCancelledClasses then

        for i = 1, #dayClass do
            if  dayClass[i].name == s.name and -- this student
                D.before(y,m,d,dayClass[i].year,dayClass[i].month,dayClass[i].date) then -- its (on?? or) after next start date
                if dayClass[i].status == 1 then
                    numCancelledClasses = numCancelledClasses + 1
                else
                    firstActiveClass = dayClass[i]
                    break
                end
            end
        end

    end
    
    -- i don't think it matters if there are no classes scheduled on or after next start date
    
    step = s.classesNishCancelled - numCancelledClasses

        -- print('cancelled on or after start = '..numCancelledClasses)    
        -- print('steps = '..step)    
        -- print('next = '..d..'/'..m..'/'..y)    

    if step > 0 then
        d,m,y = nextDay(d,m,y)
--        print('day after next = '..d..'/'..m..'/'..y)    
        for i = 1, step  do
        -- find next day after next start date where either classUsuallyScheduledFor or class there
            while not(classUsuallyScheduledFor(s,d,m,y) or classOnDay(s.name,d,m,y)) do 
                d,m,y = nextDay(d,m,y) 
            end
        end
        s.postponedStartDay = d
        s.postponedStartMth = m
        s.postponedStartYr = y
    else
        -- there is no postponed start date

        s.postponedStartDay = nil
        s.postponedStartMth = nil
        s.postponedStartYr = nil
    end
    -- debug print here
    -- if step == 0 then
    --     print(s.name..' has 0 classes to postpone ')
    -- else
    --     print(s.name..' will now start on '..d..'/'..m..'/'..y)
    -- end
end

-- sets the next session start date for student passed
-- sets it to the first possible date for the next session to start
-- the actual next session start is the first active class on or after this date
-- called for all students when program loads 
-- AND called when we set a new start date for student
function setNextSessionStart(s)
    local foundClass = false

    -- 1. set to same date next month (eg 15th Jan Start => 15th Feb)

    s.nextStartDay = s.startDay
    s.nextStartMth = s.startMth + 1
    if s.nextStartMth > 12 then
        s.nextStartMth = 1
        s.nextStartYr = s.startYr + 1
    else
        s.nextStartYr = s.startYr
    end

    -- 2. if next start date > num days in month then set it to last day of month (eg 30th Jan => 28th Feb)

    if s.nextStartDay > D.get_days_in_month(s.nextStartMth, s.nextStartYr) then
        s.nextStartDay = D.get_days_in_month(s.nextStartMth, s.nextStartYr)
    end

    if s.classesNishCancelled > 0 then
        calculatePostponedStart(s)
        return -- avoid old code below
    end

    if s.classesNishCancelled > 0 then

        
-- TO DO #8 - check all below is done and working

-- BUG #1 note this is not quite right!
-- currently (4/12/2020) next start date is just set to the 1 month anniversary of start date (adjusted for days in month)
-- so student does not necessarily have class on this day
-- so if student does not have class on this day, the postponed start is just set to next day with a class
-- should be set to the day after the 1st day student has class after anniversary of start date
-- and for each cancelled class after anniversary, should reduce classesNish cancelled by 1

-- should calculate when needed as follows
-- count number cancelled classes on and after next start day until first active class
-- set 'firstActiveClass' = first active class after the next start day
-- set a variable 'step' to be classesNishCancelled - this number
-- if step > 0 then
-- set postponed class day to 'step' number of days where classUsuallyScheduledFor
-- else there are effectively no postponed classes

        s.postponedStartDay = s.nextStartDay
        s.postponedStartMth = s.nextStartMth
        s.postponedStartYr = s.nextStartYr
        for i = 1, s.classesNishCancelled do
--print('checking day '..i)            
            foundClass = false
            while not foundClass do
                s.postponedStartDay,s.postponedStartMth,s.postponedStartYr = nextDay(s.postponedStartDay,s.postponedStartMth,s.postponedStartYr)
--print(' trying = '..s.postponedStartDay..'/'..s.postponedStartMth..'/'..s.postponedStartYr)
                if classOnDay(s.name,s.postponedStartDay,s.postponedStartMth,s.postponedStartYr) then
                    foundClass = true
                elseif classUsuallyScheduledFor(s,s.postponedStartDay,s.postponedStartMth,s.postponedStartYr) then
                    foundClass = true
                end
            end
        end
    -- print('Name '..s.name..' start = '..s.startDay..'/'..s.startMth..'/'..s.startYr)
    -- print(' next start = '..s.nextStartDay..'/'..s.nextStartMth..'/'..s.nextStartYr)
    -- print(' postponed start = '..s.postponedStartDay..'/'..s.postponedStartMth..'/'..s.postponedStartYr)
    end


    -- TO DO #8 - check all following

    -- DO ALL FOLLOWING in firstClassOfSessionDue
    -- 3. if student won't have class on that date, set next start to next class after this date

    -- even though this works, it needs to be done differently because we may delete class
    -- on this day which would change the next start day
    -- OR we may insert a makeup class on a day the student is not scheduled for
    -- so when we draw classes, just highlight either the class on this date
    -- or if there is no class on this day, highlight the next class

    -- printIfDebug('Name '..s.name..' start = '..s.startDay..'/'..s.startMth..'/'..s.startYr..' next start = '..s.nextStartDay..'/'..s.nextStartMth..'/'..s.nextStartYr)

    -- while not classUsuallyScheduledFor(s.nextStartDay,s.nextStartMth,s.nextStartYr) do 
    --     s.nextStartDay,s.nextStartMth,s.nextStartYr = nextDay(s.nextStartDay,s.nextStartMth,s.nextStartYr)
    -- end

    -- printIfDebug(' next start = '..s.nextStartDay..'/'..s.nextStartMth..'/'..s.nextStartYr)

    -- 4. if Nish Cancelled n classes, set start date to next n classes after this date - CAN THIS BE DONE HERE?

end

-- adds the student passed in 'person' to the student data structure
-- ONLY called from studentData.lua
function addStudent(person)
    student[#student + 1] = person
    student[#student].numClasses = 0
    student[#student].totalPaid = 0
    -- calculate next session start date if package > 0
    -- note : student[#student].startDay = 0 means dont count class number
    -- note : student[#student].package = 0 means student is inactive
end

-- adds the memory passed to the memories data structure
-- only called from memories.lua
function addMemory(memory)
    memories[#memories + 1] = memory
end

-- adds the reminder passed to the reminders data structure
-- only called from reminderData.lua
function addReminder(reminder)
    reminders[#reminders + 1] = reminder
end

-- loads the classes in dayClass (for the 'day' passed) into the 'week' data structure for the current week
-- works out the class' width and x position depending on its slot and classes around it
-- called from createActiveWeekEvents for each day 
-- also called from writeWeek to write classData.lua
function getClasses(day, thisDate)
    week[day] = {}
    local multiple = 0
    for i = 1, #dayClass do
        if dayClass[i].year == thisDate.year and
            dayClass[i].month == thisDate.month and
            dayClass[i].delete ~= 1 and -- NEW TEST LINE
            dayClass[i].date == thisDate.day then

            -- found a class on this day add new class
            week[day][#week[day] + 1] = dayClass[i]
            -- set x and width
            local x = startX + (day - 1) * (classBoxWidth + classBoxPadX)
            local slot = week[day][#week[day]].slot -- set slot to this class' slot
            local numSlots = 1
-- assumes slots are consecutive in dayClass which wont be true if move class
-- need to write function to count all with same year, month, day, hour, min
-- this is now  ALL FIXED coz I sort after moving
            while dayClass[i + numSlots] and dayClass[i + numSlots].slot > 1 and
                dayClass[i + numSlots].hour == dayClass[i].hour     do
                numSlots = numSlots + 1 -- count all slots at this hour ?? could be better TO DO #9 - how????
            end
            numSlots = numSlots + slot - 1 -- set total number of slots at this time
            -- set the new class' width and x position (assuming only 1 class here)
            week[day][#week[day]].width = classBoxWidth
            week[day][#week[day]].x = x
            
            if numSlots > 1 and week[day][#week[day]].status > -1 then
                local newWidth = math.floor(classBoxWidth / numSlots) - 2
                week[day][#week[day]].width = newWidth
                week[day][#week[day]].x = x + ((slot - 1) * newWidth) + 2
            elseif numSlots > 1 and week[day][#week[day]].status == -1 then
                -- this is a special event not a class
                week[day][#week[day]].width = week[day][#week[day]].width - 10
            end
        end
    end
end

-- draw the tweens for the class boxes of the current week
-- called from createActiveWeekEvents
function doTweens(day)
    for class = 1, #week[day] do
        local saveY = week[day][class].y
        local saveX = week[day][class].x
        
        week[day][class].y = math.random(-200,windowWidth + 200)
        week[day][class].x = math.random(-200,windowHeight + 200) 
        Tween.create(week[day][class], "y", saveY, tweenTime, tweenType)
        Tween.create(week[day][class], "x", saveX, tweenTime, tweenType)
    end
end

-- resets the complete 'week' data structure for the active week
-- called whenever the active week changes ie next week, previous week etc
function createActiveWeekEvents()
    weekHighlights = {} -- reset week highlights
    chosenStudentData = {} -- reset chosen student data
    lastMemoryDay = 0

    local weekDay = D.currentDayOfWeek() - 1
    if weekDay == 0 then weekDay = 7 end
    local dayAdjust = (weekOffset * 7) - weekDay -- offset to Monday of the week displayed
    local thisDate = nil
    
    -- reset the daily reminders
    thisWeekReminders = {}
    currentReminderNumber = {1,1,1,1,1,1,1}
    scrollIndex = 1
    delay = 0

    for day = 1, 7 do
        dayAdjust = dayAdjust + 1
        thisDate = D.getAdjustedDate(dayAdjust)
        getClasses(day, thisDate)
        setUpReminders(day,thisDate)
        if tweensOn then doTweens(day) end
    end
end

-- sorts the dayClass table to ensure days and classes are in correct order
-- called when a new class is added AND when a class is moved
function sort_table(a,b,c,d,e,f)
    table.sort(dayClass, function(u,v)
        return
            u[a] < v[a] or
            (u[a] == v[a] and u[b] < v[b]) or
            (u[a] == v[a] and u[b] == v[b] and u[c] < v[c]) or
            (u[a] == v[a] and u[b] == v[b] and u[c] == v[c] and u[d] < v[d]) or
            (u[a] == v[a] and u[b] == v[b] and u[c] == v[c] and u[d] == v[d] and u[e] < v[e]) or
            (u[a] == v[a] and u[b] == v[b] and u[c] == v[c] and u[d] == v[d] and u[e] == v[e] and u[f] < v[f])
    end)
end

-- calculate all totals (totalDataWeeks, bestDay, bestWeek, bestMonth) from newWeekTotals
-- called from love.load
function processData()
    thisWeekNum = weekNumSinceStart(D.currentYear(), D.currentMonthNum(), D.currentDay())
    totalDataWeeks = #newWeekTotals
    for i = 1,totalDataWeeks do
        for j = 1,8 do
            if newWeekTotals[i] then 
                -- for monday to sunday
                if j < 8 then 
                    if newWeekTotals[i][j] > 0 then totalDataDays = totalDataDays + 1 end
                    if classesPerDay[newWeekTotals[i][j]] then
                        classesPerDay[newWeekTotals[i][j]] = classesPerDay[newWeekTotals[i][j]] + 1
                    end
                end
                -- for monday to sunday and '8' the week totals do this
                if newWeekTotals[i][j] > dayRecords[j] then dayRecords[j] = newWeekTotals[i][j] end
            end
        end
    end
    for i = 1, 7 do if dayRecords[i] > bestDay then bestDay = dayRecords[i] end end
    bestWeek = dayRecords[8]
    for i = startYear,D.getCalendarYear() do
        if monthTotals[i][13] > bestYear then bestYear = monthTotals[i][13] end
        for j = 1, 12 do
            if monthTotals[i][j] > bestMonth then bestMonth = monthTotals[i][j] end
        end
    end
end

function love.load()
    love.window.setMode(windowWidth*myScale, windowHeight*myScale, {resizable=true, vsync=false})
    c_lwst('Knuta Yoga')
--    c_lgsdf('nearest', 'nearest') -- ONLY DO THIS IF USING PIXEL ART
    c_mrs(os.time())
    require('studentData') -- load the studentData.lua data file
    -- NOTE - studentData must be loaded before classData

    require('classData')  -- load the classData.lua data file
    require('memories')  -- load the memories.lua data file
    require('reminderData')  -- load the reminderData.lua data file
    -- check that all images exist just for debug
    -- for i = 380,#memories do 
    --     printIfDebug('image '..i)
    --     drawMemory(memories[i],false) 
    -- end
    Asana.load()
    setAllStudentsNextSession()
    processData()
    love.keyboard.setKeyRepeat(true)
    createActiveWeekEvents()
    loadColours()
end

-- write all class data from active week to classData.lua
-- called from writeAllClasses
function writeWeek()
    local weekDay = D.currentDayOfWeek() - 1
    if weekDay == 0 then weekDay = 7 end
    local dayAdjust = (weekOffset * 7) - weekDay
    local thisDate = nil

    for day = 1, 7 do
        dayAdjust = dayAdjust + 1
        thisDate = D.getAdjustedDate(dayAdjust)
        getClasses(day, thisDate)
        for class = 1, #week[day] do

--            printIfDebug(writeLine(day,class))
            if week[day][class].delete ~= 1 then 
                fileToWrite:write(writeLine(day,class)..'\n')            
            end
        end
    end
end

-- execute key-strokes while state == classes or state == asanas
-- called from love.keypressed
function doKey(key)
--    if key == 'm' then showMemories = not showMemories end -- debug line
    if key == 'left' then
        if mouseOverClass and love.keyboard.isDown('lctrl') then
            if mouseOverClass.slot < 4 then
                mouseOverClass.slot = mouseOverClass.slot + 1
                mouseOverClass.width = classBoxWidth / mouseOverClass.slot
            end
        else
            weekOffset = weekOffset - 1
            createActiveWeekEvents()
        end
    elseif key == 'right' then
        if mouseOverClass and love.keyboard.isDown('lctrl') then
            if mouseOverClass.slot > 1 then
                mouseOverClass.slot = mouseOverClass.slot - 1
                mouseOverClass.width = classBoxWidth / mouseOverClass.slot
            end
        else
            weekOffset = weekOffset + 1
            createActiveWeekEvents()
        end
    elseif key == 'end' then
        weekOffset = 0
        createActiveWeekEvents()
    elseif key == 'home' then
        weekOffset = -thisWeekNum + 1 
        createActiveWeekEvents()
    elseif key == 'r' then
        reCalculateClassNumbers()
    -- elseif key == 't' then
    --     testPhoto = testPhoto + 1
    --     if testPhoto > #memories then testPhoto = 1 end
    -- elseif key == 'y' then
    --     testPhoto = testPhoto + 100
    --     if testPhoto > #memories then testPhoto = 1 end
    elseif key == 'up' then
        if mouseOverClass and love.keyboard.isDown('lctrl') then 
            mouseOverClass.length = math.max(15,mouseOverClass.length - 15)
            -- TO DO #11 - collisions - if no longer collides with another class change width and slot of each
            -- ALSO MUST WRITE TO dayClass ONLY if a new class
        else
            D.prevMonth() 
        end
    elseif key == 'down' then
        if mouseOverClass and love.keyboard.isDown('lctrl') then 
            mouseOverClass.length = mouseOverClass.length + 15
            -- TO DO #11 - collisions - if collides into another class change width and slot of each
            -- ALSO MUST WRITE TO dayClass ONLY if a new class
        else
            D.nextMonth() 
        end
    end
end

-- return the weeklyOffset for the passed date
-- called from writeAllClasses
function getWeekOffsetFor(d,m,y)
    local monYr,monMth,monDay = getDate(1)
    local startTime = os.time({year=y,month=m,day=d})
    local endTime = os.time({year=monYr,month=monMth,day=monDay})
    local dayDif = os.difftime(startTime,endTime) / (3600 * 24)
    local weekDif = math.abs(math.floor(dayDif / 7))
    return weekOffset - weekDif
end

-- writes the classData.lua file
-- called from writeAllData
function writeAllClasses()
 
    -- OPEN FILE    
    fileToWrite = io.open(compDir..'classData.lua', 'w')
    
    weekOffset = getWeekOffsetFor(firstDay,firstMonth,firstYear)
--printIfDebug('weekOffset = '..weekOffset..' to '..totalDataWeeks + 1)    
--weekOffset = -1000

    for i = weekOffset, totalDataWeeks + 1 do
        writeWeek()
        weekOffset = weekOffset + 1
    end
    -- CLOSE FILE    
    io.close(fileToWrite)
end

-- writes the studentData.lua file
-- called from writeAllData
function writeAllStudents()
    fileToWrite = io.open(compDir..'studentData.lua', 'w')
    for i = 1, #student do
        local line = 'addStudent{name=\''..student[i].name..'\''..
        ',package='..student[i].package..
        ',wk={'
        for j = 1, #student[i].wk do
            line = line..student[i].wk[j]
            if j < #student[i].wk then line = line .. ',' end
        end
        line = line..'}'..
        ',colour='..student[i].colour..
        ',startYr='..student[i].startYr..
        ',startMth='..student[i].startMth..
        ',startDay='..student[i].startDay..
        ',classesNishCancelled='..student[i].classesNishCancelled
        line = line..'}'
        fileToWrite:write(line..'\n')            
    end
    io.close(fileToWrite)
end

-- writes the asanaData.lua file
-- called from writeAllData
function writeAllAsanas()
    -- TO DO #12 - yup need to write asanaData.lua once we can edit asana data
end

-- returns a colour table in string format for writing to file
-- called from writeAllColours
function colourLine(colour)
    return ' = {'..colour[1]..','..colour[2]..','..colour[3]..','..colour[4]..'}'..'\n'
end

-- write all the colour setting to file
-- called from writeAllData
function writeAllColours()
    --print('write '..colourSchemeName)
    fileToWrite = io.open(compDir..colourSchemeName, 'w')
    fileToWrite:write('-- outer colour all windows'..'\n')            
    fileToWrite:write('backgroundColour'..colourLine(backgroundColour))            
    fileToWrite:write('\n')            
    fileToWrite:write('-- Classes'..'\n')            
    fileToWrite:write('classesWindowColour'..colourLine(classesWindowColour))            
    fileToWrite:write('daySummaryBoxColour'..colourLine(daySummaryBoxColour))            
    fileToWrite:write('todaySummaryBoxColour'..colourLine(todaySummaryBoxColour))            
    fileToWrite:write('\n')            
    fileToWrite:write('-- Statistics'..'\n')            
    fileToWrite:write('statisticsWindowColour'..colourLine(statisticsWindowColour))  
    fileToWrite:write('statsDataColour'..colourLine(statsDataColour))   
    fileToWrite:write('yearCalColour'..colourLine(yearCalColour))            
    fileToWrite:write('\n')            
    fileToWrite:write('-- Buttons and Graphs'..'\n')            
    fileToWrite:write('normalButtonColour'..colourLine(normalButtonColour))            
    fileToWrite:write('highlightButtonColour'..colourLine(highlightButtonColour))            
    fileToWrite:write('graphColour'..colourLine(graphColour))            
    fileToWrite:write('\n')            
    fileToWrite:write('-- Asanas'..'\n')            
    fileToWrite:write('asanasWindowColour'..colourLine(asanasWindowColour))            
    fileToWrite:write('asanaDetailsColour'..colourLine(asanaDetailsColour))            
    fileToWrite:write('asanaListColour'..colourLine(asanaListColour))            
    fileToWrite:write('highlightTextColour'..colourLine(highlightTextColour))            
    fileToWrite:write('highlightBackColour'..colourLine(highlightBackColour))            
    fileToWrite:write('englishNameColour'..colourLine(englishNameColour))            
    fileToWrite:write('linkedAsanaBoxColour'..colourLine(linkedAsanaBoxColour))            
    fileToWrite:write('classificationColour'..colourLine(classificationColour))            
    fileToWrite:write('classificationTitleColour'..colourLine(classificationTitleColour))            
    fileToWrite:write('searchClassificationTitleColour'..colourLine(searchClassificationTitleColour))            
    fileToWrite:write('searchClassificationChoicesColour'..colourLine(searchClassificationChoicesColour))            
    io.close(fileToWrite)
end

-- write all data files
-- called from love.quit
function writeAllData()
    writeAllClasses()
    writeAllStudents()
    writeAllAsanas()
    writeAllColours()
end

-- called by love2d after love.event.quit or after user closes the window
function love.quit()
    writeAllData()
end

-- called by love2d when a key is pressed
function love.keypressed(key)
    if not Tween.noTweens() then return end -- wait for tweens to finish
    if key == 'escape' then 
        if state == statistics then
            state = classes
        elseif state == asanas then
            state = classes
        else
--            writeAllData() -- dont need coz leq calls love.quit
            c_leq() -- this calls love.quit
        end
    elseif key >= '1' and key <= '7' and chosenStudent then 
        editWeekDays(tonumber(key))
    end
    if state == classes then doKey(key)
    elseif state == asanas then Asana.doKey(key)
    end
end

-- draws the basic background for the 'classes' screen
-- called from love.draw
function showClassesWindow()
    c_lgsc(classesWindowColour)
    c_lgr('fill',20,20,windowWidth - 40, windowHeight - 40)
    c_lgsc(textColour)
end

-- draws the basic background for the 'statistics' screen
-- called from love.draw
function showStatsWindow()
    c_lgsc(statisticsWindowColour)
    c_lgr('fill',20,20,windowWidth - 40, windowHeight - 40)
    c_lgsc(statisticsTextColour)
end

-- adjusts the colour value up and down by either 0.1 or 0.01 depending on the position of the click
-- called from changeTheColours
function changeOneColour(mx,my,x,y,colourTbl,idx)
    local rounded = 0
    if U.mouse_in_rect(mx, my, x, y, 10, 15) then
        rounded = math.floor((colourTbl[idx] - 0.1) * 100 + 0.5) / 100
        colourTbl[idx] = math.max(0,rounded)
    elseif U.mouse_in_rect(mx, my, x+10, y, 10, 15) then
        rounded = math.floor((colourTbl[idx] - 0.01) * 100 + 0.5) / 100
        colourTbl[idx] = math.max(0,rounded)
    elseif U.mouse_in_rect(mx, my, x+20, y, 10, 15) then
        colourTbl[idx] = math.min(1,colourTbl[idx] + 0.01)
    elseif U.mouse_in_rect(mx, my, x+30, y, 10, 15) then
        colourTbl[idx] = math.min(1,colourTbl[idx] + 0.1)
    end
end

-- adjusts the colour values for all the editable colours and allows changing of colour themes
-- called from love.mousepressed
function changeTheColours(mx,my)
    if U.mouse_in_rect(mx, my, colourWindowxPos+55+50,colourWindowyPos+310,40,15) and theme ~= 1 then 
        theme = 1 
        loadColours()
    end
    if U.mouse_in_rect(mx, my, colourWindowxPos+55+100,colourWindowyPos+310,40,15) and theme ~= 2 then 
        theme = 2
        loadColours()
    end
    if U.mouse_in_rect(mx, my, colourWindowxPos+55+150,colourWindowyPos+310,40,15) and theme ~= 3 then 
        theme = 3 
        loadColours()
    end
    if U.mouse_in_rect(mx, my, colourWindowxPos+55+200,colourWindowyPos+310,40,15) and theme ~= 4 then 
        theme = 4 
        loadColours()
    end
    for i = 1, 4 do 
        changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 50, backgroundColour,i) 
        if state == classes then
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 70, classesWindowColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 90, daySummaryBoxColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 110, todaySummaryBoxColour,i)
        elseif state == statistics then 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 70, statisticsWindowColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 90, statsDataColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 110, yearCalColour,i) 
        elseif state == asanas then 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 70, asanasWindowColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 90, asanaDetailsColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 110, asanaListColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 130, highlightTextColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 150, highlightBackColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 170, englishNameColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 190, linkedAsanaBoxColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 210, classificationColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 230, classificationTitleColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 250, searchClassificationChoicesColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 270, searchClassificationTitleColour,i) 
        end
        if state ~= asanas then
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 150, normalButtonColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 170, highlightButtonColour,i) 
            changeOneColour(mx, my, colourWindowxPos + 55 + (i * 50), colourWindowyPos + 190, graphColour,i) 
        end
    end
end

-- returns true if mouse button 1 was clicked inside the button passed
-- called from doClassMouseClicks and doStatsMouseClicks
function clicked(btn,mx,my,mouseButton)
    return mouseButton == 1 and U.mouse_in_rect(mx, my,btn.x,btn.y,btn.w,btn.h)
end

-- deals with mouse clicks when state is 'classes'
-- called from love.mousepressed
function doClassMouseClicks(mx, my, button)
    -- old status change code - not used
    if button == 2 and U.mouse_in_rect(mx, my, startX, startY, 7 * (classBoxWidth + classBoxPadX), numEvents * (classBoxHeight + classBoxPadY)) then
        rightMouseClicked = not rightMouseClicked
--printIfDebug('Change Status when on class')                
        if rightMouseClicked then
-- adjust when scaled            
            mouseStartX,mouseStartY = getScaledMousePos() --love.mouse.getPosition()
        else
            mouseStartX,mouseStartY = 0,0
        end
    end

    -- clear chosenStudent
    if not changingColours and clicked(buttons.clearChosenStudent,mx,my,button) then
        chosenStudent = nil
        showFinancialInfo = saveShowMoney
        weekHighlights = {} -- so that highlights refresh
        chosenStudentData = {} -- reset chosen student data
        
    -- toggle animations (scrolling text and tweens)        
    elseif clicked(buttons.animations,mx,my,button) then
        scrolling = not scrolling
        tweensOn = not tweensOn

    -- edit weekly student pattern done in settingWeekPattern
    elseif button == 1 and chosenStudent and settingWeekPattern(mx,my) then
    -- edit weekly student package done in settingWeekPackage
    elseif button == 1 and chosenStudent and settingWeekPackage(mx,my) then
    -- pick student for new classes, or to edit student (note can't use 'clicked' because maxStudentY is dynamically set)
    elseif button == 1 and not changingColours and U.mouse_in_rect(mx, my, studentNamesX, studentNamesY, 305, maxStudentY - studentNamesY) then
        pickStudent(mx,my)

    -- click on class to move it
    -- disabled when chosen student .. maybe should enable here but disable in drawClass TO DO #13 - why did I write this?
    elseif not chosenStudent and clicked(buttons.classArea,mx,my,button) then
        leftMouseClicked = not leftMouseClicked
        if leftMouseClicked then
            -- adjust when scaled            
            mouseStartX,mouseStartY = getScaledMousePos() --love.mouse.getPosition()
        else
            if movingClass then
                movingClass = false
                moveTheClass = true
            end
        end
    -- previous month on month calendar
    elseif clicked(buttons.prevMonth,mx,my,button) then D.prevMonth()
    -- next month on month calendar
    elseif clicked(buttons.nextMonth,mx,my,button) then D.nextMonth()
    -- previous week of classes
    elseif clicked(buttons.prevWeek,mx,my,button) then 
        weekOffset = weekOffset - 1
        createActiveWeekEvents()
    -- next week of classes
    elseif clicked(buttons.nextWeek,mx,my,button) then
        weekOffset = weekOffset + 1
        createActiveWeekEvents()

    -- change daily reminder text number 1 = monday, 7 = sunday
    elseif clicked(buttons.reminderMon,mx,my,button) then changeReminderNumber(1)
    elseif clicked(buttons.reminderTue,mx,my,button) then changeReminderNumber(2)
    elseif clicked(buttons.reminderWed,mx,my,button) then changeReminderNumber(3)
    elseif clicked(buttons.reminderThu,mx,my,button) then changeReminderNumber(4)
    elseif clicked(buttons.reminderFri,mx,my,button) then changeReminderNumber(5)
    elseif clicked(buttons.reminderSat,mx,my,button) then changeReminderNumber(6)
    elseif clicked(buttons.reminderSun,mx,my,button) then changeReminderNumber(7)
    -- change to current week of classes
    elseif clicked(buttons.thisWeek,mx,my,button) then
        weekOffset = 0
        createActiveWeekEvents()

    -- toggle financial year / calendar Year
    elseif clicked(buttons.gotoAsanas,mx,my,button) then state = asanas
    -- toggle show all student display
    elseif clicked(buttons.allStudents,mx,my,button) then showAllStudents = not showAllStudents
    -- toggle financial totals display
    elseif clicked(buttons.financialInfo,mx,my,button) then
        showFinancialInfo = not showFinancialInfo
    -- add a new week
    elseif not chosenStudent and clicked(buttons.newWeek,mx,my,button) then
        addNewWeek()
        reCalculateClassNumbers()
    -- change to statistics window
    elseif clicked(buttons.showStats,mx,my,button) then
        state = statistics
    elseif button == 1 and chosenStudent and settingPayment(mx,my) then
        local setClass = chosenStudentData[setPaymentLine]
--        print('Setting payment on '..setClass.dayNum..' '..setClass.day..' '..setClass.date..'/'..setClass.month..'/'..setClass.year..' for '..chosenStudent)
        setPayment(setClass)
        chosenStudentData = {} -- reset chosen student data to show change
    elseif button == 1 and chosenStudent and settingStart(mx,my) then
        local setClass = chosenStudentData[setStartLine]
--        print('Setting start on '..setClass.dayNum..' '..setClass.day..' '..setClass.date..'/'..setClass.month..'/'..setClass.year..' for '..chosenStudent)
        setStartSession(setClass)       
        chosenStudentData = {} -- reset chosen student data to show change
    end
end

-- sets the payment for the class to the amount set in settingPayment
-- and ensures it is also updated in dayClass
-- called from doClassMouseClicks
function setPayment(setClass)
    local lastPaid = 0
    local classIndex = 0
    showFinancialInfo = true

    -- find student in classNumbers and get lastPaid
    for i = 1, #classNumbers do
          if classNumbers[i].studentName == chosenStudent.name then
            for j = 1, #classNumbers[i].classList do
                local thisOne = classNumbers[i].classList[j]
                if thisOne.paid > 0 then lastPaid = thisOne.paid end
            end
        end
    end

    for class = 1, #week[setClass.dayNum] do
        local thisClass = week[setClass.dayNum][class]
        if thisClass.name == chosenStudent.name and thisClass.hour == setClass.hour then
            if thisClass.paid > 0 then
                thisClass.paid = thisClass.paid + payAdjustAmount
            else
                thisClass.paid = lastPaid
            end
--print('updating payment for '..chosenStudent.name..' to '..thisClass.paid)            
            -- update in dayClass
            updatePaid(thisClass)
            -- update startYr, startMth, startDay in student (studentData.lua)
        end
    end
end

-- count postponed classes after setting student current session start date
-- called from setStartSession
function resetPostponedClasses()
    local numPostponed = 0
    if chosenStudent then
        for i = 1, #dayClass do
            if  dayClass[i].name == chosenStudent.name and 
                D.before(chosenStudent.startYr,chosenStudent.startMth,chosenStudent.startDay,
                        dayClass[i].year,dayClass[i].month,dayClass[i].date) then
                    if dayClass[i].status == 2 then numPostponed = numPostponed + 1 end
            end
        end
    end
    chosenStudent.classesNishCancelled = numPostponed
end

-- sets class=1 in week[day][class] and then in dayClass (using updateNewClassNum(thisClass)) 
-- also set start date in student (studentData.lua)
-- called from doClassMouseClicks
function setStartSession(setClass)
--    print('day is ........'..setClass.dayNum)
    for class = 1, #week[setClass.dayNum] do
        local thisClass = week[setClass.dayNum][class]
        if thisClass.name == chosenStudent.name and thisClass.hour == setClass.hour then
            thisClass.class = 1
            thisClass.tempClass = nil
--            thisClass.pkg = student[i].package -- FIXED CRASH - REMOVED THIS 15/12/2020 it was below and needs to be below

            -- update startYr, startMth, startDay in student (studentData.lua)
            for i = 1,#student do
                if student[i].name == chosenStudent.name then 
                    -- set pkg in thisClass 
                    thisClass.pkg = student[i].package
                    -- set class and pkg in in dayClass
                    updateNewClassNum(thisClass)
                    -- if its the current session then set new session start, check postponed classes and set next session start
                    if D.before(student[i].startYr,student[i].startMth,student[i].startDay,
                            setClass.year,setClass.month,setClass.date) then
                        student[i].startYr = setClass.year
                        student[i].startMth = setClass.month
                        student[i].startDay = setClass.date
                        -- set classesNishCancelled to number cancelled after new start date
                        resetPostponedClasses()
                        -- then call setNextSessionStart() -- to set start of session after this one
                        setNextSessionStart(student[i])
                        break
                    end
                end
            end
            reCalculateClassNumbers(chosenStudent.name)
        end
    end
end

-- edits the payment amount if mouse is clicked on payment button (adds and subtracts 500 or 1000)
-- called from doClassMouseClicks
function settingPayment(mx,my)
    local editStartX = startX
    for i = 1, #chosenStudentData do
        -- change done to allow 2 columns after i == 5 .. 1 + (i - 1) % 5
        if i == 6 then editStartX = startX + 480 end
        if U.mouse_in_rect(mx, my, editStartX+3*(editButtonWidth + editButtonXGap), editStartLine + (1 + (i - 1) % 5) * editLineIncrement, editButtonWidth, editButtonHeight) then
            setPaymentLine = i
            if mx < editStartX + 3 * (editButtonWidth + editButtonXGap) + editButtonWidth / 4 then payAdjustAmount = -1000
            elseif mx < editStartX + 3 * (editButtonWidth + editButtonXGap) + editButtonWidth / 2 then payAdjustAmount = -500
            elseif mx > editStartX + 3 * (editButtonWidth + editButtonXGap) + editButtonWidth - editButtonWidth / 4 then payAdjustAmount = 1000
            elseif mx > editStartX + 3 * (editButtonWidth + editButtonXGap) + editButtonWidth / 2 then payAdjustAmount = 500
            end
            return true
        end
    end
    setPaymentLine = 0
    return false
end

-- sets the class as class 1 of session if mouse is clicked on specific class
-- called from doClassMouseClicks
function settingStart(mx,my)
    local editStartX = startX
    for i = 1, #chosenStudentData do
        if i == 6 then editStartX = startX + 480 end
        if U.mouse_in_rect(mx, my, editStartX + 4 * (editButtonWidth + editButtonXGap), editStartLine + (1 + (i - 1) % 5) * editLineIncrement, editButtonWidth, editButtonHeight) then
            setStartLine = i
            return true
        end
    end
    setStartLine = 0
    return false
end

-- sets the weekly class pattern for the student being edited
-- called from doClassMouseClicks
function settingWeekPattern(mx,my)
    for i = 1, 7 do
        if U.mouse_in_rect(mx, my, weekTblX + (i - 1) * 30, buttons.clearChosenStudent.y + 25, 25, 15) then
            editWeekDays(i)
            return true
        end
    end
    return false
end

-- sets the student's chosen package for the student being edited
-- called from doClassMouseClicks
function settingWeekPackage(mx,my)
    if U.mouse_in_rect(mx, my, buttons.editPackage.x, buttons.editPackage.y, buttons.editPackage.w, buttons.editPackage.h) then
        editPackage()
        chosenStudentData = {} -- reset chosen student data to show change
        reCalculateClassNumbers(chosenStudent.name)
        return true
    end
    return false
end

-- deals with mouse clicks when state is 'statistics'
-- called from love.mousepressed
function doStatsMouseClicks(mx, my, button)
--     -- previous month on month calendar
    if clicked(buttons.prevMonth,mx,my,button) then D.prevMonth()
    -- next month on month calendar
    elseif clicked(buttons.nextMonth,mx,my,button) then D.nextMonth()
    -- previous year on year calendar
    elseif clicked(buttons.prevYear,mx,my,button) then
        if monthTotals[yearCalYear - 1] then yearCalYear = yearCalYear - 1 end
    -- next year on year calendar
    elseif clicked(buttons.nextYear,mx,my,button) then
        if monthTotals[yearCalYear + 1] then yearCalYear = yearCalYear + 1 end
    -- toggle financial year / calendar Year
    elseif clicked(buttons.financialYearToggle,mx,my,button) then
        financialYear = not financialYear
    elseif clicked(buttons.financialInfo,mx,my,button) then
        showFinancialInfo = not showFinancialInfo
    elseif clicked(buttons.showStats,mx,my,button) then
        state = classes 
    end
end

-- called from love2d whenever a mouse button is pressed
function love.mousepressed(mx, my, button)
    if not chosenStudent and state ~= asanas then
        if clicked(buttons.changeColours, mx/myScale, my/myScale, button) then
            changingColours = not changingColours
    -- change colours
        elseif button == 1 and changingColours then
            changeTheColours(mx/myScale,my/myScale)
        end
    end
    if state == classes then doClassMouseClicks(mx/myScale, my/myScale, button) 
    elseif state == statistics then doStatsMouseClicks(mx/myScale, my/myScale, button)
    elseif state == asanas then Asana.doMouseClicks(mx/myScale, my/myScale, button)
    end
end

-- updates dayClass with selected name after adding class when it's name is set to 'new class'
-- called from drawWeek
function updateNewName(thisClass)
    for i = 1, #dayClass do
        if dayClass[i].year == thisClass.year and
            dayClass[i].month == thisClass.month and
            dayClass[i].date == thisClass.date and
            dayClass[i].name == 'new class' then
                dayClass[i].name = selectedStudentName
        end
    end
end

-- updates dayClass with class number when setting class number of chosen student
-- called from drawClass when status changes to and fom active, 
-- also called from setStartSession when package is set for chosen student
function updateNewClassNum(thisClass)
    for i = 1, #dayClass do
        if dayClass[i].year == thisClass.year and
            dayClass[i].month == thisClass.month and
            dayClass[i].date == thisClass.date and
            dayClass[i].hour == thisClass.hour and
            dayClass[i].name == thisClass.name then
                dayClass[i].class = thisClass.class
                dayClass[i].pkg = thisClass.pkg
        end
    end
end

-- updates dayClass with amount paid when setting amount paid of chosen student
-- called from setPayment
function updatePaid(thisClass)
    for i = 1, #dayClass do
        if dayClass[i].year == thisClass.year and
            dayClass[i].month == thisClass.month and
            dayClass[i].date == thisClass.date and
            dayClass[i].hour == thisClass.hour and
            dayClass[i].name == thisClass.name then
                dayClass[i].paid = thisClass.paid
        end
    end
end

-- returns the number of weeks ahead of the current week on which there are no classes
-- called from addNewWeek
function findFirstFreeWeek()
    local numWeeksAhead = 0
    local weekNum = thisWeekNum + weekOffset
    while newWeekTotals[weekNum] and newWeekTotals[weekNum][9] > 0 do 
        weekNum = weekNum + 1
        numWeeksAhead = numWeeksAhead + 1
    end
    return numWeeksAhead
end

--[[
-- returns true if a class is found on the monday identified by the offset passed
-- called from addNewWeek
-- NOTE should change this to check if any classes in the whole week!!
-- should check totals for this week in newWeekTotals - DONE
-- THIS FUNCTION IS REPLACED BY findFirstFreeWeek and NO LONGER USED
function classesOnMonday(offset)
    local checkDate = D.getAdjustedDate(offset)
    for i = 1, #dayClass do
        if dayClass[i].year == checkDate.year and
            dayClass[i].month == checkDate.month and
            dayClass[i].date == checkDate.day then
                return true
        end
    end
    return false
end
]]

-- adds a new week of classes into database by adding classes from the current week
-- to the first week with no classes
-- called from doClassMouseClicks
function addNewWeek()
    local weekDay = D.currentDayOfWeek() - 1
    if weekDay == 0 then weekDay = 7 end
    local readDay = (weekOffset * 7) - weekDay -- offset to day before Monday of the week displayed
    local readDate, writeDate = nil, nil
    local offsetToNextFreeMonday = findFirstFreeWeek() * 7
    local writeDay = readDay + offsetToNextFreeMonday

    local newYear, newMonth, newDay = 0,0,0
    local newClass = {}
    
    local newWeekNum = thisWeekNum + weekOffset + offsetToNextFreeMonday/7

    totalDataWeeks = totalDataWeeks + 1

    for day = 1, 7 do
        -- readDay = readDay + 1
        -- readDate = D.getAdjustedDate(readDay)
        writeDay = writeDay + 1
        writeDate = D.getAdjustedDate(writeDay)
        for class = 1, #week[day] do
            if week[day][class].delete == 1 then break end -- NEW TEST LINE
            -- add to totals     
            if week[day][class].status ~= -1 then
                totalNumClasses = totalNumClasses + 1
                if monthTotals[writeDate.year] then
                    monthTotals[writeDate.year][writeDate.month] = monthTotals[writeDate.year][writeDate.month] + 1
                    monthTotals[writeDate.year][13] = monthTotals[writeDate.year][13] + 1
                end
                -- add to week totals
                -- if weekTotals[newWeekNum] == nil then weekTotals[newWeekNum] = 0 end
                -- weekTotals[newWeekNum] = weekTotals[newWeekNum] + 1
                -- same thing using newWeekTotals
                if newWeekTotals[newWeekNum] == nil then newWeekTotals[newWeekNum] = {0,0,0,0,0,0,0,0,0} end 
                newWeekTotals[newWeekNum][day] = newWeekTotals[newWeekNum][day] + 1
                newWeekTotals[newWeekNum][8] = newWeekTotals[newWeekNum][8] + 1
            end
            -- add to all classes week total (no matter what status)
            if newWeekTotals[newWeekNum] == nil then newWeekTotals[newWeekNum] = {0,0,0,0,0,0,0,0,0} end 
            newWeekTotals[newWeekNum][9] = newWeekTotals[newWeekNum][9] + 1

            dayClass[#dayClass + 1] = {}
            newClass = dayClass[#dayClass]
            newClass.year = writeDate.year
            newClass.month = writeDate.month
            newClass.date = writeDate.day
            newClass.hour = week[day][class].hour
            newClass.min = week[day][class].min
            newClass.slot = week[day][class].slot
            newClass.length = week[day][class].length
            newClass.name = week[day][class].name
            if week[day][class].status ~= -1 then
                newClass.status = 0
            else
                newClass.status = -1
            end
            newClass.paid = 0
            newClass.y = startY + 
                        (dayClass[#dayClass].hour - startHour) * (classBoxHeight + classBoxPadY) + 
                        math.floor(classBoxHeight / 4) * math.floor(dayClass[#dayClass].min / 15)            
        end
    end
    weekOffset = weekOffset + offsetToNextFreeMonday/7
    createActiveWeekEvents()
end

-- adds a new 'blank' class where the mouse is clicked with the student name 'new class'
-- called from love.update
function addNewClass()
    addingNewStudent = true
    showAllStudents = true
    selectedStudentName = ''
    local weekDay = D.currentDayOfWeek() - 1
    if weekDay == 0 then weekDay = 7 end
    local dayAdjust = (weekOffset * 7) - weekDay
  
-- adjust when scaled            
    local mx,my = getScaledMousePos() --love.mouse.getPosition()
    local xPos = nearestSlotX(mx)
    local yPos,newHour,newMinute = nearestSlotY(my)

    for i = 1, #positionsX do
        if xPos < positionsX[i] then 
            xPos = positionsX[i-1]; 
            newDay = i - 1
            break 
        end
        newDay = 7
    end

    dayAdjust = dayAdjust + newDay
    local thisDate = D.getAdjustedDate(dayAdjust)

    table.insert(week[newDay],{
        year = thisDate.year,
        month = thisDate.month,
        date = thisDate.day,
        hour = newHour,
        min = newMinute,
        slot = 1,
        length = 60,
        name = 'new class',
        status = 0,
        paid = 0,
        x = xPos,
        y = yPos,
        width = classBoxWidth
    })
    addClass({
        year = thisDate.year,
        month = thisDate.month,
        date = thisDate.day,
        hour = newHour,
        min = newMinute,
        slot = 1,
        length = 60,
        name = 'new class',
        status = 0,
        paid = 0
    })
end

-- enables user to click on a student name to select it
-- if adding a new class, the selected student name will be assigned to selectedStudentName 
-- selectedStudentName name will later replace 'new class' in all new classes
-- if not adding a new student, the selected student will be assigned to chosenStudent
-- then chosenStudent will be editable
-- called from doClassMouseClicks
function pickStudent(mx,my)
    for i = 1, #student do
--        if student[i].package > 0 then 
--printIfDebug('student '..student[i].name)            
            if mx >= student[i].x and mx <= student[i].x + 95 and my >= student[i].y and my <= student[i].y + 20 then
                if addingNewStudent then 
                    addingNewStudent = false -- NOV 27th to fix cant edit student after adding
                    selectedStudentName = student[i].name
                else 
                    chosenStudent = student[i]
                    saveShowMoney = showFinancialInfo
                    weekHighlights = {} -- so that highlights refresh
                    chosenStudentData = {} -- reset chosen student data
                end
                showAllStudents = false
                break
            end
--        end
    end
end

-- returns year,month,day of the day number 'day' of the active week
-- called from showMemory, and from getWeekOffsetFor
function getDate(day)
    -- uses weekoffset and day to return date
    local weekDay = D.currentDayOfWeek() - 1
    if weekDay == 0 then weekDay = 7 end
    local dayAdjust = weekOffset * 7 - weekDay + day
    local hoverDate = D.getAdjustedDate(dayAdjust)
--    printIfDebug('month = '..hoverDate.month..' date = '..hoverDate.day)
    return hoverDate.year,hoverDate.month,hoverDate.day
end

-- draws the image passed in pic
-- called from showMemory
function drawMemory(pic,exact, count)
    c_lgsc(white)
-- printIfDebug('image gfx/NA/'..pic.img)    
    local currentImage = c_lgni('gfx/NA/'..pic.img)
    local scale = math.min(300/currentImage:getWidth(),300/currentImage:getHeight())
    local currentImageX = 180 - currentImage:getWidth()*scale/2
    local currentImageW = currentImage:getWidth()*scale
    local currentImageH = currentImage:getHeight()*scale
    c_lgd(currentImage, currentImageX, 420, 0, scale, scale)
    local heartImage = c_lgni('gfx/NA/heart small.png')
    c_lgd(heartImage, 160, 420 + currentImageH + 50)

    c_lgsc(textColour)
    local words = ''
    if exact then words = 'On this day: ('..count..') ' end
    c_lgpf(words..pic.msg,currentImageX,420 + currentImageH + 10,currentImageW,'center')
    collectgarbage("collect")
end

-- if the mouse is over the day summary box it will select a memory picture to display
-- called from love.draw
function showMemory(day)
    if not Tween.noTweens() then return end -- NEEDED
    foundMemoryDate = {}
    if memoryDay == 0 then return end
    local mx,my = getScaledMousePos()
    if not (mx > startX and mx < startX + (8 - 1) * (classBoxWidth + classBoxPadX) and my > dayY and my < dayY + daySummaryBoxHeight) then
        memoryDay = 0
        lastMemoryDay = 0
--        printIfDebug('NOT OVER A MEMORY 2')
    end
    if memoryDay == 0 then return end
    if not showMemories then return end
    local yr, mth, date = getDate(day)
    if memoryDay ~= lastMemoryDay then 
        exactMemory = false
        numFoundMemories = 0
            --get a new memory
        for i = 1, #memories do -- if we haven't moved, dont' look again, just use same one! ie only if last is dif from this
            if memories[i].month == mth and memories[i].date == date then 
                foundMemoryDate[#foundMemoryDate + 1] = i
--printIfDebug('date = '..date..' i = '..i)                
            end
        end
        if #foundMemoryDate > 0 then
            exactMemory = true
        --            printIfDebug('FOUND DATE')
            randomMemory = foundMemoryDate[math.random(#foundMemoryDate)]
-- printIfDebug('random memory = '..randomMemory)    
            numFoundMemories = #foundMemoryDate
            drawMemory(memories[randomMemory],exactMemory, numFoundMemories) 
            lastMemoryDay = memoryDay
            return
        end
    end
    if memoryDay ~= lastMemoryDay then 
        randomMemory = math.random(#memories)
        lastMemoryDay = memoryDay
    end
    if randomMemory > 0 then 
        if #foundMemoryDate == 0 then drawMemory(memories[randomMemory],exactMemory, numFoundMemories) end
    else 
        printIfDebug('ERROR') 
    end
end

-- updates the time and deals with checking for memories to display, and also adding new class 
-- called 60 time pre second from love2D
function love.update(dt)
--    if dt > 0.035 then return end -- THIS WAS STOPPING MEMORY DISPLAY
    local now = os.date('*t')
    delay = delay + dt
    if delay > 0.15 then
        delay = 0
        scrollIndex = scrollIndex + 1
    end
    currentMonth = now.month
    currentDate = now.day
    currentHour = now.hour
    currentMinute = now.min
    Tween.update(dt)
    if state == asanas then 
        Asana.update(dt)

    elseif state == classes then 
        if mouseOver(startX + (1 - 1) * (classBoxWidth + classBoxPadX), dayY, classBoxWidth + classBoxPadX - 1, daySummaryBoxHeight) then
            memoryDay = 1 -- boolean if memoryDay changed then updateMemory
--            printIfDebug('monday '..dt)
        elseif mouseOver(startX + (2 - 1) * (classBoxWidth + classBoxPadX), dayY, classBoxWidth + classBoxPadX - 1, daySummaryBoxHeight) then
            memoryDay = 2
        elseif mouseOver(startX + (3 - 1) * (classBoxWidth + classBoxPadX), dayY, classBoxWidth + classBoxPadX - 1, daySummaryBoxHeight) then
            memoryDay = 3
        elseif mouseOver(startX + (4 - 1) * (classBoxWidth + classBoxPadX), dayY, classBoxWidth + classBoxPadX - 1, daySummaryBoxHeight) then
            memoryDay = 4
        elseif mouseOver(startX + (5 - 1) * (classBoxWidth + classBoxPadX), dayY, classBoxWidth + classBoxPadX - 1, daySummaryBoxHeight) then
            memoryDay = 5
        elseif mouseOver(startX + (6 - 1) * (classBoxWidth + classBoxPadX), dayY, classBoxWidth + classBoxPadX - 1, daySummaryBoxHeight) then
            memoryDay = 6
        elseif mouseOver(startX + (7 - 1) * (classBoxWidth + classBoxPadX), dayY, classBoxWidth + classBoxPadX - 1, daySummaryBoxHeight) then
            memoryDay = 7
        elseif memoryDay > 0 then
            memoryDay = 0
            lastMemoryDay = 0
--            printIfDebug('NOT OVER MEMORY 1')
--            randomMemory = 0
        end
        if leftMouseClicked and not overAnyStudent and not movingClass then
            addNewClass()
--printIfDebug('adding new class')            
            sort_table("year","month","date","hour","min","slot") -- this is good, ensures it all works
            leftMouseClicked = false
        -- doing the following instead of in draw - nope, it seems hard
        -- elseif leftMouseClicked and mouseOverClass and mouseOverClass.status > -1 then
        --     mouseOverClass.status = mouseOverClass.status + 1
        --     if mouseOverClass.status > 2 then mouseOverClass.status = 0 end
        --     leftMouseClicked = false    
        end 
    end          
end

-- draws the year totals for the active calendar year (or financial year)
-- called from love.draw
function drawYearGrid()
    -- display arrows to change years
    showButton(buttons.prevYear,'<')
    showButton(buttons.nextYear,'>')

    c_lgsc(yearCalColour)
    c_lgr('fill',yearCalX,yearCalY,270,200)

    local saveWidth = c_lgglw()
    local monthWidth = 90
    local monthHeight = 50
    c_lgslw(1)
    c_lgsc(gridLineColour)
    for i = 1, 5 do
        c_lgl(yearCalX, yearCalY + (i - 1) * monthHeight, yearCalX + 3 * monthWidth, yearCalY + (i - 1) * monthHeight)
    end
    for i = 1, 4 do
        c_lgl(yearCalX + (i - 1) * monthWidth, yearCalY, yearCalX + (i - 1) * monthWidth, yearCalY + 4 * monthHeight)
    end

    -- draw the year or financial year period
    c_lgsc(statisticsTextColour)
    if financialYear then
        c_lgpf(yearCalYear..' - '..yearCalYear + 1,yearCalX + 70,yearCalY - 20, monthWidth - 10, 'center')
    else
        c_lgpf(yearCalYear,yearCalX + 70,yearCalY - 20, monthWidth - 10, 'center')
    end
    
    -- draw the total classes for the year or financial year
    if financialYear then
        local totalClasses = 0
        for i = 4,12 do totalClasses = totalClasses + monthTotals[yearCalYear][i] end
        if monthTotals[yearCalYear + 1] then
            for i = 1,3 do totalClasses = totalClasses + monthTotals[yearCalYear + 1][i] end
        end
        c_lgp(totalClasses,yearCalX + 10,yearCalY - 20)
    else
        c_lgp(monthTotals[yearCalYear][13],yearCalX + 10,yearCalY - 20)
    end
    
    -- draw the total takings for the year or financial year
    if showFinancialInfo then
        if financialYear then
            local totalTakings = 0
            for i = 4,12 do 
                if yearTakingsTotals[yearCalYear][i] then
                    totalTakings = totalTakings + yearTakingsTotals[yearCalYear][i] 
                end
            end
            if yearTakingsTotals[yearCalYear + 1] then
                for i = 1,3 do totalTakings = totalTakings + yearTakingsTotals[yearCalYear + 1][i] end
            end
            c_lgp(rupees(totalTakings),yearCalX + 185,yearCalY - 20)
        else
            c_lgp(rupees(yearTakingsTotals[yearCalYear][13]),yearCalX + 185,yearCalY - 20)
        end
    end
    
    c_lgsc(yearCalTextColour)
    -- draw the total monthly class and takings for the year or financial year
    for i = 1, 12 do
        -- draw the month names
        local monthNum = i
        y = yearCalY + 1 + (math.floor((i + 2) / 3) - 1) * (monthHeight)
        if financialYear then monthNum = 1 + (i + 2) % 12 end
        c_lgpf(D.monthName(monthNum), yearCalX + monthWidth * ((i - 1) % 3), y, monthWidth, 'center')

        if financialYear then 
            if i < 4 then
                y = yearCalY + 1 + (math.floor((i + 2) / 3) + 2) * (monthHeight)
            else
                y = yearCalY + 1 + (math.floor((i + 2) / 3) - 2) * (monthHeight)
            end
        end

        if monthTotals[yearCalYear] then
            if financialYear then
                if i < 4 then
                    if monthTotals[yearCalYear + 1] then
                        c_lgpf(monthTotals[yearCalYear + 1][i],yearCalX + monthWidth * ((i - 1) % 3), y+15, monthWidth, 'center')
                    end
                else
                    c_lgpf(monthTotals[yearCalYear][i],yearCalX + monthWidth * ((i - 1) % 3), y+15, monthWidth, 'center')
                end
            else
                c_lgpf(monthTotals[yearCalYear][i],yearCalX + monthWidth * ((i - 1) % 3), y+15, monthWidth, 'center')
            end

            if showFinancialInfo then
                if financialYear then
                    if i < 4 then
                        if yearTakingsTotals[yearCalYear + 1] then
                            c_lgpf(rupees(yearTakingsTotals[yearCalYear + 1][i]),yearCalX + monthWidth * ((i - 1) % 3), y+30, monthWidth, 'center')
                        end
                    else
                        if yearTakingsTotals[yearCalYear][i] then
                            c_lgpf(rupees(yearTakingsTotals[yearCalYear][i]),yearCalX + monthWidth * ((i - 1) % 3), y+30, monthWidth, 'center')
                        end
                    end
                else
                    if yearTakingsTotals[yearCalYear][i] then
                        c_lgpf(rupees(yearTakingsTotals[yearCalYear][i]),yearCalX + monthWidth * ((i - 1) % 3), y+30, monthWidth, 'center')
                    end
                end
            end
        end
    end
    c_lgslw(saveWidth)
end

-- draws the grid for displaying classes
-- called from love.draw
function drawDayGrid()
    local saveWidth = c_lgglw()
    c_lgslw(1)
    for i = 1, numEvents + 1 do
        local hour = i + startHour - 1
        if hour < 12 then
            c_lgp(hour .. ' AM', startX - 50, startY - 5 + (i - 1) * (classBoxHeight + classBoxPadY))
        elseif hour == 12 then
            c_lgp(hour .. ' PM', startX - 50, startY - 5 + (i - 1) * (classBoxHeight + classBoxPadY))
        else
            c_lgp(hour - 12 .. ' PM', startX - 50, startY - 5 + (i - 1) * (classBoxHeight + classBoxPadY))
        end
    end
    c_lgsc(gridLineColour)
    for i = 1, numEvents + 1 do
        c_lgl(startX, startY + (i - 1) * (classBoxHeight + classBoxPadY), startX + 7 * (classBoxWidth + classBoxPadX), startY + (i - 1) * (classBoxHeight + classBoxPadY))
    end
    for i = 1, 8 do
        c_lgl(startX + (i - 1) * (classBoxWidth + classBoxPadX), startY, startX + (i - 1) * (classBoxWidth + classBoxPadX), startY + numEvents * (classBoxHeight + classBoxPadY))
    end
    c_lgsc(textColour)
    c_lgslw(saveWidth)
end

-- returns the colour index for the student who's name is 'name' passed, if not found returns 0
-- called from drawClass
function getStudentColour(name) 
    for i = 1, #student do
        if student[i].name == name then return student[i].colour end
    end
    return 0 
end

-- TO DO #16 - delete all this when happy
--[[ ONLY USED IN OLD VERSION
function countClasses(thisClass,startYear,startMonth,startDay)
    local count = 0
    local startCounting = false
    local debug = false

    for i = 1, #dayClass do
        if      dayClass[i].year == startYear and 
                dayClass[i].month == startMonth and 
                dayClass[i].date == startDay and
                dayClass[i].name == thisClass.name and
                dayClass[i].delete ~= 1 and -- NEW TEST LINE
                dayClass[i].status == 0 then
            -- found first class of latest session
            if dayClass[i].class then count = dayClass[i].class - 1 end
            count = count + 1
            startCounting = true
        elseif  startCounting and 
                dayClass[i].name == thisClass.name and
                D.before(dayClass[i].year,dayClass[i].month,dayClass[i].date,thisClass.year,thisClass.month,thisClass.date + 1) and
                dayClass[i].delete ~= 1 and -- NEW TEST LINE
                dayClass[i].status == 0 then
            -- found another class in this session
            count = count + 1
        elseif  D.before(thisClass.year,thisClass.month,thisClass.date,dayClass[i].year,dayClass[i].month,dayClass[i].date) then
            -- gone past this class
            break
        end
    end
    return count
end

-- may need a reCalculateClassNumbers for when we move a class??????
-- ONLY USED IN OLD VERSION
function getClassNumber(thisClass,y,m,d,package)
    if thisClass.class then return thisClass.class, package end
    if thisClass.tempclass then return thisClass.tempclass, package end
-- next line is to store class numbers to avoid calculating every time
    thisClass.tempclass = countClasses(thisClass,y,m,d)
    local class = thisClass.tempclass
    return class, package
end

-- ONLY USED IN OLD VERSION
function needClassNumber(thisClass,y,m,d,package)
    if thisClass.status ~= 0 then return false end
    if thisClass.delete == 1 then return false end -- NEW TEST LINE
    if thisClass.class then return true end -- have set a class num in classes.lua
    if thisClass.tempclass then return true end -- have set a tempclass num in classes.lua

-- NOTE use d == 0 for dont count class number
-- and then use y and m elsewhere to determine students to display
-- ie store last class date (year and month)    
    if d == 0 then return false end
    -- need class number if package start date is before or equal to thisClass date
    return D.before(y,m,d,thisClass.year,thisClass.month, thisClass.date + 1)
end


-- returns current session start year,month,day and package of the student of the passed class 'thisClass'
-- called from 
function getStart(thisClass)
    local package,yr,mth,day = 0,0,0,0
    for i = 1,#student do
        if student[i].name == thisClass.name then 
            package = student[i].package 
            yr = student[i].startYr
            mth = student[i].startMth
            day = student[i].startDay
            break
        end
    end
    return yr,mth,day,package
end

]]

-- gets the status for the student named 'name' on the 'day' passed for display on the month calendar
-- called from displayStudentDetails
function getDayStat(name,day)
    for i = 1, #dayClass do
        if dayClass[i].year == D.getCalendarYear() and
            dayClass[i].month == D.getCalendarMonthNum() and
            dayClass[i].date == day and
            dayClass[i].name == name then
                return dayClass[i].status
        end
    end
    return -1
end

-- returns true if cls should be the first class of the new session for student passed in 'stu' because :-
-- 1. DONE - its date is the first class
--      on or after the anniversary of the previous sessions start date 
        -- (adjusting for shorter months)
-- 2. DONE TO DO #17 - BUT CHECK - its date is one class beyond the anniversary for each postponed class
-- 3. DONE - its class number is greater than its package (done in drawClass already)
-- called from startSessionAniversary
function firstClassOfSessionDue(cls, stu)

    -- if this class date is the next session start date then TRUE
    if  cls.date == stu.nextStartDay and
        cls.month == stu.nextStartMth and
        cls.year == stu.nextStartYr then
            return true
    -- else if this class is before the next session start date then FALSE
    elseif D.before(cls.year,cls.month,cls.date,stu.nextStartYr,stu.nextStartMth,stu.nextStartDay) then 
        return false
    else
    -- otherwise, check in dayClass to see if this is the next class after nextStartDay

         -- find next class after nextStartDate if this is that class then true
         -- BUG #1 - 
         -- a few problems, seems to be true for EVERY class after nextStartDay
         -- also because we set nextStartDay to a day that may not have a class scheduled for
         -- this code will find the first class after nextStartDay which should actually be the nextStartDay
        for i = 1, #dayClass do
            local c = dayClass[i]
            if c.name == cls.name and c.status == 0 then -- added and c.status == 0 to fix below bug
                -- BUG (fixed) if 1st class after session start is cancelled, it doesn't mark second fixed above
                if  c.date == stu.nextStartDay and 
                    c.month == stu.nextStartMth and 
                    c.year == stu.nextStartYr then
                    -- already found a class on the next session start date
                    return false
                elseif  D.before(stu.nextStartYr,stu.nextStartMth,stu.nextStartDay,c.year,c.month,c.date) then
                    -- if this class is the FIRST??? -- YES! class after the next session start date then its the new start date
                    return  cls.date == c.date and 
                            cls.month == c.month and 
                            cls.year == c.year
                end
            end
        end
    end

    -- TO DO #18 - CHECK ALL THIS - if Nish postponed a class, need to step next start day forward to next class
    -- if class date > student.startDay, student.startMth, student.yr then check for postponed (ie only most recent session)
    -- for every class since session start has  class.status == 2, step new session due ahead by 1 scheduled class day
    -- if student cancels the class immediately after due session start date then that negates 1 postponed class

    -- this 
    -- while not classUsuallyScheduledFor(stu.nextStartDay,stu.nextStartMth,stu.nextStartYr) do 
    --     stu.nextStartDay,stu.nextStartMth,stu.nextStartYr = nextDay(stu.nextStartDay,stu.nextStartMth,stu.nextStartYr)
    -- end

    return false 
end

-- finds the student for the class passed in 'thisClass' and
-- returns true if this class should be the first of the new session
-- called from drawClass and createChosenStudentData
function startSessionAniversary(thisClass)
    for i = 1,#student do
        if student[i].name == thisClass.name and student[i].nextStartDay then -- need to check nextStartDay in case not set
            return firstClassOfSessionDue(thisClass, student[i])
        end
    end
    return false
end

-- returns true if the class passed in 'cls' should be the first class of a new session for the student passed in 'stu'
-- when the usual expected first class was postponed by Nish
-- called from postponedSessionAniversary
function firstClassOfPostponedSession(cls, stu)

    -- if this class date is the postponed session start date then TRUE
    if  cls.date == stu.postponedStartDay and
        cls.month == stu.postponedStartMth and
        cls.year == stu.postponedStartYr then
            return true
    -- else if this class is before the next postponed start date then FALSE
    elseif D.before(cls.year,cls.month,cls.date,stu.postponedStartYr,stu.postponedStartMth,stu.postponedStartDay) then 
        return false
    else
    -- otherwise, check in dayClass to see if this is the next class after the postponed start day

         -- find next class after postponedStartDate if this is that class then true
        for i = 1, #dayClass do
            local c = dayClass[i]
            if c.name == cls.name and c.status == 0 then -- added and c.status == 0 to fix below bug
                -- BUG (fixed) if 1st class after session start is cancelled, it doesn't mark second fixed above
                if  c.date == stu.postponedStartDay and 
                    c.month == stu.postponedStartMth and 
                    c.year == stu.postponedStartYr then
                    -- already found a class on the next session start date
                    return false
                elseif  D.before(stu.postponedStartYr,stu.postponedStartMth,stu.postponedStartDay,c.year,c.month,c.date) then
                    -- if this class is the FIRST??? -- YES! class after the next session start date then its the new start date
                    return  cls.date == c.date and 
                            cls.month == c.month and 
                            cls.year == c.year
                end
            end
        end
    end
    return false 
end

-- finds the student for the class passed in 'thisClass' and
-- returns true if this class should be the first of the new session having been postponed
-- called from drawClass 
function postponedSessionAniversary(thisClass)
    for i = 1,#student do
        if student[i].name == thisClass.name and student[i].postponedStartDay then -- need to check postponedStartDay in case not set
            return firstClassOfPostponedSession(thisClass, student[i])
        end
    end
    return false
end

-- set the status to -1 for the current class in dayClass if the package = 0
-- called from drawWeek
function setDayStat(year, month, day, name)
    for i = 1, #dayClass do
        if dayClass[i].year == year and
            dayClass[i].month == month and
            dayClass[i].date == day and
            dayClass[i].name == name then
                dayClass[i].status = -1
--                break -- break won't work if there are 2 on one day
        end
    end
end

-- refreshes studentClassesThisMonth for student passed in 'name'
-- called from displayStudentDetails
function setStudentClassesInMonth(name)
    local daysInMonth = D.get_days_in_month(D.getCalendarMonthNum(), D.getCalendarYear())
    for day = 1, daysInMonth  do
        studentClassesThisMonth[day] = getDayStat(name,day)
    end
    for day = daysInMonth + 1, 31 do
        studentClassesThisMonth[day] = -1
    end
end

-- displays student details in lower part of the screen
-- called from drawClass
function displayStudentDetails(thisClass)
    local startLine = windowHeight-130
    --local startLine = 720

    c_lgsc(textColour)

    if thisClass == nil then
        for i = 1,31 do studentClassesThisMonth[i] = -1 end
        return
    end

    if thisClass.delete == 1 then return end -- NEW TEST LINE

    for i = 1,#student do
        if student[i].name == thisClass.name then
            setStudentClassesInMonth(thisClass.name)

            c_lgp(thisClass.name,startX, startLine)
            if thisClass.status == 0 then 
                c_lgp('(Class on)',startX + 80, startLine) 
            end

            if thisClass.status == 1 then c_lgp('(Student missed)',startX + 80, startLine) end
            if thisClass.status == 2 then c_lgp('(I postponed)',startX + 80, startLine) end

            if NEW_CLASS_NUM_VERSION then
                -- NEW Version TO DO #19 - delete old version when happy
                if thisClass.status == 0 then                
                    local classNum, package = findClassNumber(thisClass)
                    c_lgp('Class '..classNum ..'/'.. package, startX + 150, startLine)
                end
            else
                -- OLD VERSION
                if thisClass.status == 0 then                
                    local y,m,d,package = getStart(thisClass)
                    if needClassNumber(thisClass,y,m,d,package) then
                        local classNum, package = getClassNumber(thisClass,y,m,d,package)
                        c_lgp('Class '..classNum ..'/'.. package, startX + 150, startLine)
                    end
                end
            end
            

            --            c_lgp('Days '..student[i].wk ..'/'.. package, startX + 150, startLine)
        
            if showFinancialInfo then
                c_lgp('Total Paid '..rupees(student[i].totalPaid),startX, startLine + 24)
            end
            c_lgp('Total Classes '..student[i].numClasses,startX, startLine + 40)

            c_lgp('Package '..student[i].package..' classes/month',startX + 150, startLine + 24)
            c_lgp('Package Start '..student[i].startDay..'/'..student[i].startMth..'/'..student[i].startYr,startX + 150, startLine + 40)
            break
        end
    end
end    

-- returns true if mouse is over the area passed in x,y,w,h
-- called from love.update, topMost, overChosenStudentDay, drawClass, and button
function mouseOver(x,y,w,h)
-- adjust when scaled            
    local mx,my = getScaledMousePos() --love.mouse.getPosition()
    return U.mouse_in_rect(mx,my,x,y,w,h)
end

-- returns true if the classes passed in rect1 and rect2 collide when rect1 is moved to position x,y passed
-- called from checkCollisions
function theseTwoCollide(rect1,rect2,x,y)
    if rect1 == rect2 then return false end

    local rect1r = x + rect1.width
    local rect1b = y + classBoxHeight * (rect1.length/60)
    
    local rect2r = rect2.x + rect2.width
    local rect2b = rect2.y + classBoxHeight * (rect2.length/60)

    return rect1r >= rect2.x and rect2r >= x and
           rect1b >= rect2.y and rect2b >= y
end

-- returns true if the class passed would collide with any other class if moved to position x,y passed
-- called from drawClass
function checkCollisions(class,x,y)
    local saveMoveClassWidth = class.width
    class.width = 20

    for i = 1, #week do
        for j = 1, #week[i] do
            thisClass = week[i][j]
            if thisClass.delete == 1 then break end -- NEW TEST LINE
            if theseTwoCollide(class,thisClass,x,y) and not thisClass.saveWidth then
                thisClass.saveWidth = thisClass.width
                thisClass.width = 20
            else
                if thisClass.saveWidth then 
                    thisClass.width = thisClass.saveWidth 
                    thisClass.saveWidth = nil
                    if theseTwoCollide(class,thisClass,x,y) then
                        thisClass.saveWidth = thisClass.width
                        thisClass.width = 20
                    end
                end
            end
        end
    end

    class.width = saveMoveClassWidth
end

-- returns the Y coordinate of the nearest class slot while moving the class with the mouse
-- called from drawClass
function nearestSlotY(pos)
    for i = 1, #positionsY do
--        if pos < positionsY[i] then 
        if (i == #positionsY) or (pos >= positionsY[i] and pos < positionsY[i+1]) then 
            return positionsY[i], 5 + math.floor((i-1)/4), ((i-1) % 4) * 15
        end
    end
    return positionsY[#positionsY]
end

-- returns the X coordinate of the nearest class slot while moving the class with the mouse
-- called from drawClass
function nearestSlotX(pos)
    if pos < startX then 
        return startX 
    elseif pos > startX + 6 * (classBoxWidth + classBoxPadX) then 
        return startX + 6 * (classBoxWidth + classBoxPadX)
    else 
        return pos
    end
end

-- returns true if another class c2 overlaps with the class being moved c1
-- called from moveClass
function colliding(c1,c2)
    if c1.delete == 1 then return false end -- NEW TEST LINE
    if c1.name == c2.name then return false end
    local collidingClassStartTime = (c1.hour * 60) + c1.min
    local collidingClassEndTime = collidingClassStartTime + c1.length
    local movingClassStartTime = (c2.hour * 60) + c2.min
    local movingClassEndTime = movingClassStartTime + c2.length
    return  collidingClassEndTime > movingClassStartTime and
            collidingClassStartTime < movingClassEndTime
end

-- moves a class 'class' to its new position
-- called from drawClass
function moveClass(day,class,newX,newY,newDay,newHour,newMinute)

    local alreadyCountedSlots = false
    local alreadySetMovingClass = false
    local classesAtSource = {}
    local classesAtDestination = {}
    local classInDayClass = 0
    local nextSlot = 0
    local numSlots = 1
    local newWidth = 0
    local thisClass = week[day][class]
    local thisDay = D.currentDayOfWeek() - 1
    if thisDay == 0 then thisDay = 7 end
    local dayAdjust = newDay - thisDay
    local thisDate = D.getAdjustedDate(dayAdjust + (weekOffset * 7))

    local slotPos = startX + (newDay - 1) * (classBoxWidth + classBoxPadX)

-- Find every class that collides with thisclass AND set each one's x, width, slot
-- to be correct now that thisClass is being moved

    for cls = 1, #week[newDay] do
        if colliding(week[newDay][cls], thisClass) then
            classesAtSource[#classesAtSource + 1] = cls
        end
    end

    for z = 1, #classesAtSource do
        local adjustClass = week[newDay][classesAtSource[z]]
        adjustClass.slot = z
        adjustClass.width = math.floor(classBoxWidth / #classesAtSource) - 2
        adjustClass.x = slotPos + ((z - 1) *  adjustClass.width) + 2
    end

    -- after cleaning up where we are moving class from, 
    -- can set defaults for where we are moving class to
    thisClass.width = classBoxWidth
    thisClass.slot = 1

    for i = 1,#dayClass do
        if dayClass[i].year == thisClass.year and
            dayClass[i].month == thisClass.month and
            dayClass[i].date == thisClass.date and
            dayClass[i].hour == thisClass.hour and -- 27th november - NEED THIS IN CASE STU HAS > 1 class on date
            dayClass[i].name == thisClass.name then
                classInDayClass = i
        end
    end
    

    thisClass.year = thisDate.year -- what if new day is next/prev month/year - checked and its GOOD!
    thisClass.month = thisDate.month -- what if new day is next/prev month/year - checked and its GOOD!
    thisClass.date = thisDate.day
    thisClass.hour = newHour
    thisClass.min = newMinute
    thisClass.y = newY
    thisClass.x = newX 


-- BUG if its a new class need to ensure update in dayclass - FIXED

-- check if new position will be shared
-- adjust this class and other classes slots and widths accordingly

-- START OF TESTING ANOTHER VERSION
for cls = 1, #week[newDay] do
    if colliding(week[newDay][cls], thisClass) then
        classesAtDestination[#classesAtDestination + 1] = cls
    end
end

-- insert class at correct position in classesAtDestination
for z = 1, #classesAtDestination do
    local adjustClass = week[newDay][classesAtDestination[z]]
    if (thisClass.hour * 60) + thisClass.min <= (adjustClass.hour * 60) + adjustClass.min then 
        table.insert(classesAtDestination,z,class)
        break    
    end
end

-- process classesAtDestination TO DO #21 think about using this idea fully
for z = 1, #classesAtDestination do
    local adjustClass = week[newDay][classesAtDestination[z]]
--    printIfDebug(adjustClass.name..' on day '..adjustClass.date..' hour '..adjustClass.hour..' min '..adjustClass.min..' slot '..adjustClass.slot)
    -- adjustClass.slot = z
    -- adjustClass.width = math.floor(classBoxWidth / #classesAtDestination) - 2
    -- adjustClass.x = slotPos + ((z - 1) *  adjustClass.width) + 2
end

-- END OF TESTING ANOTHER VERSION

-- above might replace all below ... althought this all works
-- TO DO #21 - explained above


    for i = 1,#week[newDay] do
        if colliding(week[newDay][i], thisClass) then
            local collidingClassStartTime = (week[newDay][i].hour * 60) + week[newDay][i].min
            local movingClassStartTime = (newHour * 60) + newMinute

            if not alreadyCountedSlots then
                alreadyCountedSlots = true
                -- count the slots
                for j = i+1, #week[newDay] do
                    if colliding(week[newDay][j], thisClass) then 
                        numSlots = numSlots + 1 
                    else break
                    end
                end
                numSlots = numSlots + 1
                -- save the new width for all classes affected
                newWidth = math.floor(classBoxWidth / numSlots) - 2
            end

            -- x is the base position of any class on this day
            local x = startX + (newDay - 1) * (classBoxWidth + classBoxPadX)

            if collidingClassStartTime < movingClassStartTime then
                if not alreadySetMovingClass then
                    if week[newDay][i+numSlots-1] then
                        thisClass.slot = week[newDay][i+numSlots-1].slot + 1
                    else
                        thisClass.slot = week[newDay][#week[newDay]].slot + 1
                    end
                    nextSlot = thisClass.slot + 1
                    thisClass.width = newWidth
                    thisClass.x = x + ((thisClass.slot - 1) *  newWidth) + 2
                    alreadySetMovingClass = true
                end
                week[newDay][i].width = newWidth
            else
                if not alreadySetMovingClass then
                    thisClass.slot = 1
                    thisClass.width = newWidth
                    nextSlot = thisClass.slot + 1
                    alreadySetMovingClass = true
                end
                week[newDay][i].slot = nextSlot 
                nextSlot = nextSlot + 1
                week[newDay][i].width = newWidth
                week[newDay][i].x = x + ((week[newDay][i].slot - 1) *  newWidth) + 2
            end
        end
    end

-- just test prints below    
for z = 1, #classesAtDestination do
    local adjustClass = week[newDay][classesAtDestination[z]]
--    printIfDebug(adjustClass.name..' on day '..adjustClass.date..' hour '..adjustClass.hour..' min '..adjustClass.min..' slot '..adjustClass.slot)
    -- adjustClass.slot = z
    -- adjustClass.width = math.floor(classBoxWidth / #classesAtDestination) - 2
    -- adjustClass.x = slotPos + ((z - 1) *  adjustClass.width) + 2
end
-- test stuff

-- TO DO #22 - check this
-- this IS necessary for new classes when moved before we do a prev/next week
-- BUT, need to update both if both are new not just the one we're moving BUG -- FIX IT
    if classInDayClass > 0 then
        dayClass[classInDayClass].year = thisClass.year
        dayClass[classInDayClass].month = thisClass.month
        dayClass[classInDayClass].date = thisClass.date
        dayClass[classInDayClass].hour = thisClass.hour
        dayClass[classInDayClass].min = thisClass.min
        dayClass[classInDayClass].slot = thisClass.slot
        dayClass[classInDayClass].y = thisClass.y
--printIfDebug('updating '..thisClass.name..' in dayClass')
    end
end

-- returns true if the class passed in 'thisClass' is the top most class for the mouse to click on
-- called from drawClass
function topMost(day, xPos, yPos, thisClass)
    for i = #week[day], 1, -1 do
        if week[day][i].delete ~= 1 then  -- NEW TEST LINE
            local thisOnesHeight = classBoxHeight * (week[day][i].length/60) + math.floor(week[day][i].length/60) * classBoxPadY
            if mouseOver(week[day][i].x, week[day][i].y, week[day][i].width, thisOnesHeight) then
                return week[day][i].name == thisClass.name
            end
        end
    end
    return false
end

-- changes the total number of classes for the student with name 'name' by amount in 'num'
-- called from drawClass when status changed to and from active, or class deleted
-- also called from drawWeek when assigning selectedStudentName to 'new class'
function updateStudentClasses(name,num)
    for i = 1, #student do
        if student[i].name == name then
            student[i].numClasses = student[i].numClasses + num
        end
    end
end

-- returns true if mouse is over one of the records when editing a student's class
-- called from drawClass
function overChosenStudentDay(day,hour)
    local editStartX = startX

    for i = 1, #chosenStudentData do
        if i == 6 then editStartX = startX + 480 end
        if chosenStudentData[i].dayNum == day and chosenStudentData[i].hour == hour and
            mouseOver(editStartX, editStartLine + ((1 + (i - 1) % 5) * editLineIncrement), 465, 15) then
            return true
        end
    end
    return false
end

-- returns true if mouse is over one of the records when editing a student's class
-- called from drawClass
function overStudentHighlight(day,class)
    if changingColours then return false end
    if #weekHighlights == 0 then return false end
    local editStartX = startX
    local highlightStartLine = colourWindowyPos

    local line = 0
    local lastDay = weekHighlights[1]:sub(1,1)
    local dayEnd = 0
    local newDay = false
    for i = 1, #weekHighlights do
        line = line + 1
        if lastDay ~= weekHighlights[i]:sub(1,1) then
            line = line + 1
            newDay = true
            lastDay = weekHighlights[i]:sub(1,1)
        else
            newDay = false
        end
        if i == 1 or newDay then
            _,dayEnd = weekHighlights[i]:find('day -')
        end
        if weekHighlights[i]:find(tostring(day)) and weekHighlights[i]:find(class.name) and
            mouseOver(colourWindowxPos+92, highlightStartLine + 5 + (line * 15), colourWindowWidth - 92, 15) then
            c_lgp(weekHighlights[i]:sub(dayEnd+3,#weekHighlights[i]),colourWindowxPos+92,highlightStartLine + 5 + (line * 15))
            return true
        end
    end
    return false
end

-- adjusts classesNishCancelled if this class is after session start date
-- question should it do this if thisClass IS the first class? -- NO because then session start date is moved
-- to next day anyway so IT IS GOOD!!
-- called from drawClass
function adjustNumPostponedClasses(thisClass,num)
    for i = 1, #student do 
        if student[i].name == thisClass.name and
           D.before(student[i].startYr,student[i].startMth,student[i].startDay,
                    thisClass.year,thisClass.month,thisClass.date) then 
                student[i].classesNishCancelled = student[i].classesNishCancelled + num
        end
    end
end

-- returns the student's class record of their next class after the class passed in 'thisClass'
-- called from drawClass
function getNextClass(thisClass)
    local gotThisClass = false
    for i = 1, #dayClass do
        if gotThisClass then return dayClass[i] end
        if dayClass[i].name == thisClass.name and
            dayClass[i].year == thisClass.year and
            dayClass[i].month == thisClass.month and
            dayClass[i].date == thisClass.date and
            dayClass[i].hour == thisClass.hour and
            dayClass[i].name == thisClass.name then
                gotThisClass = true
        end
    end

end

-- update the week, month, year totals when a class deleted or its state is changed
-- called from drawClass
function updateTotals(thisClass,day,num)
    newWeekTotals[thisWeekNum + weekOffset][day] =  newWeekTotals[thisWeekNum + weekOffset][day] + num
    newWeekTotals[thisWeekNum + weekOffset][8] =  newWeekTotals[thisWeekNum + weekOffset][8] + num

    totalNumClasses = totalNumClasses + num
    updateStudentClasses(thisClass.name,num)
    monthTotals[thisClass.year][thisClass.month] = monthTotals[thisClass.year][thisClass.month] + num
    monthTotals[thisClass.year][13] = monthTotals[thisClass.year][13] + num
end

-- draws the specific 'class' number passed on the 'day' passed
-- called from drawWeek
function drawClass(day, class)
    local thisClass = week[day][class]
    local thisClassHeight = classBoxHeight * (thisClass.length/60) + math.floor(thisClass.length/60) * classBoxPadY
    local mx,my,dx,dy = 0,0,0,0
    local saveWidth = thisClass.width
    local xPos = thisClass.x + dx
    local yPos = thisClass.y + dy
    local newHour,newMinute,newDay = 0

    -- change status
    if leftMouseClicked and thisClass.status > -1 and thisClass.name ~= 'new class' and
            U.mouse_in_rect(mouseStartX,mouseStartY,xPos + 1, yPos + 1, 16, 16) then
        thisClass.status = thisClass.status + 1
        if thisClass.status > 2 then thisClass.status = 0 end

        -- if new state is now 'active'
        if thisClass.status == 0 then 

            -- increment totals when change to active
            updateTotals(thisClass,day,1)
            -- adjust classesNishCancelled if this class is after session start date
            adjustNumPostponedClasses(thisClass,-1)

            -- if this class is marked as wasClass1 set it back to class 1 and remove class 1 from next class
            local nextClass = nil 
            local stu = nil 
            if thisClass.wasClass1 then
                nextClass = getNextClass(thisClass)
                stu = findStudent(thisClass.name)
                thisClass.wasClass1 = nil
                thisClass.class = 1
                thisClass.pkg = nextClass.pkg
                nextClass.class = nil
                nextClass.pkg = nil
                stu.startYr = thisClass.year
                stu.startMth = thisClass.month
                stu.startDay = thisClass.date
                updateNewClassNum(thisClass) -- writes class=1 and pkg=xx to dayClass
                updateNewClassNum(nextClass) -- writes class=1 and pkg=xx to dayClass
            end

            -- added to test new BUG #1 test code
            if classAfterSessionStart(thisClass) then calculatePostponedStart(getStudent(thisClass)) end

            -- recalculate class num
            reCalculateClassNumbers(thisClass.name) 
        -- if new state is now 'cancelled'
        elseif thisClass.status == 1 then -- have to change to 1 before 2 so don't need to check for 2
            -- decrement totals when change from active
            updateTotals(thisClass,day,-1)

            -- if this class is marked as class 1 of session mark next class as class 1
            -- and remove it from this class and add wasClass1 = true
            local nextClass = nil 
            local stu = nil 
            if thisClass.class == 1 then
                nextClass = getNextClass(thisClass)
                stu = findStudent(thisClass.name)
                nextClass.class = 1
                nextClass.pkg = thisClass.pkg
                thisClass.wasClass1 = true
                thisClass.class = nil
                thisClass.pkg = nil
                stu.startYr = nextClass.year
                stu.startMth = nextClass.month
                stu.startDay = nextClass.date
                updateNewClassNum(thisClass) -- writes class=1 and pkg=xx to dayClass
                updateNewClassNum(nextClass) -- writes class=1 and pkg=xx to dayClass
            end
            reCalculateClassNumbers(thisClass.name) 
        -- if new state is now 'postponed'
        elseif thisClass.status == 2 then 
            -- adjust classesNishCancelled if this class is after session start date
            adjustNumPostponedClasses(thisClass,1)
            -- added to test new BUG #1 test code
            if classAfterSessionStart(thisClass) then calculatePostponedStart(getStudent(thisClass)) end

        end
        -- update status in dayClass
        for i = 1,#dayClass do
            if dayClass[i].year == thisClass.year and
                dayClass[i].month == thisClass.month and
                dayClass[i].date == thisClass.date and
                dayClass[i].name == thisClass.name and 
                dayClass[i].hour == thisClass.hour and 
                dayClass[i].min == thisClass.min then
                    dayClass[i].status = thisClass.status
            end
        end
        leftMouseClicked = false
        weekHighlights = {} -- so that highlights refresh 

    -- delete class        
    elseif leftMouseClicked and U.mouse_in_rect(mouseStartX,mouseStartY,xPos + thisClass.width - 15, yPos, 16, 16) then
        thisClass.delete = 1

        -- if we delete a new class before assigning a student name reset showAllStudents
        if thisClass.name == 'new class' then showAllStudents = false end

        -- mark as deleted in dayclass 
        for i = 1,#dayClass do
            if dayClass[i].year == thisClass.year and
                dayClass[i].month == thisClass.month and
                dayClass[i].date == thisClass.date and
                dayClass[i].name == thisClass.name and 
                dayClass[i].hour == thisClass.hour and 
                dayClass[i].min == thisClass.min then
                    dayClass[i].delete = 1
            end
        end
        -- remove 1 from total of all classes (active or inactive)
        newWeekTotals[thisWeekNum + weekOffset][9] =  newWeekTotals[thisWeekNum + weekOffset][9] - 1
    
        -- TO DO #24 - check this stuff, its confusing to read
        -- adjust weektotals and month totals and year totals 
        -- UPDATE HERE - DONE - only add if package <> 0
--        if not zeroPackage(thisClass.name) then
        if thisClass.status == 0 then
            -- decrement totals when delete an active class
            updateTotals(thisClass,day,-1)

            -- if this class is marked as class 1 of session mark next class as class 1
            local nextClass = nil 
            local stu = nil 
            if thisClass.class == 1 then
                nextClass = getNextClass(thisClass)
                stu = findStudent(thisClass.name)
                nextClass.class = 1
                nextClass.pkg = thisClass.pkg
                thisClass.wasClass1 = true
                thisClass.class = nil
                thisClass.pkg = nil
                stu.startYr = nextClass.year
                stu.startMth = nextClass.month
                stu.startDay = nextClass.date
                updateNewClassNum(thisClass) -- writes class=1 and pkg=xx to dayClass
                updateNewClassNum(nextClass) -- writes class=1 and pkg=xx to dayClass
            end
            reCalculateClassNumbers(thisClass.name)
        elseif thisClass.status == 2 then
            -- adjust classesNishCancelled if this class is after session start date
            adjustNumPostponedClasses(thisClass,-1)
        end
        leftMouseClicked = false
        weekHighlights = {} -- so that highlights refresh - TEST LINE
        return -- if class is deleted, do no more - ADDED 4th Dec 2020

    -- Tracking the class being moved
    elseif --[[not addingNewStudent and ]] leftMouseClicked and -- not using addingNewStudent so REMOVED IT  
            U.mouse_in_rect(mouseStartX,mouseStartY,xPos,yPos,thisClass.width, thisClassHeight) then
        classToMove = thisClass 
        movingClass = true
        -- adjust when scaled            
        mx,my = getScaledMousePos() --love.mouse.getPosition()
        dx = mx - mouseStartX
        dy = my - mouseStartY
        xPos = nearestSlotX(thisClass.x + dx)
        yPos = nearestSlotY(thisClass.y + dy)
        --check collisions between classToMove and other class
        if classToMove then
            checkCollisions(classToMove,xPos,yPos)
        end
    end

    -- move the class    
    if moveTheClass and U.mouse_in_rect(mouseStartX,mouseStartY,xPos,yPos,thisClass.width, thisClassHeight) then

        -- adjust when scaled            
        mx,my = getScaledMousePos() --love.mouse.getPosition()
        dx = mx - mouseStartX
        dy = my - mouseStartY
        xPos = nearestSlotX(thisClass.x + dx)
        yPos,newHour,newMinute = nearestSlotY(thisClass.y + dy)

        for i = 1, #positionsX do
            if xPos < positionsX[i] then 
                xPos = positionsX[i-1]; 
                newDay = i - 1
                break 
            end
            newDay = 7
        end

        if not (day == newDay and thisClass.hour == newHour and thisClass.min == newMinute) then
            classMoved = true
            moveClass(day,class,xPos,yPos,newDay,newHour,newMinute)
            sort_table("year","month","date","hour","min","slot") -- this is good, ensures it all works
            reCalculateClassNumbers(thisClass.name)
        end
        classToMove = nil
        moveTheClass = false
        weekHighlights = {} -- so that highlights refresh - TEST LINE
    end

    -- draw class details box
    -- if mouse over this class class
    if mouseOver(xPos, yPos, thisClass.width, thisClassHeight) and topMost(day, xPos, yPos, thisClass) then
        overAnyStudent = true     
        mouseOverClass = thisClass   
        if not chosenStudent then displayStudentDetails(thisClass) end
        c_lgsc(highlightClassBorderColour) 
        c_lgr('line', xPos, yPos, thisClass.width, thisClassHeight, rectCorner, rectCorner)
        c_lgsc(highlightClassColour)
    -- if editing student and mouse over editing line for this class
    elseif chosenStudent and chosenStudent.name == thisClass.name and overChosenStudentDay(day,thisClass.hour) then 
        c_lgsc(highlightClassColour)
    -- if over a highlight concerning this class
    elseif overStudentHighlight(day,thisClass) then
        c_lgsc(highlightClassColour)
        -- otherwise just display in student's class colour
    else
        if thisClass.status == 0 then 
            c_lgsc(C.getColour(2,getStudentColour(thisClass.name)))
        else
            c_lgsc(C.getColour(3,getStudentColour(thisClass.name),0.5))
        end
    end

    c_lgr('fill', xPos, yPos, thisClass.width, thisClassHeight, rectCorner, rectCorner)

    -- surely this should be done when status is changed, not all the time if done here
    if thisClass.status == 2 then
        addHighlight(day..'-'..D.dayName(day)..' - '..thisClass.name..' Class Postponed')
    end

    -- draw border on box
    c_lgsc(classBorderColour)
    -- if next session is due to start on this date then draw different border colour
    -- if the next session start is delayed bacause class was postponed draw indication
    if thisClass.status == 0 and startSessionAniversary(thisClass) then
        addHighlight(day..'-'..D.dayName(day)..' - '..thisClass.name..' New Session due to start')
        c_lgsc(classNextSessionStartBorderColour)
        c_lgr('line', xPos+1, yPos+1, thisClass.width - 2, thisClassHeight - 2, rectCorner, rectCorner)
        if postponedClass(thisClass) then
            c_lgsc(yellow)
            c_lgl(xPos + thisClass.width/2 - 30, yPos + 4, xPos + thisClass.width/2 + 30, yPos + 4)
            c_lgl(xPos + thisClass.width/2 - 30, yPos + 8, xPos + thisClass.width/2 + 30, yPos + 8)
            c_lgsc(classNextSessionStartBorderColour)
        end
    -- if next session should start on this delayed start date because class was postponed
--    elseif postponedClassStart(thisClass) then -- testing these two
    elseif postponedSessionAniversary(thisClass) then -- testing these two
        c_lgsc(yellow)
        c_lgr('line', xPos+1, yPos+1, thisClass.width - 2, thisClassHeight - 2, rectCorner, rectCorner)
    end
    -- draw the border
    c_lgr('line', xPos, yPos, thisClass.width, thisClassHeight, rectCorner, rectCorner)

    -- draw grab lines at bottom NOT USED ANY MORE
    -- c_lgl(xPos + thisClass.width/2 - 10, yPos + thisClassHeight - 4, xPos + thisClass.width/2 + 10, yPos + thisClassHeight - 4)
    -- c_lgl(xPos + thisClass.width/2 - 10, yPos + thisClassHeight - 8, xPos + thisClass.width/2 + 10, yPos + thisClassHeight - 8)

    -- display status box
    if mouseOver(xPos + 1, yPos + 1, 16, 16) then
        c_lgsc(classStatusBorderColour)
        c_lgr('line', xPos + 1, yPos + 1, 16, 16)
    end

    -- display Delete box
    if mouseOver(xPos + thisClass.width - 15, yPos + 0, 16, 16) then
        c_lgsc(classStatusBorderColour)
        c_lgr('line', xPos + thisClass.width - 15, yPos + 0, 16, 16)
    end

    -- draw student name
    c_lgsc(studentNameTextColour)
    local namePosY = yPos + 15
    local namePosX = xPos + 5
    
    if thisClassHeight == math.floor(classBoxHeight / 4) then 
        namePosY = namePosY - 17; 
        namePosX = namePosX + 10
    elseif thisClassHeight == math.floor(classBoxHeight / 2) then 
        namePosY = namePosY - 13; 
        namePosX = namePosX + 10
    end
    
    if thisClass.status == -1 then namePosY = yPos end

    c_lgp(thisClass.name, namePosX, namePosY)

    -- draw payment symbol
    if thisClass.paid > 0 then
        -- ADD TO WEEK HIGHLIGHTS
        addHighlight(day..'-'..D.dayName(day)..' - '..thisClass.name..' Paid')
        c_lgsc(blue)
        c_lgp('$', xPos + math.floor(thisClass.width/2), yPos)
        c_lgsc(textColour)
    end

    -- draw delete symbol
    c_lgsc(red)
    c_lgp(' x', xPos + thisClass.width - 15, yPos)
    c_lgsc(textColour)

    -- draw class number/package
    if NEW_CLASS_NUM_VERSION then
        --NEW Version TO DO #25 - delete old version
        if thisClass.status == 0 and thisClass.delete ~= 1 and thisClass.name ~= 'new class' then        
            local classNum, package = findClassNumber(thisClass)
            if classNum == package then
                addHighlight(day..'-'..D.dayName(day)..' - '..thisClass.name..' Completed classes')
            end
            if classNum == 1 then
                addHighlight(day..'-'..D.dayName(day)..' - '..thisClass.name..' First Class')
            end
            -- draw red border when class number is beyond package
            if classNum > package and 
                not startSessionAniversary(thisClass) and -- ensure YELLOW BOX SHOWS
                not postponedSessionAniversary(thisClass) then -- ensure BLUE BOX SHOWS
                -- new session should have started so g1ve it a red border
                addHighlight(day..'-'..D.dayName(day)..' - '..thisClass.name..' Overdue Session')
                c_lgsc(red)
                c_lgr('line', xPos+1, yPos+1, thisClass.width - 2, thisClassHeight - 2, rectCorner, rectCorner)
                c_lgr('line', xPos, yPos, thisClass.width, thisClassHeight, rectCorner, rectCorner)
            end
            c_lgsc(blue)
            c_lgpf(classNum ..'/'.. package, xPos, yPos + thisClassHeight - 15, thisClass.width - 5, 'right') 
            c_lgsc(textColour)
        end
    else
        --OLD VERSION
        if thisClass.status == 0 then        
            local y,m,d,package = getStart(thisClass)
            if needClassNumber(thisClass,y,m,d,package) then
                local classNum, package = getClassNumber(thisClass,y,m,d,package)
                --c_lgp(classNum ..'/'.. package, xPos + 18, yPos + 1)
                c_lgsc(blue)
                c_lgpf(classNum ..'/'.. package, xPos, yPos + thisClassHeight - 15, thisClass.width - 5, 'right') 
                c_lgsc(textColour)
            end
        end
    end

    -- draw status blob
    c_lgsc(statusBlobActiveColour)
    if thisClass.status == 1 then c_lgsc(statusBlobStudentCancelColour) 
    elseif thisClass.status == 2 then c_lgsc(statusBlobNishCancelColour)
    end
    if thisClass.status >= 0 then c_lgc('fill', xPos + 9, yPos + 9, 5) end

    -- reset colour
    c_lgsc(textColour)

    -- DEBUG
    if #week[day] == 1 then
--        c_lgp('Draw Class End: thisClass name = '..thisClass.name..' y = '..thisClass.y..' yPos = '..yPos, 260, 825)
    end
end

-- adds/removes the highlight passed in 'text' to/from weekHighlights
-- called from drawClass
function addHighlight(text,remove)
    -- don't add highlights for classes if their name is 'new class'
    if text:find('new class') then return end

    local delete = remove and remove == -1
    for i = 1, #weekHighlights do
        if weekHighlights[i] == text then 
            -- if this highlight is already here and delete flag is set, delete it
            if delete then table.remove(weekHighlights,i) end
            -- if this highlight is already here, don't add it, just return
            return 
        end
    end
    weekHighlights[#weekHighlights + 1] = text
    table.sort(weekHighlights)
end

-- displays the highlights for the week
-- called from love.draw
function drawWeekHighlights()
    if memoryDay > 0 then return end
    if showAllStudents then return end
    if #weekHighlights == 0 then return end
    if changingColours then return end

    local thisDay = D.currentDayOfWeek() - 1
    if thisDay == 0 then thisDay = 7 end

    local highlightStartLine = colourWindowyPos

    local numDays = 1
    local lastDay = weekHighlights[1]:sub(1,1)
    for i = 1,#weekHighlights do
        if lastDay ~= weekHighlights[i]:sub(1,1) then 
            numDays = numDays + 1 
            lastDay = weekHighlights[i]:sub(1,1)
        end
    end

    local numLines = #weekHighlights + numDays
    local highlightHeight = 15 + numLines * 15

    local maxLines = 20
    if numLines > maxLines then
        highlightStartLine = highlightStartLine - (numLines - maxLines) * 15
    end

    c_lgsc(daySummaryTextColour)
    c_lgr('line', colourWindowxPos+2, highlightStartLine+2, colourWindowWidth, highlightHeight)
    c_lgsc(daySummaryBoxColour)
    c_lgr('fill', colourWindowxPos, highlightStartLine, colourWindowWidth, highlightHeight)

    c_lgsc(todaySummaryBoxColour)
    c_lgr('fill', colourWindowxPos, highlightStartLine, colourWindowWidth, 15)
    c_lgsc(todaySummaryTextColour)
    c_lgpf('Events to note',colourWindowxPos,highlightStartLine,colourWindowWidth,'center')

    local line = 0
    local lastDay = weekHighlights[1]:sub(1,1)
    local newDay = false
    local dayEnd = 0
    for i = 1, #weekHighlights do
        line = line + 1
        c_lgsc(daySummaryTextColour)
        -- draw line between days
        if lastDay ~= weekHighlights[i]:sub(1,1) then
            newDay = true
            c_lgl(colourWindowxPos+5,highlightStartLine + 13 + (line * 15),colourWindowxPos+310,highlightStartLine + 13 + (line * 15))
            line = line + 1
            lastDay = weekHighlights[i]:sub(1,1)
        else
            newDay = false
        end
        if weekOffset == 0 and weekHighlights[i]:find(D.dayName(thisDay)) then 
            c_lgsc(red)
        end
        if i == 1 or newDay then
            _,dayEnd = weekHighlights[i]:find('day -')
            c_lgp(weekHighlights[i]:sub(3,dayEnd),colourWindowxPos+5,highlightStartLine + 5 + (line * 15))
        end
        if weekHighlights[i]:find('Postponed') then c_lgsc(blue) 
        elseif weekHighlights[i]:find('Completed') then c_lgsc(green) 
        elseif weekHighlights[i]:find('New') then c_lgsc(yellow) 
        elseif weekHighlights[i]:find('Paid') then c_lgsc(lightBlue) 
        elseif weekHighlights[i]:find('First') then c_lgsc(purple) 
        elseif weekHighlights[i]:find('Over') then c_lgsc(red) 
        end
        c_lgc('fill',colourWindowxPos+85,highlightStartLine + 13 + (line * 15),5)
        if mouseOver(colourWindowxPos+92, highlightStartLine + 5 + (line * 15), colourWindowWidth - 92, 15) then
            c_lgsc(red)
        else
            c_lgsc(daySummaryTextColour)
        end
        c_lgp(weekHighlights[i]:sub(dayEnd+3,#weekHighlights[i]),colourWindowxPos+92,highlightStartLine + 5 + (line * 15))
    end
    c_lgsc(textColour)
end

-- returns true if student has package == 0
-- called from drawWeek and addClass
function zeroPackage(name) 
    for i = 1, #student do
        if student[i].name == name then
            return student[i].package == 0
        end
    end
end

-- sets up current week's reminders in thisWeekReminders
-- called from createActiveWeekEvents
function setUpReminders(day,date)
    for i = 1, #reminders do
        if (reminders[i].year == date.year or reminders[i].year == 0) and reminders[i].month == date.month and reminders[i].date == date.day then
            if not thisWeekReminders[day] then 
                thisWeekReminders[day] = {} 
            end
            thisWeekReminders[day][#thisWeekReminders[day] + 1] = {}
            thisWeekReminders[day][#thisWeekReminders[day]] = reminders[i].text 
        end
    end
end

-- increases the displayed reminder number and wraps around to 1 again
-- called from doClassMouseClicks
function changeReminderNumber(day)
    if not thisWeekReminders[day] then return end

    currentReminderNumber[day] = currentReminderNumber[day] + 1

    if currentReminderNumber[day] > #thisWeekReminders[day] then
        currentReminderNumber[day] = 1
    end
end

function scrollText(txt)
    if #txt > 16 and scrolling then
        if scrollIndex > #txt then scrollIndex = 1 end
        local newText = txt:sub(scrollIndex,#txt)..' - '..txt:sub(1,scrollIndex-1)
--print(newText:sub(1,16))
        return newText:sub(1,16)
    else
        return txt:sub(1,16)
    end
end

-- draws current reminder for 'day' passed of the current week
-- called from drawWeek
function drawReminder(day)
    if not thisWeekReminders[day] then return end

    local x = startX + (day - 1) * (classBoxWidth + classBoxPadX) + 1
    local y = dayY + 40
    local w = classBoxWidth + classBoxPadX - 2
    local h = 14

    button(x,y,w,h,scrollText(thisWeekReminders[day][currentReminderNumber[day]]),true)

    if #thisWeekReminders[day] > 1 then button(x+w-15,y-2,14,h,'>',true) end
end

-- draws a button at x,y,w,h with 'text' as its lable
-- called from everywhere 
function button(x,y,w,h,text,noBorder)
    -- top 4 menu buttons are inactive when changing colours
    local active = not changingColours or not (x < 160 and y < 180)

    local txt = text
    if type(text) == 'number' then txt = tostring(text) end
    local border = noBorder == nil or noBorder == false

    local buttonColour = normalButtonColour
    local highlight = mouseOver(x,y,w,h)
    if highlight then buttonColour = highlightButtonColour end
    if not active then buttonColour = {.8,.8,.8,1} end
    
    if border then
        c_lgsc(buttonTextColour)
        c_lgr('line',x,y,w,h)
        c_lgr('line',x+2,y+2,w,h) -- draw shadow
    end
    c_lgsc(buttonColour)
    c_lgr('fill',x,y,w,h)
    -- if first character of text = '*' set text colour to green and remove the '*'
    if txt:sub(1,1) == '*' then
        c_lgsc(red)
        txt = txt:sub(2,#txt)
    else
        c_lgsc(buttonTextColour)
    end

    local textYPos = y
    if h > 19 then textYPos = y + math.floor(h / 4) - 1 end
    c_lgpf(txt,x,textYPos,w,'center')
    if state == statistics then c_lgsc(statisticsTextColour) else c_lgsc(textColour) end
end

-- creates the chosenStudentData data structure for the student chosen for editing
-- called from editStudent
function createChosenStudentData()
    
--    print('Re-creating chosenStudentData for '..chosenStudent.name)
    for day = 1, 7 do
        for class = 1, #week[day] do
            cls = week[day][class]
            if chosenStudent and chosenStudent.name == cls.name and cls.delete ~= 1 then
                chosenStudentData[#chosenStudentData + 1] = {}
                local chosenStudentClass = chosenStudentData[#chosenStudentData]

                -- store day
                chosenStudentClass.day = D.dayName(day)

                -- store dayNum 
                chosenStudentClass.dayNum = day

                -- store hour
                chosenStudentClass.hour = cls.hour

                -- store date
                chosenStudentClass.year = cls.year
                chosenStudentClass.month = cls.month
                chosenStudentClass.date = cls.date

                -- store status
                chosenStudentClass.status = cls.status

                -- store class num and package
                if cls.status == 0 then
                    chosenStudentClass.clsNum,chosenStudentClass.pkg = findClassNumber(cls)
                else
                    chosenStudentClass.clsNum,chosenStudentClass.pkg = 0,0
                end

                -- store payment
                chosenStudentClass.paid = cls.paid

                -- store 0 for not new session start or 1 for session start
                if startSessionAniversary(cls) then
                    chosenStudentClass.start = 1
                else
                    chosenStudentClass.start = 0
                end
            end
        end
    end
    -- sorting this table by year,month,date,hour to ensure works after move class
    if #chosenStudentData > 0 then sort_chosenStudent('year','month','date','hour') end
end

-- sorts the chosenStudentData data structure
-- called from createChosenStudentData
function sort_chosenStudent(a,b,c,d)
--    print('sorting')
    table.sort(chosenStudentData, function(u,v)
        return
        u[a] < v[a] or
        (u[a] == v[a] and u[b] < v[b]) or
        (u[a] == v[a] and u[b] == v[b] and u[c] < v[c]) or
        (u[a] == v[a] and u[b] == v[b] and u[c] == v[c] and u[d] < v[d]) 
    end)
end

-- displays the class details for the chosen student so user can edit it
-- called from drawWeek
function editStudent()

    local c,p = 0,0

    local editLine = editStartLine
    local editStartX = startX -- use this to display fields, if i > 5 then add 480

    button(25, buttons.clearChosenStudent.y, 200, editButtonHeight,'Chosen Student = '..chosenStudent.name)
    showButton(buttons.clearChosenStudent,'CLEAR')

    -- check if data stored in chosenStudentData, if no stored data store it
    -- if data stored display it (use this stored data in doClassMouseClicks)

    if #chosenStudentData == 0 then createChosenStudentData() end
    if #chosenStudentData == 0 then return end

    setStudentClassesInMonth(chosenStudent.name)

    for i = 1, #chosenStudentData do
        local s = chosenStudentData[i]
        editLine = editLine + editLineIncrement
        if i == 6 then 
            editLine = editStartLine + editLineIncrement 
            editStartX = editStartX + 480
        end 
        -- display day
        button(editStartX,editLine,editButtonWidth,editButtonHeight,s.day)
        -- display date
        button(editStartX + 1 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,s.date..'/'..s.month..'/'..s.year)
        -- display class number or status
        if s.status == 0 then
            button(editStartX + 2 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,s.clsNum..'/'..s.pkg)
        elseif s.status == 1 then
            button(editStartX + 2 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'Cancelled')
        elseif s.status == 2 then
            button(editStartX + 2 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'Postponed')
        else
            button(editStartX + 2 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'Irregular')
        end
        -- display payment or 'click to pay'
        if s.paid > 0 then
            if showFinancialInfo then
                button(editStartX + 3 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,rupees(s.paid))
            else
                button(editStartX + 3 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'PAID')
            end
        else
            -- can press this to set payment
            button(editStartX + 3 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'*click to pay')
        end
        -- display 'new session' or 'click to set session'
        if s.start == 1 then
            button(editStartX + 4 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'Session Due')
        else
            button(editStartX + 4 * (editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'*Set Session')
        end
    end

    -- DELETE ALL THIS WHEN HAPPY

    -- for day = 1, 7 do
    --     for class = 1, #week[day] do
    --         cls = week[day][class]
    --         if chosenStudent.name == cls.name and cls.delete ~= 1 then
    --             editLine = editLine + editLineIncrement
    --             -- display day
    --             button(startX,editLine,editButtonWidth,editButtonHeight,D.dayName(day))
    --             -- display date
    --             button(startX + 1 *(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,cls.date..'/'..cls.month..'/'..cls.year)
    --             -- display class number or status
    --             if cls.status == 0 then
    --                 c,p = findClassNumber(cls)
    --                 button(startX+2*(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,c..'/'..p)
    --             elseif cls.status == 1 then
    --                 button(startX+2*(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'Cancelled')
    --             elseif cls.status == 2 then
    --                 button(startX+2*(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'Postponed')
    --             else
    --                 button(startX+2*(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'Irregular')
    --             end
    --             -- display payment or 'click to pay'
    --             if cls.paid > 0 then
    --                 if showFinancialInfo then
    --                     button(startX+3*(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,rupees(cls.paid))
    --                 else
    --                     button(startX+3*(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'PAID')
    --                 end
    --             else
    --                 -- can press this to set payment
    --                 button(startX+3*(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'*click to pay')
    --             end
    --             -- display 'new session' or 'click to set session'
    --             if startSessionAniversary(cls) then
    --                 button(startX+4*(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'New session')
    --             else
    --                 -- can press this to set session start
    --                 button(startX+4*(editButtonWidth + editButtonXGap),editLine,editButtonWidth,editButtonHeight,'*Set session')
    --             end
    --         end
    --     end
    -- end
end

-- draws all the classes in the active week
-- called from love.draw
function drawWeek()
    local yearOnMonday = 0
    local monthOnMonday = 0
    overAnyStudent = false
    mouseOverClass = nil
    for day = 1, 7 do
        local dayClasses = 0
        
        -- these 4 lines were moved from below
        local thisDay = D.currentDayOfWeek() - 1
        if thisDay == 0 then thisDay = 7 end
        local dayAdjust = day - thisDay
        local thisDate = D.getAdjustedDate(dayAdjust + (weekOffset * 7))
        
        drawReminder(day)

        -- draw classes and count active classes
        for class = 1,#week[day] do 
--printIfDebug('class on day '..day..' '..week[day][class].name..' status = '..week[day][class].status)        
            if week[day][class].delete ~= 1 then 
                if selectedStudentName ~= '' and week[day][class].name == 'new class' then 
                    week[day][class].name = selectedStudentName
                    updateStudentClasses(selectedStudentName,1) -- added 7th Dec 2020
                    updateNewName(week[day][class])
                    reCalculateClassNumbers(selectedStudentName)
-- UPDATE HERE - DONE - ONLY increase dayClasses if student package > 0 -- NEXT LINES
                    if zeroPackage(selectedStudentName) then 
                        week[day][class].status = -1
                        -- Need to update status of -1 in dayclass too
                        setDayStat(thisDate.year, thisDate.month, thisDate.day, week[day][class].name)
--                        weekTotals[thisWeekNum + weekOffset] =  weekTotals[thisWeekNum + weekOffset] - 1
                        -- same using newWeekTotals
                        newWeekTotals[thisWeekNum + weekOffset][day] =  newWeekTotals[thisWeekNum + weekOffset][day] - 1
                        newWeekTotals[thisWeekNum + weekOffset][8] =  newWeekTotals[thisWeekNum + weekOffset][8] - 1
                        totalNumClasses = totalNumClasses - 1
                        monthTotals[week[day][class].year][week[day][class].month] = monthTotals[week[day][class].year][week[day][class].month] - 1
                        monthTotals[week[day][class].year][13] = monthTotals[week[day][class].year][13] - 1
                    end
--                    selectedStudentName = '' -- NOV 27th to fix can't select student after add new class - didn't work
                end
                -- draw class if it is the chosen student or if no student chosen
                if not chosenStudent or chosenStudent.name == week[day][class].name then
                    drawClass(day,class) 
                end
--print('day = '..day..' class = '..class)                
                if week[day][class].status == 0 then dayClasses = dayClasses + 1 end
            end
        end
        -- moved this to above
        -- local thisDay = D.currentDayOfWeek() - 1
        -- if thisDay == 0 then thisDay = 7 end


        -- Highlight Today and draw current time line
        if weekOffset == 0 and (day == thisDay) then
            c_lgsc(todaySummaryBoxColour) 
            c_lgr('fill', startX + (thisDay - 1) * (classBoxWidth + classBoxPadX), dayY, classBoxWidth + classBoxPadX - 1, classBoxHeight, rectCorner, rectCorner)
            -- draw the date and the day totals on the day summary box
            c_lgsc(todaySummaryTextColour)
            c_lgp(D.dayName(day) .. ' ' .. thisDate.day ..'/' .. thisDate.month, startX + (day - 1) * (classBoxWidth + classBoxPadX) + 15, dayY + 5)
            c_lgp(dayClasses .. ' Classes', startX + (day - 1) * (classBoxWidth + classBoxPadX) + 15, dayY + 20)
            -- draw current time line it time is between displayed time ranges
            if currentHour >= startHour and currentHour < startHour + numEvents then
                local timeBarX = startX + (thisDay - 1) * (classBoxWidth + classBoxPadX)
                local minuteOffset = math.floor(classBoxHeight * (currentMinute / 60))
                local timeBarY = startY + ((currentHour - startHour) * (classBoxHeight + classBoxPadY)) + minuteOffset

                local saveWidth = c_lgglw()

                c_lgslw(3)
                c_lgsc(red)
                c_lgl(timeBarX, timeBarY, timeBarX + classBoxWidth + classBoxPadX, timeBarY)
                c_lgslw(saveWidth)
            end
        else
            -- draw day summary box
            c_lgsc(daySummaryBoxColour) 
            c_lgr('fill', startX + (day - 1) * (classBoxWidth + classBoxPadX), dayY, classBoxWidth + classBoxPadX - 1, daySummaryBoxHeight, rectCorner, rectCorner)
            -- draw the date and the day totals on the day summary box
            c_lgsc(daySummaryTextColour)
            c_lgp(D.dayName(day) .. ' ' .. thisDate.day ..'/' .. thisDate.month, startX + (day - 1) * (classBoxWidth + classBoxPadX) + 15, dayY + 5)
            c_lgp(dayClasses .. ' Classes', startX + (day - 1) * (classBoxWidth + classBoxPadX) + 15, dayY + 20)
        end


        -- print the month, year or months, years at top of screen
        c_lgsc(textColour)
        if day == 1 then 
            yearOnMonday = thisDate.year 
            monthOnMonday = thisDate.month 
        elseif day == 7 then
            if yearOnMonday ~= thisDate.year or monthOnMonday ~= thisDate.month then 
                c_lgpf(D.monthName(monthOnMonday)..', '..yearOnMonday..' - '..D.monthName(thisDate.month)..', '..thisDate.year,0, 3, windowWidth, 'center')
            else
                c_lgpf(D.monthName(thisDate.month)..', '..thisDate.year,0, 3, windowWidth, 'center')
            end
        end
    end

    if classMoved then 
        classMoved = false
        tweensOn = false
        createActiveWeekEvents() -- required to ensure correct day is set when class is moved
        tweensOn = true
    end

    if chosenStudent then 
        editStudent() 
        D.drawMonth(calendarX, calendarY,studentClassesThisMonth)
        showWeekDays()
    end
end

-- returns true if the student has had class within 60 days or if showAllStudents is true
-- called from displayStudents
function activeAtTime(name,lastClassYr,lastClassMth)
    if showAllStudents then return true end

    for i = 1, #week do
        for j = 1, #week[i] do
            thisClass = week[i][j]
            if thisClass.name == name then 
                return true
            end
        end
    end

    local weekDay = D.currentDayOfWeek() - 1
    if weekDay == 0 then weekDay = 7 end
    local dayAdjust = ((weekOffset + 1) * 7) - weekDay    
    local displayWeekDate = D.getAdjustedDate(dayAdjust)
    local days = D.numDaysBetween(lastClassYr,lastClassMth,1,displayWeekDate.year,displayWeekDate.month,displayWeekDate.day)
    return days < 60 and days > 0
end

-- displays student names on the left of the screen so they can be selected
-- called from love.draw
function displayStudents()
    local xPos, yPos
    local activeStudents = {}
    for i = 1, #student do
        student[i].x = 0
        student[i].y = 0
        if activeAtTime(student[i].name, student[i].startYr, student[i].startMth) then
--            if student[i].package > 0 then 
                activeStudents[#activeStudents + 1] = i
--            end
        end
    end
    local middle = #activeStudents - math.floor(#activeStudents / 3)
    local left = middle - math.floor(#activeStudents / 3)
    for i = 1, #activeStudents do
        if i > middle then
            xPos = studentNamesX + 210
            yPos = studentNamesY + ((i - middle) * 25)
        elseif i > left then
            xPos = studentNamesX + 105
            yPos = studentNamesY + ((i - left) * 25)
        else
            xPos = studentNamesX
            yPos = studentNamesY + (i * 25)
        end
        student[activeStudents[i]].x = xPos
        student[activeStudents[i]].y = yPos
        c_lgsc(C.getColour(2,student[activeStudents[i]].colour))
        c_lgr('fill', xPos, yPos, 95, 20, rectCorner, rectCorner)
        c_lgsc(studentNameTextColour)
        c_lgp(student[activeStudents[i]].name..' '..student[activeStudents[i]].numClasses, xPos + 5, yPos + 3)
        if yPos > maxStudentY then maxStudentY = yPos end
    end
    maxStudentY = maxStudentY + 25
    c_lgsc(textColour)
end

-- returns the number passed in 'num' in rupee format
-- called from everywhere
function rupees(num)
    local lachs = math.floor(num / 100000)
    local thousands = math.floor((num - lachs * 100000) / 1000)
    local rest = num - lachs * 100000 - thousands * 1000
    if rest == 0 then rest = '000' end
    if thousands < 10 then 
        if lachs > 0 then thousands = '0'..thousands end
    end
    if lachs == 0 then
        return 'Rs. '..thousands..','..rest
    else
        return 'Rs. '..lachs..','..thousands..','..rest
    end
end

-- draws menu button which are common to the states :- classes and statistics
-- called from drawMenu
function drawCommonMenuBits()
    -- display button to toggle rupee totals display
    if showFinancialInfo then
        showButton(buttons.financialInfo,'Hide Rupees')
    else
        showButton(buttons.financialInfo,'Show Rupees')
    end

    -- display button to toggle statistics window
    if state == statistics then
        showButton(buttons.showStats,'Hide Stats')
    else
        showButton(buttons.showStats,'Show Stats')
    end

    -- display button to toggle changing colours
    if changingColours then
        showButton(buttons.changeColours,'Stop Colour Change')
    else
        showButton(buttons.changeColours,'Start Colour Change')
    end
end

-- draws menu button which are specific to the state :- classes 
-- called from drawMenu
function drawClassesMenu()
    -- display button to add a new week
    showButton(buttons.newWeek,'Add a new week')

    -- display button to toggle active student display
    if showAllStudents then
        showButton(buttons.allStudents,'Show Active Students')
    else
        showButton(buttons.allStudents,'Show All Students')
    end

    -- display button to change to asanas
    showButton(buttons.gotoAsanas,'Show Asanas')
end

-- draws menu button which are specific to the state :- statistics
-- called from drawMenu
function drawStatisticsMenu()
    -- display button to toggle financial year or calendar year
    if financialYear then
        showButton(buttons.financialYearToggle,'Calendar Year')
    else
        showButton(buttons.financialYearToggle,'Financial Year')
    end
end

-- draws all the menu elements
-- called from drawScreenElements
function drawMenu()
    if state == classes then
        drawClassesMenu()
        drawCommonMenuBits()
    elseif state == statistics then
        drawStatisticsMenu()
        drawCommonMenuBits()
    elseif state == asanas then
    end
end

-- draws buttons used on classes screen, and draws the week's totals and the week number
-- called from love.draw
function drawButtons()
    -- display arrows to change weeks
    showButton(buttons.prevWeek,'<')
    showButton(buttons.nextWeek,'>')

    -- display Today to reset week to current
    button(startX - 47, dayY - 10, 40, 25, 'Today')

    -- draw this weeks totals
--    if weekTotals[thisWeekNum + weekOffset] == nil then weekTotals[thisWeekNum + weekOffset] = 0 end
--    c_lgp('Week Total : ' .. weekTotals[thisWeekNum + weekOffset], startX, dayY - 15)
    -- same using newWeekTotals
    if newWeekTotals[thisWeekNum + weekOffset] == nil then newWeekTotals[thisWeekNum + weekOffset] = {0,0,0,0,0,0,0,0,0} end
    c_lgp('Week Total : ' .. newWeekTotals[thisWeekNum + weekOffset][8]..'/'..newWeekTotals[thisWeekNum + weekOffset][9], startX, dayY - 15)
    c_lgp(thisWeekNum + weekOffset, startX + 885, dayY - 15)
end

-- draws the bar of the monthly takings graph for passed 'yr' and 'mth' at position 'x','y' passed
-- called from drawAllTimeTotalTakingsGraph
function drawGraph(yr,mth,x,y)
--    if state == classes then c_lgsc(0,.6,.6,1) else c_lgsc(1,1,.6,1) end
    c_lgsc(graphColour)
    local maxMthTakings = 250000
    local maxBarSize = 65
    local ratio = yearTakingsTotals[yr][mth]/maxMthTakings
    local thisBar = ratio * maxBarSize
    c_lgr('fill',x,y - thisBar, 2, thisBar)
    if state == statistics then c_lgsc(statisticsTextColour) else c_lgsc(textColour) end
end
    
-- draws the monthly takings graph
-- called from drawScreenElements
function drawAllTimeTotalTakingsGraph()
    if not overAnyStudent and not chosenStudent then
        if state == statistics then c_lgsc(statisticsTextColour) else c_lgsc(textColour) end
        local totalPaymentsAllTime = 0
        local thisYear = D.currentYear()
        local startYear = thisYear - 8
        for i = 2012,thisYear do
            totalPaymentsAllTime = totalPaymentsAllTime + yearTakingsTotals[i][13]
            if i >= startYear then
                c_lgp(i,graphX + (i % 2012) * 100, windowHeight - 120)
                if showFinancialInfo then
                    c_lgp(rupees(yearTakingsTotals[i][13]),graphX + (i % 2012) * 100, windowHeight - 100)
                end
                for j = 1,12 do 
                    if yearTakingsTotals[i][j] then
                        drawGraph(i,j,(j - 1) * 7 + graphX + (i % 2012) * 100, windowHeight - 25) 
                    end
                end
            end
        end
        if showFinancialInfo then
            c_lgp('Total',graphX + 900, windowHeight - 120)
            c_lgp(rupees(totalPaymentsAllTime),graphX + 900,windowHeight - 100)
        end
    end
end

-- draws all the screen elements
-- called from love.draw
function drawScreenElements()
    -- draw month calendar and month totals
    if state == statistics then c_lgsc(statisticsTextColour) else c_lgsc(textColour) end

    if overAnyStudent then
        D.drawMonth(calendarX, calendarY,studentClassesThisMonth)
    else
        D.drawMonth(calendarX, calendarY)
    end

    if state == statistics then c_lgsc(statisticsTextColour) else c_lgsc(textColour) end

    if monthTotals[D.getCalendarYear()] then
        c_lgp('Total Classes : ' .. monthTotals[D.getCalendarYear()][D.getCalendarMonthNum()],calendarX + 20, calendarY - 37)
    end

    drawAllTimeTotalTakingsGraph()
    drawMenu()
end

-- returns the number passed 'num' to the number of decimals passed in 'numDecimalPlaces'
-- called from drawAllTimeTotals
function round2(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- draws the labels for the data on the statistics window
-- called from drawAllTimeTotals
function drawTotalsLabels(startLine,gap)
    c_lgsc(statisticsTextColour)
    c_lgp('Totals',370, startLine + gap)
    c_lgp('Average',370, startLine + 2 * gap)
    c_lgp('Best',370, startLine + 3 * gap)

    c_lgp('Best Day',370,startLine + 5 * gap)
    c_lgp('Best Week',370,startLine + 6 * gap)
    c_lgp('Best Month',370,startLine + 7 * gap)
    c_lgp('Best Year',370,startLine + 8 * gap)

    c_lgp('Average Day',500,startLine + 5 * gap)
    c_lgp('Average Week',500,startLine + 6 * gap)
    c_lgp('Average Month',500,startLine + 7 * gap)
    c_lgp('Average Year',500,startLine + 8 * gap)

    c_lgp('Total Classes',370,startLine + 10 * gap)
    c_lgp('Total Days',370,startLine + 11 * gap)
    c_lgp('Total Weeks',370,startLine + 12 * gap)
    c_lgp('Total Months',370,startLine + 13 * gap)
    c_lgp('Total Years',370,startLine + 14 * gap)

    c_lgp('Weekly Class Numbers',370,300)
    c_lgp('Monthly Class Numbers',370,430)
    c_lgp('Monthly Takings',370,700)

    local wd = {"Mon","Tue","Wed","Thu","Fri","Sat","Sun"}
    for i = 1, 7 do c_lgpf(wd[i], 400 + (i - 1) * 60, startLine, 100, 'center') end
end

-- draws all the statistics data on the statistics window
-- called from love.draw
function drawAllTimeTotals()
    local startLine = 60
    local gap = 15
    local dayDistributionX = 650--370
    local dayDistributionY = 240--650

    drawTotalsLabels(startLine,gap)

    c_lgsc(statsDataColour)

    -- draw monday to sunday totals, averages, and records
    for i = 1, 7 do
        c_lgpf(weekDayTotals[i], 400 + (i - 1) * 60, startLine + gap, 100, 'center')
        c_lgpf(round2(weekDayTotals[i]/totalDataWeeks,3), 400 + (i - 1) * 60, startLine + 2 * gap, 100, 'center')
        c_lgpf(dayRecords[i],400 + (i - 1) * 60, startLine + 3 * gap, 100, 'center')
    end

    -- draw best day, week, month, and year
    c_lgpf(bestDay,420,startLine + 5 * gap, 100, 'center')
    c_lgpf(bestWeek,420,startLine + 6 * gap, 100, 'center')
    c_lgpf(bestMonth,420,startLine + 7 * gap, 100, 'center')
    c_lgpf(bestYear,420,startLine + 8 * gap, 100, 'center')

    -- draw Average day, week, month, and year
    c_lgpf(round2(totalNumClasses/totalDataDays,2),570,startLine + 5 * gap, 100, 'center')
    c_lgpf(round2(totalNumClasses/totalDataWeeks,2),570,startLine + 6 * gap, 100, 'center')
    c_lgpf(round2(totalNumClasses/numMonths,2),570,startLine + 7 * gap, 100, 'center')
    c_lgpf(round2(totalNumClasses/numYears),570,startLine + 8 * gap, 100, 'center')

    -- draw all-time totals
    c_lgpf(totalNumClasses,420,startLine + 10 * gap, 100, 'center')
    c_lgpf(totalDataDays,420,startLine + 11 * gap, 100, 'center')
    c_lgpf(totalDataWeeks,420,startLine + 12 * gap, 100, 'center')
    c_lgpf(numMonths,420,startLine + 13 * gap, 100, 'center')
    c_lgpf(numYears,420,startLine + 14 * gap, 100, 'center')

    -- draw per-day distribution labels and heading
    for i = 1,bestDay do c_lgpf(i,dayDistributionX + (i - 1) * 20,dayDistributionY + 5, 20, 'center') end
    c_lgsc(statisticsTextColour)
    c_lgp('Classes per day distribution',dayDistributionX + 35,dayDistributionY + 20)

    -- draw week totals graph
    c_lgsc(graphColour)
    local maxBarSize = 100
    local barNumber = 0
    local year = startYear + 1
    for i = math.max(1,#newWeekTotals - 200), #newWeekTotals do -- replaced weekTotals with newWeekTotals 
        barNumber = barNumber + 1
        if (i - 9) % 52 == 0 then barNumber = barNumber + 2 end
        if (i - 9) % 52 == 0 then 
            c_lgsc(textColour)
            c_lgp(year,370 + (barNumber - 1) * 5,405) 
            year = year + 1
        end
        -- if weekTotals[i] == nil then weekTotals[i] = 0 end
        -- local ratio = weekTotals[i]/bestWeek
        if newWeekTotals[i] == nil then newWeekTotals[i] = {0,0,0,0,0,0,0,0,0} end
        local ratio = newWeekTotals[i][8]/bestWeek
        local thisBar = ratio * maxBarSize
        if ratio > 0.9 then c_lgsc(green) 
        elseif ratio > 0.8 then c_lgsc(lightBlue) 
        elseif ratio > 0.7 then c_lgsc(yellow) 
        else c_lgsc(white) 
        end
        c_lgr('fill',370 + (barNumber - 1) * 5,400 - thisBar, 3, thisBar)
    end

    -- draw month totals graph
    barNumber = 0
    for i = startYear,D.getCalendarYear() do
        for j = 1, 12 do
            if i > startYear or (i >= startYear and j >= startMonth) then
                barNumber = barNumber + 1
                local ratio = monthTotals[i][j]/bestMonth
                local thisBar = ratio * maxBarSize
                if ratio > 0.9 then c_lgsc(green) 
                elseif ratio > 0.8 then c_lgsc(lightBlue) 
                elseif ratio > 0.7 then c_lgsc(yellow) 
                else c_lgsc(white) 
                end
            c_lgr('fill',370 + (barNumber - 1) * 5,550 - thisBar, 3, thisBar)
            end
        end
    end

    c_lgsc(graphColour)

    -- draw classes per day distribution graph
    local maxBarSize = 180
    for i = 1,bestDay do
        local ratio = classesPerDay[i]/200
        local thisBar = ratio * maxBarSize
        c_lgr('fill',dayDistributionX + 5 + (i - 1) * 20,dayDistributionY - thisBar, 12, thisBar)
    end

    c_lgsc(textColour)
end

-- function love.wheelmoved(x, y)
-- end

-- draw the colour elements R G B A for the colour called 'name' at position 'x','y'
-- called from changeColours
function displayColours(name,itemColour,x,y)
    local bWidth = 40
    local bHeight = 15
    local gapX = 50
    c_lgsc(changeColoursTextColour)
    c_lgp(name,x,y)
    for i = 1, 4 do button(x+50+(i * gapX),y,bWidth,bHeight,itemColour[i]) end
end

-- displays all the colours that the used can change
-- called from love.draw
function changeColours()
    if memoryDay > 0 then return end
    c_lgsc(changeColoursTextColour)   
    c_lgr('line', colourWindowxPos+2, colourWindowyPos+2, colourWindowWidth, colourWindowHeight)
    c_lgsc(.8,.8,.8,1)
    c_lgr('fill', colourWindowxPos, colourWindowyPos, colourWindowWidth, colourWindowHeight)

    displayColours('Colour',{'R','G','B','A'},colourWindowxPos+5,colourWindowyPos+10)
    displayColours('Load Theme',{'Dark','Light','Andy','Nish'},colourWindowxPos+5,colourWindowyPos+310)

    displayColours('Border',backgroundColour,colourWindowxPos+5,colourWindowyPos+50)
    
    if state == classes then
        displayColours('Background',classesWindowColour,colourWindowxPos+5,colourWindowyPos+70)
        displayColours('Day Header',daySummaryBoxColour,colourWindowxPos+5,colourWindowyPos+90)
        displayColours('Today Header',todaySummaryBoxColour,colourWindowxPos+5,colourWindowyPos+110)
    elseif state == statistics then
        displayColours('Background',statisticsWindowColour,colourWindowxPos+5,colourWindowyPos+70)
        displayColours('Data',statsDataColour,colourWindowxPos+5,colourWindowyPos+90)
        displayColours('Year Calendar',yearCalColour,colourWindowxPos+5,colourWindowyPos+110)
    elseif state == asanas then
        displayColours('Background',asanasWindowColour,colourWindowxPos+5,colourWindowyPos+70)
        displayColours('Centre',asanaDetailsColour,colourWindowxPos+5,colourWindowyPos+90)
        displayColours('List',asanaListColour,colourWindowxPos+5,colourWindowyPos+110)
        displayColours('Highlight Text',highlightTextColour,colourWindowxPos+5,colourWindowyPos+130)
        displayColours('Highlight Back',highlightBackColour,colourWindowxPos+5,colourWindowyPos+150)
        displayColours('Name',englishNameColour,colourWindowxPos+5,colourWindowyPos+170)
        displayColours('Linked Asana',linkedAsanaBoxColour,colourWindowxPos+5,colourWindowyPos+190)
        displayColours('Classification',classificationColour,colourWindowxPos+5,colourWindowyPos+210)
        displayColours('Class Name',classificationTitleColour,colourWindowxPos+5,colourWindowyPos+230)
        displayColours('Search Box',searchClassificationChoicesColour,colourWindowxPos+5,colourWindowyPos+250)
        displayColours('Search Title',searchClassificationTitleColour,colourWindowxPos+5,colourWindowyPos+270)
--        displayColours('Colour 12',statisticsWindowColour,colourWindowxPos+5,colourWindowyPos+270)
    end
    if state ~= asanas then
        displayColours('Button',normalButtonColour,colourWindowxPos+5,colourWindowyPos+150)
        displayColours('Over Button',highlightButtonColour,colourWindowxPos+5,colourWindowyPos+170)
        displayColours('Graph',graphColour,colourWindowxPos+5,colourWindowyPos+190)
    end
    c_lgsc(textColour)
end

-- returns true if the 'colour' passed is considered dark
-- called from fixDarkText
function dark(colour)
    return (colour[1] < .4 and colour[2] < .4 and colour[3] < .4)
end

-- swaps text colours from white to black when the background changes from light to dark
-- called from love.draw
function fixDarkText()
    if dark(classesWindowColour) then textColour = white else textColour = black end
    if dark(daySummaryBoxColour) then daySummaryTextColour = white else daySummaryTextColour = black end
    if dark(todaySummaryBoxColour) then todaySummaryTextColour = white else todaySummaryTextColour = black end
    if dark(statisticsWindowColour) then statisticsTextColour = white else statisticsTextColour = black end
    if dark(normalButtonColour) then buttonTextColour = white else buttonTextColour = black end
end

-- scales the graphics and calls program elements depending on current state
-- called from love2d
function love.draw()
--    love.graphics.push()
    love.graphics.scale(myScale, myScale)
    -- set background colour
    c_lgclr(backgroundColour)
    fixDarkText()
    if state == statistics then
        showStatsWindow()
        drawScreenElements()
        drawYearGrid()
        drawAllTimeTotals()
    elseif state == asanas then
        Asana.showAsanasWindow()
    elseif state == classes then
        showClassesWindow()
        drawScreenElements()
        drawDayGrid()
        drawWeek()
        displayStudents()
        drawWeekHighlights()
        drawButtons()
        showMemory(memoryDay)
        findFirstFreeWeek() -- debug
        if testPhoto > 0 then drawMemory(memories[testPhoto],true, testPhoto) end
    end
    if changingColours then changeColours() end
--    love.graphics.pop()
    local mx,my = getScaledMousePos() --love.mouse.getPosition()
    c_lgp('mx = '..math.floor(mx*myScale)..' my = '..math.floor(my*myScale),windowWidth-150,windowHeight - 18)   
    c_lgp('Animations',20,windowHeight - 18) 
    c_lgc('line',100,windowHeight - 11,8)
--    c_lgr('line',92,windowHeight - 19,16,16)
    if scrolling then c_lgc('fill',100,windowHeight - 11,4) end
end 