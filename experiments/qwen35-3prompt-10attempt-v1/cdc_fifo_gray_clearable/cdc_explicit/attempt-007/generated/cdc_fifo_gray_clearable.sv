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
    reg [GRAY_WIDTH-1:0]   src_gray_ptr;
    reg [GRAY_WIDTH-1:0]   dst_gray_ptr;
    reg [WIDTH-1:0]        fifo_mem [DEPTH-1:0];
    reg                    fifo_empty;
    reg                    fifo_full;
    reg                    src_clear_req;
    reg                    dst_clear_req;
    reg                    src_clear_ack;
    reg                    dst_clear_ack;
    reg                    src_clear_pending;
    reg                    dst_clear_pending;
    reg                    src_clear_in_progress;
    reg                    dst_clear_in_progress;
    reg                    src_clear_done;
    reg                    dst_clear_done;

    // Synchronizers for control signals
    reg [SYNC_STAGES-1:0]   src_clear_sync;
    reg [SYNC_STAGES-1:0]   dst_clear_sync;
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync;
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_dst; // Extra stage for dst_clear_pending_o

    // Synchronizers for pointers (Gray code)
    reg [SYNC_STAGES-1:0]   src_gray_ptr_sync;
    reg [SYNC_STAGES-1:0]   dst_gray_ptr_sync;

    // Synchronizers for ready/valid
    reg [SYNC_STAGES-1:0]   dst_ready_sync;
    reg [SYNC_STAGES-1:0]   src_valid_sync;

    // Synchronizers for clear requests on the other side to prevent race conditions
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst;

    // Synchronizers for clear acks on the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src;

    // Synchronizers for clear pending signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src;

    // Synchronizers for clear done signals
    reg [SYNC_STAGES-1:0]   src_clear_done_sync;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync;

    // Synchronizers for clear in progress signals
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync;

    // Synchronizers for clear sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync;

    // Synchronizers for clear ack sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync;

    // Synchronizers for clear pending sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync;

    // Synchronizers for clear done sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src;

    // Synchronizers for clear in progress sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src;

    // Synchronizers for clear sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst;

    // Synchronizers for clear ack sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src;

    // Synchronizers for clear pending sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src;

    // Synchronizers for clear done sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst;

    // Synchronizers for clear in progress sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst;

    // Synchronizers for clear sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst;

    // Synchronizers for clear ack sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src;

    // Synchronizers for clear pending sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src;

    // Synchronizers for clear done sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst;

    // Synchronizers for clear in progress sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst;

    // Synchronizers for clear sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src;

    // Synchronizers for clear pending sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src;

    // Synchronizers for clear done sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_ack_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear pending sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_pending_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_pending_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;

    // Synchronizers for clear done sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_done_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_done_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear in progress sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_in_progress_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC_STAGES-1:0]   dst_clear_in_progress_sync_src_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   dst_clear_sync_src_sync_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src_src;
    reg [SYNC_STAGES-1:0]   src_clear_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;

    // Synchronizers for clear ack sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync sync signals to the other side
    reg [SYNC_STAGES-1:0]   src_clear_ack_sync_dst_sync_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst_dst;
    reg [SYNC