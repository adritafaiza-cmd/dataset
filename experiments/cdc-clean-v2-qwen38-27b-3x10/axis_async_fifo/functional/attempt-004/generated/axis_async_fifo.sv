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
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Total width for storage
    localparam TOTAL_WIDTH = DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [TOTAL_WIDTH-1:0] s_axis_tdata_packed;
    wire [TOTAL_WIDTH-1:0] m_axis_tdata_packed;

    // Pack input
    assign s_axis_tdata_packed = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Unpack output
    assign m_axis_tdata = m_axis_tdata_packed[DATA_WIDTH-1:0];
    assign m_axis_tkeep = m_axis_tdata_packed[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH-1 : 0) -: KEEP_WIDTH];
    assign m_axis_tlast = m_axis_tdata_packed[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)];
    assign m_axis_tid = m_axis_tdata_packed[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? ID_WIDTH-1 : 0) -: ID_WIDTH];
    assign m_axis_tdest = m_axis_tdata_packed[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)];
    assign m_axis_tuser = m_axis_tdata_packed[TOTAL_WIDTH-1 -: USER_WIDTH];

    // Correct unpacking with proper offsets
    wire [TOTAL_WIDTH-1:0] unpacked_data;
    assign unpacked_data = m_axis_tdata_packed;

    assign m_axis_tdata = unpacked_data[DATA_WIDTH-1:0];
    generate
        if (KEEP_ENABLE) begin : gen_keep
            assign m_axis_tkeep = unpacked_data[DATA_WIDTH + KEEP_WIDTH-1 : DATA_WIDTH];
        end else begin : gen_keep_no
            assign m_axis_tkeep = {KEEP_WIDTH{1'b0}};
        end
    endgenerate

    generate
        if (LAST_ENABLE) begin : gen_last
            assign m_axis_tlast = unpacked_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)];
        end else begin : gen_last_no
            assign m_axis_tlast = 1'b0;
        end
    endgenerate

    generate
        if (ID_ENABLE) begin : gen_id
            assign m_axis_tid = unpacked_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + ID_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)];
        end else begin : gen_id_no
            assign m_axis_tid = {ID_WIDTH{1'b0}};
        end
    endgenerate

    generate
        if (DEST_ENABLE) begin : gen_dest
            assign m_axis_tdest = unpacked_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + DEST_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)];
        end else begin : gen_dest_no
            assign m_axis_tdest = {DEST_WIDTH{1'b0}};
        end
    endgenerate

    generate
        if (USER_ENABLE) begin : gen_user
            assign m_axis_tuser = unpacked_data[TOTAL_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)];
        end else begin : gen_user_no
            assign m_axis_tuser = {USER_WIDTH{1'b0}};
        end
    endgenerate

    // Async FIFO core
    wire [TOTAL_WIDTH-1:0] fifo_dout;
    wire fifo_full;
    wire fifo_empty;
    wire [PTR_WIDTH-1:0] fifo_depth;

    // Write side
    wire s_axis_tready_internal;
    wire s_axis_tready_final;
    wire s_axis_tvalid_internal;
    wire s_axis_tlast_internal;
    wire [TOTAL_WIDTH-1:0] s_axis_tdata_internal;

    // Read side
    wire m_axis_tvalid_internal;
    wire m_axis_tready_internal;
    wire [TOTAL_WIDTH-1:0] m_axis_tdata_internal;
    wire m_axis_tlast_internal;

    // Pause logic
    wire s_pause_active;
    wire m_pause_active;

    // Status signals
    wire s_status_overflow_internal;
    wire s_status_bad_frame_internal;
    wire s_status_good_frame_internal;
    wire m_status_overflow_internal;
    wire m_status_bad_frame_internal;
    wire m_status_good_frame_internal;

    // Frame tracking
    wire s_in_frame;
    wire m_in_frame;
    wire s_frame_overflow;
    wire m_frame_overflow;

    // Simple async FIFO implementation
    // Using dual-port RAM with Gray code pointers

    reg [TOTAL_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr_gray;
    reg [PTR_WIDTH-1:0] rd_ptr_gray;
    reg [PTR_WIDTH-1:0] wr_ptr_bin;
    reg [PTR_WIDTH-1:0] rd_ptr_bin;

    // Synchronizers
    reg [PTR_WIDTH-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

    // Write side logic
    wire s_axis_tready_base = !fifo_full;
    wire s_axis_tready_with_pause = s_axis_tready_base && !s_pause_active;
    wire s_axis_tready_with_drop = (DROP_WHEN_FULL || MARK_WHEN_FULL) ? 1'b1 : s_axis_tready_with_pause;
    wire s_axis_tready_with_frame = (FRAME_FIFO && DROP_OVERSIZE_FRAME) ? (s_axis_tready_with_drop && !s_in_frame) : s_axis_tready_with_drop;
    
    assign s_axis_tready = s_axis_tready_with_frame;

    wire s_axis_tvalid_final = s_axis_tvalid && s_axis_tready;

    // Write enable
    wire s_wr_en = s_axis_tvalid_final;

    // Read side logic
    wire m_axis_tvalid_base = !fifo_empty;
    wire m_axis_tvalid_with_pause = m_axis_tvalid_base && !m_pause_active;
    wire m_axis_tvalid_with_frame = (FRAME_FIFO) ? (m_axis_tvalid_with_pause && m_in_frame) : m_axis_tvalid_with_pause;
    
    assign m_axis_tvalid = m_axis_tvalid_with_frame;

    wire m_axis_tready_final = m_axis_tready && m_axis_tvalid;

    // Read enable
    wire m_rd_en = m_axis_tready_final;

    // Gray code conversion
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        integer i;
        begin
            gray2bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i-1)
                gray2bin[i] = gray[i] ^ gray2bin[i+1];
        end
    endfunction

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr_bin <= {PTR_WIDTH{1'b0}};
            wr_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (s_wr_en) begin
            wr_ptr_bin <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1'b1);
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr_bin <= {PTR_WIDTH{1'b0}};
            rd_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (m_rd_en) begin
            rd_ptr_bin <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1'b1);
        end
    end

    // Synchronize write pointer to read clock
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            wr_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Synchronize read pointer to write clock
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // Convert synchronized pointers to binary
    wire [PTR_WIDTH-1:0] wr_ptr_gray_sync2_bin = gray2bin(wr_ptr_gray_sync2);
    wire [PTR_WIDTH-1:0] rd_ptr_gray_sync2_bin = gray2bin(rd_ptr_gray_sync2);

    // Full and empty detection
    assign fifo_full = (wr_ptr_bin[PTR_WIDTH-1] != rd_ptr_gray_sync2_bin[PTR_WIDTH-1]) && 
                       (wr_ptr_bin[PTR_WIDTH-2:0] == rd_ptr_gray_sync2_bin[PTR_WIDTH-2:0]);
    assign fifo_empty = (wr_ptr_gray_sync2 == rd_ptr_gray);

    // Depth calculation
    wire [PTR_WIDTH-1:0] depth_wr = wr_ptr_bin - rd_ptr_gray_sync2_bin;
    wire [PTR_WIDTH-1:0] depth_rd = wr_ptr_gray_sync2_bin - rd_ptr_bin;
    assign fifo_depth = (wr_ptr_bin[PTR_WIDTH-1] >= rd_ptr_gray_sync2_bin[PTR_WIDTH-1]) ? depth_wr : depth_rd;

    // Memory write
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= s_axis_tdata_packed;
        end
    end

    // Memory read
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr_bin[ADDR_WIDTH-1:0];
    wire [TOTAL_WIDTH-1:0] rd_data = mem[rd_addr];

    // Pipeline stage for RAM read
    reg [TOTAL_WIDTH-1:0] rd_data_pipe;
    reg rd_valid_pipe;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_data_pipe <= {TOTAL_WIDTH{1'b0}};
            rd_valid_pipe <= 1'b0;
        end else begin
            rd_data_pipe <= rd_data;
            rd_valid_pipe <= m_rd_en;
        end
    end

    // Output data
    assign m_axis_tdata_packed = rd_data_pipe;

    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            s_pause_ack_reg <= s_pause_req;
        end else begin
            s_pause_ack_reg <= 1'b0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            m_pause_ack_reg <= m_pause_req;
        end else begin
            m_pause_ack_reg <= 1'b0;
        end
    end

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    assign s_pause_active = PAUSE_ENABLE ? s_pause_ack_reg : 1'b0;
    assign m_pause_active = PAUSE_ENABLE ? m_pause_ack_reg : 1'b0;

    // Frame tracking
    reg s_in_frame_reg;
    reg m_in_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame_reg <= 1'b0;
        end else if (s_wr_en) begin
            if (LAST_ENABLE && s_axis_tlast) begin
                s_in_frame_reg <= 1'b0;
            end else begin
                s_in_frame_reg <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_in_frame_reg <= 1'b0;
        end else if (m_rd_en) begin
            if (LAST_ENABLE && m_axis_tlast) begin
                m_in_frame_reg <= 1'b0;
            end else begin
                m_in_frame_reg <= 1'b1;
            end
        end
    end

    assign s_in_frame = s_in_frame_reg;
    assign m_in_frame = m_in_frame_reg;

    // Status signals
    assign s_status_overflow = s_wr_en && fifo_full;
    assign m_status_overflow = m_rd_en && fifo_empty;

    // Frame status
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_bad_frame_reg <= 1'b0;
            s_status_good_frame_reg <= 1'b0;
        end else if (s_wr_en && LAST_ENABLE && s_axis_tlast) begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                s_status_bad_frame_reg <= 1'b1;
                s_status_good_frame_reg <= 1'b0;
            end else begin
                s_status_bad_frame_reg <= 1'b0;
                s_status_good_frame_reg <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_bad_frame_reg <= 1'b0;
            m_status_good_frame_reg <= 1'b0;
        end else if (m_rd_en && LAST_ENABLE && m_axis_tlast) begin
            if (DROP_BAD_FRAME && (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                m_status_bad_frame_reg <= 1'b1;
                m_status_good_frame_reg <= 1'b0;
            end else begin
                m_status_bad_frame_reg <= 1'b0;
                m_status_good_frame_reg <= 1'b1;
            end
        end
    end

    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    // Depth status
    assign s_status_depth = fifo_depth;
    assign s_status_depth_commit = fifo_depth;
    assign m_status_depth = fifo_depth;
    assign m_status_depth_commit = fifo_depth;

endmodule
