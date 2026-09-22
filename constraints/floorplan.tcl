
foreach layer {M1 M3 M5 M7 M9} {
    set_attribute -objects [get_layers $layer] \
                  -name    routing_direction  \
                  -value   horizontal
}

foreach layer {M2 M4 M6 M8 MRDL} {
    set_attribute -objects [get_layers $layer] \
                  -name    routing_direction  \
                  -value   vertical
}
