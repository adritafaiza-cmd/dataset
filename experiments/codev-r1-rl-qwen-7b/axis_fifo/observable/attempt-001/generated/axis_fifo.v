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
    // Input AXI
    input wire [DATA_WIDTH-1:0] s_axis_tdata,
    input wire [KEEP_WIDTH-1:0] s_axis_tkeep,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tlast,
    input wire [ID_WIDTH-1:0] s_axis_tid,
    input wire [DEST_WIDTH-1:0] s_axis_tdest,
    input wire [USER_WIDTH-1:0] s_axis_tuser,
    // Output AXI
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

    localparam TOTAL_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1 + (ID_ENABLE ? ID_WIDTH :0) + (DEST_ENABLE ? DEST_WIDTH :0) + (USER_ENABLE ? USER_WIDTH :0);

    reg [TOTAL_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] count;

    reg in_frame;
    reg [$clog2(DEPTH):0] current_frame_size;

    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    assign status_depth = count;
    assign status_depth_commit = count;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

    wire [DATA_WIDTH-1:0] data_out;
    wire [KEEP_WIDTH-1:0] keep_out;
    wire tlast_out;
    wire [ID_WIDTH-1:0] id_out;
    wire [DEST_WIDTH-1:0] dest_out;
    wire [USER_WIDTH-1:0] user_out;

    assign {data_out, keep_out, tlast_out, id_out, dest_out, user_out} = mem[rd_ptr];

    assign m_axis_tdata = data_out;
    assign m_axis_tkeep = keep_out;
    assign m_axis_tlast = tlast_out;
    assign m_axis_tid = id_out;
    assign m_axis_tdest = dest_out;
    assign m_axis_tuser = user_out;

    assign m_axis_tvalid = (count != 0);

    assign s_axis_tready = (count < DEPTH) || (DROP_WHEN_FULL && (count == DEPTH));

    assign pause_ack = (PAUSE_ENABLE && (count >= FRAME_PAUSE));

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            in_frame <= 0;
            current_frame_size <= 0;
            status_overflow_reg <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (in_frame) begin
                    current_frame_size <= current_frame_size + 1;
                end else begin
                    current_frame_size <= 1;
                    in_frame <= 1;
                end

                if (current_frame_size >= DEPTH) begin
                    if (DROP_OVERSIZE_FRAME) begin
                        status_overflow_reg <= 1;
                    end else if (MARK_WHEN_FULL) begin
                        // Mark user signals if needed
                    end
                end

                if (!(DROP_OVERSIZE_FRAME && current_frame_size >= DEPTH)) begin
                    mem[wr_ptr] <= {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
                    wr_ptr <= wr_ptr + 1;
                    count <= count + 1;
                end

                if (s_axis_tlast) begin
                    in_frame <= 0;
                    if (current_frame_size >= DEPTH) begin
                        status_bad_frame_reg <= 1;
                    end else begin
                        status_good_frame_reg <= 1;
                    end
                end
            end

            if (m_axis_tready && m_axis_tvalid) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end

endmodule
