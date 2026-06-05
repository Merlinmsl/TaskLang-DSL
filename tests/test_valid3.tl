# Test 3 : Multiple chained dependencies
# Scenario: A 3-step CI/CD pipeline where each step depends on the previous.
#           taskC depends on taskB, which depends on taskA.
#           Expected execution order: taskA --> taskB --> taskC

TASK buildApp {
    RUN "build.sh"
    EVERY DAY AT 08:00
}

TASK runTests {
    RUN "test_suite.sh"
    AFTER buildApp
    IF success
}

TASK deployApp {
    RUN "deploy.sh"
    AFTER runTests
    IF success
}
