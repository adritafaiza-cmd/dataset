module axis_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH > 8),
    parameter KEEP_WIDTH = ((DATA_WIDTH + 7) / 8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1,
    parameter OUTPUT_FIFO_ENABLE = 0,
    parameter FRAME_FIFO = 0,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = FRAME_FIFO,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = FRAME_FIFO
) (
    input wire clk,
    input wire rst,
    // AXI input
    input wire [DATA_WIDTH-1:0] s_axis_tdata,
    input wire [KEEP_WIDTH-1:0] s_axis_tkeep,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tlast,
    input wire [ID_WIDTH-1:0] s_axis_tid,
    input wire [DEST_WIDTH-1:0] s_axis_tdest,
    input wire [USER_WIDTH-1:0] s_axis_tuser,
    // AXI output
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire [KEEP_WIDTH-1:0] m_axis_tkeep,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast,
    output wire [ID_WIDTH-1:0] m_axis_tid,
    output wire [DEST_WIDTH-1:0] m_axis_tdest,
    output wire [USER_WIDTH-1:0] m_axis_tuser,
    // Pause
    input wire pause_req,
    output wire pause_ack,
    // Status
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire status_overflow,
    output wire status_bad_frame,
    output wire status_good_frame
);

    // FIFO memory arrays
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

    // Pointers
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;

    // Status
    assign status_depth = wr_ptr - rd_ptr;

    // Full and empty conditions
    wire full = (wr_ptr - rd_ptr) >= DEPTH;
    wire empty = (wr_ptr == rd_ptr);

    // Write logic
    wire drop_bad_frame = DROP_BAD_FRAME && ((s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
    wire can_write = !full || DROP_WHEN_FULL || drop_bad_frame;
    assign s_axis_tready = can_write && !pause_req && (PAUSE_ENABLE ? pause_ack : 1'b1);

    // Read logic
    assign m_axis_tvalid = !empty;

    // Output assignments
    assign m_axis_tdata = mem_data[rd_ptr];
    assign m_axis_tkeep = mem_keep[rd_ptr];
    assign m_axis_tlast = mem_last[rd_ptr];
    assign m_axis_tid = mem_id[rd_ptr];
    assign m_axis_tdest = mem_dest[rd_ptr];
    assign m_axis_tuser = mem_user[rd_ptr];

    // Pointer updates
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            // Write
            if (s_axis_tvalid && s_axis_tready) begin
                mem_data[wr_ptr] <= s_axis_tdata;
                if (KEEP_ENABLE) mem_keep[wr_ptr] <= s_axis_tkeep;
                if (LAST_ENABLE) mem_last[wr_ptr] <= s_axis_tlast;
                if (ID_ENABLE) mem_id[wr_ptr] <= s_axis_tid;
                if (DEST_ENABLE) mem_dest[wr_ptr] <= s_axis_tdest;
                if (USER_ENABLE) mem_user[wr_ptr] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
            end
            // Read
            if (m_axis_tvalid && m_axis_tready) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // Pause handling
    assign pause_ack = PAUSE_ENABLE ? (/* Implement pause logic */) : 1'b0;

    // Status signals (simplified)
    assign status_overflow = DROP_WHEN_FULL && full && s_axis_tvalid && s_axis_tready;
    assign status_bad_frame = DROP_BAD_FRAME && drop_bad_frame;
    assign status_good_frame = !status_overflow && !status_bad_frame;

endmodule
