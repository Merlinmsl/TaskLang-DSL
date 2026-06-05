# Test Valid 5: REAL-WORLD CI/CD PIPELINE (Edge Case)
# Scenario: A 4-task pipeline combining all features:
#   - One-time scheduled task (AT time only)
#   - Tasks with BEFORE dependency syntax
#   - IF failure conditional notification
#   This tests the AT schedule variant and BEFORE keyword.

TASK fetchData {
    RUN "fetch.sh"
    AT 00:00
}

TASK processData {
    RUN "process.py"
    AFTER fetchData
    IF success
}

TASK archiveData {
    RUN "archive.sh"
    AFTER processData
    IF success
}

TASK notifyFailure {
    RUN "notify.sh"
    AFTER processData
    IF failure
}
