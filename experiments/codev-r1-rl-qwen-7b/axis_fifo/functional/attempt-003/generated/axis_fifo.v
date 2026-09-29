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

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam ENTRY_WIDTH = DATA_WIDTH +
                             (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                             (LAST_ENABLE ? 1 : 0) +
                             (ID_ENABLE ? ID_WIDTH : 0) +
                             (DEST_ENABLE ? DEST_WIDTH : 0) +
                             (USER_ENABLE ? USER_WIDTH : 0);

    reg [ENTRY_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    wire [$clog2(DEPTH):0] fill_count = wr_ptr - rd_ptr;

    // Status assignments
    assign status_depth = fill_count;
    assign status_depth_commit = 0; // Placeholder
    assign status_overflow = 0; // Placeholder
    assign status_bad_frame = 0; // Placeholder
    assign status_good_frame = 0; // Placeholder

    // AXI ready logic
    assign s_axis_tready = (fill_count < DEPTH) && !pause_req;

    // Memory write
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            mem[wr_ptr] <= {s_axis_tdata,
                            KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}},
                            LAST_ENABLE ? s_axis_tlast : 1'b0,
                            ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}},
                            DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}},
                            USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}};
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Memory read
    reg [$clog2(DEPTH):0] rd_ptr_reg;
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr_reg <= 0;
        end else if (m_axis_tready && m_axis_tvalid) begin
            rd_ptr_reg <= rd_ptr_reg + 1;
        end
    end

    // Assign outputs
    assign m_axis_tvalid = (rd_ptr != wr_ptr);
    assign m_axis_tdata = mem[rd_ptr_reg][ENTRY_WIDTH-1 -: DATA_WIDTH];
    assign m_axis_tkeep = mem[rd_ptr_reg][ENTRY_WIDTH-1 - DATA_WIDTH -: KEEP_WIDTH];
    assign m_axis_tlast = mem[rd_ptr_reg][ENTRY_WIDTH-1 - DATA_WIDTH - KEEP_WIDTH];
    assign m_axis_tid = mem[rd_ptr_reg][ENTRY_WIDTH-1 - DATA_WIDTH - KEEP_WIDTH - 1 -: ID_WIDTH];
    assign m_axis_tdest = mem[rd_ptr_reg][ENTRY_WIDTH-1 - DATA_WIDTH - KEEP_WIDTH - 1 - ID_WIDTH -: DEST_WIDTH];
    assign m_axis_tuser = mem[rd_ptr_reg][ENTRY_WIDTH-1 - DATA_WIDTH - KEEP_WIDTH - 1 - ID_WIDTH - DEST_WIDTH -: USER_WIDTH];

    // Pause logic (simplified)
    assign pause_ack = pause_req; // Placeholder

endmodule
