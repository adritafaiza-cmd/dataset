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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    // CDC FIFO signals
    reg [ADDR_WIDTH:0] s2m_wr_ptr_gray;
    reg [ADDR_WIDTH:0] s2m_rd_ptr_gray;
    reg [ADDR_WIDTH:0] s2m_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] s2m_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m2s_wr_ptr_gray;
    reg [ADDR_WIDTH:0] m2s_rd_ptr_gray;
    reg [ADDR_WIDTH:0] m2s_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m2s_rd_ptr_gray_sync;

    // FIFO memory
    reg [S_DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] fifo_keep [0:DEPTH-1];
    reg [USER_WIDTH-1:0] fifo_user [0:DEPTH-1];
    reg [ID_WIDTH-1:0] fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] fifo_dest [0:DEPTH-1];
    reg fifo_tlast [0:DEPTH-1];

    // FIFO pointers
    reg [ADDR_WIDTH:0] s_wr_ptr;
    reg [ADDR_WIDTH:0] s_rd_ptr;
    reg [ADDR_WIDTH:0] m_wr_ptr;
    reg [ADDR_WIDTH:0] m_rd_ptr;

    // FIFO status
    wire s_fifo_empty;
    wire s_fifo_full;
    wire m_fifo_empty;
    wire m_fifo_full;

    // Width adapter signals
    reg [M_DATA_WIDTH-1:0] width_adapter_tdata;
    reg [M_KEEP_WIDTH-1:0] width_adapter_tkeep;
    reg width_adapter_tlast;
    reg [USER_WIDTH-1:0] width_adapter_tuser;
    reg [ID_WIDTH-1:0] width_adapter_tid;
    reg [DEST_WIDTH-1:0] width_adapter_tdest;

    // CDC FIFO instantiation
    cdc_fifo #(.WIDTH(ADDR_WIDTH+1)) s2m_cdc_fifo_inst (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_data(s2m_wr_ptr_gray),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_data(s2m_wr_ptr_gray_sync)
    );

    cdc_fifo #(.WIDTH(ADDR_WIDTH+1)) s2m_cdc_fifo_rd_inst (
        .src_clk(m_clk),
        .src_rst(m_rst),
        .src_data(s2m_rd_ptr_gray),
        .dst_clk(s_clk),
        .dst_rst(s_rst),
        .dst_data(s2m_rd_ptr_gray_sync)
    );

    cdc_fifo #(.WIDTH(ADDR_WIDTH+1)) m2s_cdc_fifo_inst (
        .src_clk(m_clk),
        .src_rst(m_rst),
        .src_data(m2s_wr_ptr_gray),
        .dst_clk(s_clk),
        .dst_rst(s_rst),
        .dst_data(m2s_wr_ptr_gray_sync)
    );

    cdc_fifo #(.WIDTH(ADDR_WIDTH+1)) m2s_cdc_fifo_rd_inst (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_data(m2s_rd_ptr_gray),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_data(m2s_rd_ptr_gray_sync)
    );

    // Width adapter instantiation
    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_ENABLE(S_KEEP_ENABLE),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_ENABLE(M_KEEP_ENABLE),
        .M_KEEP_WIDTH(M_KEEP_WIDTH)
    ) width_adapter_inst (
        .s_tdata(fifo_mem[s_rd_ptr]),
        .s_tkeep(fifo_keep[s_rd_ptr]),
        .s_tlast(fifo_tlast[s_rd_ptr]),
        .s_tuser(fifo_user[s_rd_ptr]),
        .m_tdata(width_adapter_tdata),
        .m_tkeep(width_adapter_tkeep),
        .m_tlast(width_adapter_tlast),
        .m_tuser(width_adapter_tuser)
    );

    // Status counter instantiation
    status_counter #(.DEPTH(DEPTH)) s_status_counter_inst (
        .clk(s_clk),
        .rst(s_rst),
        .wr_ptr(s_wr_ptr),
        .rd_ptr(s_rd_ptr),
        .fifo_full(s_fifo_full),
        .fifo_empty(s_fifo_empty),
        .status_depth(s_status_depth),
        .status_depth_commit(s_status_depth_commit),
        .status_overflow(s_status_overflow),
        .status_bad_frame(s_status_bad_frame),
        .status_good_frame(s_status_good_frame)
    );

    status_counter #(.DEPTH(DEPTH)) m_status_counter_inst (
        .clk(m_clk),
        .rst(m_rst),
        .wr_ptr(m_wr_ptr),
        .rd_ptr(m_rd_ptr),
        .fifo_full(m_fifo_full),
        .fifo_empty(m_fifo_empty),
        .status_depth(m_status_depth),
        .status_depth_commit(m_status_depth_commit),
        .status_overflow(m_status_overflow),
        .status_bad_frame(m_status_bad_frame),
        .status_good_frame(m_status_good_frame)
    );

    // Pause control instantiation
    pause_control #(.PAUSE_ENABLE(PAUSE_ENABLE)) s_pause_control_inst (
        .clk(s_clk),
        .rst(s_rst),
        .pause_req(s_pause_req),
        .pause_ack(s_pause_ack)
    );

    pause_control #(.PAUSE_ENABLE(PAUSE_ENABLE)) m_pause_control_inst (
        .clk(m_clk),
        .rst(m_rst),
        .pause_req(m_pause_req),
        .pause_ack(m_pause_ack)
    );

    // Source clock domain logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_rd_ptr <= 0;
            s2m_wr_ptr_gray <= 0;
            s2m_rd_ptr_gray <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                fifo_mem[s_wr_ptr] <= s_axis_tdata;
                fifo_keep[s_wr_ptr] <= s_axis_tkeep;
                fifo_tlast[s_wr_ptr] <= s_axis_tlast;
                fifo_user[s_wr_ptr] <= s_axis_tuser;
                fifo_id[s_wr_ptr] <= s_axis_tid;
                fifo_dest[s_wr_ptr] <= s_axis_tdest;
                s_wr_ptr <= s_wr_ptr + 1;
                s2m_wr_ptr_gray <= (s_wr_ptr + 1) ^ ((s_wr_ptr + 1) >> 1);
            end
            if (m_axis_tvalid && m_axis_tready) begin
                s_rd_ptr <= s_rd_ptr + 1;
                s2m_rd_ptr_gray <= (s_rd_ptr + 1) ^ ((s_rd_ptr + 1) >> 1);
            end
        end
    end

    // Destination clock domain logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr <= 0;
            m_rd_ptr <= 0;
            m2s_wr_ptr_gray <= 0;
            m2s_rd_ptr_gray <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                m_rd_ptr <= m_rd_ptr + 1;
                m2s_rd_ptr_gray <= (m_rd_ptr + 1) ^ ((m_rd_ptr + 1) >> 1);
            end
            if (s_axis_tvalid && s_axis_tready) begin
                m_wr_ptr <= m_wr_ptr + 1;
                m2s_wr_ptr_gray <= (m_wr_ptr + 1) ^ ((m_wr_ptr + 1) >> 1);
            end
        end
    end

    // FIFO status flags
    assign s_fifo_empty = (s_wr_ptr == s_rd_ptr);
    assign s_fifo_full = (s_wr_ptr_gray_sync == {s_rd_ptr_gray_sync[ADDR_WIDTH-1:0], ~s_rd_ptr_gray_sync[ADDR_WIDTH]});
    assign m_fifo_empty = (m_wr_ptr == m_rd_ptr);
    assign m_fifo_full = (m_wr_ptr_gray_sync == {m_rd_ptr_gray_sync[ADDR_WIDTH-1:0], ~m_rd_ptr_gray_sync[ADDR_WIDTH]});

    // AXI ready signals
    assign s_axis_tready = ~s_fifo_full & ~s_pause_req;
    assign m_axis_tvalid = ~m_fifo_empty;

    // AXI output signals
    assign m_axis_tdata = width_adapter_tdata;
    assign m_axis_tkeep = width_adapter_tkeep;
    assign m_axis_tlast = width_adapter_tlast;
    assign m_axis_tuser = width_adapter_tuser;
    assign m_axis_tid = fifo_id[m_rd_ptr];
    assign m_axis_tdest = fifo_dest[m_rd_ptr];

