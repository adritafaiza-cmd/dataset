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

    // Internal signals
    wire s_rst_synced;
    wire m_rst_synced;
    wire [DATA_WIDTH-1:0] fifo_out_data;
    wire [KEEP_WIDTH-1:0] fifo_out_keep;
    wire fifo_out_valid;
    wire fifo_out_ready;
    wire fifo_out_last;
    wire [ID_WIDTH-1:0] fifo_out_id;
    wire [DEST_WIDTH-1:0] fifo_out_dest;
    wire [USER_WIDTH-1:0] fifo_out_user;
    wire [$clog2(DEPTH):0] fifo_depth;
    wire [$clog2(DEPTH):0] fifo_depth_commit;
    wire fifo_overflow;
    wire fifo_bad_frame;
    wire fifo_good_frame;

    // Clock domain crossing for reset
    cdc_sync cdc_sync_s_rst (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_rst),
        .dout(s_rst_synced)
    );

    cdc_sync cdc_sync_m_rst (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_rst),
        .dout(m_rst_synced)
    );

    // Asynchronous FIFO implementation
    async_fifo #(
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
        .s_clk(s_clk),
        .s_rst(s_rst_synced),
        .s_data(s_axis_tdata),
        .s_keep(s_axis_tkeep),
        .s_valid(s_axis_tvalid),
        .s_ready(s_axis_tready),
        .s_last(s_axis_tlast),
        .s_id(s_axis_tid),
        .s_dest(s_axis_tdest),
        .s_user(s_axis_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst_synced),
        .m_data(fifo_out_data),
        .m_keep(fifo_out_keep),
        .m_valid(fifo_out_valid),
        .m_ready(fifo_out_ready),
        .m_last(fifo_out_last),
        .m_id(fifo_out_id),
        .m_dest(fifo_out_dest),
        .m_user(fifo_out_user),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack),
        .s_status_depth(s_status_depth),
        .s_status_depth_commit(s_status_depth_commit),
        .s_status_overflow(s_status_overflow),
        .s_status_bad_frame(s_status_bad_frame),
        .s_status_good_frame(s_status_good_frame),
        .m_status_depth(m_status_depth),
        .m_status_depth_commit(m_status_depth_commit),
        .m_status_overflow(m_status_overflow),
        .m_status_bad_frame(m_status_bad_frame),
        .m_status_good_frame(m_status_good_frame)
    );

    // AXI-Stream output assignments
    assign m_axis_tdata = fifo_out_data;
    assign m_axis_tkeep = fifo_out_keep;
    assign m_axis_tvalid = fifo_out_valid;
    assign fifo_out_ready = m_axis_tready;
    assign m_axis_tlast = fifo_out_last;
    assign m_axis_tid = fifo_out_id;
    assign m_axis_tdest = fifo_out_dest;
    assign m_axis_tuser = fifo_out_user;

endmodule

module cdc_sync (
    input  wire clk,
    input  wire rst,
    input  wire din,
    output wire dout
);

    reg dout_reg1;
    reg dout_reg2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_reg1 <= 1'b0;
            dout_reg2 <= 1'b0;
        end else begin
            dout_reg1 <= din;
            dout_reg2 <= dout_reg1;
        end
    end

    assign dout = dout_reg2;

endmodule

