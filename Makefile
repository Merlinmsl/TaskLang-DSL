# ================================================================
# Makefile -- TaskLang++ Build System
# SE2052 Programming Paradigms
# ================================================================
#
# This Makefile follows the Exact compile sequence taught in Lec4:
#
#   Step 1:  bison -d parser.y
#              (equivalent to "yacc -d calc.y")
#              --> produces parser.tab.c  (the parser C code)
#              --> produces parser.tab.h  (token #define constants)
#              The -d flag means "generate the header file"
#
#   Step 2:  flex lexer.l
#              (equivalent to "lex calc.l")
#              --> produces lex.yy.c  (the lexer C code)
#              The lexer #includes parser.tab.h to get token codes
#
#   Step 3:  gcc -o tasklang parser.tab.c lex.yy.c -lfl
#              --> compiles both generated C files into one program
#              -lfl  links the Flex runtime library
#              (equivalent to "gcc -o calc y.tab.c lex.yy.c -lfl")
#
# Notes:      "GNU Bison is the Linux version of Yacc.
#             BSD Flex is the Linux version of Lex."
# ================================================================

# Compiler and flags
CC     = gcc
CFLAGS = -Wall -g

# Output executable name
TARGET = tasklang

# Default target: build the executable
.PHONY: all clean test

all: $(TARGET)

# ----------------------------------------------------------------
# Step 3: Link compiled C files into the executable.
# Dependencies ensure Steps 1 and 2 run first if needed.
# ----------------------------------------------------------------
$(TARGET): parser.tab.c lex.yy.c
	$(CC) $(CFLAGS) -o $(TARGET) parser.tab.c lex.yy.c -lfl

# ----------------------------------------------------------------
# Step 1: Run Bison on parser.y
# Produces parser.tab.c and parser.tab.h
# ----------------------------------------------------------------
parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

# ----------------------------------------------------------------
# Step 2: Run Flex on lexer.l
# Must happen AFTER Step 1 because lexer.l includes parser.tab.h
# ----------------------------------------------------------------
lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

# ----------------------------------------------------------------
# Test target: runs all 10 test cases
# ----------------------------------------------------------------
test: $(TARGET)
	@echo "======================================================="
	@echo "  TaskLang++ Test Suite -- SE2052"
	@echo "======================================================="
	@echo ""
	@echo "--- VALID PROGRAMS (should parse and execute) ---"
	@echo ""
	@echo "[TEST 1] Simple daily recurring task"
	@./$(TARGET) < tests/test_valid1.tl
	@echo ""
	@echo "[TEST 2] Multi-step workflow with conditions (assignment example)"
	@./$(TARGET) < tests/test_valid2.tl
	@echo ""
	@echo "[TEST 3] Three-step CI/CD pipeline (chained dependencies)"
	@./$(TARGET) < tests/test_valid3.tl
	@echo ""
	@echo "[TEST 4] Weekly schedule + DEPENDS ON + IF failure"
	@./$(TARGET) < tests/test_valid4.tl
	@echo ""
	@echo "[TEST 5] Complex 4-task pipeline with AT time and dual-branch"
	@./$(TARGET) < tests/test_valid5.tl
	@echo ""
	@echo "--- INVALID PROGRAMS (should report errors) ---"
	@echo ""
	@echo "[TEST 6] Circular dependency -- A depends on B, B depends on A"
	@./$(TARGET) < tests/test_invalid1.tl 2>&1 || true
	@echo ""
	@echo "[TEST 7] Missing task name -- TASK { } without an identifier"
	@./$(TARGET) < tests/test_invalid2.tl 2>&1 || true
	@echo ""
	@echo "[TEST 8] Task with no RUN statement -- schedule but no command"
	@./$(TARGET) < tests/test_invalid3.tl 2>&1 || true
	@echo ""
	@echo "[TEST 9] Dependency on undefined task -- task name not declared"
	@./$(TARGET) < tests/test_invalid4.tl 2>&1 || true
	@echo ""
	@echo "[TEST 10] Unknown keyword -- SCHEDULE is not in TaskLang++"
	@./$(TARGET) < tests/test_invalid5.tl 2>&1 || true
	@echo ""
	@echo "======================================================="
	@echo "  All tests completed."
	@echo "======================================================="

# ----------------------------------------------------------------
# Clean: remove all generated files(fresh start)
# ----------------------------------------------------------------
clean:
	rm -f $(TARGET) parser.tab.c parser.tab.h lex.yy.c *.o
	@echo "Cleaned all generated files."
