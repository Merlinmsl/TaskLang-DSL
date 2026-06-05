# TaskLang++ — A Domain-Specific Language for Task Scheduling and Automation

**SE2052 Programming Paradigms | Y2 S2 — BSc (Hons) in Computer Science**
**Take-Home Individual Assignment**

---

## What is TaskLang++?

TaskLang++ is a Domain-Specific Language (DSL) designed to make task scheduling simple and readable. Instead of writing complex scripts in Python or Bash to automate recurring jobs, you write clean and human-readable TaskLang++ programs.

A TaskLang++ program looks like this:

```
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
```

The parser reads this, resolves dependencies, detects circular dependency errors, and prints the correct execution order.

---

## Features

- Define tasks with a name and a script to run
- Schedule tasks daily, weekly on a named day, or at a specific one-off time
- Chain tasks using `AFTER`, `BEFORE`, or `DEPENDS ON`
- Conditional execution using `IF success` or `IF failure`
- Automatic dependency ordering using Depth-First Search (topological sort)
- Circular dependency detection with a clear error message
- Warning for dependencies referencing undefined tasks
- Lexical error reporting for unrecognised characters
- Syntax error reporting with line number and the problematic token
- Comment support using the `#` character
- 10 test programs covering valid and invalid scenarios

---

## Language Syntax Overview

### Task Definition

```
TASK taskName {
    RUN "script_name.sh"
    EVERY DAY AT 06:00
}
```

### Scheduling Options

```
EVERY DAY AT 06:00                  # runs every day at 6AM
EVERY WEEK ON SUNDAY AT 03:00       # runs every Sunday at 3AM
AT 00:00                            # runs once at midnight
```

### Dependencies

```
AFTER taskName                      # run after taskName completes
BEFORE taskName                     # this task runs before taskName
DEPENDS ON taskName                 # same meaning as AFTER
```

### Conditional Execution

```
IF success                          # only run if dependency succeeded
IF failure                          # only run if dependency failed
```

### Comments

```
# This is a comment — ignored by the parser
```

---

## Project Structure

```
tasklang/
├── lexer.l                         # Lex lexical analyser
├── parser.y                        # Yacc grammar and parser
├── Makefile                        # Build instructions
└── tests/
    ├── test_valid1.tl              # Simple daily task
    ├── test_valid2.tl              # Multi-step workflow (assignment example)
    ├── test_valid3.tl              # Three-step CI/CD pipeline
    ├── test_valid4.tl              # Weekly schedule + DEPENDS ON + IF failure
    ├── test_valid5.tl              # Complex 4-task pipeline
    ├── test_invalid1.tl            # Circular dependency
    ├── test_invalid2.tl            # Missing task name
    ├── test_invalid3.tl            # Task with no RUN statement
    ├── test_invalid4.tl            # Dependency on undefined task
    ├── test_invalid5.tl            # Unknown keyword
    ├── sample_morning_routine.tl   # Fun sample — morning automation
    └── sample_pizza_shop.tl        # Fun sample — pizza shop operations
```

---

## How It Works

The implementation follows the classic compiler front-end architecture:

```
Input (.tl file)
       |
       v
  [ LEXER — lexer.l ]
  Reads characters, groups them into tokens
  Tokens: TASK, IDENTIFIER, RUN, STRING, EVERY, DAY, AT, TIME_VAL ...
       |
       v
  [ PARSER — parser.y ]
  Receives tokens, checks grammar rules (BNF)
  Builds a task list, resolves dependencies
       |
       v
  [ EXECUTION SIMULATION ]
  Topological sort (DFS) for correct order
  Circular dependency detection
  Prints task execution details
```

The lexer is written in **Lex format** (compiled with GNU Flex).
The parser is written in **Yacc format** (compiled with GNU Bison).
Both generate C code that is compiled with GCC.

---

## Prerequisites

You need the following tools installed on Linux or WSL (Windows Subsystem for Linux):

| Tool | Purpose |
|------|---------|
| `flex` | Lexer generator |
| `bison` | Parser generator |
| `gcc` | C compiler |
| `make` | Build automation |

Install all of them on Ubuntu or WSL with one command:

```bash
sudo apt update
sudo apt install -y flex bison gcc make
```

---

## Building the Project

Clone the repository and navigate into the project folder:

```bash
git clone https://github.com/your-username/tasklang-plus-plus.git
cd tasklang-plus-plus
```

Build using Make:

```bash
make
```

This runs three steps automatically:

```bash
bison -d parser.y       # generates parser.tab.c and parser.tab.h
flex lexer.l            # generates lex.yy.c
gcc -Wall -g -o tasklang parser.tab.c lex.yy.c -lfl
```

Clean all generated files:

```bash
make clean
```

---

## Running the Parser

Run a specific TaskLang++ program:

```bash
./tasklang < tests/test_valid1.tl
```

Run the exact example from the assignment specification:

```bash
./tasklang < tests/test_valid2.tl
```

Run all 10 tests at once:

```bash
make test
```

Run the fun sample programs:

```bash
./tasklang < tests/sample_morning_routine.tl
./tasklang < tests/sample_pizza_shop.tl
```

