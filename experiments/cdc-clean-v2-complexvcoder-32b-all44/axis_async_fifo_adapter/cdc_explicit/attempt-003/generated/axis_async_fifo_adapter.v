module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
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
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    // Internal signals for async_fifo
    wire [S_DATA_WIDTH-1:0]         async_fifo_data_out;
    wire [S_KEEP_WIDTH-1:0]         async_fifo_keep_out;
    wire                            async_fifo_valid_out;
    wire                            async_fifo_last_out;
    wire [ID_WIDTH-1:0]             async_fifo_id_out;
    wire [DEST_WIDTH-1:0]           async_fifo_dest_out;
    wire [USER_WIDTH-1:0]           async_fifo_user_out;
    wire                            async_fifo_ready_in;

    // Internal signals for width_adapter
    wire [M_DATA_WIDTH-1:0]         width_adapter_data_out;
    wire [M_KEEP_WIDTH-1:0]         width_adapter_keep_out;
    wire                            width_adapter_valid_out;
    wire                            width_adapter_last_out;
    wire [ID_WIDTH-1:0]             width_adapter_id_out;
    wire [DEST_WIDTH-1:0]           width_adapter_dest_out;
    wire [USER_WIDTH-1:0]           width_adapter_user_out;
    wire                            width_adapter_ready_in;

    // Instantiate async_fifo
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) async_fifo_inst (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .data_in(s_axis_tdata),
        .keep_in(s_axis_tkeep),
        .valid_in(s_axis_tvalid),
        .last_in(s_axis_tlast),
        .id_in(s_axis_tid),
        .dest_in(s_axis_tdest),
        .user_in(s_axis_tuser),
        .ready_in(async_fifo_ready_in),
        .data_out(async_fifo_data_out),
        .keep_out(async_fifo_keep_out),
        .valid_out(async_fifo_valid_out),
        .last_out(async_fifo_last_out),
        .id_out(async_fifo_id_out),
        .dest_out(async_fifo_dest_out),
        .user_out(async_fifo_user_out),
        .ready_out(m_axis_tready),
        .status_depth_wr(s_status_depth),
        .status_depth_commit_wr(s_status_depth_commit),
        .status_overflow_wr(s_status_overflow),
        .status_bad_frame_wr(s_status_bad_frame),
        .status_good_frame_wr(s_status_good_frame),
        .status_depth_rd(m_status_depth),
        .status_depth_commit_rd(m_status_depth_commit),
        .status_overflow_rd(m_status_overflow),
        .status_bad_frame_rd(m_status_bad_frame),
        .status_good_frame_rd(m_status_good_frame)
    );

    // Instantiate width_adapter
    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH)
    ) width_adapter_inst (
        .clk(m_clk),
        .rst(m_rst),
        .data_in(async_fifo_data_out),
        .keep_in(async_fifo_keep_out),
        .valid_in(async_fifo_valid_out),
        .last_in(async_fifo_last_out),
        .id_in(async_fifo_id_out),
        .dest_in(async_fifo_dest_out),
        .user_in(async_fifo_user_out),
        .ready_in(m_axis_tready),
        .data_out(width_adapter_data_out),
        .keep_out(width_adapter_keep_out),
        .valid_out(width_adapter_valid_out),
        .last_out(width_adapter_last_out),
        .id_out(width_adapter_id_out),
        .dest_out(width_adapter_dest_out),
        .user_out(width_adapter_user_out),
        .ready_out(async_fifo_ready_in)
    );

    // Connect width_adapter outputs to m_axis
    assign m_axis_tdata = width_adapter_data_out;
    assign m_axis_tkeep = width_adapter_keep_out;
    assign m_axis_tvalid = width_adapter_valid_out;
    assign m_axis_tlast = width_adapter_last_out;
    assign m_axis_tid = width_adapter_id_out;
    assign m_axis_tdest = width_adapter_dest_out;
    assign m_axis_tuser = width_adapter_user_out;

    // Connect pause signals (assuming no pause functionality implemented)
    assign s_pause_ack = 1'b0;
    assign m_pause_ack = 1'b0;

    // Connect s_axis_tready from async_fifo
    assign s_axis_tready = async_fifo_ready_in;

endmodule

