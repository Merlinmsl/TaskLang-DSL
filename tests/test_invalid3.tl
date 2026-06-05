# Test Invalid 3: TASK WITH NO RUN STATEMENT
# Scenario: A task that has schedule but no RUN command.
#           This is valid syntactically (task_body can be empty or partial)
#           but semantically incomplete - shows warning in output.

TASK emptyTask {
    EVERY DAY AT 10:00
}
