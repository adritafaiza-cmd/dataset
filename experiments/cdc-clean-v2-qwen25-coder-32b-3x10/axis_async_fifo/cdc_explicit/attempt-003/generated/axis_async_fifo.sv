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

    // FIFO memory
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_user [DEPTH-1:0];
    reg mem_last [DEPTH-1:0];

    // Write and read pointers
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Status signals
    reg [$clog2(DEPTH):0] s_depth, m_depth;
    reg s_overflow, m_overflow;
    reg s_bad_frame, m_bad_frame;
    reg s_good_frame, m_good_frame;

    // Pause signals
    reg s_pause_ack_reg, m_pause_ack_reg;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Binary code conversion
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
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            s_depth <= 0;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                if (KEEP_ENABLE) mem_keep[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                if (ID_ENABLE) mem_id[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE) mem_dest[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE) mem_user[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                if (LAST_ENABLE) mem_last[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;

                wr_ptr <= wr_ptr + 1;
                wr_ptr_gray <= bin_to_gray(wr_ptr + 1);

                if (wr_ptr_gray == rd_ptr_gray_sync) begin
                    s_overflow <= 1;
                end else begin
                    s_depth <= wr_ptr - rd_ptr_gray_sync;
                    s_overflow <= 0;
                end

                if (s_axis_tlast) begin
                    if (s_axis_tuser & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                        s_bad_frame <= 1;
                    end else begin
                        s_good_frame <= 1;
                    end
                end
            end else begin
                s_bad_frame <= 0;
                s_good_frame <= 0;
            end
        end
    end

    // Read side logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            m_depth <= 0;
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                rd_ptr <= rd_ptr + 1;
                rd_ptr_gray <= bin_to_gray(rd_ptr + 1);

                if (wr_ptr_gray_sync == rd_ptr_gray) begin
                    m_overflow <= 1;
                end else begin
                    m_depth <= wr_ptr_gray_sync - rd_ptr;
                    m_overflow <= 0;
                end

                if (mem_last[rd_ptr[ADDR_WIDTH-1:0]]) begin
                    if (mem_user[rd_ptr[ADDR_WIDTH-1:0]] & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                        m_bad_frame <= 1;
                    end else begin
                        m_good_frame <= 1;
                    end
                end
            end else begin
                m_bad_frame <= 0;
                m_good_frame <= 0;
            end
        end
    end

    // Gray code synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Output assignments
    assign s_axis_tready = (wr_ptr_gray != rd_ptr_gray_sync) && !s_pause_req;
    assign m_axis_tdata = mem[rd_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = KEEP_ENABLE ? mem_keep[rd_ptr[ADDR_WIDTH-1:0]] : {KEEP_WIDTH{1'b1}};
    assign m_axis_tvalid = (wr_ptr_gray_sync != rd_ptr_gray) && !m_pause_req;
    assign m_axis_tlast = LAST_ENABLE ? mem_last[rd_ptr[ADDR_WIDTH-1:0]] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? mem_id[rd_ptr[ADDR_WIDTH-1:0]] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? mem_dest[rd_ptr[ADDR_WIDTH-1:0]] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? mem_user[rd_ptr[ADDR_WIDTH-1:0]] : {USER_WIDTH{1'b0}};

    // Pause signals
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status signals
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
