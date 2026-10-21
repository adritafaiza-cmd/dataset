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
    reg [WIDTH-1:0]     data_mem [0:DEPTH-1];
    reg                 full_reg;
    reg [LOG_DEPTH-1:0] head_gray;
    reg [LOG_DEPTH-1:0] tail_gray;
    reg                 src_clear_req;
    reg                 dst_clear_req;
    reg                 src_clear_pending;
    reg                 dst_clear_pending;
    reg                 src_clear_done;
    reg                 dst_clear_done;
    reg                 src_clear_active;
    reg                 dst_clear_active;
    reg                 src_clear_in_progress;
    reg                 dst_clear_in_progress;

    // Synchronizers for control signals
    wire [SYNC_STAGES-1:0] src_clear_sync;
    wire [SYNC_STAGES-1:0] dst_clear_sync;
    wire [SYNC_STAGES-1:0] src_valid_sync;
    wire [SYNC_STAGES-1:0] dst_ready_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_sync;
    wire [SYNC_STAGES-1:0] dst_clear_pending_sync;

    // Synchronizers for clear requests from opposite domains
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flags to opposite domains
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flags
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flags
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flags
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request from opposite domain (cross-domain clear)
    wire [SYNC_STAGES-1:0] dst_clear_src_sync;
    wire [SYNC_STAGES-1:0] src_clear_dst_sync;

    // Synchronizers for clear pending flag from opposite domain
    wire [SYNC_STAGES-1:0] dst_clear_pending_dst_sync;
    wire [SYNC_STAGES-1:0] src_clear_pending_src_sync;

    // Synchronizers for clear done flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_done_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_done_src_sync;

    // Synchronizers for clear active flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_active_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_active_src_sync;

    // Synchronizers for clear in progress flag from opposite domain
    wire [SYNC_STAGES-1:0] src_clear_in_progress_dst_sync;
    wire [SYNC_STAGES-1:0] dst_clear_in_progress_src_sync;

    // Synchronizers for clear request