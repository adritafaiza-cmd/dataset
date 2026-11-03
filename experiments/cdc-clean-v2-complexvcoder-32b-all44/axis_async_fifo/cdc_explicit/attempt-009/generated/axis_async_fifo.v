module axis_async_fifo #
(
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
)
(
    /*
     * AXI input
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    /*
     * Internal signals
     */
    reg [DATA_WIDTH-1:0]          fifo_data_in;
    reg [KEEP_WIDTH-1:0]          fifo_keep_in;
    reg                           fifo_last_in;
    reg [ID_WIDTH-1:0]            fifo_id_in;
    reg [DEST_WIDTH-1:0]          fifo_dest_in;
    reg [USER_WIDTH-1:0]          fifo_user_in;
    reg                           fifo_valid_in;
    wire                          fifo_ready_out;
    wire [DATA_WIDTH-1:0]         fifo_data_out;
    wire [KEEP_WIDTH-1:0]         fifo_keep_out;
    wire                          fifo_last_out;
    wire [ID_WIDTH-1:0]           fifo_id_out;
    wire [DEST_WIDTH-1:0]         fifo_dest_out;
    wire [USER_WIDTH-1:0]         fifo_user_out;
    wire                          fifo_valid_out;
    reg                           fifo_ready_in;
    wire [$clog2(DEPTH):0]        fifo_depth_wr;
    wire [$clog2(DEPTH):0]        fifo_depth_rd;
    wire                          fifo_overflow;
    wire                          pause_ack_s;
    wire                          pause_ack_m;
    wire                          s_status_bad_frame_reg;
    wire                          s_status_good_frame_reg;
    wire                          m_status_bad_frame_reg;
    wire                          m_status_good_frame_reg;

    /*
     * FIFO Dual Clock Domain Cross
     */
    fifo_dc #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) fifo_dc_inst (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .data_in(fifo_data_in),
        .keep_in(fifo_keep_in),
        .last_in(fifo_last_in),
        .id_in(fifo_id_in),
        .dest_in(fifo_dest_in),
        .user_in(fifo_user_in),
        .valid_in(fifo_valid_in),
        .ready_out(fifo_ready_out),
        .data_out(fifo_data_out),
        .keep_out(fifo_keep_out),
        .last_out(fifo_last_out),
        .id_out(fifo_id_out),
        .dest_out(fifo_dest_out),
        .user_out(fifo_user_out),
        .valid_out(fifo_valid_out),
        .ready_in(fifo_ready_in),
        .depth_wr(fifo_depth_wr),
        .depth_rd(fifo_depth_rd),
        .overflow(fifo_overflow)
    );

    /*
     * Pause Control Logic
     */
    pause_control pause_control_inst (
        .clk(s_clk),
        .rst(s_rst),
        .pause_req(s_pause_req),
        .pause_ack(pause_ack_s),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_pause_req(m_pause_req),
        .m_pause_ack(pause_ack_m)
    );

    /*
     * Frame Control Logic
     */
    frame_control frame_control_inst (
        .clk(s_clk),
        .rst(s_rst),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .s_status_bad_frame(s_status_bad_frame_reg),
        .s_status_good_frame(s_status_good_frame_reg),
        .m_status_bad_frame(m_status_bad_frame_reg),
        .m_status_good_frame(m_status_good_frame_reg)
    );

    /*
     * AXI-S Stream Interface
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_data_in <= 0;
            fifo_keep_in <= 0;
            fifo_last_in <= 0;
            fifo_id_in <= 0;
            fifo_dest_in <= 0;
            fifo_user_in <= 0;
            fifo_valid_in <= 0;
        end else begin
            if (s_axis_tvalid && fifo_ready_out) begin
                fifo_data_in <= s_axis_tdata;
                fifo_keep_in <= s_axis_tkeep;
                fifo_last_in <= s_axis_tlast;
                fifo_id_in <= s_axis_tid;
                fifo_dest_in <= s_axis_tdest;
                fifo_user_in <= s_axis_tuser;
                fifo_valid_in <= 1;
            end else begin
                fifo_valid_in <= 0;
            end
        end
    end

    assign s_axis_tready = fifo_ready_out && !s_rst;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            fifo_ready_in <= 0;
        end else begin
            fifo_ready_in <= m_axis_tready;
        end
    end

    assign m_axis_tdata = fifo_data_out;
    assign m_axis_tkeep = fifo_keep_out;
    assign m_axis_tvalid = fifo_valid_out;
    assign m_axis_tlast = fifo_last_out;
    assign m_axis_tid = fifo_id_out;
    assign m_axis_tdest = fifo_dest_out;
    assign m_axis_tuser = fifo_user_out;

    /*
     * Pause Acknowledgement
     */
    assign s_pause_ack = pause_ack_s;
    assign m_pause_ack = pause_ack_m;

    /*
     * Status Signals
     */
    assign s_status_depth = fifo_depth_wr;
    assign s_status_depth_commit = fifo_depth_wr;
    assign s_status_overflow = fifo_overflow;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_depth = fifo_depth_rd;
    assign m_status_depth_commit = fifo_depth_rd;
    assign m_status_overflow = fifo_overflow;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

