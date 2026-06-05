/*
 * ================================================================
 * parser.y  --  Parser
 * SE2052 Programming Paradigms
 * ================================================================
 */


/* ================================================================
   SECTION 1 -- DECLARATIONS
   ================================================================ */

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- Data Structures ------------------------------------------ */

/*
 * Maximum number of tasks allowed in one program.
 * Using a fixed array keeps the code simple and clear.
 */
#define MAX_TASKS 50
#define MAX_LEN   256

/*
 * Task structure - one struct per TASK block in the program.
 * Fields are filled in as each statement inside the block is parsed.
 */

typedef struct {
    char name[MAX_LEN];       /* e.g. "backupDB"             */
    char script[MAX_LEN];     /* e.g. "\"backup.sh\""        */
    char schedule[MAX_LEN];   /* e.g. "EVERY DAY AT 02:00"   */
    char depends_on[MAX_LEN]; /* e.g. "backupDB" or ""       */
    char condition[MAX_LEN];  /* e.g. "success" or ""        */
} Task;

/*
 * Global task list -- filled in as the parser processes each TASK block.
 * task_count tracks how many tasks have been parsed so far.
 */

Task tasks[MAX_TASKS];
int  task_count = 0;

/*
 * current_task -- a temporary buffer for the task currently being parsed.
 * When a TASK block ends (}), current_task is copied into tasks[].
 */
Task current_task;

/* ---- Dependency Resolution ----------------------------------- */
/*
 * Used a Depth-First Search (DFS) to:
 *   1. Sort tasks into correct execution order (topological sort)
 *   2. Detect circular dependencies(Task A depends on B depends on A)
 *
 * DFS visits each task. If a task's dependency hasn't been visited yet,
 * visit it first (recursion). This naturally gives the right order.
 *
 * Three visit states:
 *   0 = NOT_VISITED  -- haven't looked at this task yet
 *   1 = IN_PROGRESS  -- currently visiting
 *   2 = DONE         -- fully processed
 *
 * A circular dependency is detected when DFS tries to visit a task
 * that is already IN_PROGRESS (state = 1).
 */

#define NOT_VISITED  0
#define IN_PROGRESS  1
#define DONE         2

int visit_state[MAX_TASKS];   /* visit state for each task              */
int exec_order[MAX_TASKS];    /* final execution order (indices)        */
int exec_count = 0;           /* how many tasks placed in exec_order    */
int cycle_detected = 0;       /* flag set to 1 if a cycle is found      */

/* ----- Function Prototypes ------------------------------------------- */
void yyerror(const char *msg);
int  yylex(void);
void clear_current_task(void);
int  find_task_by_name(const char *name);
void dfs_visit(int index);
void run_execution_simulation(void);

/*
 * External variable from the lexer.
 */
/*
 * line_num is declared in lexer.l (Section 1) and incremented
 * manually each time a newline is matched -- the classic Lex way.
 * declared it extern here so parser.y can use it in yyerror()
 */
extern int  line_num;
extern char *yytext;

%}


/*
 * %union - defines the types that token values can be.
 *
 * When the lexer returns a token like IDENTIFIER, it also stores
 * a value in yylval. The %union tells Bison what types are possible.
 * only need one type: char* (a string pointer) for names, times,
 * and quoted strings.
 *
 * In the Lex file: yylval.str = strdup(yytext);
 * In grammar actions: $1, $2 etc. access the values.
 */
%union {
    char *str;   /* used for IDENTIFIER, TIME_VAL, STRING tokens */
}


/*
 * Token declarations ("%token name1 name2 ...")
 *
 * Tokens without a value -- the parser only needs to know they appeared:
 */
%token TASK RUN EVERY DAY WEEK AT ON AFTER BEFORE DEPENDS IF_KW
%token SUCCESS FAILURE
%token LBRACE RBRACE

/*
 * Tokens with a string value (from the <str> field of %union).
 * These come from the lexer with yylval.str set.
 */
%token <str> IDENTIFIER
%token <str> TIME_VAL
%token <str> STRING


/*
 * %type -- declares the return type of non-terminal symbols.
 * condition_kw produces a string (the word "success" or "failure").
 */
%type <str> condition_kw


/*
 * %start -- declares the start symbol of the grammar.
 * The parser begins trying to match a <program>.
 */
%start program


/* ================================================================
   SECTION 2 -- GRAMMAR RULES
   ================================================================
   Format:
       non_terminal : production { action }
                    | alternative { action }
                    ;
   
   $1, $2, $3 ... refer to the values of the 1st, 2nd, 3rd symbol
   on the right-hand side of the rule.
   $$ is the value this rule produces (returned to its parent rule).
   
   NOTE: Each Yacc rule below is the DIRECT translation of the
   corresponding BNF rule.
   The BNF rule is shown in a comment above each Yacc rule.
   ================================================================ */

