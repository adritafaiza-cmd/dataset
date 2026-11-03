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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0]  s_axis_tdata_r;
    reg [KEEP_WIDTH-1:0]  s_axis_tkeep_r;
    reg                   s_axis_tvalid_r;
    reg                   s_axis_tlast_r;
    reg [ID_WIDTH-1:0]    s_axis_tid_r;
    reg [DEST_WIDTH-1:0]  s_axis_tdest_r;
    reg [USER_WIDTH-1:0]  s_axis_tuser_r;

    reg [DATA_WIDTH-1:0]  m_axis_tdata_r;
    reg [KEEP_WIDTH-1:0]  m_axis_tkeep_r;
    reg                   m_axis_tvalid_r;
    reg                   m_axis_tlast_r;
    reg [ID_WIDTH-1:0]    m_axis_tid_r;
    reg [DEST_WIDTH-1:0]  m_axis_tdest_r;
    reg [USER_WIDTH-1:0]  m_axis_tuser_r;

    wire                  fifo_full;
    wire                  fifo_empty;
    wire                  fifo_almost_full;
    wire                  fifo_almost_empty;

    wire [DATA_WIDTH-1:0] fifo_dout;
    wire [KEEP_WIDTH-1:0] fifo_dout_keep;
    wire                  fifo_dout_last;
    wire [ID_WIDTH-1:0]   fifo_dout_tid;
    wire [DEST_WIDTH-1:0] fifo_dout_dest;
    wire [USER_WIDTH-1:0] fifo_dout_user;

    reg [$clog2(DEPTH):0] s_status_depth_r;
    reg [$clog2(DEPTH):0] s_status_depth_commit_r;
    reg                   s_status_overflow_r;
    reg                   s_status_bad_frame_r;
    reg                   s_status_good_frame_r;

    reg [$clog2(DEPTH):0] m_status_depth_r;
    reg [$clog2(DEPTH):0] m_status_depth_commit_r;
    reg                   m_status_overflow_r;
    reg                   m_status_bad_frame_r;
    reg                   m_status_good_frame_r;

    wire                  s_pause_ack_r;
    wire                  m_pause_ack_r;

    // FIFO instantiation
    dual_clock_fifo #(
        .WIDTH(DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH),
        .DEPTH(DEPTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) fifo_inst (
        .wr_clk(s_clk),
        .wr_rst(s_rst),
        .rd_clk(m_clk),
        .rd_rst(m_rst),
        .din({s_axis_tdata_r, s_axis_tkeep_r, s_axis_tlast_r, s_axis_tid_r, s_axis_tdest_r, s_axis_tuser_r}),
        .wr_en(s_axis_tvalid_r),
        .full_n(~fifo_full),
        .dout({fifo_dout, fifo_dout_keep, fifo_dout_last, fifo_dout_tid, fifo_dout_dest, fifo_dout_user}),
        .valid(m_axis_tvalid_r),
        .rd_en(m_axis_tready & m_axis_tvalid_r),
        .wr_count(s_status_depth_r),
        .wr_commit_count(s_status_depth_commit_r),
        .overflow(s_status_overflow_r),
        .bad_frame(s_status_bad_frame_r),
        .good_frame(s_status_good_frame_r),
        .rd_count(m_status_depth_r),
        .rd_commit_count(m_status_depth_commit_r)
    );

    // Synchronous FIFO inputs on s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tdata_r <= 0;
            s_axis_tkeep_r <= 0;
            s_axis_tvalid_r <= 0;
            s_axis_tlast_r <= 0;
            s_axis_tid_r <= 0;
            s_axis_tdest_r <= 0;
            s_axis_tuser_r <= 0;
        end else begin
            if (s_axis_tvalid && !fifo_full) begin
                s_axis_tdata_r <= s_axis_tdata;
                s_axis_tkeep_r <= s_axis_tkeep;
                s_axis_tvalid_r <= s_axis_tvalid;
                s_axis_tlast_r <= s_axis_tlast;
                s_axis_tid_r <= s_axis_tid;
                s_axis_tdest_r <= s_axis_tdest;
                s_axis_tuser_r <= s_axis_tuser;
            end else if (fifo_full) begin
                s_axis_tvalid_r <= 0;
            end
        end
    end

    // Synchronous FIFO outputs on m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata_r <= 0;
            m_axis_tkeep_r <= 0;
            m_axis_tvalid_r <= 0;
            m_axis_tlast_r <= 0;
            m_axis_tid_r <= 0;
            m_axis_tdest_r <= 0;
            m_axis_tuser_r <= 0;
        end else begin
            if (m_axis_tready & m_axis_tvalid_r) begin
                m_axis_tvalid_r <= 0;
            end else if (m_axis_tvalid_r) begin
                // Hold the data if not ready
            end else begin
                m_axis_tdata_r <= fifo_dout;
                m_axis_tkeep_r <= fifo_dout_keep;
                m_axis_tvalid_r <= 1;
                m_axis_tlast_r <= fifo_dout_last;
                m_axis_tid_r <= fifo_dout_tid;
                m_axis_tdest_r <= fifo_dout_dest;
                m_axis_tuser_r <= fifo_dout_user;
            end
        end
    end

    // Assign outputs
    assign s_axis_tready = ~fifo_full;
    assign m_axis_tdata = m_axis_tdata_r;
    assign m_axis_tkeep = m_axis_tkeep_r;
    assign m_axis_tvalid = m_axis_tvalid_r;
    assign m_axis_tlast = m_axis_tlast_r;
    assign m_axis_tid = m_axis_tid_r;
    assign m_axis_tdest = m_axis_tdest_r;
    assign m_axis_tuser = m_axis_tuser_r;

    assign s_status_depth = s_status_depth_r;
    assign s_status_depth_commit = s_status_depth_commit_r;
    assign s_status_overflow = s_status_overflow_r;
    assign s_status_bad_frame = s_status_bad_frame_r;
    assign s_status_good_frame = s_status_good_frame_r;

    assign m_status_depth = m_status_depth_r;
    assign m_status_depth_commit = m_status_depth_commit_r;
    assign m_status_overflow = m_status_overflow_r;
    assign m_status_bad_frame = m_status_bad_frame_r;
    assign m_status_good_frame = m_status_good_frame_r;

    assign s_pause_ack = s_pause_ack_r;
    assign m_pause_ack = m_pause_ack_r;

