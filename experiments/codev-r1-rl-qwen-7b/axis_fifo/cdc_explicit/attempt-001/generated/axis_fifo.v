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
    input clk,
    input rst,
    // AXI input
    input [DATA_WIDTH-1:0] s_axis_tdata,
    input [KEEP_WIDTH-1:0] s_axis_tkeep,
    input s_axis_tvalid,
    output s_axis_tready,
    input s_axis_tlast,
    input [ID_WIDTH-1:0] s_axis_tid,
    input [DEST_WIDTH-1:0] s_axis_tdest,
    input [USER_WIDTH-1:0] s_axis_tuser,
    // AXI output
    output [DATA_WIDTH-1:0] m_axis_tdata,
    output [KEEP_WIDTH-1:0] m_axis_tkeep,
    output m_axis_tvalid,
    input m_axis_tready,
    output m_axis_tlast,
    output [ID_WIDTH-1:0] m_axis_tid,
    output [DEST_WIDTH-1:0] m_axis_tdest,
    output [USER_WIDTH-1:0] m_axis_tuser,
    // Pause
    input pause_req,
    output pause_ack,
    // Status
    output [$clog2(DEPTH):0] status_depth,
    output [$clog2(DEPTH):0] status_depth_commit,
    output status_overflow,
    output status_bad_frame,
    output status_good_frame
);

    localparam TOTAL_WIDTH = DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + 
                             (ID_ENABLE ? ID_WIDTH : 0) + 
                             (DEST_ENABLE ? DEST_WIDTH : 0) + 
                             (USER_ENABLE ? USER_WIDTH : 0);

    reg [TOTAL_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] count;

    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    assign status_depth = count;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

    assign pause_ack = (PAUSE_ENABLE) ? (count < (FRAME_PAUSE ? (DEPTH - 1) : DEPTH)) : 1'b0;

    wire fifo_full = (count >= DEPTH);
    wire fifo_almost_full = (count >= DEPTH - 1);

    assign s_axis_tready = (DROP_WHEN_FULL ? !fifo_full : !fifo_full) && !pause_ack;

    assign m_axis_tvalid = (count > 0);

    reg [TOTAL_WIDTH-1:0] mem_out;

    generate
        if (RAM_PIPELINE) begin
            always @(posedge clk) begin
                mem_out <= mem[rd_ptr];
            end
        end else begin
            assign mem_out = mem[rd_ptr];
        end
    endgenerate

    assign m_axis_tdata = mem_out[DATA_WIDTH +: DATA_WIDTH];
    assign m_axis_tkeep = mem_out[DATA_WIDTH + KEEP_WIDTH +: KEEP_WIDTH];
    assign m_axis_tlast = mem_out[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE +: LAST_ENABLE];
    assign m_axis_tid = mem_out[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + (ID_ENABLE ? ID_WIDTH : 0) +: ID_WIDTH];
    assign m_axis_tdest = mem_out[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) +: DEST_WIDTH];
    assign m_axis_tuser = mem_out[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0) +: USER_WIDTH];

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            status_overflow_reg <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (s_axis_tlast) begin
                    if ((s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        status_bad_frame_reg <= 1;
                    end else begin
                        status_good_frame_reg <= 1;
                    end
                    if (count + 1 > DEPTH) begin
                        status_overflow_reg <= 1;
                    end
                end
                mem[wr_ptr] <= {s_axis_tdata, s_axis_tkeep, s_axis_tlast, 
                               s_axis_tid, s_axis_tdest, s_axis_tuser};
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end

            if (m_axis_tvalid && m_axis_tready) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end

endmodule
