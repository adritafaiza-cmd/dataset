```verilog
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
    reg [WIDTH-1:0]   data_mem [DEPTH:0];
    reg                full_reg;
    reg                empty_reg;
    reg [LOG_DEPTH-1:0] write_ptr;
    reg [LOG_DEPTH-1:0] read_ptr;
    reg                clear_pending_src;
    reg                clear_pending_dst;
    reg                src_clear_req;
    reg                dst_clear_req;
    reg                src_clear_ack;
    reg                dst_clear_ack;
    reg                src_clear_in_progress;
    reg                dst_clear_in_progress;

    // Synchronizers for clear requests
    reg [SYNC_STAGES-1:0] src_clear_sync;
    reg [SYNC_STAGES-1:0] dst_clear_sync;

    // Synchronizers for clear pending outputs
    reg [SYNC_STAGES-1:0] src_clear_pending_sync;
    reg [SYNC_STAGES-1:0] dst_clear_pending_sync;

    // Synchronizers for clear acks (internal logic)
    reg [SYNC_STAGES-1:0] src_clear_ack_sync;
    reg [SYNC_STAGES-1:0] dst_clear_ack_sync;

    // Synchronizers for clear in-progress flags
    reg [SYNC_STAGES-1:0] src_clear_in_progress_sync;
    reg [SYNC_STAGES-1:0] dst_clear_in_progress_sync;

    // Synchronizers for read/write pointers (Gray code)
    reg [LOG_DEPTH-1:0] read_ptr_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags
    reg                full_sync [SYNC_STAGES-1:0];
    reg                empty_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals
    reg                src_valid_sync [SYNC_STAGES-1:0];
    reg                dst_ready_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal;
    reg                dst_clear_pending_internal;

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal;
    reg                dst_clear_ack_internal;

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal;
    reg                dst_clear_in_progress_internal;

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal [SYNC_STAGES-1:0];
    reg                empty_internal [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal [SYNC_STAGES-1:0];
    reg                dst_ready_internal [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for read/write pointers (for internal logic)
    reg [LOG_DEPTH-1:0] read_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] write_ptr_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for full/empty flags (for internal logic)
    reg                full_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                empty_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for valid/ready signals (for internal logic)
    reg                src_valid_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_ready_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear pending outputs (for internal logic)
    reg                src_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_pending_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear acks (for internal logic)
    reg                src_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_ack_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    // Synchronizers for clear in-progress flags (for internal logic)
    reg                src_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];
    reg                dst_clear_in_progress_internal_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [SYNC_STAGES-1:0];

    //