#!/usr/bin/awk -f

################################################################################
# Utility to calculate stack usage of STM8 code. Takes as input one or more .asm
# files from SDCC compilation. Outputs one line per function, with each line
# consisting of filename, line number, function name, and the maximum bytes of
# stack used by that function.
# 
# Copyright (c) 2020 Basil Hussain
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 
################################################################################

BEGIN {
	FS = "\t";
	# OFS = "\t";
	reset();
}

END {
	if(ret_count > 0) {
		output();
		reset();
	}
}

$1 ~ /_([A-Za-z0-9.$_]+):/ {
	if(ret_count > 0) {
		output();
		reset();
	}
	if(match($1, /_([A-Za-z0-9.$_]+):/, m)) {
		func_name = m[1];
		func_file = FILENAME;
		func_line = FNR;
	}
	next;
}

$2 == "ret" || $2 == "retf" {
	ret_count++;
}

$2 == "iret" {
	# When interrupt occurs, A, X, Y, PC and CC registers are saved on to stack,
	# and restored upon return.
	stack_incr(9);
	stack_decr(9);
	ret_count++;
}

$2 == "sub" {
	if(match($3, /sp, #(([0-9]+)|(0x[A-Fa-f0-9]+))/, m)) {
		stack_incr(strtonum(m[1]));
	}
}

$2 == "addw" {
	if(match($3, /sp, #(([0-9]+)|(0x[A-Fa-f0-9]+))/, m)) {
		stack_decr(strtonum(m[1]));
	}
}

$2 == "push" {
	stack_incr(1);
}

$2 == "pushw" {
	stack_incr(2);
}

$2 == "pop" {
	stack_decr(1);
}

$2 == "popw" {
	stack_decr(2);
}

$2 == "call" || $2 == "callr" {
	stack_incr(2);
	stack_decr(2);
}

$2 == "callf" {
	# Far subroutine calls put extended 3-byte return address on to stack (and
	# cleared upon return).
	stack_incr(3);
	stack_decr(3);
}

################################################################################

function stack_incr(count) {
	stack += count;
	if(stack > stack_max) stack_max = stack;
}

function stack_decr(count) {
	stack -= count;
}

function stack_reset() {
	stack = 0;
	stack_max = 0;
}

function output() {
	print func_file, func_line, func_name, stack_max;
}

function reset() {
	func_name = "";
	func_file = "";
	func_line = 0;
	ret_count = 0;
	stack_reset();
}