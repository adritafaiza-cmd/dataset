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

    // Internal signals
    reg [S_DATA_WIDTH+S_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:0] fifo_wr_data;
    reg [S_KEEP_WIDTH-1:0] fifo_wr_data_keep;
    reg fifo_wr_data_last;
    reg [ID_WIDTH-1:0] fifo_wr_data_id;
    reg [DEST_WIDTH-1:0] fifo_wr_data_dest;
    reg [USER_WIDTH-1:0] fifo_wr_data_user;
    reg fifo_full;
    reg fifo_empty;
    reg [S_DATA_WIDTH+S_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:0] fifo_rd_data;
    reg [S_KEEP_WIDTH-1:0] fifo_rd_data_keep;
    reg fifo_rd_data_last;
    reg [ID_WIDTH-1:0] fifo_rd_data_id;
    reg [DEST_WIDTH-1:0] fifo_rd_data_dest;
    reg [USER_WIDTH-1:0] fifo_rd_data_user;
    reg fifo_wr_en;
    reg fifo_rd_en;

    // FIFO instantiation
    sync_fifo #(
        .WIDTH(S_DATA_WIDTH+S_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_sync (
        .clk_wr(s_clk),
        .clk_rd(m_clk),
        .rst_wr(s_rst),
        .rst_rd(m_rst),
        .din(fifo_wr_data),
        .wr_en(fifo_wr_en),
        .full(fifo_full),
        .empty(fifo_empty),
        .dout(fifo_rd_data),
        .rd_en(fifo_rd_en),
        .depth(s_status_depth),
        .depth_commit(s_status_depth_commit),
        .overflow(s_status_overflow)
    );

    // Width adapter instantiation
    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
    ) width_adapter_inst (
        .s_axis_tdata(fifo_rd_data[S_DATA_WIDTH-1:0]),
        .s_axis_tkeep(fifo_rd_data[S_DATA_WIDTH+S_KEEP_WIDTH-1:S_DATA_WIDTH]),
        .s_axis_tvalid(fifo_rd_en),
        .s_axis_tlast(fifo_rd_data_last),
        .s_axis_tid(fifo_rd_data[S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH+DEST_WIDTH+USER_WIDTH]),
        .s_axis_tdest(fifo_rd_data[S_DATA_WIDTH+S_KEEP_WIDTH+DEST_WIDTH+USER_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH+USER_WIDTH]),
        .s_axis_tuser(fifo_rd_data[S_DATA_WIDTH+S_KEEP_WIDTH+USER_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH]),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser)
    );

    // Write enable logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_wr_en <= 0;
        end else begin
            fifo_wr_en <= s_axis_tvalid && !fifo_full;
        end
    end

    // Read enable logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            fifo_rd_en <= 0;
        end else begin
            fifo_rd_en <= m_axis_tready && !fifo_empty;
        end
    end

    // AXI ready signals
    assign s_axis_tready = !fifo_full;
    assign m_axis_tvalid = !fifo_empty;

    // Pause signals (not used in this implementation as per the given parameters)
    assign s_pause_ack = 0;
    assign m_pause_ack = 0;

    // Status signals (additional signals not covered by the sync_fifo)
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;
    assign m_status_depth = s_status_depth;
    assign m_status_depth_commit = s_status_depth_commit;
    assign m_status_overflow = s_status_overflow;

endmodule

// Synchronous FIFO module
module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)
(
    input wire clk_wr,
    input wire clk_rd,
    input wire rst_wr,
    input wire rst_rd,
    input wire [WIDTH-1:0] din,
    input wire wr_en,
    output reg full,
    output reg empty,
    output reg [WIDTH-1:0] dout,
    input wire rd_en,
    output reg [$clog2(DEPTH):0] depth,
    output reg [$clog2(DEPTH):0] depth_commit,
    output reg overflow
);

    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Write pointer logic
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            full <= 0;
            depth <= 0;
            overflow <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            depth <= depth + 1;
            if (wr_ptr == rd_ptr - 1)
                full <= 1;
            if (wr_ptr == DEPTH - 1 && rd_ptr == 0)
                overflow <= 1;
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            empty <= 1;
            depth_commit <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            depth_commit <= depth_commit + 1;
            if (rd_ptr == wr_ptr - 1)
                empty <= 1;
        end
    end

    // Output data
    always @(posedge clk_rd) begin
        if (rd_en && !empty)
            dout <= mem[rd_ptr];
    end

endmodule

// Width Adapter module
module width_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
)
(
    input wire [S_DATA_WIDTH-1:0] s_axis_tdata,
    input wire [S_KEEP_WIDTH-1:0] s_axis_tkeep,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    input wire [ID_WIDTH-1:0] s_axis_tid,
    input wire [DEST_WIDTH-1:0] s_axis_tdest,
    input wire [USER_WIDTH-1:0] s_axis_tuser,
    output wire [M_DATA_WIDTH-1:0] m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0] m_axis_tkeep,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast,
    output wire [ID_WIDTH-1:0] m_axis_tid,
    output wire [DEST_WIDTH-1:0] m_axis_tdest,
    output wire [USER_WIDTH-1:0] m_axis_tuser
);

    // Register inputs to hold data while m_axis_tready is low
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tvalid_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;

    // Internal signals
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_int;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_int;
    reg m_axis_tvalid_int;
    reg m_axis_tlast_int;
    reg [ID_WIDTH-1:0] m_axis_tid_int;
    reg [DEST_WIDTH-1:0] m_axis_tdest_int;
    reg [USER_WIDTH-1:0] m_axis_tuser_int;

    // Register inputs
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
        end else if (s_axis_tvalid && !s_axis_tvalid_reg) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tvalid_reg <= s_axis_tvalid;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;
        end else if (m_axis_tready) begin
            s_axis_tvalid_reg <= 0;
        end
    end

    // Width conversion logic (assuming M_DATA_WIDTH == S_DATA_WIDTH for simplicity)
    assign m_axis_tdata_int = s_axis_tdata_reg;
    assign m_axis_tkeep_int = s_axis_tkeep_reg;
    assign m_axis_tvalid_int = s_axis_tvalid_reg;
    assign m_axis_tlast_int = s_axis_tlast_reg;
    assign m_axis_tid_int = s_axis_tid_reg;
    assign m_axis_tdest_int = s_axis_tdest_reg;
    assign m_axis_tuser_int = s_axis_tuser_reg;

    // Output assignments
    assign m_axis_tdata = m_axis_tdata_int;
    assign m_axis_tkeep = m_axis_tkeep_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = m_axis_tlast_int;
    assign m_axis_tid = m_axis_tid_int;
    assign m_axis_tdest = m_axis_tdest_int;
    assign m_axis_tuser = m_axis_tuser_int;

endmodule
