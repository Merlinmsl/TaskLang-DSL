# Test 4: Weekly task with DEPENDS ON syntax and IF failure condition
# Scenario: A weekly database maintenance workflow.
#           Uses DEPENDS ON alternative syntax.
#           Also tests IF failure condition.

TASK weeklyBackup {
    RUN "weekly_backup.sh"
    EVERY WEEK ON SATURDAY AT 23:00
}

TASK alertAdmin {
    RUN "alert.sh"
    DEPENDS ON weeklyBackup
    IF failure
}

TASK generateReport {
    RUN "weekly_report.py"
    EVERY WEEK ON SUNDAY AT 08:00
}
