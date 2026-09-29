module axis_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
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

localparam ENTRY_WIDTH = DATA_WIDTH + KEEP_WIDTH*KEEP_ENABLE + LAST_ENABLE + ID_WIDTH*ID_ENABLE + DEST_WIDTH*DEST_ENABLE + USER_WIDTH*USER_ENABLE;
localparam PTR_WIDTH = $clog2(DEPTH);

reg [ENTRY_WIDTH-1:0] mem [0:DEPTH-1];
reg [PTR_WIDTH:0] wr_ptr, rd_ptr;

wire full = (wr_ptr - rd_ptr) >= DEPTH;
wire empty = (wr_ptr == rd_ptr);

// Pause logic
reg pause_ack_reg;
assign pause_ack = pause_req && full;

// AXI ready
assign s_axis_tready = !full && !pause_ack;

// Entry construction
wire [ENTRY_WIDTH-1:0] entry = { s_axis_tdata,
                                KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}},
                                LAST_ENABLE ? s_axis_tlast : 1'b0,
                                ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}},
                                DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}},
                                USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}} };

// Write and read pointers
always @(posedge clk) begin
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin
            mem[wr_ptr[PTR_WIDTH-1:0]] <= entry;
            wr_ptr <= wr_ptr + 1;
        end
        if (m_axis_tvalid && m_axis_tready) begin
            rd_ptr <= rd_ptr + 1;
        end
    end
end

// Read data
wire [ENTRY_WIDTH-1:0] current_entry = mem[rd_ptr[PTR_WIDTH-1:0]];

// AXI output assignments
assign m_axis_tvalid = !empty;
assign m_axis_tdata = current_entry[DATA_WIDTH-1:0];

generate
    if (KEEP_ENABLE) begin
        assign m_axis_tkeep = current_entry[DATA_WIDTH +: KEEP_WIDTH];
    end else begin
        assign m_axis_tkeep = {KEEP_WIDTH{1'b0}};
    end
endgenerate

generate
    if (LAST_ENABLE) begin
        assign m_axis_tlast = current_entry[DATA_WIDTH + KEEP_WIDTH];
    end else begin
        assign m_axis_tlast = 1'b0;
    end
endgenerate

generate
    if (ID_ENABLE) begin
        assign m_axis_tid = current_entry[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE +: ID_WIDTH];
    end else begin
        assign m_axis_tid = {ID_WIDTH{1'b0}};
    end
endgenerate

generate
    if (DEST_ENABLE) begin
        assign m_axis_tdest = current_entry[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH +: DEST_WIDTH];
    end else begin
        assign m_axis_tdest = {DEST_WIDTH{1'b0}};
    end
endgenerate

generate
    if (USER_ENABLE) begin
        assign m_axis_tuser = current_entry[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH + DEST_WIDTH +: USER_WIDTH];
    end else begin
        assign m_axis_tuser = {USER_WIDTH{1'b0}};
    end
endgenerate

// Status signals
assign status_depth = wr_ptr - rd_ptr;
assign status_depth_commit = status_depth;
assign status_overflow = 0;
assign status_bad_frame = 0;
assign status_good_frame = 0;

endmodule