module async_fifo #
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
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_data,
    input  wire [KEEP_WIDTH-1:0]  s_keep,
    input  wire                   s_valid,
    output wire                   s_ready,
    input  wire                   s_last,
    input  wire [ID_WIDTH-1:0]    s_id,
    input  wire [DEST_WIDTH-1:0]  s_dest,
    input  wire [USER_WIDTH-1:0]  s_user,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_data,
    output wire [KEEP_WIDTH-1:0]  m_keep,
    output wire                   m_valid,
    input  wire                   m_ready,
    output wire                   m_last,
    output wire [ID_WIDTH-1:0]    m_id,
    output wire [DEST_WIDTH-1:0]  m_dest,
    output wire [USER_WIDTH-1:0]  m_user,
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
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

    localparam ADDR_WIDTH = $clog2(DEPTH);
    reg [ADDR_WIDTH:0] s_wr_ptr;
    reg [ADDR_WIDTH:0] s_wr_ptr_gray;
    reg [ADDR_WIDTH:0] s_wr_ptr_gray_synced;
    reg [ADDR_WIDTH:0] m_rd_ptr;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_synced;
    reg [ADDR_WIDTH:0] s_depth;
    reg [ADDR_WIDTH:0] s_depth_commit;
    reg [ADDR_WIDTH:0] m_depth;
    reg [ADDR_WIDTH:0] m_depth_commit;
    reg s_full;
    reg m_empty;
    reg s_overflow;
    reg s_bad_frame;
    reg s_good_frame;
    reg m_bad_frame;
    reg m_good_frame;
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    reg [DATA_WIDTH-1:0] ram_data_out;
    reg [KEEP_WIDTH-1:0] ram_keep_out;
    reg [ID_WIDTH-1:0] ram_id_out;
    reg [DEST_WIDTH-1:0] ram_dest_out;
    reg [USER_WIDTH-1:0] ram_user_out;
    reg ram_last_out;
    wire [DATA_WIDTH-1:0] ram_data_in;
    wire [KEEP_WIDTH-1:0] ram_keep_in;
    wire [ID_WIDTH-1:0] ram_id_in;
    wire [DEST_WIDTH-1:0] ram_dest_in;
    wire [USER_WIDTH-1:0] ram_user_in;
    wire ram_last_in;
    wire wr_en;
    wire rd_en;

    // Binary to Gray code conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to binary code conversion
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray_to_bin = bin;
    endfunction

    // Clock domain crossing for write pointer
    cdc_sync cdc_sync_s_wr_ptr_gray (
        .clk(m_clk),
        .rst(m_rst),
        .din(s_wr_ptr_gray),
        .dout(s_wr_ptr_gray_synced)
    );

    // Clock domain crossing for read pointer
    cdc_sync cdc_sync_m_rd_ptr_gray (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_rd_ptr_gray),
        .dout(m_rd_ptr_gray_synced)
    );

    // Write pointer logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {ADDR_WIDTH+1{1'b0}};
            s_wr_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
        end else if (wr_en) begin
            s_wr_ptr <= s_wr_ptr + 1;
            s_wr_ptr_gray <= bin_to_gray(s_wr_ptr + 1);
        end
    end

    // Read pointer logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {ADDR_WIDTH+1{1'b0}};
            m_rd_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
        end else if (rd_en) begin
            m_rd_ptr <= m_rd_ptr + 1;
            m_rd_ptr_gray <= bin_to_gray(m_rd_ptr + 1);
        end
    end

    // Depth calculation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth <= {ADDR_WIDTH+1{1'b0}};
            s_depth_commit <= {ADDR_WIDTH+1{1'b0}};
            s_full <= 1'b0;
            s_overflow <= 1'b0;
        end else begin
            if (wr_en && !rd_en) begin
                s_depth <= s_depth + 1;
            end else if (!wr_en && rd_en) begin
                s_depth <= s_depth - 1;
            end
            if (wr_en) begin
                s_depth_commit <= s_depth_commit + 1;
            end
            if (s_depth_commit == DEPTH) begin
                s_full <= 1'b1;
                if (!wr_en) begin
                    s_depth_commit <= s_depth_commit - 1;
                end
            end else begin
                s_full <= 1'b0;
            end
            if (s_depth_commit == DEPTH && wr_en) begin
                s_overflow <= 1'b1;
            end else begin
                s_overflow <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth <= {ADDR_WIDTH+1{1'b0}};
            m_depth_commit <= {ADDR_WIDTH+1{1'b0}};
            m_empty <= 1'b1;
        end else begin
            if (wr_en && !rd_en) begin
                m_depth_commit <= m_depth_commit + 1;
            end else if (!wr_en && rd_en) begin
                m_depth_commit <= m_depth_commit - 1;
            end
            if (rd_en) begin
                m_depth <= m_depth - 1;
            end
            if (m_depth_commit == 0) begin
                m_empty <= 1'b1;
            end else begin
                m_empty <= 1'b0;
            end
        end
    end

    // Write enable
    assign wr_en = s_valid && s_ready && !s_full;

    // Read enable
    assign rd_en = m_valid && m_ready && !m_empty;

    // Ready signal
    assign s_ready = !s_full;

    // Valid signal
    assign m_valid = !m_empty;

    // Dual-port RAM
    dual_port_ram #(
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
    ) fifo_ram (
        .clk_a(s_clk),
        .we_a(wr_en),
        .addr_a(s_wr_ptr[ADDR_WIDTH-1:0]),
        .din_a({s_data, s_keep, s_last, s_id, s_dest, s_user}),
        .dout_a(),
        .clk_b(m_clk),
        .we_b(1'b0),
        .addr_b(m_rd_ptr[ADDR_WIDTH-1:0]),
        .din_b({ram_data_in, ram_keep_in, ram_last_in, ram_id_in, ram_dest_in, ram_user_in}),
        .dout_b({ram_data_out, ram_keep_out, ram_last_out, ram_id_out, ram_dest_out, ram_user_out})
    );

    // Output assignments
    assign m_data = ram_data_out;
    assign m_keep = ram_keep_out;
    assign m_last = ram_last_out;
    assign m_id = ram_id_out;
    assign m_dest = ram_dest_out;
    assign m_user = ram_user_out;

    // Pause logic
    assign s_pause_ack_reg = s_pause_req && s_ready;
    assign m_pause_ack_reg = m_pause_req && m_valid;

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status signals
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_status_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

endmodule

module dual_port_ram #
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
    parameter RAM_PIPELINE = 1
)
(
    input  wire clk_a,
    input  wire we_a,
    input  wire [$clog2(DEPTH)-1:0] addr_a,
    input  wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] din_a,
    output wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] dout_a,
    input  wire clk_b,
    input  wire we_b,
    input  wire [$clog2(DEPTH)-1:0] addr_b,
    input  wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] din_b,
    output wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] dout_b
);

    reg [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] dout_a_reg;
    reg [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] dout_b_reg;

    always @(posedge clk_a) begin
        if (we_a) begin
            mem[addr_a] <= din_a;
        end
        if (RAM_PIPELINE) begin
            dout_a_reg <= mem[addr_a];
        end else begin
            dout_a_reg <= din_a;
        end
    end

    always @(posedge clk_b) begin
        if (RAM_PIPELINE) begin
            dout_b_reg <= mem[addr_b];
        end else begin
            dout_b_reg <= din_b;
        end
    end

    assign dout_a = dout_a_reg;
    assign dout_b = dout_b_reg;

endmodule
