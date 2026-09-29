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

    // FIFO storage arrays
    reg [DATA_WIDTH-1:0] fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] fifo_keep [0:DEPTH-1];
    reg                   fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]    fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]  fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]  fifo_user [0:DEPTH-1];

    // Pointers
    reg [$clog2(DEPTH):0] write_ptr, read_ptr;

    // Status signals
    assign status_depth = write_ptr - read_ptr;
    assign status_depth_commit = status_depth; // Simplified for example

    // FIFO control
    wire full = (status_depth == DEPTH);
    wire empty = (status_depth == 0);

    assign s_axis_tready = ~full;
    assign m_axis_tvalid = ~empty;

    // Output assignments
    assign m_axis_tdata = fifo_data[read_ptr[$clog2(DEPTH)-1:0]];
    assign m_axis_tkeep = KEEP_ENABLE ? fifo_keep[read_ptr[$clog2(DEPTH)-1:0]] : '0;
    assign m_axis_tlast = LAST_ENABLE ? fifo_last[read_ptr[$clog2(DEPTH)-1:0]] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? fifo_id[read_ptr[$clog2(DEPTH)-1:0]] : '0;
    assign m_axis_tdest = DEST_ENABLE ? fifo_dest[read_ptr[$clog2(DEPTH)-1:0]] : '0;
    assign m_axis_tuser = USER_ENABLE ? fifo_user[read_ptr[$clog2(DEPTH)-1:0]] : '0;

    // Pause logic
    assign pause_ack = (PAUSE_ENABLE && (status_depth >= FRAME_PAUSE)) ? 1'b0 : 1'b1;

    // Status flags (simplified)
    assign status_overflow = DROP_OVERSIZE_FRAME && (status_depth >= DEPTH);
    assign status_bad_frame = DROP_BAD_FRAME && (USER_BAD_FRAME_MASK & fifo_user[read_ptr[$clog2(DEPTH)-1:0]] & USER_BAD_FRAME_VALUE);
    assign status_good_frame = ~status_bad_frame;

    // FIFO pointer updates
    always @(posedge clk) begin
        if (rst) begin
            write_ptr <= 0;
            read_ptr <= 0;
        end else begin
            // Write logic
            if (s_axis_tvalid && s_axis_tready) begin
                fifo_data[write_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tdata;
                if (KEEP_ENABLE) fifo_keep[write_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tkeep;
                if (LAST_ENABLE) fifo_last[write_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tlast;
                if (ID_ENABLE) fifo_id[write_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tid;
                if (DEST_ENABLE) fifo_dest[write_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tdest;
                if (USER_ENABLE) fifo_user[write_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tuser;
                write_ptr <= write_ptr + 1;
            end

            // Read logic
            if (m_axis_tvalid && m_axis_tready) begin
                read_ptr <= read_ptr + 1;
            end
        end
    end

endmodule
