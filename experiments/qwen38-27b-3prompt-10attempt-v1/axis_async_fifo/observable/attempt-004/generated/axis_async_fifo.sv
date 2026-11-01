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

    // RAM storage
    reg [TOTAL_WIDTH-1:0] ram [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] w_addr;

    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    reg [ADDR_WIDTH-1:0] r_addr;

    // Gray code pointers for CDC
    reg [PTR_WIDTH-1:0] w_ptr_gray;
    reg [PTR_WIDTH-1:0] r_ptr_gray;

    // Synchronizers
    reg [PTR_WIDTH-1:0] w_ptr_gray_m_sync1, w_ptr_gray_m_sync2;
    reg [PTR_WIDTH-1:0] r_ptr_gray_s_sync1, r_ptr_gray_s_sync2;

    // Binary pointers in opposite domains (for depth calculation)
    reg [PTR_WIDTH-1:0] w_ptr_m;
    reg [PTR_WIDTH-1:0] r_ptr_s;

    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    reg s_frame_overflow;
    reg m_frame_overflow;
    reg s_bad_frame;
    reg m_bad_frame;
    reg s_good_frame;
    reg m_good_frame;

    // Pause logic
    reg s_paused;
    reg m_paused;

    // Write enable
    wire s_write_en;
    wire s_accept;

    // Read enable
    wire m_read_en;
    wire m_accept;

    // Full/Empty
    wire s_full;
    wire m_empty;

    // Data path
    wire [TOTAL_WIDTH-1:0] w_data;
    wire [TOTAL_WIDTH-1:0] r_data;

    // Output FIFO (if enabled)
    reg [TOTAL_WIDTH-1:0] out_fifo [0:1];
    reg out_fifo_wr_ptr, out_fifo_rd_ptr;
    reg out_fifo_valid;

    // Frame FIFO logic
    reg s_frame_drop;
    reg m_frame_drop;

    // Calculate write data
    assign w_data = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Extract read data
    wire [DATA_WIDTH-1:0] r_data_tdata = r_data[DATA_WIDTH-1:0];
    wire [KEEP_WIDTH-1:0] r_data_tkeep = r_data[DATA_WIDTH:DATA_WIDTH+KEEP_WIDTH-1];
    wire r_data_tlast = r_data[DATA_WIDTH+KEEP_WIDTH];
    wire [ID_WIDTH-1:0] r_data_tid = r_data[DATA_WIDTH+KEEP_WIDTH+1:DATA_WIDTH+KEEP_WIDTH+ID_WIDTH];
    wire [DEST_WIDTH-1:0] r_data_tdest = r_data[DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH:DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH-1];
    wire [USER_WIDTH-1:0] r_data_tuser = r_data[TOTAL_WIDTH-1:TOTAL_WIDTH-USER_WIDTH];

    // Gray code conversion
    function [PTR_WIDTH-1:0] bin_to_gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_WIDTH-1:0] gray_to_bin;
        input [PTR_WIDTH-1:0] gray;
        reg [PTR_WIDTH-1:0] bin;
        integer i;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray_to_bin = bin;
        end
    endfunction

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_ptr_gray <= {PTR_WIDTH{1'b0}};
            w_addr <= {ADDR_WIDTH{1'b0}};
        end else begin
            w_ptr_gray <= bin_to_gray(w_ptr);
            if (s_write_en) begin
                w_ptr <= w_ptr + 1'b1;
                w_addr <= w_addr + 1'b1;
            end
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_ptr_gray <= {PTR_WIDTH{1'b0}};
            r_addr <= {ADDR_WIDTH{1'b0}};
        end else begin
            r_ptr_gray <= bin_to_gray(r_ptr);
            if (m_read_en) begin
                r_ptr <= r_ptr + 1'b1;
                r_addr <= r_addr + 1'b1;
            end
        end
    end

    // Synchronizers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_gray_m_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_gray_m_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_gray_m_sync1 <= w_ptr_gray;
            w_ptr_gray_m_sync2 <= w_ptr_gray_m_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_gray_s_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_gray_s_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_gray_s_sync1 <= r_ptr_gray;
            r_ptr_gray_s_sync2 <= r_ptr_gray_s_sync1;
        end
    end

    // Convert gray to binary in opposite domains
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            w_ptr_m <= {PTR_WIDTH{1'b0}};
        else
            w_ptr_m <= gray_to_bin(w_ptr_gray_m_sync2);
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            r_ptr_s <= {PTR_WIDTH{1'b0}};
        else
            r_ptr_s <= gray_to_bin(r_ptr_gray_s_sync2);
    end

    // Full/Empty detection
    assign s_full = (w_ptr[PTR_WIDTH-1:1] == r_ptr_s[PTR_WIDTH-1:1]) && (w_ptr[0] != r_ptr_s[0]);
    assign m_empty = (r_ptr == w_ptr_m);

    // Frame drop logic
    wire s_drop_beat;
    wire m_drop_beat;

    assign s_drop_beat = (DROP_OVERSIZE_FRAME && s_in_frame && s_full) || (DROP_BAD_FRAME && s_bad_frame);
    assign m_drop_beat = (DROP_OVERSIZE_FRAME && m_in_frame && m_empty == 0) || (DROP_BAD_FRAME && m_bad_frame);

    // Accept logic
    assign s_accept = s_axis_tvalid && (s_full ? (DROP_WHEN_FULL || MARK_WHEN_FULL) : 1'b1) && (s_paused ? 1'b0 : 1'b1) && (s_drop_beat ? 1'b0 : 1'b1);
    assign s_write_en = s_accept;

    assign m_accept = m_axis_tready && (m_empty ? 1'b0 : 1'b1) && (m_paused ? 1'b0 : 1'b1) && (m_drop_beat ? 1'b0 : 1'b1);
    assign m_read_en = m_accept;

    // tready
    assign s_axis_tready = (s_full ? (DROP_WHEN_FULL || MARK_WHEN_FULL) : 1'b1) && (s_paused ? 1'b0 : 1'b1) && (s_drop_beat ? 1'b0 : 1'b1);

    // RAM write
    always @(posedge s_clk) begin
        if (s_write_en)
            ram[w_addr] <= w_data;
    end

    // RAM read
    wire [TOTAL_WIDTH-1:0] ram_rdata;
    assign ram_rdata = ram[r_addr];

    // Output FIFO
    reg [TOTAL_WIDTH-1:0] out_data;
    reg out_valid;

    if (OUTPUT_FIFO_ENABLE) begin
        // Simple 2-entry output FIFO
        reg [TOTAL_WIDTH-1:0] ofifo [0:1];
        reg ofifo_wr, ofifo_rd;
        reg ofifo_valid;

        always @(posedge m_clk or posedge m_rst) begin
            if (m_rst) begin
                ofifo_wr <= 1'b0;
                ofifo_rd <= 1'b0;
                ofifo_valid <= 1'b0;
            end else begin
                if (m_read_en && ofifo_valid) begin
                    ofifo_rd <= ofifo_rd ^ 1'b1;
                    ofifo_valid <= 1'b0;
                end
                if (m_read_en && !ofifo_valid) begin
                    ofifo[ofifo_wr] <= ram_rdata;
                    ofifo_wr <= ofifo_wr ^ 1'b1;
                    ofifo_valid <= 1'b1;
                end
            end
        end

        assign out_data = ofifo[ofifo_rd];
        assign out_valid = ofifo_valid;
    end else begin
        assign out_data = ram_rdata;
        assign out_valid = !m_empty;
    end

    // Output
    assign m_axis_tdata = out_data[DATA_WIDTH-1:0];
    assign m_axis_tkeep = out_data[DATA_WIDTH:DATA_WIDTH+KEEP_WIDTH-1];
    assign m_axis_tlast = out_data[DATA_WIDTH+KEEP_WIDTH];
    assign m_axis_tid = out_data[DATA_WIDTH+KEEP_WIDTH+1:DATA_WIDTH+KEEP_WIDTH+ID_WIDTH];
    assign m_axis_tdest = out_data[DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH:DATA_WIDTH+KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH-1];
    assign m_axis_tuser = out_data[TOTAL_WIDTH-1:TOTAL_WIDTH-USER_WIDTH];
    assign m_axis_tvalid = out_valid;

    // Frame tracking
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
            s_frame_overflow <= 1'b0;
        end else begin
            if (s_write_en) begin
                if (s_axis_tlast) begin
                    s_in_frame <= 1'b0;
                    s_good_frame <= 1'b1;
                    s_bad_frame <= 1'b0;
                end else begin
                    s_in_frame <= 1'b1;
                end
            end
            if (s_drop_beat) begin
                s_bad_frame <= 1'b1;
                s_good_frame <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_in_frame <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
            m_frame_overflow <= 1'b0;
        end else begin
            if (m_read_en) begin
                if (r_data_tlast) begin
                    m_in_frame <= 1'b0;
                    m_good_frame <= 1'b1;
                    m_bad_frame <= 1'b0;
                end else begin
                    m_in_frame <= 1'b1;
                end
            end
            if (m_drop_beat) begin
                m_bad_frame <= 1'b1;
                m_good_frame <= 1'b0;
            end
        end
    end

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_paused <= 1'b0;
        else if (PAUSE_ENABLE)
            s_paused <= s_pause_req;
        else
            s_paused <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_paused <= 1'b0;
        else if (PAUSE_ENABLE)
            m_paused <= m_pause_req;
        else
            m_paused <= 1'b0;
    end

    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Status
    wire [PTR_WIDTH-1:0] s_depth = w_ptr - r_ptr_s;
    wire [PTR_WIDTH-1:0] m_depth = w_ptr_m - r_ptr;

    assign s_status_depth = s_depth[PTR_WIDTH-1:0];
    assign s_status_depth_commit = s_depth[PTR_WIDTH-1:0];
    assign s_status_overflow = s_frame_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;

    assign m_status_depth = m_depth[PTR_WIDTH-1:0];
    assign m_status_depth_commit = m_depth[PTR_WIDTH-1:0];
    assign m_status_overflow = m_frame_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

endmodule