module async_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
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
    input  wire                     clk_wr,
    input  wire                     rst_wr,
    input  wire                     clk_rd,
    input  wire                     rst_rd,
    input  wire [DATA_WIDTH-1:0]    data_in,
    input  wire [KEEP_WIDTH-1:0]    keep_in,
    input  wire                     valid_in,
    input  wire                     last_in,
    input  wire [ID_WIDTH-1:0]      id_in,
    input  wire [DEST_WIDTH-1:0]    dest_in,
    input  wire [USER_WIDTH-1:0]    user_in,
    output wire                     ready_in,
    output wire [DATA_WIDTH-1:0]    data_out,
    output wire [KEEP_WIDTH-1:0]    keep_out,
    output wire                     valid_out,
    output wire                     last_out,
    output wire [ID_WIDTH-1:0]      id_out,
    output wire [DEST_WIDTH-1:0]    dest_out,
    output wire [USER_WIDTH-1:0]    user_out,
    input  wire                     ready_out,
    output wire [$clog2(DEPTH):0]   status_depth_wr,
    output wire [$clog2(DEPTH):0]   status_depth_commit_wr,
    output wire                     status_overflow_wr,
    output wire                     status_bad_frame_wr,
    output wire                     status_good_frame_wr,
    output wire [$clog2(DEPTH):0]   status_depth_rd,
    output wire [$clog2(DEPTH):0]   status_depth_commit_rd,
    output wire                     status_overflow_rd,
    output wire                     status_bad_frame_rd,
    output wire                     status_good_frame_rd
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg last_mem [0:DEPTH-1];

    // Binary to Gray code converter
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary code converter
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH-1; i > 0; i = i - 1)
            bin[i-1] = bin[i-1] ^ bin[i];
        gray_to_bin = bin;
    endfunction

    // Write side
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (ready_in && valid_in) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
        end
    end

    // Read side
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (ready_out && valid_out) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_wr) begin
        wr_ptr_gray_sync <= wr_ptr_gray;
    end

    always @(posedge clk_rd) begin
        rd_ptr_gray_sync <= rd_ptr_gray;
    end

    // Ready signals
    assign ready_in = (wr_ptr_gray != bin_to_gray(rd_ptr_gray_sync));
    assign valid_out = (wr_ptr_gray_sync != bin_to_gray(rd_ptr));

    // Write to memory
    always @(posedge clk_wr) begin
        if (ready_in && valid_in) begin
            mem[wr_ptr] <= data_in;
            keep_mem[wr_ptr] <= keep_in;
            id_mem[wr_ptr] <= id_in;
            dest_mem[wr_ptr] <= dest_in;
            user_mem[wr_ptr] <= user_in;
            last_mem[wr_ptr] <= last_in;
        end
    end

    // Read from memory
    always @(posedge clk_rd) begin
        data_out <= mem[rd_ptr];
        keep_out <= keep_mem[rd_ptr];
        id_out <= id_mem[rd_ptr];
        dest_out <= dest_mem[rd_ptr];
        user_out <= user_mem[rd_ptr];
        last_out <= last_mem[rd_ptr];
    end

    // Status signals
    assign status_depth_wr = wr_ptr - gray_to_bin(rd_ptr_gray_sync);
    assign status_depth_commit_wr = wr_ptr - rd_ptr;
    assign status_depth_rd = wr_ptr_gray_sync - rd_ptr;
    assign status_depth_commit_rd = wr_ptr - rd_ptr;
    assign status_overflow_wr = (wr_ptr_gray == bin_to_gray(rd_ptr_gray_sync + DEPTH));
    assign status_overflow_rd = (wr_ptr_gray_sync == bin_to_gray(rd_ptr + DEPTH));
    assign status_bad_frame_wr = 1'b0; // Placeholder for bad frame detection
    assign status_bad_frame_rd = 1'b0; // Placeholder for bad frame detection
    assign status_good_frame_wr = 1'b0; // Placeholder for good frame detection
    assign status_good_frame_rd = 1'b0; // Placeholder for good frame detection

endmodule

module width_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [S_DATA_WIDTH-1:0]  data_in,
    input  wire [S_KEEP_WIDTH-1:0]  keep_in,
    input  wire                     valid_in,
    input  wire                     last_in,
    input  wire [ID_WIDTH-1:0]      id_in,
    input  wire [DEST_WIDTH-1:0]    dest_in,
    input  wire [USER_WIDTH-1:0]    user_in,
    input  wire                     ready_in,
    output wire [M_DATA_WIDTH-1:0]  data_out,
    output wire [M_KEEP_WIDTH-1:0]  keep_out,
    output wire                     valid_out,
    output wire                     last_out,
    output wire [ID_WIDTH-1:0]      id_out,
    output wire [DEST_WIDTH-1:0]    dest_out,
    output wire [USER_WIDTH-1:0]    user_out,
    output wire                     ready_out
);

    // Internal signals
    reg [S_DATA_WIDTH-1:0]          data_reg;
    reg [S_KEEP_WIDTH-1:0]          keep_reg;
    reg                             valid_reg;
    reg                             last_reg;
    reg [ID_WIDTH-1:0]              id_reg;
    reg [DEST_WIDTH-1:0]            dest_reg;
    reg [USER_WIDTH-1:0]            user_reg;

    // Ready signals
    assign ready_out = valid_in;

    // Data and sideband registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 0;
            keep_reg <= 0;
            valid_reg <= 0;
            last_reg <= 0;
            id_reg <= 0;
            dest_reg <= 0;
            user_reg <= 0;
        end else if (ready_out && valid_in) begin
            data_reg <= data_in;
            keep_reg <= keep_in;
            valid_reg <= valid_in;
            last_reg <= last_in;
            id_reg <= id_in;
            dest_reg <= dest_in;
            user_reg <= user_in;
        end else if (ready_in && valid_reg) begin
            valid_reg <= 0;
        end
    end

    // Output assignments
    assign data_out = data_reg;
    assign keep_out = keep_reg;
    assign valid_out = valid_reg;
    assign last_out = last_reg;
    assign id_out = id_reg;
    assign dest_out = dest_reg;
    assign user_out = user_reg;

endmodule
