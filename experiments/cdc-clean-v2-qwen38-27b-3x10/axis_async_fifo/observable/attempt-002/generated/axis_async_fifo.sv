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
    localparam DATA_TOTAL_WIDTH = DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH;

    // Internal signals
    reg [DATA_TOTAL_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] w_addr;
    
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [ADDR_WIDTH-1:0] r_addr;
    
    // Synchronizers
    reg [PTR_WIDTH-1:0] w_ptr_sync1, w_ptr_sync2, w_ptr_sync3;
    reg [PTR_WIDTH-1:0] r_ptr_sync1, r_ptr_sync2, r_ptr_sync3;
    
    // Status registers
    reg s_overflow_reg, s_bad_frame_reg, s_good_frame_reg;
    reg m_overflow_reg, m_bad_frame_reg, m_good_frame_reg;
    
    // Pause registers
    reg s_pause_ack_reg, m_pause_ack_reg;
    
    // Frame tracking
    reg in_frame;
    reg frame_overflow;
    
    // Write enable
    wire s_write_en;
    wire s_full;
    wire s_empty;
    
    // Read enable
    wire m_read_en;
    wire m_full;
    wire m_empty;
    
    // Depth calculations
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;
    
    // Data packing/unpacking
    wire [DATA_WIDTH-1:0] w_data;
    wire [KEEP_WIDTH-1:0] w_keep;
    wire w_last;
    wire [ID_WIDTH-1:0] w_id;
    wire [DEST_WIDTH-1:0] w_dest;
    wire [USER_WIDTH-1:0] w_user;
    
    wire [DATA_WIDTH-1:0] r_data;
    wire [KEEP_WIDTH-1:0] r_keep;
    wire r_last;
    wire [ID_WIDTH-1:0] r_id;
    wire [DEST_WIDTH-1:0] r_dest;
    wire [USER_WIDTH-1:0] r_user;
    
    // Output register
    reg [DATA_TOTAL_WIDTH-1:0] out_reg;
    reg out_valid;
    
    // Assign write data
    assign w_data = s_axis_tdata;
    assign w_keep = KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}};
    assign w_last = LAST_ENABLE ? s_axis_tlast : 1'b0;
    assign w_id = ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
    assign w_dest = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
    assign w_user = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};
    
    // Pack data
    wire [DATA_TOTAL_WIDTH-1:0] w_packed;
    assign w_packed = {w_data, w_keep, w_last, w_id, w_dest, w_user};
    
    // Unpack read data
    assign r_data = out_reg[DATA_TOTAL_WIDTH-1 -: DATA_WIDTH];
    assign r_keep = out_reg[DATA_TOTAL_WIDTH-DATA_WIDTH-1 -: KEEP_WIDTH];
    assign r_last = out_reg[DATA_TOTAL_WIDTH-DATA_WIDTH-KEEP_WIDTH-1];
    assign r_id = out_reg[DATA_TOTAL_WIDTH-DATA_WIDTH-KEEP_WIDTH-LAST_ENABLE-1 -: ID_WIDTH];
    assign r_dest = out_reg[DATA_TOTAL_WIDTH-DATA_WIDTH-KEEP_WIDTH-LAST_ENABLE-ID_ENABLE*ID_WIDTH-1 -: DEST_WIDTH];
    assign r_user = out_reg[DATA_TOTAL_WIDTH-DATA_WIDTH-KEEP_WIDTH-LAST_ENABLE-ID_ENABLE*ID_WIDTH-DEST_ENABLE*DEST_WIDTH-1 -: USER_WIDTH];
    
    // Full/Empty logic
    assign s_full = (w_ptr - r_ptr_sync3) == DEPTH;
    assign s_empty = (w_ptr == r_ptr_sync3);
    assign m_full = (w_ptr_sync3 - r_ptr) == DEPTH;
    assign m_empty = (w_ptr_sync3 == r_ptr);
    
    // Depth
    assign s_depth = w_ptr - r_ptr_sync3;
    assign m_depth = w_ptr_sync3 - r_ptr;
    
    // Write enable
    wire s_pause_active = PAUSE_ENABLE ? s_pause_req : 1'b0;
    wire m_pause_active = PAUSE_ENABLE ? m_pause_req : 1'b0;
    
    // Frame logic
    wire frame_drop = (DROP_OVERSIZE_FRAME && in_frame && s_full) || 
                      (DROP_BAD_FRAME && in_frame && (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE));
    
    wire s_accept = s_axis_tvalid && !s_full && !s_pause_active && !frame_drop;
    wire s_write = s_accept;
    
    // Read enable
    wire m_accept = m_axis_tready && out_valid && !m_pause_active;
    wire m_read = m_accept;
    
    // Synchronizers
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync1 <= w_ptr;
            w_ptr_sync2 <= w_ptr_sync1;
            w_ptr_sync3 <= w_ptr_sync2;
        end
    end
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync1 <= r_ptr;
            r_ptr_sync2 <= r_ptr_sync1;
            r_ptr_sync3 <= r_ptr_sync2;
        end
    end
    
    // Write pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_addr <= {ADDR_WIDTH{1'b0}};
        end else if (s_write) begin
            w_ptr <= w_ptr + 1'b1;
            w_addr <= w_addr + 1'b1;
        end
    end
    
    // Read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_addr <= {ADDR_WIDTH{1'b0}};
        end else if (m_read) begin
            r_ptr <= r_ptr + 1'b1;
            r_addr <= r_addr + 1'b1;
        end
    end
    
    // Memory write
    always @(posedge s_clk) begin
        if (s_write) begin
            mem[w_addr] <= w_packed;
        end
    end
    
    // Memory read
    reg [DATA_TOTAL_WIDTH-1:0] mem_read_data;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            mem_read_data <= {DATA_TOTAL_WIDTH{1'b0}};
        end else begin
            mem_read_data <= mem[r_addr];
        end
    end
    
    // Output register
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_reg <= {DATA_TOTAL_WIDTH{1'b0}};
            out_valid <= 1'b0;
        end else begin
            if (m_read) begin
                out_valid <= 1'b0;
            end
            if (!out_valid || m_read) begin
                if (!m_empty) begin
                    out_reg <= mem_read_data;
                    out_valid <= 1'b1;
                end
            end
        end
    end
    
    // Frame tracking
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            in_frame <= 1'b0;
            frame_overflow <= 1'b0;
        end else begin
            if (s_write) begin
                if (w_last) begin
                    in_frame <= 1'b0;
                end else begin
                    in_frame <= 1'b1;
                end
            end
            if (s_full && s_axis_tvalid && in_frame) begin
                frame_overflow <= 1'b1;
            end
        end
    end
    
    // Status registers
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow_reg <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
        end else begin
            if (s_full && s_axis_tvalid) begin
                s_overflow_reg <= 1'b1;
            end
            if (s_write && w_last) begin
                if (USER_ENABLE && (w_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    s_bad_frame_reg <= 1'b1;
                end else begin
                    s_good_frame_reg <= 1'b1;
                end
            end
        end
    end
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow_reg <= 1'b0;
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
        end else begin
            if (m_full && m_axis_tready && out_valid) begin
                m_overflow_reg <= 1'b1;
            end
            if (m_read && r_last) begin
                if (USER_ENABLE && (r_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    m_bad_frame_reg <= 1'b1;
                end else begin
                    m_good_frame_reg <= 1'b1;
                end
            end
        end
    end
    
    // Pause ack
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 1'b0;
        end else begin
            s_pause_ack_reg <= s_pause_req;
        end
    end
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 1'b0;
        end else begin
            m_pause_ack_reg <= m_pause_req;
        end
    end
    
    // Outputs
    assign s_axis_tready = !s_full && !s_pause_active && !frame_drop;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    
    assign m_axis_tdata = r_data;
    assign m_axis_tkeep = r_keep;
    assign m_axis_tvalid = out_valid;
    assign m_axis_tlast = r_last;
    assign m_axis_tid = r_id;
    assign m_axis_tdest = r_dest;
    assign m_axis_tuser = r_user;
    
    assign s_status_depth = s_depth[ADDR_WIDTH:0];
    assign s_status_depth_commit = s_depth[ADDR_WIDTH:0];
    assign s_status_overflow = s_overflow_reg;
    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    
    assign m_status_depth = m_depth[ADDR_WIDTH:0];
    assign m_status_depth_commit = m_depth[ADDR_WIDTH:0];
    assign m_status_overflow = m_overflow_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

endmodule
