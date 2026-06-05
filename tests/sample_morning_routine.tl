# ============================================
# morning_routine.tl
# TaskLang++ Sample Program 1
# A personal morning automation pipeline
# =============================================

# Step 1 - Wake up and make coffee first!
TASK makeCoffee {
    RUN "coffee_machine.sh"
    EVERY DAY AT 07:00
}

# Step 2 - Check the weather only AFTER coffee is ready
TASK checkWeather {
    RUN "weather_alert.py"
    AFTER makeCoffee
    IF success
}

# Step 3 - Send yourself a good morning summary
TASK morningBriefing {
    RUN "send_briefing.py"
    AFTER checkWeather
    IF success
}

# Step 4 - If weather check FAILED, send a plain alarm instead
TASK backupAlarm {
    RUN "loud_alarm.sh"
    AFTER checkWeather
    IF failure
}