%%

/* ----------------------------------------------------------------
   BNF Rule:
   <program> ::= <task_def>
               | <program> <task_def>
   
   A program is ONE or MORE task definitions.
   This is a LEFT-RECURSIVE rule -- required for LALR(1) parsing. 
   Left recursion means the parser can process tasks
   one by one as it reads them, without waiting.
   
   When the whole program has been parsed, run the simulation.
   ---------------------------------------------------------------- */
program
    : task_def
        { /* single task: simulation runs after parsing ends */ }
    | program task_def
        { /* each additional task adds to the task list */ }
    ;


/* ----------------------------------------------------------------
   BNF Rule:
   <task_def> ::= TASK IDENTIFIER "{" <task_body> "}"
   
   A task definition always has:
     - the keyword TASK
     - a name (IDENTIFIER, e.g. backupDB)
     - a body enclosed in curly braces { }
   
   This mirrors the if-statement pattern:
     if_stmt : 'if' '(' condition ')' '{' statements '}'
   ---------------------------------------------------------------- */
task_def
    : TASK IDENTIFIER LBRACE
        {
            clear_current_task();
            strncpy(current_task.name, $2, MAX_LEN - 1);
            free($2);   /* free the strdup copy from the lexer */
        }
      task_body RBRACE
        {
            /*
             * Copy the finished task into the global tasks[] array.
             */
            if (task_count < MAX_TASKS) {
                tasks[task_count] = current_task;
                task_count++;
            } else {
                fprintf(stderr, "ERROR: Too many tasks (max %d)\n", MAX_TASKS);
            }
        }
    ;


/* ----------------------------------------------------------------
   BNF Rule:
   <task_body> ::= ε
                 | <task_body> <statement>
   
   A task body is ZERO or MORE statements.
   In BNF, repetition is expressed through recursion:
     - the first alternative "ε" means the body can be empty
     - the second alternative adds one more statement each time
   
   ε (epsilon) = empty production -- nothing at all
   
   Compare to EBNF where this would be written as:
     <task_body> ::= { <statement> }
   EBNF is more compact, but BNF is what Yacc rules follow.
   ---------------------------------------------------------------- */
task_body
    : /* ε -- empty production: a task body can have no statements */
    | task_body statement
        { /* each statement is processed as it is parsed */ }
    ;


/* ----------------------------------------------------------------
   BNF Rule:
   <statement> ::= <run_stmt>
                 | <schedule_stmt>
                 | <dependency_stmt>
                 | <condition_stmt>
   
   There are four possible types of statement inside a task body.
   The parser picks the right one by looking at the first token
   (one symbol lookahead -- the "1" in LALR(1)).
   
   This is unambiguous because each alternative starts with a
   different keyword:
     RUN     --> run_stmt
     EVERY or AT --> schedule_stmt
     AFTER, BEFORE, DEPENDS --> dependency_stmt
     IF  --> condition_stmt
   ---------------------------------------------------------------- */
statement
    : run_stmt
    | schedule_stmt
    | dependency_stmt
    | condition_stmt
    ;


/* ----------------------------------------------------------------
   BNF Rule:
   <run_stmt> ::= RUN STRING
   
   Specifies the script or command to execute.
   Example:  RUN "backup.sh"
   $2 is the STRING value (e.g. "\"backup.sh\"")
   ---------------------------------------------------------------- */
run_stmt
    : RUN STRING
        {
            strncpy(current_task.script, $2, MAX_LEN - 1);
            free($2);
        }
    ;


/* ----------------------------------------------------------------
   BNF Rule:
   <schedule_stmt> ::= EVERY DAY AT TIME_VAL
                     | EVERY WEEK ON IDENTIFIER AT TIME_VAL
                     | AT TIME_VAL
   
   Three scheduling patterns (rule for multiple
   alternatives: "A: B C D | E F | G ;"):
   
   1. EVERY DAY AT 06:00     --> runs once a day at that time
   2. EVERY WEEK ON SUNDAY AT 03:00 --> runs weekly on a given day
   3. AT 09:00               --> runs once at that specific time
   
   snprintf builds a human-readable schedule description string.
   $4, $6 etc. pick out the correct token values by position.
   ---------------------------------------------------------------- */
