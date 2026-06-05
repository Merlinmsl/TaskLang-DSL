# Test 2: Multi-step workflow chained with conditions
# Scenario: Backup DB first, then send a report only if backup succeeded, then run weekly cleanup.

TASK backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00
}

TASK sendReport {
    RUN "report.py"
    AFTER backupDB
    IF success
}

TASK cleanup {
    RUN "cleanup.sh"
    EVERY WEEK ON SUNDAY AT 03:00
}
