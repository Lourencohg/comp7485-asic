#!/usr/bin/env python3
# =============================================================================
# sim/scripts/gen_cell_models.py
# Generate zero-delay Verilog models of standard cells from the Boolean
# functions stored in the cell library (dumped by dump_cell_functions.tcl).
#
# Input : one line per output pin:   CELL|OUTPUT_PIN|FUNCTION
#         e.g.  AO21X1_RVT|Y|(A1 A2) + A3
# Output: one Verilog module per cell.
#
# Function syntax (as reported by Fusion Compiler / Liberty):
#   A B  or A*B or A&B -> AND      A+B or A|B -> OR       A^B -> XOR
#   A'   or !A         -> NOT      ( )        -> grouping  0 / 1 -> constants
#
# Usage: python3 gen_cell_models.py <cell_functions.txt> <cells_out.v>
# =============================================================================
import re
import sys

TOKEN_RE = re.compile(r"\s*([A-Za-z_][A-Za-z0-9_]*|[01]|[()+|*&!^'])")


def tokenize(text):
    tokens, pos = [], 0
    text = text.strip()
    while pos < len(text):
        m = TOKEN_RE.match(text, pos)
        if not m:
            raise ValueError(f"cannot parse function near: '{text[pos:]}'")
        tokens.append(m.group(1))
        pos = m.end()
    return tokens


class Parser:
    """Recursive-descent parser. Precedence: NOT > XOR > AND > OR."""

    def __init__(self, tokens):
        self.t, self.i, self.inputs = tokens, 0, []

    def peek(self):
        return self.t[self.i] if self.i < len(self.t) else None

    def take(self):
        tok = self.t[self.i]
        self.i += 1
        return tok

    def parse(self):
        e = self.expr()
        if self.peek() is not None:
            raise ValueError(f"unexpected token '{self.peek()}'")
        return e

    def expr(self):                                   # OR level
        e = self.term()
        while self.peek() in ("+", "|"):
            self.take()
            e = f"({e} | {self.term()})"
        return e

    def starts_factor(self, tok):
        return tok is not None and (tok in ("(", "!", "0", "1")
                                    or re.match(r"[A-Za-z_]", tok))

    def term(self):                                   # AND level (implicit)
        e = self.xor()
        while True:
            if self.peek() in ("*", "&"):
                self.take()
            elif not self.starts_factor(self.peek()):
                break
            e = f"({e} & {self.xor()})"
        return e

    def xor(self):                                    # XOR level
        e = self.unary()
        while self.peek() == "^":
            self.take()
            e = f"({e} ^ {self.unary()})"
        return e

    def unary(self):                                  # NOT (prefix ! / postfix ')
        if self.peek() == "!":
            self.take()
            return f"(~{self.unary()})"
        e = self.primary()
        while self.peek() == "'":
            self.take()
            e = f"(~{e})"
        return e

    def primary(self):
        tok = self.take()
        if tok == "(":
            e = self.expr()
            if self.take() != ")":
                raise ValueError("missing ')'")
            return e
        if tok in ("0", "1"):
            return f"1'b{tok}"
        if not re.match(r"[A-Za-z_]", tok):
            raise ValueError(f"unexpected token '{tok}'")
        if tok not in self.inputs:
            self.inputs.append(tok)
        return tok


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: gen_cell_models.py <cell_functions.txt> <cells_out.v>")

    cells = {}                                        # cell -> {pin: function}
    with open(sys.argv[1]) as f:
        for line in f:
            if line.strip():
                cell, pin, func = [x.strip() for x in line.split("|", 2)]
                cells.setdefault(cell, {})[pin] = func

    with open(sys.argv[2], "w") as out:
        out.write("// Zero-delay cell models generated from the cell library functions\n")
        out.write("// by gen_cell_models.py. For functional gate-level simulation only.\n")
        out.write("`timescale 1ns/1ps\n\n")
        for cell in sorted(cells):
            inputs, assigns = [], []
            for pin, func in cells[cell].items():
                p = Parser(tokenize(func))
                expr = p.parse()
                inputs += [x for x in p.inputs if x not in inputs]
                assigns.append(f"  assign {pin} = {expr};  // {func}")
            outputs = list(cells[cell])
            out.write(f"module {cell} ({', '.join(inputs + outputs)});\n")
            if inputs:                                # tie cells have no inputs
                out.write(f"  input  {', '.join(inputs)};\n")
            out.write(f"  output {', '.join(outputs)};\n")
            out.write("\n".join(assigns) + "\nendmodule\n\n")
    print(f"{len(cells)} cell models written to {sys.argv[2]}")


if __name__ == "__main__":
    main()