schedule_stmt
    : EVERY DAY AT TIME_VAL
        {
            /* $4 is the TIME_VAL value (4th symbol in this rule) */
            snprintf(current_task.schedule, MAX_LEN,
                     "EVERY DAY AT %s", $4);
            free($4);
        }
    | EVERY WEEK ON IDENTIFIER AT TIME_VAL
        {
            /* $4 = day name (IDENTIFIER),  $6 = time (TIME_VAL) */
            snprintf(current_task.schedule, MAX_LEN,
                     "EVERY WEEK ON %s AT %s", $4, $6);
            free($4);
            free($6);
        }
    | AT TIME_VAL
        {
            /* $2 is the TIME_VAL value */
            snprintf(current_task.schedule, MAX_LEN, "AT %s", $2);
            free($2);
        }
    ;


/* ----------------------------------------------------------------
   BNF Rule:
   <dependency_stmt> ::= AFTER IDENTIFIER
                       | BEFORE IDENTIFIER
                       | DEPENDS ON IDENTIFIER
   
   Three ways to declare that this task depends on another.
   All three store the name of the dependency task.
   
   "AFTER backupDB"    -- run this task after backupDB finishes
   "BEFORE sendReport" -- this task must finish before sendReport
   "DEPENDS ON taskX"  -- alternative phrasing for AFTER
   ---------------------------------------------------------------- */
dependency_stmt
    : AFTER IDENTIFIER
        {
            /* $2 is the task name this task depends on */
            strncpy(current_task.depends_on, $2, MAX_LEN - 1);
            free($2);
        }
    | BEFORE IDENTIFIER
        {
            /*
             * BEFORE taskX means: this task runs before taskX.
             * store "BEFORE taskX" so the output makes it clear.
             */
            snprintf(current_task.depends_on, MAX_LEN,
                     "BEFORE %s", $2);
            free($2);
        }
    | DEPENDS ON IDENTIFIER
        {
            /* $3 is the task name (ON is the 2nd symbol, IDENTIFIER is 3rd) */
            strncpy(current_task.depends_on, $3, MAX_LEN - 1);
            free($3);
        }
    ;


/* ----------------------------------------------------------------
   BNF Rule:
   <condition_stmt> ::= IF <condition_kw>
   
   Conditional execution: only run this task if the condition holds.
   IF_KW is used (not IF) to avoid conflict with C's own "if".
   $2 is the string returned by condition_kw (see below).
   ---------------------------------------------------------------- */
condition_stmt
    : IF_KW condition_kw
        {
            strncpy(current_task.condition, $2, MAX_LEN - 1);
            free($2);
        }
    ;


/* ----------------------------------------------------------------
   BNF Rule:
   <condition_kw> ::= success
                    | failure
   
   Only two condition keywords are allowed.
   $$ = the string value this rule produces (passed up to condition_stmt).
   strdup makes a new copy of the string literal so it can be freed.
   ---------------------------------------------------------------- */
condition_kw
    : SUCCESS  { $$ = strdup("success"); }
    | FAILURE  { $$ = strdup("failure"); }
    ;

%%

/* ================================================================
   SECTION 3 -- PROGRAMS
   ================================================================
   C functions: main(), yyerror(), and the execution simulation.
   
   ================================================================ */


/*
 * yyerror - called by Bison automatically when a syntax error
 * is detected.
 *
 * Parameters:
 *   msg -- the error description from Bison(usually "syntax error")
 *
 * print the line number(from line_num, tracked manually in the lexer) and the token that
 * caused the problem(from yytext) to help the user find the mistake.
 */
void yyerror(const char *msg) {
    fprintf(stderr,
        "\n*** SYNTAX ERROR at line %d: %s\n"
        "    Problem near: '%s'\n\n",
        line_num, msg, yytext);
}


/*
 * clear_current_task -- resets the current_task buffer to empty.
 * Called at the start of every new TASK block so that leftover
 * data from the previous task does not bleed into the new one.
 * memset fills every byte with 0 (which is '\0' for char fields).
 */
void clear_current_task(void) {
    memset(&current_task, 0, sizeof(Task));
}


/*
 * find_task_by_name -- searches the tasks[] array for a task
 * whose name matches the given string.
 * Returns the array index if found, or -1 if not found.
 * Used by the DFS when resolving dependencies.
 */
int find_task_by_name(const char *name) {
    int i;
    for (i = 0; i < task_count; i++) {
        if (strcmp(tasks[i].name, name) == 0) {
            return i;   /* found it */
        }
    }
    return -1;          /* not found */
}


/*
 * dfs_visit - performs a Depth-First Search visit on task[index].
 *
 * DFS TOPOLOGICAL SORT:
 * --------------------------------
 * Topological sort gives the correct execution order when tasks
 * depend on each other. If sendReport depends on backupDB, then
 * backupDB must appear BEFORE sendReport in the output.
 *
 * The DFS algorithm:
 *   1. Mark the current task as IN_PROGRESS
 *   2. If this task has a dependency, visit that task first (recursion)
 *   3. Mark the current task as DONE
 *   4. Add this task to the execution order list
 *
 * CYCLE DETECTION:
 * --------------------------------
 * If try to visit a task that is already IN_PROGRESS, it means
 * have followed a chain that loops back to itself -- a cycle!
 * Example: taskA -> taskB -> taskA (infinite loop)
 * detect this by checking if visit_state[index] == IN_PROGRESS.
 */
