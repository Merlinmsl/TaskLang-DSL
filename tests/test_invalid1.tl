# Test invalid 1: CIRCULAR DEPENDENCY
# Scenario: taskA depends on taskB, and taskB depends on taskA.
#           This creates an infinite loop in execution order.
#           Expected: ERROR - circular dependency detected.

TASK taskA {
    RUN "scriptA.sh"
    AFTER taskB
}

TASK taskB {
    RUN "scriptB.sh"
    AFTER taskA
}
