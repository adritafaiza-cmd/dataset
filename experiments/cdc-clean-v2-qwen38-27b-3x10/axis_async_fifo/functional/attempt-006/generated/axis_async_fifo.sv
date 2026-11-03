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
    localparam DEPTH_MASK = DEPTH - 1;

    // Total width of the data word stored in RAM
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + 
                                   (LAST_ENABLE ? 1 : 0) + 
                                   (ID_ENABLE ? ID_WIDTH : 0) + 
                                   (DEST_ENABLE ? DEST_WIDTH : 0) + 
                                   (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    reg [TOTAL_DATA_WIDTH-1:0] ram [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [ADDR_WIDTH:0] w_ptr;
    // Read pointer (m_clk domain)
    reg [ADDR_WIDTH:0] r_ptr;

    // Gray code pointers for CDC
    reg [ADDR_WIDTH:0] w_ptr_gray;
    reg [ADDR_WIDTH:0] r_ptr_gray;

    // Synchronizers
    reg [ADDR_WIDTH:0] r_ptr_gray_sync1, r_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] w_ptr_gray_sync1, w_ptr_gray_sync2;

    // Write enable
    wire s_axis_tready_int;
    wire s_axis_tready;
    assign s_axis_tready = s_axis_tready_int;

    // Read enable
    wire m_axis_tvalid_int;
    wire m_axis_tvalid;
    assign m_axis_tvalid = m_axis_tvalid_int;

    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status flags
    reg s_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_overflow_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    // Depth calculation
    wire [$clog2(DEPTH):0] s_depth;
    wire [$clog2(DEPTH):0] m_depth;
    wire [$clog2(DEPTH):0] s_depth_commit;
    wire [$clog2(DEPTH):0] m_depth_commit;

    // Full/Empty detection
    wire s_full;
    wire m_empty;

    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    reg [USER_WIDTH-1:0] s_frame_user;
    reg [USER_WIDTH-1:0] m_frame_user;
    reg s_frame_bad;
    reg m_frame_bad;

    // Oversize frame tracking
    reg s_oversize;
    reg m_oversize;

    // Write data assembly
    reg [TOTAL_DATA_WIDTH-1:0] w_data;
    integer i;

    // Read data decomposition
    wire [TOTAL_DATA_WIDTH-1:0] r_data;
    wire [DATA_WIDTH-1:0] r_tdata;
    wire [KEEP_WIDTH-1:0] r_tkeep;
    wire r_tlast;
    wire [ID_WIDTH-1:0] r_tid;
    wire [DEST_WIDTH-1:0] r_tdest;
    wire [USER_WIDTH-1:0] r_tuser;

    // RAM read
    reg [ADDR_WIDTH-1:0] r_addr;
    reg [TOTAL_DATA_WIDTH-1:0] r_data_reg;
    reg r_data_valid;

    // Output FIFO (if enabled)
    reg [TOTAL_DATA_WIDTH-1:0] out_fifo [0:DEPTH-1];
    reg [ADDR_WIDTH:0] out_w_ptr;
    reg [ADDR_WIDTH:0] out_r_ptr;
    reg [ADDR_WIDTH:0] out_w_ptr_gray;
    reg [ADDR_WIDTH:0] out_r_ptr_gray;
    reg [ADDR_WIDTH:0] out_r_ptr_gray_sync1, out_r_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] out_w_ptr_gray_sync1, out_w_ptr_gray_sync2;
    wire out_full;
    wire out_empty;
    wire [$clog2(DEPTH):0] out_depth;

    // Helper function to convert binary to gray
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Helper function to convert gray to binary
    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        reg [ADDR_WIDTH:0] bin;
        integer j;
        begin
            bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (j = ADDR_WIDTH-1; j >= 0; j = j-1)
                bin[j] = gray[j] ^ bin[j+1];
            gray2bin = bin;
        end
    endfunction

    // Write data assembly
    always @* begin
        w_data = {TOTAL_DATA_WIDTH{1'b0}};
        if (USER_ENABLE) w_data[USER_WIDTH-1:0] = s_axis_tuser;
        if (DEST_ENABLE) w_data[USER_WIDTH + DEST_WIDTH-1:USER_WIDTH] = s_axis_tdest;
        if (ID_ENABLE) w_data[USER_WIDTH + DEST_WIDTH + ID_WIDTH-1:USER_WIDTH + DEST_WIDTH] = s_axis_tid;
        if (LAST_ENABLE) w_data[USER_WIDTH + DEST_WIDTH + ID_WIDTH] = s_axis_tlast;
        if (KEEP_ENABLE) w_data[USER_WIDTH + DEST_WIDTH + ID_WIDTH + (LAST_ENABLE?1:0) + KEEP_WIDTH-1:USER_WIDTH + DEST_WIDTH + ID_WIDTH + (LAST_ENABLE?1:0)] = s_axis_tkeep;
        w_data[DATA_WIDTH-1:0] = s_axis_tdata;
    end

    // Read data decomposition
    assign r_tdata = r_data[DATA_WIDTH-1:0];
    assign r_tkeep = KEEP_ENABLE ? r_data[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign r_tlast = LAST_ENABLE ? r_data[DATA_WIDTH + (KEEP_ENABLE?KEEP_WIDTH:0)] : 1'b0;
    assign r_tid = ID_ENABLE ? r_data[DATA_WIDTH + (KEEP_ENABLE?KEEP_WIDTH:0) + (LAST_ENABLE?1:0) + ID_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE?KEEP_WIDTH:0) + (LAST_ENABLE?1:0)] : {ID_WIDTH{1'b0}};
    assign r_tdest = DEST_ENABLE ? r_data[DATA_WIDTH + (KEEP_ENABLE?KEEP_WIDTH:0) + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0) + DEST_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE?KEEP_WIDTH:0) + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0)] : {DEST_WIDTH{1'b0}};
    assign r_tuser = USER_ENABLE ? r_data[TOTAL_DATA_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE?KEEP_WIDTH:0) + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0) + (DEST_ENABLE?DEST_WIDTH:0)] : {USER_WIDTH{1'b0}};

    // Synchronizers for read pointer (to s_clk domain)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_gray_sync1 <= {ADDR_WIDTH+1{1'b0}};
            r_ptr_gray_sync2 <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            r_ptr_gray_sync1 <= r_ptr_gray;
            r_ptr_gray_sync2 <= r_ptr_gray_sync1;
        end
    end

    // Synchronizers for write pointer (to m_clk domain)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_gray_sync1 <= {ADDR_WIDTH+1{1'b0}};
            w_ptr_gray_sync2 <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            w_ptr_gray_sync1 <= w_ptr_gray;
            w_ptr_gray_sync2 <= w_ptr_gray_sync1;
        end
    end

    // Depth calculations
    wire [$clog2(DEPTH):0] s_r_ptr_bin;
    wire [$clog2(DEPTH):0] m_w_ptr_bin;
    assign s_r_ptr_bin = gray2bin(r_ptr_gray_sync2);
    assign m_w_ptr_bin = gray2bin(w_ptr_gray_sync2);

    assign s_depth = w_ptr - s_r_ptr_bin;
    assign m_depth = m_w_ptr_bin - r_ptr;

    // Full/Empty
    assign s_full = (w_ptr[ADDR_WIDTH] == s_r_ptr_bin[ADDR_WIDTH]) && 
                    (w_ptr[ADDR_WIDTH-1:0] == s_r_ptr_bin[ADDR_WIDTH-1:0]) && 
                    (w_ptr[ADDR_WIDTH-1:0] != 0);
    // More accurate full check:
    assign s_full = (w_ptr[ADDR_WIDTH-1:0] == s_r_ptr_bin[ADDR_WIDTH-1:0]) && 
                    (w_ptr[ADDR_WIDTH] != s_r_ptr_bin[ADDR_WIDTH]);
    assign m_empty = (r_ptr[ADDR_WIDTH-1:0] == m_w_ptr_bin[ADDR_WIDTH-1:0]) && 
                     (r_ptr[ADDR_WIDTH] == m_w_ptr_bin[ADDR_WIDTH]);

    // Commit depth (same as depth for this implementation)
    assign s_depth_commit = s_depth;
    assign m_depth_commit = m_depth;

    // Write pointer update
    wire s_write_en;
    assign s_write_en = s_axis_tvalid && s_axis_tready_int;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {ADDR_WIDTH+1{1'b0}};
            w_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
            s_in_frame <= 1'b0;
            s_frame_user <= {USER_WIDTH{1'b0}};
            s_frame_bad <= 1'b0;
            s_oversize <= 1'b0;
            s_status_overflow_reg <= 1'b0;
            s_status_bad_frame_reg <= 1'b0;
            s_status_good_frame_reg <= 1'b0;
            s_pause_ack_reg <= 1'b0;
        end else begin
            w_ptr_gray <= bin2gray(w_ptr);
            
            // Pause handling
            if (PAUSE_ENABLE) begin
                if (s_pause_req && !s_pause_ack_reg) begin
                    s_pause_ack_reg <= 1'b1;
                end else if (!s_pause_req && s_pause_ack_reg) begin
                    s_pause_ack_reg <= 1'b0;
                end
            end else begin
                s_pause_ack_reg <= 1'b0;
            end

            // Frame tracking
            if (s_write_en) begin
                if (!s_in_frame) begin
                    s_in_frame <= 1'b1;
                    s_frame_user <= s_axis_tuser;
                    s_frame_bad <= 1'b0;
                    s_oversize <= 1'b0;
                end else begin
                    // Check for bad frame
                    if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        s_frame_bad <= 1'b1;
                    end
                end
                
                if (s_axis_tlast) begin
                    s_in_frame <= 1'b0;
                    if (s_frame_bad) begin
                        s_status_bad_frame_reg <= 1'b1;
                    end else begin
                        s_status_good_frame_reg <= 1'b1;
                    end
                end
            end

            // Pointer increment
            if (s_write_en) begin
                w_ptr <= w_ptr + 1'b1;
            end
        end
    end

    // tready generation
    wire s_pause_active;
    assign s_pause_active = PAUSE_ENABLE && s_pause_ack_reg;
    
    wire s_can_accept;
    assign s_can_accept = !s_full || DROP_WHEN_FULL || MARK_WHEN_FULL;
    
    assign s_axis_tready_int = s_can_accept && !s_pause_active;

    // RAM write
    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram[w_ptr[ADDR_WIDTH-1:0]] <= w_data;
        end
    end

    // Read pointer update
    wire m_read_en;
    assign m_read_en = m_axis_tvalid_int && m_axis_tready;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {ADDR_WIDTH+1{1'b0}};
            r_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
            m_in_frame <= 1'b0;
            m_frame_user <= {USER_WIDTH{1'b0}};
            m_frame_bad <= 1'b0;
            m_oversize <= 1'b0;
            m_status_overflow_reg <= 1'b0;
            m_status_bad_frame_reg <= 1'b0;
            m_status_good_frame_reg <= 1'b0;
            m_pause_ack_reg <= 1'b0;
        end else begin
            r_ptr_gray <= bin2gray(r_ptr);
            
            // Pause handling
            if (PAUSE_ENABLE) begin
                if (m_pause_req && !m_pause_ack_reg) begin
                    m_pause_ack_reg <= 1'b1;
                end else if (!m_pause_req && m_pause_ack_reg) begin
                    m_pause_ack_reg <= 1'b0;
                end
            end else begin
                m_pause_ack_reg <= 1'b0;
            end

            // Frame tracking
            if (m_read_en) begin
                if (!m_in_frame) begin
                    m_in_frame <= 1'b1;
                    m_frame_user <= r_tuser;
                    m_frame_bad <= 1'b0;
                    m_oversize <= 1'b0;
                end else begin
                    if (USER_ENABLE && (r_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        m_frame_bad <= 1'b1;
                    end
                end
                
                if (r_tlast) begin
                    m_in_frame <= 1'b0;
                    if (m_frame_bad) begin
                        m_status_bad_frame_reg <= 1'b1;
                    end else begin
                        m_status_good_frame_reg <= 1'b1;
                    end
                end
            end

            // Pointer increment
            if (m_read_en) begin
                r_ptr <= r_ptr + 1'b1;
            end
        end
    end

    // RAM read
    assign r_addr = r_ptr[ADDR_WIDTH-1:0];
    assign r_data = ram[r_addr];

    // tvalid generation
    wire m_pause_active;
    assign m_pause_active = PAUSE_ENABLE && m_pause_ack_reg;
    
    assign m_axis_tvalid_int = !m_empty && !m_pause_active;

    // Output signals
    assign m_axis_tdata = r_tdata;
    assign m_axis_tkeep = r_tkeep;
    assign m_axis_tlast = r_tlast;
    assign m_axis_tid = r_tid;
    assign m_axis_tdest = r_tdest;
    assign m_axis_tuser = r_tuser;

endmodule
