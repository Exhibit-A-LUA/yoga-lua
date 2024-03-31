local date = {}

local font = c_lggf()

    -- os.date returns fields year (four digits), month (1--12), day (1--31), 
    -- hour (0--23), min (0--59), sec (0--61), wday (weekday, Sunday is 1), 
    -- yday (day of the year), and isdst (daylight saving flag, a boolean).

    
    
local months = {'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'}
local days = {'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'}
    
    
local dateTable = os.date('*t')
local thisMonth = dateTable.month
local thisYear = dateTable.year
local thisDay = dateTable.day

local calendarYear = thisYear
local calendarMonth = thisMonth
local calendarDay = thisDay

function date.numDaysBetween(Yr1,Mth1,Day1,Yr2,Mth2,Day2)
    local startTime = os.time({year=Yr1,month=Mth1,day=Day1})
    local endTime = os.time({year=Yr2,month=Mth2,day=Day2})
    return (endTime - startTime) / (3600 * 24)
end

function date.before(Yr1,Mth1,Day1,Yr2,Mth2,Day2)
    local startTime = os.time({year=Yr1,month=Mth1,day=Day1})
    local endTime = os.time({year=Yr2,month=Mth2,day=Day2})
    return startTime < endTime
end

function date.get_days_in_month(mnth, yr)
    return os.date('*t',os.time{year=yr,month=mnth+1,day=0})['day']
end

-- returns the day of week integer 0 = Sunday
-- and the name of the week day
function date.get_day_of_week(dd, mm, yy)
    dw=os.date('*t',os.time{year=yy,month=mm,day=dd})['wday']
    return dw,({"Sun","Mon","Tue","Wed","Thu","Fri","Sat" })[dw]
end

function date.currentDayOfWeek()
    return date.get_day_of_week(thisDay, thisMonth, thisYear)
end

function date.getAdjustedDate(dayDiff)
    local now = os.date("*t") -- defaults to current date and time
    local nowutc = os.time(now)
    return os.date('*t',nowutc + dayDiff * 24 * 3600)
end

function date.currentDay()
    return thisDay
end

function date.dayName(day)
    return days[day]
end

function date.monthName(mth)
    return months[mth]
end

function date.currentMonth()
    return months[thisMonth]
end

function date.currentMonthNum()
    return thisMonth
end

function date.currentYear()
    return thisYear
end

function date.getCalendarMonthNum()
    return calendarMonth
end

function date.getCalendarYear()
    return calendarYear
end

function date.nextMonth()
    calendarMonth = calendarMonth + 1
    if calendarMonth > 12 then
        calendarMonth = 1
        calendarYear = calendarYear + 1
    end
end

function date.prevMonth()
    calendarMonth = calendarMonth - 1
    if calendarMonth < 1 then
        calendarMonth = 12
        calendarYear = calendarYear - 1
    end
end

function date.drawMonth(calendarX,startY,highlight)

    local highlightColour = {.9,.9,.9,1}
    local thisMonthName = months[calendarMonth]
    local dayOfWeek = date.get_day_of_week(01, calendarMonth, calendarYear) - 1
    if dayOfWeek == 0 then dayOfWeek = 7 end
    
    local daysInMonth = date.get_days_in_month(calendarMonth, calendarYear)

    c_lgp(thisMonthName .. '  ' .. calendarYear, calendarX + 5, startY - 20)
    -- uses global variable buttons!
    button(buttons.nextMonth.x,buttons.nextMonth.y,buttons.nextMonth.w,buttons.nextMonth.h,'>')
    button(buttons.prevMonth.x,buttons.prevMonth.y,buttons.prevMonth.w,buttons.prevMonth.h,'<')

    local width = font:getWidth('28') * 1.4
    c_lgpf('M', calendarX, startY, width, 'center')
    c_lgpf('T', calendarX + width * 1, startY, width, 'center')
    c_lgpf('W', calendarX + width * 2, startY, width, 'center')
    c_lgpf('T', calendarX + width * 3, startY, width, 'center')
    c_lgpf('F', calendarX + width * 4, startY, width, 'center')
    c_lgpf('S', calendarX + width * 5, startY, width, 'center')
    c_lgpf('S', calendarX + width * 6, startY, width, 'center')

    for i = 1, daysInMonth do
        local pos = i + dayOfWeek - 1
        if highlight then
            if highlight[i] == 1 then     highlightColour = {1,0,0,1}
            elseif highlight[i] == 2 then highlightColour = {.2,.8,1,1}
            elseif highlight[i] == 0 then highlightColour = {0,1,0,1}
            else                          highlightColour = {.9,.9,.9,1}
            end
        end
        c_lgsc(highlightColour)
        c_lgr('fill',calendarX + width * ((pos - 1) % 7), startY + 20 + 20 * math.floor((pos - 1) / 7), width - 3, 20 - 3)
        c_lgsc(0,0,0,1)
        c_lgpf(i, calendarX + width * ((pos - 1) % 7), startY + 20 + 20 * math.floor((pos - 1) / 7), width, 'center')
    end
    c_lgsc(0,0,0,1)
end

return date
