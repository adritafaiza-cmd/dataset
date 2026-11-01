module axi_dma #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 16,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXI_ID_WIDTH = 8,
    parameter AXI_MAX_BURST_LEN = 16,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    parameter AXIS_LAST_ENABLE = 1,
    parameter AXIS_ID_ENABLE = 0,
    parameter AXIS_ID_WIDTH = 8,
    parameter AXIS_DEST_ENABLE = 0,
    parameter AXIS_DEST_WIDTH = 8,
    parameter AXIS_USER_ENABLE = 1,
    parameter AXIS_USER_WIDTH = 1,
    parameter LEN_WIDTH = 20,
    parameter TAG_WIDTH = 8,
    parameter ENABLE_SG = 0,
    parameter ENABLE_UNALIGNED = 0
)
(
    input  wire                       clk,
    input  wire                       rst,
    /*
     * AXI read descriptor input
     */
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_read_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_read_desc_tag,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_read_desc_id,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_read_desc_dest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_read_desc_user,
    input  wire                       s_axis_read_desc_valid,
    output wire                       s_axis_read_desc_ready,
    /*
     * AXI read descriptor status output
     */
    output wire [TAG_WIDTH-1:0]       m_axis_read_desc_status_tag,
    output wire [3:0]                 m_axis_read_desc_status_error,
    output wire                       m_axis_read_desc_status_valid,
    /*
     * AXI stream read data output
     */
    output wire [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep,
    output wire                       m_axis_read_data_tvalid,
    input  wire                       m_axis_read_data_tready,
    output wire                       m_axis_read_data_tlast,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser,
    /*
     * AXI write descriptor input
     */
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_write_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_write_desc_tag,
    input  wire                       s_axis_write_desc_valid,
    output wire                       s_axis_write_desc_ready,
    /*
     * AXI write descriptor status output
     */
    output wire [LEN_WIDTH-1:0]       m_axis_write_desc_status_len,
    output wire [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_write_desc_status_id,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user,
    output wire [3:0]                 m_axis_write_desc_status_error,
    output wire                       m_axis_write_desc_status_valid,
    /*
     * AXI stream write data input
     */
    input  wire [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input  wire                       s_axis_write_data_tvalid,
    output wire                       s_axis_write_data_tready,
    input  wire                       s_axis_write_data_tlast,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,
    /*
     * AXI master interface
     */
    output wire [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output wire [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output wire                       m_axi_awlock,
    output wire [3:0]                 m_axi_awcache,
    output wire [2:0]                 m_axi_awprot,
    output wire                       m_axi_awvalid,
    input  wire                       m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]  m_axi_wstrb,
    output wire                       m_axi_wlast,
    output wire                       m_axi_wvalid,
    input  wire                       m_axi_wready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output wire                       m_axi_bready,
    output wire [AXI_ID_WIDTH-1:0]    m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output wire [7:0]                 m_axi_arlen,
    output wire [2:0]                 m_axi_arsize,
    output wire [1:0]                 m_axi_arburst,
    output wire                       m_axi_arlock,
    output wire [3:0]                 m_axi_arcache,
    output wire [2:0]                 m_axi_arprot,
    output wire                       m_axi_arvalid,
    input  wire                       m_axi_arready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                 m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output wire                       m_axi_rready,
    /*
     * Configuration
     */
    input  wire                       read_enable,
    input  wire                       write_enable,
    input  wire                       write_abort
);

    // Local parameters
    localparam AXI_DATA_BYTES = AXI_DATA_WIDTH / 8;
    localparam AXI_DATA_LOG2 = $clog2(AXI_DATA_BYTES);
    localparam AXI_MAX_BURST_LEN_LOG2 = $clog2(AXI_MAX_BURST_LEN);
    localparam BURST_LEN_WIDTH = (AXI_MAX_BURST_LEN_LOG2 > 8) ? AXI_MAX_BURST_LEN_LOG2 : 8;
    localparam BURST_LEN_MASK = (1 << BURST_LEN_WIDTH) - 1;

    // Read channel state
    reg [AXI_ADDR_WIDTH-1:0] rd_addr;
    reg [LEN_WIDTH-1:0] rd_len;
    reg [TAG_WIDTH-1:0] rd_tag;
    reg [AXIS_ID_WIDTH-1:0] rd_id;
    reg [AXIS_DEST_WIDTH-1:0] rd_dest;
    reg [AXIS_USER_WIDTH-1:0] rd_user;
    reg rd_active;
    reg [LEN_WIDTH-1:0] rd_bytes_remaining;
    reg [BURST_LEN_WIDTH-1:0] rd_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] rd_burst_addr;
    reg rd_burst_active;
    reg [BURST_LEN_WIDTH-1:0] rd_burst_beats_remaining;
    reg [AXI_ADDR_WIDTH-1:0] rd_burst_addr_next;
    reg [LEN_WIDTH-1:0] rd_burst_bytes_remaining;
    reg rd_burst_last_beat;
    reg [AXI_DATA_WIDTH-1:0] rd_data_reg;
    reg rd_data_valid;
    reg rd_data_last;
    reg [AXIS_ID_WIDTH-1:0] rd_data_id;
    reg [AXIS_DEST_WIDTH-1:0] rd_data_dest;
    reg [AXIS_USER_WIDTH-1:0] rd_data_user;
    reg [TAG_WIDTH-1:0] rd_status_tag;
    reg [3:0] rd_status_error;
    reg rd_status_valid;
    reg rd_status_pending;

    // Write channel state
    reg [AXI_ADDR_WIDTH-1:0] wr_addr;
    reg [LEN_WIDTH-1:0] wr_len;
    reg [TAG_WIDTH-1:0] wr_tag;
    reg wr_active;
    reg [LEN_WIDTH-1:0] wr_bytes_remaining;
    reg [BURST_LEN_WIDTH-1:0] wr_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] wr_burst_addr;
    reg wr_burst_active;
    reg [BURST_LEN_WIDTH-1:0] wr_burst_beats_remaining;
    reg [AXI_ADDR_WIDTH-1:0] wr_burst_addr_next;
    reg [LEN_WIDTH-1:0] wr_burst_bytes_remaining;
    reg wr_burst_last_beat;
    reg [AXI_DATA_WIDTH-1:0] wr_data_reg;
    reg [AXI_STRB_WIDTH-1:0] wr_strb_reg;
    reg wr_data_valid;
    reg wr_data_last;
    reg [TAG_WIDTH-1:0] wr_status_tag;
    reg [LEN_WIDTH-1:0] wr_status_len;
    reg [AXIS_ID_WIDTH-1:0] wr_status_id;
    reg [AXIS_DEST_WIDTH-1:0] wr_status_dest;
    reg [AXIS_USER_WIDTH-1:0] wr_status_user;
    reg [3:0] wr_status_error;
    reg wr_status_valid;
    reg wr_status_pending;
    reg wr_abort;

    // AXI AW channel
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg awlock_reg;
    reg [3:0] awcache_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;

    // AXI W channel
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;

    // AXI B channel
    reg bready_reg;

    // AXI AR channel
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg arlock_reg;
    reg [3:0] arcache_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;

    // AXI R channel
    reg rready_reg;

    // Read descriptor ready
    assign s_axis_read_desc_ready = read_enable && !rd_active && !rd_status_pending;

    // Write descriptor ready
    assign s_axis_write_desc_ready = write_enable && !wr_active && !wr_status_pending;

    // Read data output
    assign m_axis_read_data_tdata = rd_data_reg;
    assign m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
    assign m_axis_read_data_tvalid = rd_data_valid;
    assign m_axis_read_data_tlast = rd_data_last;
    assign m_axis_read_data_tid = rd_data_id;
    assign m_axis_read_data_tdest = rd_data_dest;
    assign m_axis_read_data_tuser = rd_data_user;

    // Write data ready
    assign s_axis_write_data_tready = wr_active && wr_burst_active && wr_burst_beats_remaining > 0 && !wr_abort;

    // Read status output
    assign m_axis_read_desc_status_tag = rd_status_tag;
    assign m_axis_read_desc_status_error = rd_status_error;
    assign m_axis_read_desc_status_valid = rd_status_valid;

    // Write status output
    assign m_axis_write_desc_status_len = wr_status_len;
    assign m_axis_write_desc_status_tag = wr_status_tag;
    assign m_axis_write_desc_status_id = wr_status_id;
    assign m_axis_write_desc_status_dest = wr_status_dest;
    assign m_axis_write_desc_status_user = wr_status_user;
    assign m_axis_write_desc_status_error = wr_status_error;
    assign m_axis_write_desc_status_valid = wr_status_valid;

    // AXI AW output
    assign m_axi_awid = awid_reg;
    assign m_axi_awaddr = awaddr_reg;
    assign m_axi_awlen = awlen_reg;
    assign m_axi_awsize = awsize_reg;
    assign m_axi_awburst = awburst_reg;
    assign m_axi_awlock = awlock_reg;
    assign m_axi_awcache = awcache_reg;
    assign m_axi_awprot = awprot_reg;
    assign m_axi_awvalid = awvalid_reg;

    // AXI W output
    assign m_axi_wdata = wdata_reg;
    assign m_axi_wstrb = wstrb_reg;
    assign m_axi_wlast = wlast_reg;
    assign m_axi_wvalid = wvalid_reg;

    // AXI B output
    assign m_axi_bready = bready_reg;

    // AXI AR output
    assign m_axi_arid = arid_reg;
    assign m_axi_araddr = araddr_reg;
    assign m_axi_arlen = arlen_reg;
    assign m_axi_arsize = arsize_reg;
    assign m_axi_arburst = arburst_reg;
    assign m_axi_arlock = arlock_reg;
    assign m_axi_arcache = arcache_reg;
    assign m_axi_arprot = arprot_reg;
    assign m_axi_arvalid = arvalid_reg;

    // AXI R output
    assign m_axi_rready = rready_reg;

    // Helper: calculate burst length for given bytes remaining
    function [BURST_LEN_WIDTH-1:0] calc_burst_len;
        input [LEN_WIDTH-1:0] bytes_remaining;
        input [AXI_ADDR_WIDTH-1:0] addr;
        reg [LEN_WIDTH-1:0] max_bytes;
        reg [BURST_LEN_WIDTH-1:0] max_beats;
        reg [BURST_LEN_WIDTH-1:0] beats_for_bytes;
        reg [AXI_ADDR_WIDTH-1:0] boundary;
        reg [LEN_WIDTH-1:0] bytes_to_boundary;
        reg [BURST_LEN_WIDTH-1:0] beats_to_boundary;
        begin
            max_beats = AXI_MAX_BURST_LEN[BURST_LEN_WIDTH-1:0];
            beats_for_bytes = (bytes_remaining + AXI_DATA_BYTES - 1) / AXI_DATA_BYTES;
            if (beats_for_bytes > max_beats)
                beats_for_bytes = max_beats;
            
            // Check 4KB boundary
            boundary = {addr[AXI_ADDR_WIDTH-1:12], 12'b0} + 4096;
            if (boundary > addr)
                bytes_to_boundary = boundary - addr;
            else
                bytes_to_boundary = 4096;
            
            beats_to_boundary = (bytes_to_boundary + AXI_DATA_BYTES - 1) / AXI_DATA_BYTES;
            
            if (beats_to_boundary < beats_for_bytes)
                beats_for_bytes = beats_to_boundary;
            
            if (beats_for_bytes == 0)
                beats_for_bytes = 1;
            
            calc_burst_len = beats_for_bytes;
        end
    endfunction

    // Helper: calculate bytes in burst
    function [LEN_WIDTH-1:0] calc_burst_bytes;
        input [BURST_LEN_WIDTH-1:0] beats;
        input [LEN_WIDTH-1:0] bytes_remaining;
        reg [LEN_WIDTH-1:0] total_bytes;
        begin
            total_bytes = beats * AXI_DATA_BYTES;
            if (total_bytes > bytes_remaining)
                total_bytes = bytes_remaining;
            calc_burst_bytes = total_bytes;
        end
    endfunction

    // Helper: calculate strobes for last beat of burst
    function [AXI_STRB_WIDTH-1:0] calc_last_strb;
        input [LEN_WIDTH-1:0] bytes_in_burst;
        input [BURST_LEN_WIDTH-1:0] beats;
        reg [LEN_WIDTH-1:0] last_beat_bytes;
        reg [AXI_STRB_WIDTH-1:0] strb;
        integer i;
        begin
            last_beat_bytes = bytes_in_burst - (beats - 1) * AXI_DATA_BYTES;
            strb = 0;
            for (i = 0; i < AXI_STRB_WIDTH; i = i + 1) begin
                if (i < last_beat_bytes)
                    strb[i] = 1'b1;
                else
                    strb[i] = 1'b0;
            end
            calc_last_strb = strb;
        end
    endfunction

    // Read channel logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_len <= {LEN_WIDTH{1'b0}};
            rd_tag <= {TAG_WIDTH{1'b0}};
            rd_id <= {AXIS_ID_WIDTH{1'b0}};
            rd_dest <= {AXIS_DEST_WIDTH{1'b0}};
            rd_user <= {AXIS_USER_WIDTH{1'b0}};
            rd_active <= 1'b0;
            rd_bytes_remaining <= {LEN_WIDTH{1'b0}};
            rd_burst_len <= {BURST_LEN_WIDTH{1'b0}};
            rd_burst_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_burst_active <= 1'b0;
            rd_burst_beats_remaining <= {BURST_LEN_WIDTH{1'b0}};
            rd_burst_addr_next <= {AXI_ADDR_WIDTH{1'b0}};
            rd_burst_bytes_remaining <= {LEN_WIDTH{1'b0}};
            rd_burst_last_beat <= 1'b0;
            rd_data_reg <= {AXI_DATA_WIDTH{1'b0}};
            rd_data_valid <= 1'b0;
            rd_data_last <= 1'b0;
            rd_data_id <= {AXIS_ID_WIDTH{1'b0}};
            rd_data_dest <= {AXIS_DEST_WIDTH{1'b0}};
            rd_data_user <= {AXIS_USER_WIDTH{1'b0}};
            rd_status_tag <= {TAG_WIDTH{1'b0}};
            rd_status_error <= 4'b0000;
            rd_status_valid <= 1'b0;
            rd_status_pending <= 1'b0;
            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            arlen_reg <= 8'b0;
            arsize_reg <= 3'b0;
            arburst_reg <= 2'b0;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'b0;
            arprot_reg <= 3'b0;
            arvalid_reg <= 1'b0;
            rready_reg <= 1'b0;
        end else begin
            // Default: clear valid signals
            rd_data_valid <= 1'b0;
            rd_status_valid <= 1'b0;
            arvalid_reg <= 1'b0;
            rready_reg <= 1'b0;

            // Accept read descriptor
            if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                rd_addr <= s_axis_read_desc_addr;
                rd_len <= s_axis_read_desc_len;
                rd_tag <= s_axis_read_desc_tag;
                rd_id <= s_axis_read_desc_id;
                rd_dest <= s_axis_read_desc_dest;
                rd_user <= s_axis_read_desc_user;
                rd_active <= 1'b1;
                rd_bytes_remaining <= s_axis_read_desc_len;
                rd_burst_active <= 1'b0;
                rd_burst_beats_remaining <= {BURST_LEN_WIDTH{1'b0}};
                rd_burst_addr <= s_axis_read_desc_addr;
                rd_burst_addr_next <= s_axis_read_desc_addr;
                rd_burst_bytes_remaining <= {LEN_WIDTH{1'b0}};
                rd_burst_last_beat <= 1'b0;
            end

            // Issue AR when not in burst and have bytes remaining
            if (rd_active && !rd_burst_active && rd_bytes_remaining > 0) begin
                rd_burst_len <= calc_burst_len(rd_bytes_remaining, rd_burst_addr);
                rd_burst_bytes_remaining <= calc_burst_bytes(rd_burst_len, rd_bytes_remaining);
                rd_burst_beats_remaining <= rd_burst_len;
                rd_burst_addr_next <= rd_burst_addr + rd_burst_bytes_remaining;
                rd_burst_last_beat <= (rd_burst_bytes_remaining == rd_bytes_remaining);
                rd_burst_active <= 1'b1;
                
                arid_reg <= rd_tag[AXI_ID_WIDTH-1:0];
                araddr_reg <= rd_burst_addr;
                arlen_reg <= rd_burst_len - 1;
                arsize_reg <= AXI_DATA_LOG2[2:0];
                arburst_reg <= 2'b01; // INCR
                arlock_reg <= 1'b0;
                arcache_reg <= 4'b0000;
                arprot_reg <= 3'b000;
                arvalid_reg <= 1'b1;
            end

            // Handle AR handshake
            if (arvalid_reg && m_axi_arready) begin
                arvalid_reg <= 1'b0;
            end

            // Handle R channel
            if (m_axi_rvalid && m_axi_rready) begin
                rd_data_reg <= m_axi_rdata;
                rd_data_valid <= 1'b1;
                rd_data_last <= m_axi_rlast;
                rd_data_id <= rd_id;
                rd_data_dest <= rd_dest;
                rd_data_user <= rd_user;
                
                if (m_axi_rlast) begin
                    rd_burst_beats_remaining <= rd_burst_beats_remaining - 1;
                    rd_bytes_remaining <= rd_bytes_remaining - rd_burst_bytes_remaining;
                    rd_burst_addr <= rd_burst_addr_next;
                    
                    if (rd_bytes_remaining == 0) begin
                        rd_active <= 1'b0;
                        rd_burst_active <= 1'b0;
                        rd_status_tag <= rd_tag;
                        rd_status_error <= 4'b0000;
                        rd_status_valid <= 1'b1;
                        rd_status_pending <= 1'b1;
                    end else begin
                        rd_burst_active <= 1'b0;
                    end
                end
            end

            // R ready when we have space in output
            if (rd_burst_active && rd_burst_beats_remaining > 0 && !rd_data_valid) begin
                rready_reg <= 1'b1;
            end

            // Clear data valid when consumed
            if (rd_data_valid && m_axis_read_data_tready) begin
                rd_data_valid <= 1'b0;
            end

            // Clear status valid when consumed
            if (rd_status_valid && rd_status_pending) begin
                rd_status_pending <= 1'b0;
            end
        end
    end

    // Write channel logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_len <= {LEN_WIDTH{1'b0}};
            wr_tag <= {TAG_WIDTH{1'b0}};
            wr_active <= 1'b0;
            wr_bytes_remaining <= {LEN_WIDTH{1'b0}};
            wr_burst_len <= {BURST_LEN_WIDTH{1'b0}};
            wr_burst_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_burst_active <= 1'b0;
            wr_burst_beats_remaining <= {BURST_LEN_WIDTH{1'b0}};
            wr_burst_addr_next <= {AXI_ADDR_WIDTH{1'b0}};
            wr_burst_bytes_remaining <= {LEN_WIDTH{1'b0}};
            wr_burst_last_beat <= 1'b0;
            wr_data_reg <= {AXI_DATA_WIDTH{1'b0}};
            wr_strb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wr_data_valid <= 1'b0;
            wr_data_last <= 1'b0;
            wr_status_tag <= {TAG_WIDTH{1'b0}};
            wr_status_len <= {LEN_WIDTH{1'b0}};
            wr_status_id <= {AXIS_ID_WIDTH{1'b0}};
            wr_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            wr_status_user <= {AXIS_USER_WIDTH{1'b0}};
            wr_status_error <= 4'b0000;
            wr_status_valid <= 1'b0;
            wr_status_pending <= 1'b0;
            wr_abort <= 1'b0;
            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            awlen_reg <= 8'b0;
            awsize_reg <= 3'b0;
            awburst_reg <= 2'b0;
            awlock_reg <= 1'b0;
            awcache_reg <= 4'b0;
            awprot_reg <= 3'b0;
            awvalid_reg <= 1'b0;
            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wlast_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;
        end else begin
            // Default: clear valid signals
            wr_data_valid <= 1'b0;
            wr_status_valid <= 1'b0;
            awvalid_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;

            // Accept write descriptor
            if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                wr_addr <= s_axis_write_desc_addr;
                wr_len <= s_axis_write_desc_len;
                wr_tag <= s_axis_write_desc_tag;
                wr_active <= 1'b1;
                wr_bytes_remaining <= s_axis_write_desc_len;
                wr_burst_active <= 1'b0;
                wr_burst_beats_remaining <= {BURST_LEN_WIDTH{1'b0}};
                wr_burst_addr <= s_axis_write_desc_addr;
                wr_burst_addr_next <= s_axis_write_desc_addr;
                wr_burst_bytes_remaining <= {LEN_WIDTH{1'b0}};
                wr_burst_last_beat <= 1'b0;
                wr_abort <= 1'b0;
            end

            // Handle write abort
            if (write_abort && wr_active) begin
                wr_active <= 1'b0;
                wr_burst_active <= 1'b0;
                wr_abort <= 1'b1;
                wr_status_tag <= wr_tag;
                wr_status_len <= wr_bytes_remaining;
                wr_status_id <= {AXIS_ID_WIDTH{1'b0}};
                wr_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
                wr_status_user <= {AXIS_USER_WIDTH{1'b0}};
                wr_status_error <= 4'b0001;
                wr_status_valid <= 1'b1;
                wr_status_pending <= 1'b1;
            end

            // Issue AW when not in burst and have bytes remaining
            if (wr_active && !wr_burst_active && wr_bytes_remaining > 0 && !wr_abort) begin
                wr_burst_len <= calc_burst_len(wr_bytes_remaining, wr_burst_addr);
                wr_burst_bytes_remaining <= calc_burst_bytes(wr_burst_len, wr_bytes_remaining);
                wr_burst_beats_remaining <= wr_burst_len;
                wr_burst_addr_next <= wr_burst_addr + wr_burst_bytes_remaining;
                wr_burst_last_beat <= (wr_burst_bytes_remaining == wr_bytes_remaining);
                wr_burst_active <= 1'b1;
                
                awid_reg <= wr_tag[AXI_ID_WIDTH-1:0];
                awaddr_reg <= wr_burst_addr;
                awlen_reg <= wr_burst_len - 1;
                awsize_reg <= AXI_DATA_LOG2[2:0];
                awburst_reg <= 2'b01; // INCR
                awlock_reg <= 1'b0;
                awcache_reg <= 4'b0000;
                awprot_reg <= 3'b000;
                awvalid_reg <= 1'b1;
            end

            // Handle AW handshake
            if (awvalid_reg && m_axi_awready) begin
                awvalid_reg <= 1'b0;
            end

            // Accept write data and forward to W channel
            if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                wr_data_reg <= s_axis_write_data_tdata;
                wr_strb_reg <= s_axis_write_data_tkeep;
                wr_data_valid <= 1'b1;
                wr_data_last <= s_axis_write_data_tlast;
                
                wdata_reg <= s_axis_write_data_tdata;
                wstrb_reg <= s_axis_write_data_tkeep;
                wlast_reg <= s_axis_write_data_tlast;
                wvalid_reg <= 1'b1;
            end

            // Handle W handshake
            if (wvalid_reg && m_axi_wready) begin
                wvalid_reg <= 1'b0;
                wr_burst_beats_remaining <= wr_burst_beats_remaining - 1;
                
                if (wlast_reg) begin
                    wr_bytes_remaining <= wr_bytes_remaining - wr_burst_bytes_remaining;
                    wr_burst_addr <= wr_burst_addr_next;
                    
                    if (wr_bytes_remaining == 0) begin
                        wr_active <= 1'b0;
                        wr_burst_active <= 1'b0;
                        wr_status_tag <= wr_tag;
                        wr_status_len <= wr_len;
                        wr_status_id <= {AXIS_ID_WIDTH{1'b0}};
                        wr_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
                        wr_status_user <= {AXIS_USER_WIDTH{1'b0}};
                        wr_status_error <= 4'b0000;
                        wr_status_valid <= 1'b1;
                        wr_status_pending <= 1'b1;
                    end else begin
                        wr_burst_active <= 1'b0;
                    end
                end
            end

            // B ready when we expect a response
            if (wr_burst_active && wr_burst_beats_remaining == 1) begin
                bready_reg <= 1'b1;
            end

            // Handle B channel
            if (m_axi_bvalid && m_axi_bready) begin
                bready_reg <= 1'b0;
            end

            // Clear status valid when consumed
            if (wr_status_valid && wr_status_pending) begin
                wr_status_pending <= 1'b0;
            end
        end
    end

endmodule
