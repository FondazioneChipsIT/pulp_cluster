if {![info exists ::env(VSIM_PATH) ]} {
    error "You must set the \"VSIM_PATH\" variable before sourcing the start script."
    set VSIM_PATH ""
}

if {![info exists APP]} {
    set APP "./test/test"
}

if {[info exists USE_QONE] && $USE_QONE == 1} {
    qsim -qwavedb=+signal+memory +permissive -suppress 3053 -suppress 8885 -suppress 12130 -lib $::env(VSIM_PATH)/work +APP=$APP +notimingchecks +nospecify  -t 1ps  pulp_cluster_tb_optimized +permissive-off ++$APP
} else {
    vsim +permissive -suppress 3053 -suppress 8885 -suppress 12130 -suppress 7077 -lib $::env(VSIM_PATH)/work +APP=$APP +notimingchecks +nospecify -t 1ps pulp_cluster_tb_optimized +permissive-off ++$APP
}

if {[info exists ::env(FAULT_INJECTION)]} {
    if {![info exists ::env(FAULT_INJECTION_SCRIPT)]} {
        error "Error: Missing FAULT_INJECTION_SCRIPT to source!"
    }
    source $::env(FAULT_INJECTION_SCRIPT)
}

run -all
quit -code [examine -radix decimal sim:/pulp_cluster_tb/ret_val(30:0)]
