# pipex

![42 Logo](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTXfAZMOWHDQ3DKE63A9jWhIqQaKcKqUIXvzg&s)

**pipex** is a project from 42 School that replicates the behavior of Unix pipes and redirections. The project simulates the execution of a command line such as:

```bash  
< infile "command1" | "command2" > outfile  
```

and also includes a bonus feature for here_doc functionality.

## Table of Contents

- [Description](#description)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Testing](#testing)
- [Custom Testing](#custom-testing)

## Description

The **pipex** project simulates the piping mechanism found in Unix-like systems. It reads data from an input file, processes it through a series of commands connected by pipes, and writes the final output to an output file. Additionally, the bonus here_doc feature allows the program to accept input from the terminal until a specified delimiter is reached.

## Features

- **Pipe Simulation:** Emulates Unix pipe behavior to connect multiple commands.
- **Input/Output Redirection:** Reads data from a file and writes the processed output to another file.
- **Bonus - Here_doc:** Supports here_doc functionality for interactive input until a delimiter is met.
- **Process Management:** Uses system calls like `fork()`, `pipe()`, and `dup2()` to manage multiple processes.
- **Robust Error Handling:** Displays clear error messages and ensures proper resource cleanup.
- **Libft Integration:** Utilizes custom library functions from libft to aid in various operations.

## Requirements

- **C Compiler** (e.g., `gcc`)
- **Make** for building the project
- **Unix-based Operating System** (Linux, macOS)

## Installation

1. **Clone the repository:**
   
```bash
git clone https://github.com/tigran-sargsyan-w/pipex.git  
```

2. **Navigate to the project directory:**
   
```bash
cd pipex  
```

3. **Build the project using Make:**
   
```bash 
make  
```

This command compiles the project and produces the `pipex` executable.

## Usage

### Standard Mode

Run the program with an input file, two (or more) commands, and an output file:

```bash 
./pipex infile "command1" "command2" outfile  
```

**Example:**

```bash  
./pipex infile "cat" "grep test" "wc -l" outfile  
```

### Bonus Mode - Here_doc

To use the here_doc bonus feature, replace the input file with `here_doc` and specify a limiter:

```bash
./pipex here_doc LIMITER "command1" "command2" outfile  
```

**Example:**

```bash
./pipex here_doc END "cat" "wc -l" outfile  
```

In this mode, the program reads from the terminal until the `LIMITER` word (e.g., `END`) is encountered.

## How It Works

1. **Input Parsing:** Validates and parses command-line arguments.
2. **Pipe Creation:** Sets up pipes to channel data between commands.
3. **Process Forking:** Creates child processes for each command execution.
4. **Command Execution:** Executes commands using functions like `execve()` with proper redirection of file descriptors.
5. **Bonus Handling:** Implements here_doc functionality for interactive input.
6. **Error Management:** Detects errors, outputs descriptive messages, and cleans up resources appropriately.

## Testing

To test **pipex**, run the provided test script:

```bash
./tester.sh  
```

This script checks:
- **Functional Correctness:** Ensures that the pipe simulation and here_doc bonus work as expected.
- **Error Handling:** Verifies the program's response to invalid or missing input.
- **Memory Management:** Optionally, run with Valgrind to check for memory leaks:

```bash 
valgrind --leak-check=full ./pipex infile "command1" "command2" outfile  
```

## Custom Testing

If you want to run your own tests, here are some example commands that you can use:

### Functional Tests

```bash  
./pipex infile "cat" "wc -l" outfile
```
```bash
./pipex infile "cat" "grep test" "sort" "uniq" "wc -l" outfile
```
```bash
./pipex here_doc END "cat" "wc -l" outfile  
```
```bash
./pipex here_doc END "cat" "grep a" "wc -l" outfile
```
```bash
./pipex infile "cat" "nonexist test" "wc -l" outfile  
```

### Memory Leak & File Descriptor Tests Using Valgrind

```  
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes -s -q ./pipex infile "cat" "grep test" "wc -l" outfile
```
```
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes -s -q ./pipex infile "cat" "grep test" "sort" "uniq" "wc -l" outfile
```
```
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes -s -q ./pipex here_doc END "cat" "wc -l" outfile
```
```
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes -s -q ./pipex here_doc END "cat" "grep a" "wc -l" outfile
```
```
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes -s -q ./pipex infile "cat" "nonexist test" "wc -l" outfile  
```

These examples cover both regular functional testing and memory/descriptor checks with Valgrind.


