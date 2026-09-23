open_lib comp7485.dlib 
open_block comp7485

file mkdir ../..sim/work
set fh [open ../../sim/work/cell_functions.txt w]


foreach ref [lsort -unique [get_attribute [get_cells -hierarchical *] ref_name]] {
    set lib_cell [index_collection [get_lib_cells */$ref] 0]
    foreach_in_collection pin [get_lib_pins -of_objects $lib_cell -filter "direction == out"] {
        puts $fh "$ref|[get_attribute $pin name]|[get_attribute $pin function]"
    }
}

close $fh
puts "Cell functions written to ../../sim/work/cell_functions.txt"
exit