endmodule

// Dual clock FIFO module
module dual_clock_fifo #
(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter RAM_PIPELINE = 1
)
(
    input  wire                 wr_clk,
    input  wire                 wr_rst,
    input  wire                 rd_clk,
    input  wire                 rd_rst,
    input  wire [WIDTH-1:0]     din,
    input  wire                 wr_en,
    output wire                 full_n,
    output wire [WIDTH-1:0]     dout,
    output wire                 valid,
    input  wire                 rd_en,
    output wire [$clog2(DEPTH):0] wr_count,
    output wire [$clog2(DEPTH):0] wr_commit_count,
    output wire                 overflow,
    output wire                 bad_frame,
    output wire                 good_frame,
    output wire [$clog2(DEPTH):0] rd_count,
    output wire [$clog2(DEPTH):0] rd_commit_count
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_commit_ptr, rd_commit_ptr;

    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_commit_ptr_gray, rd_commit_ptr_gray;

    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] wr_commit_ptr_gray_sync, rd_commit_ptr_gray_sync;

    wire [ADDR_WIDTH:0] wr_ptr_bin, rd_ptr_bin;
    wire [ADDR_WIDTH:0] wr_commit_ptr_bin, rd_commit_ptr_bin;

    wire full, empty, almost_full, almost_empty;

    // Write pointer logic
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Commit pointers
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_commit_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_commit_ptr <= wr_commit_ptr + 1;
        end
    end

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_commit_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_commit_ptr <= rd_commit_ptr + 1;
        end
    end

    // Gray code conversion
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);
    assign wr_commit_ptr_gray = wr_commit_ptr ^ (wr_commit_ptr >> 1);
    assign rd_commit_ptr_gray = rd_commit_ptr ^ (rd_commit_ptr >> 1);

    // Synchronize gray codes to the opposite clock domain
    sync_gray_counter #(.WIDTH(ADDR_WIDTH+1)) sync_wr_ptr (
        .clk(rd_clk),
        .rst(rd_rst),
        .gray_in(wr_ptr_gray),
        .gray_out(wr_ptr_gray_sync)
    );

    sync_gray_counter #(.WIDTH(ADDR_WIDTH+1)) sync_rd_ptr (
        .clk(wr_clk),
        .rst(wr_rst),
        .gray_in(rd_ptr_gray),
        .gray_out(rd_ptr_gray_sync)
    );

    sync_gray_counter #(.WIDTH(ADDR_WIDTH+1)) sync_wr_commit_ptr (
        .clk(rd_clk),
        .rst(rd_rst),
        .gray_in(wr_commit_ptr_gray),
        .gray_out(wr_commit_ptr_gray_sync)
    );

    sync_gray_counter #(.WIDTH(ADDR_WIDTH+1)) sync_rd_commit_ptr (
        .clk(wr_clk),
        .rst(wr_rst),
        .gray_in(rd_commit_ptr_gray),
        .gray_out(rd_commit_ptr_gray_sync)
    );

    // Binary conversion
    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) gtb_wr_ptr (
        .gray(wr_ptr_gray_sync),
        .bin(wr_ptr_bin)
    );

    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) gtb_rd_ptr (
        .gray(rd_ptr_gray_sync),
        .bin(rd_ptr_bin)
    );

    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) gtb_wr_commit_ptr (
        .gray(wr_commit_ptr_gray_sync),
        .bin(wr_commit_ptr_bin)
    );

    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) gtb_rd_commit_ptr (
        .gray(rd_commit_ptr_gray_sync),
        .bin(rd_commit_ptr_bin)
    );

    // Full and empty flags
    assign full = (wr_ptr_bin == {~rd_ptr_bin[ADDR_WIDTH], rd_ptr_bin[ADDR_WIDTH-1:0]});
    assign empty = (wr_ptr_bin == rd_ptr_bin);
    assign almost_full = (wr_ptr_bin == {~rd_ptr_bin[ADDR_WIDTH], rd_ptr_bin[ADDR_WIDTH-1:0]} + 1);
    assign almost_empty = (wr_ptr_bin == rd_ptr_bin + 1);

    // FIFO write
    always @(posedge wr_clk) begin
        if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
        end
    end

    // FIFO read
    always @(posedge rd_clk) begin
        if (rd_en && !empty) begin
            dout <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        end
    end

    // FIFO valid
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            valid <= 0;
        end else begin
            valid <= rd_en && !empty;
        end
    end

    // FIFO full_n
    assign full_n = ~full;

    // FIFO counts
    assign wr_count = wr_ptr_bin;
    assign wr_commit_count = wr_commit_ptr_bin;
    assign rd_count = rd_ptr_bin;
    assign rd_commit_count = rd_commit_ptr_bin;

    // Overflow and underflow flags
    assign overflow = wr_en && full;
    assign bad_frame = 1'b0; // Placeholder for bad frame detection
    assign good_frame = 1'b0; // Placeholder for good frame detection

endmodule

// Gray code synchronizer
module sync_gray_counter #
(
    parameter WIDTH = 4
)
(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [WIDTH-1:0]     gray_in,
    output reg [WIDTH-1:0]      gray_out
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sync_stage
            reg sync_reg;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    sync_reg <= 0;
                end else begin
                    sync_reg <= gray_in[i];
                end
            end
            assign gray_out[i] = sync_reg;
        end
    endgenerate

endmodule

// Gray to binary conversion
module gray_to_bin #
(
    parameter WIDTH = 4
)
(
    input  wire [WIDTH-1:0]     gray,
    output wire [WIDTH-1:0]     bin
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gtb_stage
            assign bin[i] = gray[i] ^ gray[i+1];
        end
    endgenerate

endmodule
