import pulp_cluster_package::*;
import rapid_recovery_pkg::*;

module cluster_core2hmr_delay_chain #(
    parameter int unsigned NUM_DELAYS = 2
) (
    input   logic           clk_i,
    input   logic           rst_ni,
    input   logic           en_i,
    input   core_outputs_t  hmr2sys_i,
    input   core_outputs_t  inputs_i,
    input   core_backup_t   core_backup_i,
    output  core_outputs_t  outputs_o,
    output  core_backup_t   core_backup_o,
    output  core_outputs_t  hmr2sys_o
);

core_outputs_t [NUM_DELAYS:0] r_core_outputs;
core_backup_t  [NUM_DELAYS:0] r_core_backup;
core_outputs_t  [NUM_DELAYS:0] r_hmr2sys;

assign r_core_outputs[0] = inputs_i;
assign r_core_backup[0]  = core_backup_i;
assign r_hmr2sys[0]      = hmr2sys_i;

    generate
        for (genvar i = 0; i < NUM_DELAYS; i++) begin : gen_delay_registers
            always_ff @( posedge clk_i, negedge rst_ni ) begin : reg_gen
                if (rst_ni == 1'b0) begin
                    r_core_outputs[i+1] <= '0;
                    r_core_backup[i+1]  <= '0;
                    r_hmr2sys[i+1]      <= '0;
                end else begin
                    r_core_outputs[i+1] <= r_core_outputs[i];
                    r_core_backup[i+1]  <= r_core_backup[i];
                    r_hmr2sys[i+1]      <= r_hmr2sys[i];      
                end
            end
        end
    endgenerate

assign outputs_o     = en_i ? r_core_outputs[NUM_DELAYS] : inputs_i;
assign core_backup_o = en_i ? r_core_backup[NUM_DELAYS]  : core_backup_i;
assign hmr2sys_o     = en_i ? r_hmr2sys[NUM_DELAYS]      : hmr2sys_i;

endmodule

module cluster_hmr2core_delay_chain #(
    parameter int unsigned NUM_DELAYS = 2
) (
    input   logic           clk_i,
    input   logic           rst_ni,
    input   logic           en_i,
    input   logic           fetch_en_int_i,
    input   logic           setback_i,
    input   logic           core_dbg_irq_i,
    input   rapid_recovery_pkg::rapid_recovery_t recovery_bus_i,
    input   core_inputs_t   inputs_i,
    input   core_inputs_t   sys2hmr_i,
    output  core_inputs_t   outputs_o,
    output  logic           fetch_en_int_o,
    output  logic           setback_o,
    output  logic           core_dbg_irq_o,
    output  rapid_recovery_pkg::rapid_recovery_t recovery_bus_o,
    output  core_inputs_t   sys2hmr_o
);

core_inputs_t [NUM_DELAYS:0] r_core_inputs;
core_inputs_t [NUM_DELAYS:0] r_sys2hmr;
logic [NUM_DELAYS:0] r_fetch_en_int;
logic [NUM_DELAYS:0] r_setback;
logic [NUM_DELAYS:0] r_core_dbg_irq;
rapid_recovery_pkg::rapid_recovery_t [NUM_DELAYS:0] r_recovery_bus;

assign r_core_inputs[0] = inputs_i;
assign r_fetch_en_int[0] = fetch_en_int_i;
assign r_setback[0] = setback_i;
assign r_core_dbg_irq[0] = core_dbg_irq_i;
assign r_recovery_bus[0] = recovery_bus_i;
assign r_sys2hmr[0]      = sys2hmr_i;

    generate
        for (genvar i = 0; i < NUM_DELAYS; i++) begin : gen_delay_registers
            always_ff @( posedge clk_i, negedge rst_ni ) begin : reg_gen
                if (rst_ni == 1'b0) begin
                    r_core_inputs[i+1]  <= '0;
                    r_fetch_en_int[i+1] <= '0;
                    r_setback[i+1]      <= '0;
                    r_core_dbg_irq[i+1] <= '0;
                    r_recovery_bus[i+1] <= '0;
                    r_sys2hmr[i+1]      <= '0;
                end else begin
                    r_core_inputs[i+1]  <= r_core_inputs[i];
                    r_fetch_en_int[i+1] <= r_fetch_en_int[i];
                    r_setback[i+1]      <= r_setback[i];
                    r_core_dbg_irq[i+1] <= r_core_dbg_irq[i];
                    r_recovery_bus[i+1] <= r_recovery_bus[i];
                    r_sys2hmr[i+1]      <= r_sys2hmr[i];
                end
            end
        end
    endgenerate

assign outputs_o      = en_i ? r_core_inputs[NUM_DELAYS]  : inputs_i;
assign fetch_en_int_o = en_i ? r_fetch_en_int[NUM_DELAYS] : fetch_en_int_i;
assign setback_o      = en_i ? r_setback[NUM_DELAYS]      : setback_i;
assign core_dbg_irq_o = en_i ? r_core_dbg_irq[NUM_DELAYS] : core_dbg_irq_i;
assign recovery_bus_o = en_i ? r_recovery_bus[NUM_DELAYS] : recovery_bus_i;
assign sys2hmr_o      = en_i ? r_sys2hmr[NUM_DELAYS]      : sys2hmr_i;

endmodule
