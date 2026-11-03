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

    // FIFO storage
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_user [DEPTH-1:0];
    reg mem_last [DEPTH-1:0];

    // Write and read pointers
    reg [ADDR_WIDTH:0] wr_ptr_s, wr_ptr_m, rd_ptr_s, rd_ptr_m;
    reg [ADDR_WIDTH:0] wr_ptr_gray_s, wr_ptr_gray_m, rd_ptr_gray_s, rd_ptr_gray_m;

    // Status signals
    reg [$clog2(DEPTH):0] s_depth, m_depth;
    reg s_overflow, m_overflow;
    reg s_bad_frame, m_bad_frame;
    reg s_good_frame, m_good_frame;

    // Pause signals
    reg s_pause_ack_reg, m_pause_ack_reg;

    // CDC synchronization
    reg [1:0] s_rst_sync, m_rst_sync;

    // FIFO control
    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;
    reg m_axis_tlast_reg;

    // CDC synchronization for pointers
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rst_sync <= 2'b11;
        end else begin
            s_rst_sync <= {s_rst_sync[0], s_rst};
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rst_sync <= 2'b11;
        end else begin
            m_rst_sync <= {m_rst_sync[0], m_rst};
        end
    end

    // Binary to Gray conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary conversion
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ bin[i];
        end
        gray_to_bin = bin;
    endfunction

    // Write side logic
    always @(posedge s_clk or posedge s_rst_sync[1]) begin
        if (s_rst_sync[1]) begin
            wr_ptr_s <= 0;
            wr_ptr_gray_s <= 0;
            s_axis_tready_reg <= 0;
            s_depth <= 0;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready_reg) begin
                mem[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                if (KEEP_ENABLE) mem_keep[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                if (ID_ENABLE) mem_id[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE) mem_dest[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE) mem_user[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                if (LAST_ENABLE) mem_last[wr_ptr_s[ADDR_WIDTH-1:0]] <= s_axis_tlast;

                wr_ptr_s <= wr_ptr_s + 1;
                wr_ptr_gray_s <= bin_to_gray(wr_ptr_s + 1);
                s_depth <= s_depth + 1;

                if (s_depth >= DEPTH - 1) begin
                    s_overflow <= 1;
                end else begin
                    s_overflow <= 0;
                end

                if (s_axis_tlast) begin
                    if (s_depth >= DEPTH - 1) begin
                        s_bad_frame <= 1;
                    end else begin
                        s_good_frame <= 1;
                    end
                end
            end else begin
                s_axis_tready_reg <= (s_depth < DEPTH - 1);
                s_good_frame <= 0;
                s_bad_frame <= 0;
            end
        end
    end

    // Read side logic
    always @(posedge m_clk or posedge m_rst_sync[1]) begin
        if (m_rst_sync[1]) begin
            rd_ptr_m <= 0;
            rd_ptr_gray_m <= 0;
            m_axis_tvalid_reg <= 0;
            m_depth <= 0;
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
        end else begin
            if (m_axis_tvalid_reg && m_axis_tready) begin
                rd_ptr_m <= rd_ptr_m + 1;
                rd_ptr_gray_m <= bin_to_gray(rd_ptr_m + 1);
                m_depth <= m_depth - 1;

                if (m_axis_tlast_reg) begin
                    m_good_frame <= 1;
                end
            end else begin
                m_axis_tvalid_reg <= (m_depth > 0);
                m_good_frame <= 0;
            end

            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tdata_reg <= mem[rd_ptr_m[ADDR_WIDTH-1:0]];
                if (KEEP_ENABLE) m_axis_tkeep_reg <= mem_keep[rd_ptr_m[ADDR_WIDTH-1:0]];
                if (ID_ENABLE) m_axis_tid_reg <= mem_id[rd_ptr_m[ADDR_WIDTH-1:0]];
                if (DEST_ENABLE) m_axis_tdest_reg <= mem_dest[rd_ptr_m[ADDR_WIDTH-1:0]];
                if (USER_ENABLE) m_axis_tuser_reg <= mem_user[rd_ptr_m[ADDR_WIDTH-1:0]];
                if (LAST_ENABLE) m_axis_tlast_reg <= mem_last[rd_ptr_m[ADDR_WIDTH-1:0]];
            end
        end
    end

    // Cross-domain pointer synchronization
    always @(posedge m_clk or posedge m_rst_sync[1]) begin
        if (m_rst_sync[1]) begin
            wr_ptr_gray_m <= 0;
        end else begin
            wr_ptr_gray_m <= wr_ptr_gray_s;
        end
    end

    always @(posedge s_clk or posedge s_rst_sync[1]) begin
        if (s_rst_sync[1]) begin
            rd_ptr_gray_s <= 0;
        end else begin
            rd_ptr_gray_s <= rd_ptr_gray_m;
        end
    end

    // Calculate depth
    always @(posedge s_clk or posedge s_rst_sync[1]) begin
        if (s_rst_sync[1]) begin
            s_depth <= 0;
        end else begin
            s_depth <= gray_to_bin(wr_ptr_gray_s) - gray_to_bin(rd_ptr_gray_s);
        end
    end

    always @(posedge m_clk or posedge m_rst_sync[1]) begin
        if (m_rst_sync[1]) begin
            m_depth <= 0;
        end else begin
            m_depth <= gray_to_bin(wr_ptr_gray_m) - gray_to_bin(rd_ptr_gray_m);
        end
    end

    // Pause logic
    always @(posedge s_clk or posedge s_rst_sync[1]) begin
        if (s_rst_sync[1]) begin
            s_pause_ack_reg <= 0;
        end else begin
            s_pause_ack_reg <= s_pause_req;
        end
    end

    always @(posedge m_clk or posedge m_rst_sync[1]) begin
        if (m_rst_sync[1]) begin
            m_pause_ack_reg <= 0;
        end else begin
            m_pause_ack_reg <= m_pause_req;
        end
    end

    // Output assignments
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

endmodule
