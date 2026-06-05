# Test 1: Simple daily recurring scheduled task
# Scenario: A basic task that runs a script every day at 6AM.

TASK dailyReport {
    RUN "report.py"
    EVERY DAY AT 06:00
}
