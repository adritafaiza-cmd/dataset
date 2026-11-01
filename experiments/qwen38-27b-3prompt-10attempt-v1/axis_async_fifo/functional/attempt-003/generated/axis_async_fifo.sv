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
    wire [DATA_WIDTH-1:0] ram_dout;
    wire [KEEP_WIDTH-1:0] ram_keep;
    wire s_axis_tlast_ram;
    wire [ID_WIDTH-1:0] ram_tid;
    wire [DEST_WIDTH-1:0] ram_tdest;
    wire [USER_WIDTH-1:0] ram_tuser;

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    wire [ADDR_WIDTH-1:0] w_addr = w_ptr[ADDR_WIDTH-1:0];
    wire w_full;
    wire w_empty;
    wire w_wr_en;
    wire w_drop;
    wire w_mark;

    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    wire [ADDR_WIDTH-1:0] r_addr = r_ptr[ADDR_WIDTH-1:0];
    wire r_full;
    wire r_empty;
    wire r_rd_en;

    // Synchronizers
    reg [PTR_WIDTH-1:0] w_ptr_sync1, w_ptr_sync2, w_ptr_sync3;
    reg [PTR_WIDTH-1:0] r_ptr_sync1, r_ptr_sync2, r_ptr_sync3;

    // Status registers
    reg s_overflow_reg;
    reg s_bad_frame_reg;
    reg s_good_frame_reg;
    reg m_overflow_reg;
    reg m_bad_frame_reg;
    reg m_good_frame_reg;

    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    reg [USER_WIDTH-1:0] s_frame_user;
    reg [USER_WIDTH-1:0] m_frame_user;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth_raw;
    wire [PTR_WIDTH-1:0] m_depth_raw;
    wire [PTR_WIDTH-1:0] s_depth_commit_raw;
    wire [PTR_WIDTH-1:0] m_depth_commit_raw;

    // RAM interface
    wire [ADDR_WIDTH-1:0] ram_waddr;
    wire [ADDR_WIDTH-1:0] ram_raddr;
    wire ram_wen;
    wire ram_ren;
    wire [DATA_WIDTH-1:0] ram_wdata;
    wire [KEEP_WIDTH-1:0] ram_wkeep;
    wire s_axis_tlast_ram_w;
    wire [ID_WIDTH-1:0] ram_wtid;
    wire [DEST_WIDTH-1:0] ram_wtdest;
    wire [USER_WIDTH-1:0] ram_wtuser;

    // Output FIFO (if enabled)
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_tuser [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] out_fifo_wptr;
    reg [PTR_WIDTH-1:0] out_fifo_rptr;
    wire out_fifo_full;
    wire out_fifo_empty;
    wire out_fifo_wr_en;
    wire out_fifo_rd_en;

    // Assignments for RAM
    assign ram_waddr = w_addr;
    assign ram_raddr = r_addr;
    assign ram_wen = w_wr_en;
    assign ram_ren = r_rd_en;
    assign ram_wdata = s_axis_tdata;
    assign ram_wkeep = s_axis_tkeep;
    assign s_axis_tlast_ram_w = s_axis_tlast;
    assign ram_wtid = s_axis_tid;
    assign ram_wtdest = s_axis_tdest;
    assign ram_wtuser = s_axis_tuser;

    // Synchronizer for write pointer to m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync1 <= w_ptr;
            w_ptr_sync2 <= w_ptr_sync1;
            w_ptr_sync3 <= w_ptr_sync2;
        end
    end

    // Synchronizer for read pointer to s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync1 <= r_ptr;
            r_ptr_sync2 <= r_ptr_sync1;
            r_ptr_sync3 <= r_ptr_sync2;
        end
    end

    // Depth calculations
    assign s_depth_raw = w_ptr - r_ptr_sync3;
    assign m_depth_raw = w_ptr_sync3 - r_ptr;
    assign s_depth_commit_raw = w_ptr - r_ptr_sync3;
    assign m_depth_commit_raw = w_ptr_sync3 - r_ptr;

    // Full/Empty conditions
    assign w_full = (s_depth_raw == DEPTH);
    assign w_empty = (s_depth_raw == 0);
    assign r_full = (m_depth_raw == DEPTH);
    assign r_empty = (m_depth_raw == 0);

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (s_pause_req) begin
                s_pause_ack_reg <= 1'b1;
            end else begin
                s_pause_ack_reg <= 1'b0;
            end
        end else begin
            s_pause_ack_reg <= 1'b0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (m_pause_req) begin
                m_pause_ack_reg <= 1'b1;
            end else begin
                m_pause_ack_reg <= 1'b0;
            end
        end else begin
            m_pause_ack_reg <= 1'b0;
        end
    end

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Write enable logic
    wire s_pause_active = PAUSE_ENABLE && s_pause_req;
    wire m_pause_active = PAUSE_ENABLE && m_pause_req;

    assign w_drop = (DROP_WHEN_FULL && w_full) || 
                    (DROP_OVERSIZE_FRAME && s_in_frame && s_axis_tlast && (s_depth_raw >= DEPTH));
    assign w_mark = (MARK_WHEN_FULL && w_full);

    assign w_wr_en = s_axis_tvalid && !s_pause_active && (!w_full || w_drop || w_mark);

    // Frame tracking on write side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
            s_frame_user <= {USER_WIDTH{1'b0}};
        end else if (w_wr_en) begin
            if (s_axis_tlast) begin
                s_in_frame <= 1'b0;
            end else begin
                s_in_frame <= 1'b1;
                s_frame_user <= s_axis_tuser;
            end
        end
    end

    // Read enable logic
    assign r_rd_en = m_axis_tready && !m_pause_active && !r_empty;

    // Frame tracking on read side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_in_frame <= 1'b0;
            m_frame_user <= {USER_WIDTH{1'b0}};
        end else if (r_rd_en) begin
            if (m_axis_tlast) begin
                m_in_frame <= 1'b0;
            end else begin
                m_in_frame <= 1'b1;
                m_frame_user <= m_axis_tuser;
            end
        end
    end

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
        end else if (w_wr_en) begin
            w_ptr <= w_ptr + 1'b1;
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
        end else if (r_rd_en) begin
            r_ptr <= r_ptr + 1'b1;
        end
    end

    // RAM instantiation
    if (RAM_PIPELINE) begin
        reg [DATA_WIDTH-1:0] ram_pipe_data;
        reg [KEEP_WIDTH-1:0] ram_pipe_keep;
        reg ram_pipe_last;
        reg [ID_WIDTH-1:0] ram_pipe_tid;
        reg [DEST_WIDTH-1:0] ram_pipe_tdest;
        reg [USER_WIDTH-1:0] ram_pipe_tuser;
        reg ram_pipe_valid;

        always @(posedge m_clk or posedge m_rst) begin
            if (m_rst) begin
                ram_pipe_valid <= 1'b0;
            end else begin
                ram_pipe_valid <= r_rd_en;
            end
        end

        always @(posedge m_clk) begin
            if (r_rd_en) begin
                ram_pipe_data <= ram_dout;
                ram_pipe_keep <= ram_keep;
                ram_pipe_last <= s_axis_tlast_ram;
                ram_pipe_tid <= ram_tid;
                ram_pipe_tdest <= ram_tdest;
                ram_pipe_tuser <= ram_tuser;
            end
        end

        assign m_axis_tdata = ram_pipe_data;
        assign m_axis_tkeep = ram_pipe_keep;
        assign m_axis_tlast = ram_pipe_last;
        assign m_axis_tid = ram_pipe_tid;
        assign m_axis_tdest = ram_pipe_tdest;
        assign m_axis_tuser = ram_pipe_tuser;
        assign m_axis_tvalid = ram_pipe_valid;
    end else begin
        assign m_axis_tdata = ram_dout;
        assign m_axis_tkeep = ram_keep;
        assign m_axis_tlast = s_axis_tlast_ram;
        assign m_axis_tid = ram_tid;
        assign m_axis_tdest = ram_tdest;
        assign m_axis_tuser = ram_tuser;
        assign m_axis_tvalid = !r_empty;
    end

    // RAM model
    reg [DATA_WIDTH-1:0] ram_mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep_mem [0:DEPTH-1];
    reg ram_last_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_tid_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_tdest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_tuser_mem [0:DEPTH-1];

    always @(posedge s_clk) begin
        if (ram_wen) begin
            ram_mem[ram_waddr] <= ram_wdata;
            ram_keep_mem[ram_waddr] <= ram_wkeep;
            ram_last_mem[ram_waddr] <= s_axis_tlast_ram_w;
            ram_tid_mem[ram_waddr] <= ram_wtid;
            ram_tdest_mem[ram_waddr] <= ram_wtdest;
            ram_tuser_mem[ram_waddr] <= ram_wtuser;
        end
    end

    always @(posedge m_clk) begin
        if (ram_ren) begin
            ram_dout <= ram_mem[ram_raddr];
            ram_keep <= ram_keep_mem[ram_raddr];
            s_axis_tlast_ram <= ram_last_mem[ram_raddr];
            ram_tid <= ram_tid_mem[ram_raddr];
            ram_tdest <= ram_tdest_mem[ram_raddr];
            ram_tuser <= ram_tuser_mem[ram_raddr];
        end
    end

    // Output FIFO logic
    if (OUTPUT_FIFO_ENABLE) begin
        assign out_fifo_full = (out_fifo_wptr - out_fifo_rptr == DEPTH);
        assign out_fifo_empty = (out_fifo_wptr == out_fifo_rptr);
        assign out_fifo_wr_en = r_rd_en && !out_fifo_full;
        assign out_fifo_rd_en = m_axis_tready && !out_fifo_empty;

        always @(posedge m_clk or posedge m_rst) begin
            if (m_rst) begin
                out_fifo_wptr <= {PTR_WIDTH{1'b0}};
                out_fifo_rptr <= {PTR_WIDTH{1'b0}};
            end else begin
                if (out_fifo_wr_en) begin
                    out_fifo_wptr <= out_fifo_wptr + 1'b1;
                end
                if (out_fifo_rd_en) begin
                    out_fifo_rptr <= out_fifo_rptr + 1'b1;
                end
            end
        end

        always @(posedge m_clk) begin
            if (out_fifo_wr_en) begin
                out_fifo_data[out_fifo_wptr[ADDR_WIDTH-1:0]] <= ram_dout;
                out_fifo_keep[out_fifo_wptr[ADDR_WIDTH-1:0]] <= ram_keep;
                out_fifo_last[out_fifo_wptr[ADDR_WIDTH-1:0]] <= s_axis_tlast_ram;
                out_fifo_tid[out_fifo_wptr[ADDR_WIDTH-1:0]] <= ram_tid;
                out_fifo_tdest[out_fifo_wptr[ADDR_WIDTH-1:0]] <= ram_tdest;
                out_fifo_tuser[out_fifo_wptr[ADDR_WIDTH-1:0]] <= ram_tuser;
            end
        end

        assign m_axis_tdata = out_fifo_data[out_fifo_rptr[ADDR_WIDTH-1:0]];
        assign m_axis_tkeep = out_fifo_keep[out_fifo_rptr[ADDR_WIDTH-1:0]];
        assign m_axis_tlast = out_fifo_last[out_fifo_rptr[ADDR_WIDTH-1:0]];
        assign m_axis_tid = out_fifo_tid[out_fifo_rptr[ADDR_WIDTH-1:0]];
        assign m_axis_tdest = out_fifo_tdest[out_fifo_rptr[ADDR_WIDTH-1:0]];
        assign m_axis_tuser = out_fifo_tuser[out_fifo_rptr[ADDR_WIDTH-1:0]];
        assign m_axis_tvalid = !out_fifo_empty;
    end else begin
        // Direct output from RAM
        assign m_axis_tdata = ram_dout;
        assign m_axis_tkeep = ram_keep;
        assign m_axis_tlast = s_axis_tlast_ram;
        assign m_axis_tid = ram_tid;
        assign m_axis_tdest = ram_tdest;
        assign m_axis_tuser = ram_tuser;
        assign m_axis_tvalid = !r_empty;
    end

    // Tready logic
    assign s_axis_tready = !w_full || w_drop || w_mark;

    // Status logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow_reg <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
        end else begin
            if (w_full && s_axis_tvalid && !w_drop && !w_mark) begin
                s_overflow_reg <= 1'b1;
            end
            if (w_wr_en && s_axis_tlast) begin
                if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
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
            if (r_full && m_axis_tready) begin
                m_overflow_reg <= 1'b1;
            end
            if (r_rd_en && m_axis_tlast) begin
                if (USER_ENABLE && (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    m_bad_frame_reg <= 1'b1;
                end else begin
                    m_good_frame_reg <= 1'b1;
                end
            end
        end
    end

    assign s_status_depth = s_depth_raw;
    assign s_status_depth_commit = s_depth_commit_raw;
    assign s_status_overflow = s_overflow_reg;
    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;

    assign m_status_depth = m_depth_raw;
    assign m_status_depth_commit = m_depth_commit_raw;
    assign m_status_overflow = m_overflow_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

endmodule