void dfs_visit(int index) {

    /* If a cycle was already found, stop immediately */
    if (cycle_detected) return;

    /* If this task is already fully processed, nothing to do */
    if (visit_state[index] == DONE) return;

    /* If reach a task that is currently being processed,
     * found a circular dependency -- report and stop */
    if (visit_state[index] == IN_PROGRESS) {
        fprintf(stderr,
            "\n*** ERROR: Circular dependency detected! "
            "Task '%s' is part of a dependency cycle.\n"
            "    A task cannot (directly or indirectly) depend on itself.\n\n",
            tasks[index].name);
        cycle_detected = 1;
        return;
    }

    /* Mark this task as currently being visited */
    visit_state[index] = IN_PROGRESS;

    /*
     * If this task has a dependency, visit the dependency first.
     * skip dependencies declared with BEFORE (those are handled
     * from the other direction).
     */
    if (strlen(tasks[index].depends_on) > 0) {
        if (strncmp(tasks[index].depends_on, "BEFORE ", 7) != 0) {
            int dep_index = find_task_by_name(tasks[index].depends_on);
            if (dep_index == -1) {
                /* The dependency task was not defined in this program */
                fprintf(stderr,
                    "*** WARNING: Task '%s' depends on '%s', "
                    "but '%s' was not defined.\n",
                    tasks[index].name,
                    tasks[index].depends_on,
                    tasks[index].depends_on);
            } else {
                /* Recursively visit the dependency task first */
                dfs_visit(dep_index);
            }
        }
    }

    /* Mark this task as fully processed */
    visit_state[index] = DONE;

    /* Add to the execution order list */
    exec_order[exec_count] = index;
    exec_count++;
}


/*
 * run_execution_simulation -- prints the execution results in the
 * correct dependency order.
 *
 * This is called from main() after yyparse() successfully finishes.
 * It first runs the DFS on all tasks to determine execution order,
 * then prints each task's details.
 */
void run_execution_simulation(void) {
    int i;

    printf("\n--- EXECUTION START ---\n");

    /* Reset all DFS tracking variables */
    memset(visit_state, NOT_VISITED, sizeof(visit_state));
    exec_count    = 0;
    cycle_detected = 0;

    /*
     * Run DFS from every unvisited task.
     * This handles programs with multiple independent tasks
     * (tasks that don't depend on each other).
     */
    for (i = 0; i < task_count; i++) {
        if (visit_state[i] == NOT_VISITED) {
            dfs_visit(i);
        }
        if (cycle_detected) {
            printf("--- EXECUTION ABORTED: Circular dependency detected ---\n");
            return;
        }
    }

    /* Print each task in the computed execution order */
    for (i = 0; i < exec_count; i++) {
        Task *t = &tasks[exec_order[i]];

        printf("\nExecuting Task: %s\n", t->name);

        /* Script: show "(none)" if no RUN statement was given */
        printf("  Script: %s\n",
               strlen(t->script) > 0 ? t->script : "(none)");

        /* Schedule: only print if one was declared */
        printf("  Schedule: %s\n",
               strlen(t->schedule) > 0 ? t->schedule : "");

        /* Dependency: only print if one was declared */
        if (strlen(t->depends_on) > 0) {
            printf("  Depends on: %s\n", t->depends_on);
        }

        /* Condition: only print if one was declared */
        if (strlen(t->condition) > 0) {
            printf("  Condition: %s\n", t->condition);
        }
    }

    printf("\n--- EXECUTION COMPLETE ---\n");
}


/*
 * main -- entry point of the program.
 *
 * By default, Lex uses a default main() that reads
 * from stdin. You can call yylex from your own code.
 *
 * Here main() that:
 *   1. Announces parsing has started
 *   2. Calls yyparse() -- which internally calls yylex() for each token
 *   3. If parsing succeeded (return value 0), runs the simulation
 *
 * yyparse() return values:
 *   0 = success (input matched the grammar)
 *   1 = failure (syntax error was found)
 */
int main(void) {
    int result;

    printf("Parsing TaskLang++ input...\n");

    /* yyparse() drives the whole parsing process.
     * It calls yylex() repeatedly to get tokens from the lexer,
     * applies the grammar rules, and triggers actions. */
    result = yyparse();

    if (result == 0) {
        /* Parsing succeeded -- run the execution simulation */
        run_execution_simulation();
    }
    /* If result != 0, yyerror() already printed the error message */

    return result;
}
