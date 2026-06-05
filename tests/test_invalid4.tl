# Test Invalid 4: DEPENDENCY ON UNDEFINED TASK
# Scenario: sendReport depends on "dbBackup" but that task doesn't exist.
#           Expected: WARNING about unknown dependency, but parsing continues.

TASK sendReport {
    RUN "report.py"
    AFTER dbBackup
    IF success
}