---

## Example Output

**Input — `tests/test_valid2.tl`:**

```
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
```

**Output:**

```
Parsing TaskLang++ input...

--- EXECUTION START ---

Executing Task: backupDB
  Script: "backup.sh"
  Schedule: EVERY DAY AT 02:00

Executing Task: sendReport
  Script: "report.py"
  Schedule:
  Depends on: backupDB
  Condition: success

Executing Task: cleanup
  Script: "cleanup.sh"
  Schedule: EVERY WEEK ON SUNDAY AT 03:00

--- EXECUTION COMPLETE ---
```

---

## Error Handling

### Syntax Error — Missing Task Name

**Input:**
```
TASK {
    RUN "script.sh"
}
```

**Output:**
```
*** SYNTAX ERROR at line 2: syntax error
    Problem near: '{'
```

---

### Circular Dependency

**Input:**
```
TASK taskA {
    RUN "scriptA.sh"
    AFTER taskB
}

TASK taskB {
    RUN "scriptB.sh"
    AFTER taskA
}
```

**Output:**
```
*** ERROR: Circular dependency detected!
Task 'taskA' is part of a dependency cycle.
A task cannot (directly or indirectly) depend on itself.

--- EXECUTION START ---
--- EXECUTION ABORTED: Circular dependency detected ---
```

---

### Unknown Keyword

**Input:**
```
TASK myTask {
    RUN "script.sh"
    SCHEDULE DAILY AT 09:00
}
```

**Output:**
```
*** SYNTAX ERROR at line 4: syntax error
    Problem near: 'SCHEDULE'
```

---

### Dependency on Undefined Task

**Input:**
```
TASK sendReport {
    RUN "report.py"
    AFTER nonExistentTask
    IF success
}
```

**Output:**
```
*** WARNING: Task 'sendReport' depends on 'nonExistentTask',
but 'nonExistentTask' was not defined.
```

---

## Grammar Overview

The formal grammar is defined using BNF (Backus-Naur Form). The Yacc rules in `parser.y` are a direct translation of these BNF productions.

```
<program>          ::= <task_def> | <program> <task_def>
<task_def>         ::= TASK IDENTIFIER '{' <task_body> '}'
<task_body>        ::= epsilon | <task_body> <statement>
<statement>        ::= <run_stmt> | <schedule_stmt> | <dependency_stmt> | <condition_stmt>
<run_stmt>         ::= RUN STRING
<schedule_stmt>    ::= EVERY DAY AT TIME_VAL
                     | EVERY WEEK ON IDENTIFIER AT TIME_VAL
                     | AT TIME_VAL
<dependency_stmt>  ::= AFTER IDENTIFIER | BEFORE IDENTIFIER | DEPENDS ON IDENTIFIER
<condition_stmt>   ::= IF <condition_kw>
<condition_kw>     ::= success | failure
```

---

## Test Results Summary

| Test File | Category | Scenario | Result |
|-----------|----------|----------|--------|
| `test_valid1.tl` | Valid | Simple daily task | Correct output |
| `test_valid2.tl` | Valid | Multi-step workflow — assignment example | Matches spec exactly |
| `test_valid3.tl` | Valid | Three-step CI/CD pipeline | Correct order |
| `test_valid4.tl` | Valid | DEPENDS ON + IF failure | Correct output |
| `test_valid5.tl` | Valid | 4-task dual-branch pipeline | Correct output |
| `test_invalid1.tl` | Invalid | Circular dependency | Detected, aborted |
| `test_invalid2.tl` | Invalid | Missing task name | SYNTAX ERROR reported |
| `test_invalid3.tl` | Invalid | No RUN statement | Graceful, shows (none) |
| `test_invalid4.tl` | Invalid | Undefined dependency | WARNING issued |
| `test_invalid5.tl` | Invalid | Unknown keyword | SYNTAX ERROR reported |

---

## Tools and Technologies

| Tool | Purpose |
|------|---------|
| GNU Flex | Compiles `lexer.l` into `lex.yy.c` |
| GNU Bison | Compiles `parser.y` into `parser.tab.c` |
| GCC | Compiles generated C code into the executable |
| GNU Make | Automates the three-step build process |
| C Language | Implementation language for lexer and parser actions |

---

## Limitations

- Each task supports at most one `RUN`, one schedule, one dependency, and one condition. If duplicates appear, the last one silently overwrites the previous.
- Time values are matched by the regex pattern `HH:MM` but are not validated for range. For example, `99:99` would be accepted syntactically.
- The parser simulates execution by printing details in topological order. It does not actually run the specified scripts.
- Only a single dependency per task is supported. Multiple dependencies such as `AFTER taskA AND taskB` are not part of the current grammar.

---

## Module Information

| Field | Detail |
|-------|--------|
| Module | SE2052 — Programming Paradigms |
| Year / Semester | Y2 S2 |
| Degree | BSc (Hons) in Computer Science |
| Assignment Type | Individual Take-Home Assignment |
| Language Tools | Lex / Flex, Yacc / Bison |
| Implementation Language | C |

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
