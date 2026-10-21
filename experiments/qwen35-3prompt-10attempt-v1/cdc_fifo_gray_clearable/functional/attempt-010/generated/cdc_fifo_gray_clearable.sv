```verilog
`timescale 1ns/1ps

module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam GRAY_WIDTH = LOG_DEPTH;

    // Internal signals
    reg [WIDTH-1:0]   src_data_reg;
    reg               src_valid_reg;
    reg               src_ready_reg;
    reg [LOG_DEPTH-1:0] src_ptr;
    reg [LOG_DEPTH-1:0] dst_ptr;
    reg               src_clear_pending;
    reg               dst_clear_pending;
    reg               fifo_empty;
    reg               fifo_full;
    reg               src_clear_req;
    reg               dst_clear_req;

    // Synchronizers for clear requests
    reg [SYNC_STAGES-1:0] src_clear_sync;
    reg [SYNC_STAGES-1:0] dst_clear_sync;

    // Synchronizers for clear pending flags
    reg [SYNC_STAGES-1:0] src_clear_pending_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_sync;

    // Gray code pointers
    reg [GRAY_WIDTH-1:0] src_gray_ptr;
    reg [GRAY_WIDTH-1:0] dst_gray_ptr;

    // Synchronizers for Gray pointers
    reg [SYNC_STAGES-1:0] src_gray_sync;
    reg [SYNC_STAGES-1:0] dst_gray_sync;

    // Synchronizers for valid/ready handshake
    reg [SYNC_STAGES-1:0] src_valid_sync;
    reg [SYNC_STAGES-1:0] dst_ready_sync;

    // Synchronizers for output valid
    reg [SYNC_STAGES-1:0] dst_valid_sync;

    // Synchronizers for output data
    reg [SYNC_STAGES-1:0] dst_data_sync;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_out_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_out_sync;

    // Synchronizers for input clear pending
    reg [SYNC_STAGES-1:0] src_clear_pending_in_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_in_sync;

    // Synchronizers for input data
    reg [SYNC_STAGES-1:0] src_data_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_in;

    // Synchronizers for input ready
    reg [SYNC_STAGES-1:0] dst_ready_sync_in;
    reg [SYNC_STAGES-1:0] dst_clear_sync_in;

    // Synchronizers for output