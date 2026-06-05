# Test Invalid 2: MISSING TASK NAME
# Scenario: A task block opened without providing a name.
#           Expected: SYNTAX ERROR

TASK {
    RUN "script.sh"
    EVERY DAY AT 09:00
}
