# Purely combinational design

if {![info exists T]} {
    set T 20
}


set clkName vclk
set inp [all_inputs]
set out [all_outputs]


create_clock -name $clkName -period $T

set_clock_uncertainty -setup 0 $clkName
set_input_delay  -max 0 -clock $clkName $inp
set_output_delay -max 0 -clock $clkName $out