endmodule

module cdc_fifo #(
    parameter WIDTH = 8
)
(
    input  wire                     src_clk,
    input  wire                     src_rst,
    input  wire [WIDTH-1:0]         src_data,
    input  wire                     dst_clk,
    input  wire                     dst_rst,
    output reg [WIDTH-1:0]          dst_data
);

    reg [WIDTH-1:0] sync_reg1;
    reg [WIDTH-1:0] sync_reg2;

    always @(posedge src_clk or posedge src_rst) begin
        if (src_rst)
            sync_reg1 <= 0;
        else
            sync_reg1 <= src_data;
    end

    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst) begin
            sync_reg2 <= 0;
            dst_data <= 0;
        end else begin
            sync_reg2 <= sync_reg1;
            dst_data <= sync_reg2;
        end
    end

endmodule

module width_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = 0,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = 0,
    parameter M_KEEP_WIDTH = 1
)
(
    input  wire [S_DATA_WIDTH-1:0]  s_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_tkeep,
    input  wire                     s_tlast,
    input  wire [USER_WIDTH-1:0]    s_tuser,
    output wire [M_DATA_WIDTH-1:0]  m_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_tkeep,
    output wire                     m_tlast,
    output wire [USER_WIDTH-1:0]    m_tuser
);

    assign m_tdata = s_tdata;
    assign m_tkeep = s_tkeep;
    assign m_tlast = s_tlast;
    assign m_tuser = s_tuser;

endmodule

module status_counter #(
    parameter DEPTH = 1024
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [$clog2(DEPTH):0]   wr_ptr,
    input  wire [$clog2(DEPTH):0]   rd_ptr,
    input  wire                     fifo_full,
    input  wire                     fifo_empty,
    output reg [$clog2(DEPTH):0]    status_depth,
    output reg [$clog2(DEPTH):0]    status_depth_commit,
    output reg                      status_overflow,
    output reg                      status_bad_frame,
    output reg                      status_good_frame
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_depth <= 0;
            status_depth_commit <= 0;
            status_overflow <= 0;
            status_bad_frame <= 0;
            status_good_frame <= 0;
        end else begin
            if (fifo_full)
                status_overflow <= 1;
            else
                status_overflow <= 0;

            if (wr_ptr >= rd_ptr)
                status_depth <= wr_ptr - rd_ptr;
            else
                status_depth <= DEPTH + wr_ptr - rd_ptr;

            if (wr_ptr != rd_ptr)
                status_depth_commit <= wr_ptr - rd_ptr;
            else
                status_depth_commit <= 0;

            // Placeholder for bad frame and good frame logic
            status_bad_frame <= 0;
            status_good_frame <= 0;
        end
    end

endmodule

module pause_control #(
    parameter PAUSE_ENABLE = 0
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     pause_req,
    output reg                      pause_ack
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pause_ack <= 0;
        else if (PAUSE_ENABLE) begin
            if (pause_req)
                pause_ack <= 1;
            else
                pause_ack <= 0;
        end
    end

endmodule
