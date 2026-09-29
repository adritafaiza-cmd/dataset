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

    localparam PTR_WIDTH = $clog2(DEPTH);
    reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
    reg [DATA_WIDTH-1:0] data_mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg last_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] depth_reg, depth_commit_reg;
    reg overflow_reg, bad_frame_reg, good_frame_reg;

    wire full = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]) && (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]);
    wire empty = (wr_ptr == rd_ptr);

    assign s_axis_tready = !full;
    assign pause_ack = PAUSE_ENABLE ? pause_req : 0;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            depth_reg <= 0;
            depth_commit_reg <= 0;
            overflow_reg <= 0;
            bad_frame_reg <= 0;
            good_frame_reg <= 0;
        end else begin
            // Write logic
            if (s_axis_tvalid && s_axis_tready) begin
                data_mem[wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tdata;
                if (KEEP_ENABLE) keep_mem[wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tkeep;
                if (LAST_ENABLE) last_mem[wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tlast;
                if (ID_ENABLE) id_mem[wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE) dest_mem[wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE) user_mem[wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
            end

            // Read logic
            if (m_axis_tvalid && m_axis_tready) begin
                rd_ptr <= rd_ptr + 1;
            end

            // Depth calculation
            depth_reg <= wr_ptr - rd_ptr;
            depth_commit_reg <= wr_ptr - rd_ptr;

            // Overflow detection
            overflow_reg <= s_axis_tvalid && s_axis_tready && full;

            // Bad frame detection
            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                bad_frame_reg <= (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
            end

            // Good frame detection
            good_frame_reg <= (s_axis_tvalid && s_axis_tready && s_axis_tlast && !bad_frame_reg);
        end
    end

    assign m_axis_tvalid = !empty;
    assign m_axis_tdata = data_mem[rd_ptr[PTR_WIDTH-1:0]];
    assign m_axis_tkeep = KEEP_ENABLE ? keep_mem[rd_ptr[PTR_WIDTH-1:0]] : 0;
    assign m_axis_tlast = LAST_ENABLE ? last_mem[rd_ptr[PTR_WIDTH-1:0]] : 0;
    assign m_axis_tid = ID_ENABLE ? id_mem[rd_ptr[PTR_WIDTH-1:0]] : 0;
    assign m_axis_tdest = DEST_ENABLE ? dest_mem[rd_ptr[PTR_WIDTH-1:0]] : 0;
    assign m_axis_tuser = USER_ENABLE ? user_mem[rd_ptr[PTR_WIDTH-1:0]] : 0;

    assign status_depth = depth_reg;
    assign status_depth_commit = depth_commit_reg;
    assign status_overflow = overflow_reg;
    assign status_bad_frame = bad_frame_reg;
    assign status_good_frame = good_frame_reg;

endmodule
