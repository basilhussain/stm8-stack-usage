# Overview

This is a script to calculate the stack usage of C code written for the STM8 microcontroller that has been compiled using [SDCC](http://sdcc.sourceforge.net/). It takes as input one or more of the intermediate `.asm` files produced by the SDCC compiler and outputs one line per function with that function's stack usage.

# Usage

```
stack_usage.awk <file.asm ...>
```

Or, should the path to the Awk executable embedded in the shebang line not match your environment:

```
awk -f stack_usage.awk <file.asm ...>
```

Multiple `.asm` files may be given as input. They will each be processed and output provided in the same order they are given. Functions are also listed in the order they are present within the assembly listing.

One line is output per function found in the input assembly code. Each line consists of space-separated fields representing filename, line number, function name, and the maximum number of bytes (i.e. 'high water mark') of stack used by that function.

If you desire a different output format (e.g. tab-separated), uncomment the `OFS` line within the `BEGIN` section of the script. The string value assigned to the `OFS` variable is used as the output field separator.

Please note the script was written for and intended to be used with [GNU Awk](https://www.gnu.org/software/gawk/). It may or may not work with other Awk implementations.

## Sample Output

```
main.asm 93 clock_init 0
main.asm 114 gpio_init 0
main.asm 156 timer_init 0
main.asm 180 pwm_init 21
main.asm 324 pwm_set_duty_cycle 15
main.asm 384 adc_init 0
main.asm 492 main 27
main.asm 621 timer_isr 9
main.asm 649 adc_isr 9
spi_master.asm 67 spi_init 18
spi_master.asm 156 spi_begin_transaction 1
spi_master.asm 189 spi_end_transaction 1
spi_master.asm 211 spi_transfer_byte 10
spi_master.asm 240 spi_transfer_word 11
spi_master.asm 269 spi_transfer_buffer 10
```

# Technical Notes & Caveats

The script only analyses each function in isolation and does not take into account the function call graph (i.e. nesting or chaining) in any way. If you want to find out the stack usage over a chain of function calls, you will need to manually add up the stack usage of each function call in the chain. Such call graphing functionality is beyond the scope of a simple script like this.

Functions are identified in the assembly listing as any label prefixed with an underscore (`_`) which has a following block of code that contains one or more return instructions (e.g. `ret`, `retf`, `iret`). In the output, because the underscore prefix in the function name is added by SDCC, it is discarded, so it matches the function name given in the as-compiled C source.

The stack usage of interrupt service routines (ISRs) takes into account the saving of the A, X, Y, PC and CC registers on to the stack (9 bytes).

The saving of the program counter (PC) on to the stack by a subroutine call instruction is counted against the caller function, not the callee. Call and return instructions that use 24-bit 'far'/'extended' addressing are also handled appropriately, with 3 bytes of stack usage recorded, versus the standard 2 bytes for regular addressing.

Where there are instructions that manipulate the stack pointer (SP) manually by addition or subtraction of a literal value (e.g. `sub sp, #14`), only values that are represented in decimal integer or `0x`-prefixed hexadecimal notation are supported. Others such as octal (`0o`), binary (`0b`), or `0h` hexadecimal are not.

Parsing of the assembly listing relies on particular formatting used by the SDCC compiler. With this formatting, labels, operators and operands are tab-separated, with function labels always appearing as the first 'field' of a line, the operator (i.e. instruction) indented with a single tab, and operands (i.e. arguments) separated from the operator by another tab character. Should this formatting happen to change in future, it is likely this script will no longer work.

# Licence

This script is licenced under the MIT Licence. See the script source code for full licence text.