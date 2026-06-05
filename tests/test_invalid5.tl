# Test Invalid 5: WRONG KEYWORD / TYPO
# Scenario: "SCHEDULE" is not a valid keyword in TaskLang++
#           Expected: SYNTAX ERROR - unrecognized token.

TASK badSyntax {
    RUN "script.sh"
    SCHEDULE DAILY AT 09:00
}
















