module cdc_2phase_clearable_formal_dut (
 input src_rst_ni,src_clk_i,src_clear_i,src_valid_i,
 input [7:0] src_data_i,
 output src_clear_pending_o,src_ready_o,
 input dst_rst_ni,dst_clk_i,dst_clear_i,dst_ready_i,
 output dst_clear_pending_o,dst_valid_o,
 output [7:0] dst_data_o
);
 cdc_2phase_clearable #(.WIDTH(8),.SYNC_STAGES(3),.CLEAR_ON_ASYNC_RESET(1)) dut(.*);
endmodule