endmodule

module fifo_dc #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 1,
    parameter KEEP_WIDTH = 1,
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1
)
(
    input  wire                   clk_wr,
    input  wire                   rst_wr,
    input  wire                   clk_rd,
    input  wire                   rst_rd,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire [KEEP_WIDTH-1:0]  keep_in,
    input  wire                   last_in,
    input  wire [ID_WIDTH-1:0]    id_in,
    input  wire [DEST_WIDTH-1:0]  dest_in,
    input  wire [USER_WIDTH-1:0]  user_in,
    input  wire                   valid_in,
    output wire                   ready_out,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire [KEEP_WIDTH-1:0]  keep_out,
    output wire                   last_out,
    output wire [ID_WIDTH-1:0]    id_out,
    output wire [DEST_WIDTH-1:0]  dest_out,
    output wire [USER_WIDTH-1:0]  user_out,
    output wire                   valid_out,
    input  wire                   ready_in,
    output wire [$clog2(DEPTH):0] depth_wr,
    output wire [$clog2(DEPTH):0] depth_rd,
    output wire                   overflow
);

    /*
     * FIFO Memory
     */
    reg [DATA_WIDTH-1:0]          mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]          mem_keep [0:DEPTH-1];
    reg                           mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]            mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]          mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]          mem_user [0:DEPTH-1];
    reg [$clog2(DEPTH):0]         wr_ptr;
    reg [$clog2(DEPTH):0]         rd_ptr;
    reg [$clog2(DEPTH):0]         wr_ptr_gray;
    reg [$clog2(DEPTH):0]         rd_ptr_gray;
    reg [$clog2(DEPTH):0]         wr_ptr_gray_sync;
    reg [$clog2(DEPTH):0]         rd_ptr_gray_sync;
    reg [$clog2(DEPTH):0]         depth;

    /*
     * Gray Code Conversion
     */
    function [$clog2(DEPTH):0] bin_to_gray;
        input [$clog2(DEPTH):0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    function [$clog2(DEPTH):0] gray_to_bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        reg [$clog2(DEPTH):0] bin;
        bin = gray;
        for (i = 1; i <= $clog2(DEPTH); i = i << 1) begin
            bin = bin ^ (bin >> i);
        end
        gray_to_bin = bin;
    endfunction

    /*
     * Write Pointer Update
     */
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (valid_in && ready_out) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
        end
    end

    /*
     * Read Pointer Update
     */
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (valid_out && ready_in) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
        end
    end

    /*
     * Gray Code Synchronization
     */
    always @(posedge clk_wr) begin
        wr_ptr_gray_sync <= wr_ptr_gray;
    end

    always @(posedge clk_rd) begin
        rd_ptr_gray_sync <= rd_ptr_gray;
    end

    /*
     * Depth Calculation
     */
    always @(posedge clk_wr) begin
        depth <= gray_to_bin(wr_ptr_gray_sync) - gray_to_bin(rd_ptr_gray);
    end

    /*
     * FIFO Memory Write
     */
    always @(posedge clk_wr) begin
        if (valid_in && ready_out) begin
            mem_data[wr_ptr] <= data_in;
            mem_keep[wr_ptr] <= keep_in;
            mem_last[wr_ptr] <= last_in;
            mem_id[wr_ptr] <= id_in;
            mem_dest[wr_ptr] <= dest_in;
            mem_user[wr_ptr] <= user_in;
        end
    end

    /*
     * FIFO Memory Read
     */
    always @(posedge clk_rd) begin
        if (valid_out && ready_in) begin
            data_out <= mem_data[rd_ptr];
            keep_out <= mem_keep[rd_ptr];
            last_out <= mem_last[rd_ptr];
            id_out <= mem_id[rd_ptr];
            dest_out <= mem_dest[rd_ptr];
            user_out <= mem_user[rd_ptr];
        end
    end

    /*
     * FIFO Valid and Ready Signals
     */
    assign valid_out = (depth > 0);
    assign ready_out = (depth < DEPTH);

    /*
     * Status Signals
     */
    assign depth_wr = depth;
    assign depth_rd = gray_to_bin(rd_ptr_gray_sync) - gray_to_bin(rd_ptr_gray);
    assign overflow = (depth >= DEPTH);

endmodule

module pause_control (
    input  wire clk,
    input  wire rst,
    input  wire pause_req,
    output wire pause_ack,
    input  wire m_clk,
    input  wire m_rst,
    input  wire m_pause_req,
    output wire m_pause_ack
);

    reg pause_ack_reg;
    reg m_pause_ack_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_ack_reg <= 0;
        end else begin
            pause_ack_reg <= pause_req;
        end
    end

    assign pause_ack = pause_ack_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 0;
        end else begin
            m_pause_ack_reg <= m_pause_req;
        end
    end

    assign m_pause_ack = m_pause_ack_reg;

endmodule

module frame_control (
    input  wire clk,
    input  wire rst,
    input  wire s_axis_tlast,
    input  wire s_axis_tvalid,
    input  wire s_axis_tready,
    input  wire m_axis_tlast,
    input  wire m_axis_tvalid,
    input  wire m_axis_tready,
    output wire s_status_bad_frame,
    output wire s_status_good_frame,
    output wire m_status_bad_frame,
    output wire m_status_good_frame
);

    reg s_frame_start;
    reg s_frame_end;
    reg s_frame_valid;
    reg m_frame_start;
    reg m_frame_end;
    reg m_frame_valid;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_frame_start <= 0;
            s_frame_end <= 0;
            s_frame_valid <= 0;
        end else begin
            s_frame_start <= s_axis_tvalid && s_axis_tready && !s_frame_valid;
            s_frame_end <= s_axis_tvalid && s_axis_tready && s_axis_tlast;
            s_frame_valid <= (s_frame_valid && !s_frame_end) || s_frame_start;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_frame_start <= 0;
            m_frame_end <= 0;
            m_frame_valid <= 0;
        end else begin
            m_frame_start <= m_axis_tvalid && m_axis_tready && !m_frame_valid;
            m_frame_end <= m_axis_tvalid && m_axis_tready && m_axis_tlast;
            m_frame_valid <= (m_frame_valid && !m_frame_end) || m_frame_start;
        end
    end

    assign s_status_bad_frame = 0; // Placeholder for actual bad frame detection
    assign s_status_good_frame = s_frame_end;
    assign m_status_bad_frame = 0; // Placeholder for actual bad frame detection
    assign m_status_good_frame = m_frame_end;

endmodule
