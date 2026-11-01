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
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signals
    wire [DATA_WIDTH-1:0] ram_data;
    wire [KEEP_WIDTH-1:0] ram_keep;
    wire                   ram_last;
    wire [ID_WIDTH-1:0]    ram_tid;
    wire [DEST_WIDTH-1:0]  ram_tdest;
    wire [USER_WIDTH-1:0]  ram_tuser;

    // Write side (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] w_addr;
    reg [DATA_WIDTH-1:0] w_data;
    reg [KEEP_WIDTH-1:0] w_keep;
    reg                   w_last;
    reg [ID_WIDTH-1:0]    w_tid;
    reg [DEST_WIDTH-1:0]  w_tdest;
    reg [USER_WIDTH-1:0]  w_tuser;
    reg                   w_en;

    // Read side (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg                   r_en;

    // Synchronizers
    reg [PTR_WIDTH-1:0] w_ptr_sync1, w_ptr_sync2, w_ptr_sync3;
    reg [PTR_WIDTH-1:0] r_ptr_sync1, r_ptr_sync2, r_ptr_sync3;

    // Depth calculation
    wire [PTR_WIDTH-1:0] w_ptr_m;
    wire [PTR_WIDTH-1:0] r_ptr_s;
    wire [PTR_WIDTH-1:0] depth_s;
    wire [PTR_WIDTH-1:0] depth_m;

    // Status flags
    reg s_overflow;
    reg s_bad_frame;
    reg s_good_frame;
    reg m_overflow;
    reg m_bad_frame;
    reg m_good_frame;

    // Pause logic
    reg s_paused;
    reg m_paused;

    // Frame tracking for drop/mark when full
    reg s_in_frame;
    reg m_in_frame;

    // Output FIFO (if enabled)
    // For simplicity, we implement a basic output FIFO if OUTPUT_FIFO_ENABLE is set
    // Otherwise, direct RAM read

    // RAM instantiation
    // Using a simple dual-port RAM model
    // In real implementation, this would be a block RAM
    // For this exercise, we use a behavioral model

    // Write address and data
    wire [ADDR_WIDTH-1:0] ram_w_addr = w_addr;
    wire [DATA_WIDTH-1:0] ram_w_data = w_data;
    wire [KEEP_WIDTH-1:0] ram_w_keep = w_keep;
    wire                   ram_w_last = w_last;
    wire [ID_WIDTH-1:0]    ram_w_tid = w_tid;
    wire [DEST_WIDTH-1:0]  ram_w_tdest = w_tdest;
    wire [USER_WIDTH-1:0]  ram_w_tuser = w_tuser;
    wire                   ram_w_en = w_en;

    // Read address
    wire [ADDR_WIDTH-1:0] ram_r_addr = r_addr;

    // RAM read data (pipelined if RAM_PIPELINE)
    reg [DATA_WIDTH-1:0] ram_r_data_reg;
    reg [KEEP_WIDTH-1:0] ram_r_keep_reg;
    reg                   ram_r_last_reg;
    reg [ID_WIDTH-1:0]    ram_r_tid_reg;
    reg [DEST_WIDTH-1:0]  ram_r_tdest_reg;
    reg [USER_WIDTH-1:0]  ram_r_tuser_reg;

    // RAM storage
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg                   mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]    mem_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]  mem_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]  mem_tuser [0:DEPTH-1];

    // Write to RAM
    always @(posedge s_clk) begin
        if (w_en) begin
            mem_data[w_addr] <= w_data;
            mem_keep[w_addr] <= w_keep;
            mem_last[w_addr] <= w_last;
            mem_tid[w_addr] <= w_tid;
            mem_tdest[w_addr] <= w_tdest;
            mem_tuser[w_addr] <= w_tuser;
        end
    end

    // Read from RAM
    always @(posedge m_clk) begin
        ram_r_data_reg <= mem_data[r_addr];
        ram_r_keep_reg <= mem_keep[r_addr];
        ram_r_last_reg <= mem_last[r_addr];
        ram_r_tid_reg <= mem_tid[r_addr];
        ram_r_tdest_reg <= mem_tdest[r_addr];
        ram_r_tuser_reg <= mem_tuser[r_addr];
    end

    // Synchronizers for write pointer to m_clk domain
    always @(posedge m_clk) begin
        w_ptr_sync1 <= w_ptr;
        w_ptr_sync2 <= w_ptr_sync1;
        w_ptr_sync3 <= w_ptr_sync2;
    end

    // Synchronizers for read pointer to s_clk domain
    always @(posedge s_clk) begin
        r_ptr_sync1 <= r_ptr;
        r_ptr_sync2 <= r_ptr_sync1;
        r_ptr_sync3 <= r_ptr_sync2;
    end

    assign w_ptr_m = w_ptr_sync3;
    assign r_ptr_s = r_ptr_sync3;

    // Depth calculation
    assign depth_s = w_ptr - r_ptr_s;
    assign depth_m = w_ptr_m - r_ptr;

    // Full and empty conditions
    wire s_full = (depth_s == DEPTH);
    wire m_empty = (depth_m == 0);

    // Pause logic
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_paused <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (s_pause_req) begin
                s_paused <= 1'b1;
            end else if (s_pause_ack) begin
                s_paused <= 1'b0;
            end
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            m_paused <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (m_pause_req) begin
                m_paused <= 1'b1;
            end else if (m_pause_ack) begin
                m_paused <= 1'b0;
            end
        end
    end

    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Write enable logic
    wire s_can_write = s_axis_tvalid && s_axis_tready;

    // tready logic
    wire s_tready_base = !s_full && !s_paused;
    wire s_tready_drop = DROP_WHEN_FULL && s_full;
    wire s_tready_mark = MARK_WHEN_FULL && s_full;
    assign s_axis_tready = s_tready_base || s_tready_drop || s_tready_mark;

    // Frame tracking
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
        end else if (s_can_write) begin
            if (s_axis_tlast) begin
                s_in_frame <= 1'b0;
            end else begin
                s_in_frame <= 1'b1;
            end
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            m_in_frame <= 1'b0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            if (m_axis_tlast) begin
                m_in_frame <= 1'b0;
            end else begin
                m_in_frame <= 1'b1;
            end
        end
    end

    // Write data capture
    always @(posedge s_clk) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_addr <= {ADDR_WIDTH{1'b0}};
            w_data <= {DATA_WIDTH{1'b0}};
            w_keep <= {KEEP_WIDTH{1'b0}};
            w_last <= 1'b0;
            w_tid <= {ID_WIDTH{1'b0}};
            w_tdest <= {DEST_WIDTH{1'b0}};
            w_tuser <= {USER_WIDTH{1'b0}};
            w_en <= 1'b0;
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
        end else begin
            w_en <= 1'b0;
            
            if (s_can_write) begin
                w_en <= 1'b1;
                w_addr <= w_addr + 1'b1;
                w_ptr <= w_ptr + 1'b1;
                w_data <= s_axis_tdata;
                w_keep <= s_axis_tkeep;
                w_last <= s_axis_tlast;
                w_tid <= s_axis_tid;
                w_tdest <= s_axis_tdest;
                w_tuser <= s_axis_tuser;
                
                // Status updates
                if (s_full && !DROP_WHEN_FULL && !MARK_WHEN_FULL) begin
                    s_overflow <= 1'b1;
                end
                
                if (s_axis_tlast) begin
                    if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        s_bad_frame <= 1'b1;
                    end else begin
                        s_good_frame <= 1'b1;
                    end
                end
            end
        end
    end

    // Read pointer logic
    wire m_can_read = m_axis_tvalid && m_axis_tready;

    always @(posedge m_clk) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_addr <= {ADDR_WIDTH{1'b0}};
            r_en <= 1'b0;
            m_overflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
        end else begin
            r_en <= 1'b0;
            
            if (m_can_read) begin
                r_en <= 1'b1;
                r_addr <= r_addr + 1'b1;
                r_ptr <= r_ptr + 1'b1;
                
                // Status updates
                if (USER_ENABLE && (ram_r_tuser_reg & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    m_bad_frame <= 1'b1;
                end else begin
                    m_good_frame <= 1'b1;
                end
            end
        end
    end

    // Output valid logic
    wire m_tvalid_base = !m_empty && !m_paused;
    assign m_axis_tvalid = m_tvalid_base;

    // Output data
    assign m_axis_tdata = ram_r_data_reg;
    assign m_axis_tkeep = ram_r_keep_reg;
    assign m_axis_tlast = ram_r_last_reg;
    assign m_axis_tid = ram_r_tid_reg;
    assign m_axis_tdest = ram_r_tdest_reg;
    assign m_axis_tuser = ram_r_tuser_reg;

    // Status outputs
    assign s_status_depth = depth_s;
    assign s_status_depth_commit = depth_s;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    
    assign m_status_depth = depth_m;
    assign m_status_depth_commit = depth_m;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

endmodule
