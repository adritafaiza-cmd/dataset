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
    localparam AXI_BURST_LEN_WIDTH = (AXI_MAX_BURST_LEN > 256) ? 9 : 8;
    localparam AXI_BURST_LEN_MASK = (AXI_MAX_BURST_LEN > 256) ? 9'd255 : 8'd255;
    localparam AXI_SIZE = $clog2(AXI_DATA_BYTES);
    localparam AXI_SIZE_VAL = (AXI_DATA_BYTES == 1) ? 3'd0 :
                              (AXI_DATA_BYTES == 2) ? 3'd1 :
                              (AXI_DATA_BYTES == 4) ? 3'd2 :
                              (AXI_DATA_BYTES == 8) ? 3'd3 :
                              (AXI_DATA_BYTES == 16) ? 3'd4 :
                              (AXI_DATA_BYTES == 32) ? 3'd5 :
                              (AXI_DATA_BYTES == 64) ? 3'd6 : 3'd7;

    // Read channel state
    reg [AXI_ADDR_WIDTH-1:0] rd_addr;
    reg [LEN_WIDTH-1:0] rd_len;
    reg [LEN_WIDTH-1:0] rd_remaining;
    reg [TAG_WIDTH-1:0] rd_tag;
    reg [AXIS_ID_WIDTH-1:0] rd_id;
    reg [AXIS_DEST_WIDTH-1:0] rd_dest;
    reg [AXIS_USER_WIDTH-1:0] rd_user;
    reg rd_active;
    reg [AXI_BURST_LEN_WIDTH-1:0] rd_burst_len;
    reg [LEN_WIDTH-1:0] rd_burst_remaining;
    reg rd_burst_active;
    reg [3:0] rd_error;
    reg rd_status_valid;
    reg [TAG_WIDTH-1:0] rd_status_tag;
    reg [3:0] rd_status_error;

    // Write channel state
    reg [AXI_ADDR_WIDTH-1:0] wr_addr;
    reg [LEN_WIDTH-1:0] wr_len;
    reg [LEN_WIDTH-1:0] wr_remaining;
    reg [TAG_WIDTH-1:0] wr_tag;
    reg wr_active;
    reg [AXI_BURST_LEN_WIDTH-1:0] wr_burst_len;
    reg [LEN_WIDTH-1:0] wr_burst_remaining;
    reg wr_burst_active;
    reg [3:0] wr_error;
    reg wr_status_valid;
    reg [LEN_WIDTH-1:0] wr_status_len;
    reg [TAG_WIDTH-1:0] wr_status_tag;
    reg [AXIS_ID_WIDTH-1:0] wr_status_id;
    reg [AXIS_DEST_WIDTH-1:0] wr_status_dest;
    reg [AXIS_USER_WIDTH-1:0] wr_status_user;
    reg [3:0] wr_status_error;

    // AXI read address channel
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg arlock_reg;
    reg [3:0] arcache_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;

    // AXI read data channel
    reg rready_reg;

    // AXI write address channel
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg awlock_reg;
    reg [3:0] awcache_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;

    // AXI write data channel
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;

    // AXI write response channel
    reg bready_reg;

    // Read data output
    reg [AXIS_DATA_WIDTH-1:0] rd_data_out;
    reg [AXIS_KEEP_WIDTH-1:0] rd_keep_out;
    reg rd_valid_out;
    reg rd_last_out;
    reg [AXIS_ID_WIDTH-1:0] rd_tid_out;
    reg [AXIS_DEST_WIDTH-1:0] rd_tdest_out;
    reg [AXIS_USER_WIDTH-1:0] rd_tuser_out;

    // Write data input ready
    reg wr_data_ready;

    // Helper: calculate burst length for remaining bytes
    function [AXI_BURST_LEN_WIDTH-1:0] calc_burst_len;
        input [LEN_WIDTH-1:0] remaining;
        begin
            if (remaining == 0)
                calc_burst_len = 0;
            else if (remaining > AXI_MAX_BURST_LEN)
                calc_burst_len = AXI_MAX_BURST_LEN;
            else
                calc_burst_len = remaining;
        end
    endfunction

    // Read descriptor acceptance
    wire rd_desc_accept = s_axis_read_desc_valid && s_axis_read_desc_ready;
    assign s_axis_read_desc_ready = read_enable && !rd_active && !rd_burst_active;

    // Write descriptor acceptance
    wire wr_desc_accept = s_axis_write_desc_valid && s_axis_write_desc_ready;
    assign s_axis_write_desc_ready = write_enable && !wr_active && !wr_burst_active;

    // Read data output assignments
    assign m_axis_read_data_tdata = rd_data_out;
    assign m_axis_read_data_tkeep = rd_keep_out;
    assign m_axis_read_data_tvalid = rd_valid_out;
    assign m_axis_read_data_tlast = rd_last_out;
    assign m_axis_read_data_tid = rd_tid_out;
    assign m_axis_read_data_tdest = rd_tdest_out;
    assign m_axis_read_data_tuser = rd_tuser_out;

    // Write data ready
    assign s_axis_write_data_tready = wr_data_ready;

    // AXI read address channel
    assign m_axi_arid = arid_reg;
    assign m_axi_araddr = araddr_reg;
    assign m_axi_arlen = arlen_reg;
    assign m_axi_arsize = arsize_reg;
    assign m_axi_arburst = arburst_reg;
    assign m_axi_arlock = arlock_reg;
    assign m_axi_arcache = arcache_reg;
    assign m_axi_arprot = arprot_reg;
    assign m_axi_arvalid = arvalid_reg;

    // AXI read data channel
    assign m_axi_rready = rready_reg;

    // AXI write address channel
    assign m_axi_awid = awid_reg;
    assign m_axi_awaddr = awaddr_reg;
    assign m_axi_awlen = awlen_reg;
    assign m_axi_awsize = awsize_reg;
    assign m_axi_awburst = awburst_reg;
    assign m_axi_awlock = awlock_reg;
    assign m_axi_awcache = awcache_reg;
    assign m_axi_awprot = awprot_reg;
    assign m_axi_awvalid = awvalid_reg;

    // AXI write data channel
    assign m_axi_wdata = wdata_reg;
    assign m_axi_wstrb = wstrb_reg;
    assign m_axi_wlast = wlast_reg;
    assign m_axi_wvalid = wvalid_reg;

    // AXI write response channel
    assign m_axi_bready = bready_reg;

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

    // Read data output handshake
    wire rd_data_handshake = rd_valid_out && m_axis_read_data_tready;

    // Write data input handshake
    wire wr_data_handshake = s_axis_write_data_tvalid && wr_data_ready;

    // AXI read address handshake
    wire ar_handshake = arvalid_reg && m_axi_arready;

    // AXI read data handshake
    wire r_handshake = m_axi_rvalid && rready_reg;

    // AXI write address handshake
    wire aw_handshake = awvalid_reg && m_axi_awready;

    // AXI write data handshake
    wire w_handshake = wvalid_reg && m_axi_wready;

    // AXI write response handshake
    wire b_handshake = m_axi_bvalid && bready_reg;

    // Read channel logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_len <= {LEN_WIDTH{1'b0}};
            rd_remaining <= {LEN_WIDTH{1'b0}};
            rd_tag <= {TAG_WIDTH{1'b0}};
            rd_id <= {AXIS_ID_WIDTH{1'b0}};
            rd_dest <= {AXIS_DEST_WIDTH{1'b0}};
            rd_user <= {AXIS_USER_WIDTH{1'b0}};
            rd_active <= 1'b0;
            rd_burst_len <= {AXI_BURST_LEN_WIDTH{1'b0}};
            rd_burst_remaining <= {LEN_WIDTH{1'b0}};
            rd_burst_active <= 1'b0;
            rd_error <= 4'b0000;
            rd_status_valid <= 1'b0;
            rd_status_tag <= {TAG_WIDTH{1'b0}};
            rd_status_error <= 4'b0000;
            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            arlen_reg <= 8'd0;
            arsize_reg <= 3'd0;
            arburst_reg <= 2'b00;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'b0000;
            arprot_reg <= 3'b000;
            arvalid_reg <= 1'b0;
            rready_reg <= 1'b0;
            rd_data_out <= {AXIS_DATA_WIDTH{1'b0}};
            rd_keep_out <= {AXIS_KEEP_WIDTH{1'b0}};
            rd_valid_out <= 1'b0;
            rd_last_out <= 1'b0;
            rd_tid_out <= {AXIS_ID_WIDTH{1'b0}};
            rd_tdest_out <= {AXIS_DEST_WIDTH{1'b0}};
            rd_tuser_out <= {AXIS_USER_WIDTH{1'b0}};
        end else begin
            // Default: clear valid signals
            rd_valid_out <= 1'b0;
            rd_last_out <= 1'b0;
            arvalid_reg <= 1'b0;
            rready_reg <= 1'b0;
            rd_status_valid <= 1'b0;

            // Accept read descriptor
            if (rd_desc_accept) begin
                rd_addr <= s_axis_read_desc_addr;
                rd_len <= s_axis_read_desc_len;
                rd_remaining <= s_axis_read_desc_len;
                rd_tag <= s_axis_read_desc_tag;
                rd_id <= s_axis_read_desc_id;
                rd_dest <= s_axis_read_desc_dest;
                rd_user <= s_axis_read_desc_user;
                rd_active <= 1'b1;
                rd_error <= 4'b0000;
                rd_burst_active <= 1'b0;
                rd_burst_len <= 0;
                rd_burst_remaining <= 0;
            end

            // Issue read address
            if (rd_active && !rd_burst_active && rd_remaining > 0) begin
                rd_burst_len <= calc_burst_len(rd_remaining);
                rd_burst_remaining <= rd_remaining;
                rd_burst_active <= 1'b1;
                arid_reg <= rd_tag;
                araddr_reg <= rd_addr;
                arlen_reg <= rd_burst_len - 1;
                arsize_reg <= AXI_SIZE_VAL;
                arburst_reg <= 2'b01; // INCR
                arlock_reg <= 1'b0;
                arcache_reg <= 4'b0000;
                arprot_reg <= 3'b000;
                arvalid_reg <= 1'b1;
            end

            // Handle read address handshake
            if (ar_handshake) begin
                arvalid_reg <= 1'b0;
                rready_reg <= 1'b1;
            end

            // Handle read data
            if (r_handshake) begin
                rd_data_out <= m_axi_rdata;
                rd_keep_out <= {AXIS_KEEP_WIDTH{1'b1}};
                rd_valid_out <= 1'b1;
                rd_tid_out <= rd_id;
                rd_tdest_out <= rd_dest;
                rd_tuser_out <= rd_user;
                rd_burst_remaining <= rd_burst_remaining - 1;
                rd_addr <= rd_addr + AXI_DATA_BYTES;
                rd_remaining <= rd_remaining - 1;

                if (m_axi_rlast) begin
                    rd_last_out <= 1'b1;
                    rready_reg <= 1'b0;
                    rd_burst_active <= 1'b0;
                    if (rd_remaining == 1) begin
                        rd_active <= 1'b0;
                        rd_status_valid <= 1'b1;
                        rd_status_tag <= rd_tag;
                        rd_status_error <= rd_error;
                    end
                end
            end

            // Handle read data output handshake
            if (rd_data_handshake) begin
                rd_valid_out <= 1'b0;
            end

            // Check for read errors
            if (r_handshake && m_axi_rresp != 2'b00) begin
                rd_error <= 4'b0001;
            end
        end
    end

    // Write channel logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_len <= {LEN_WIDTH{1'b0}};
            wr_remaining <= {LEN_WIDTH{1'b0}};
            wr_tag <= {TAG_WIDTH{1'b0}};
            wr_active <= 1'b0;
            wr_burst_len <= {AXI_BURST_LEN_WIDTH{1'b0}};
            wr_burst_remaining <= {LEN_WIDTH{1'b0}};
            wr_burst_active <= 1'b0;
            wr_error <= 4'b0000;
            wr_status_valid <= 1'b0;
            wr_status_len <= {LEN_WIDTH{1'b0}};
            wr_status_tag <= {TAG_WIDTH{1'b0}};
            wr_status_id <= {AXIS_ID_WIDTH{1'b0}};
            wr_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            wr_status_user <= {AXIS_USER_WIDTH{1'b0}};
            wr_status_error <= 4'b0000;
            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            awlen_reg <= 8'd0;
            awsize_reg <= 3'd0;
            awburst_reg <= 2'b00;
            awlock_reg <= 1'b0;
            awcache_reg <= 4'b0000;
            awprot_reg <= 3'b000;
            awvalid_reg <= 1'b0;
            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wlast_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;
            wr_data_ready <= 1'b0;
        end else begin
            // Default: clear valid signals
            awvalid_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;
            wr_data_ready <= 1'b0;
            wr_status_valid <= 1'b0;

            // Accept write descriptor
            if (wr_desc_accept) begin
                wr_addr <= s_axis_write_desc_addr;
                wr_len <= s_axis_write_desc_len;
                wr_remaining <= s_axis_write_desc_len;
                wr_tag <= s_axis_write_desc_tag;
                wr_active <= 1'b1;
                wr_error <= 4'b0000;
                wr_burst_active <= 1'b0;
                wr_burst_len <= 0;
                wr_burst_remaining <= 0;
            end

            // Issue write address
            if (wr_active && !wr_burst_active && wr_remaining > 0) begin
                wr_burst_len <= calc_burst_len(wr_remaining);
                wr_burst_remaining <= wr_remaining;
                wr_burst_active <= 1'b1;
                awid_reg <= wr_tag;
                awaddr_reg <= wr_addr;
                awlen_reg <= wr_burst_len - 1;
                awsize_reg <= AXI_SIZE_VAL;
                awburst_reg <= 2'b01; // INCR
                awlock_reg <= 1'b0;
                awcache_reg <= 4'b0000;
                awprot_reg <= 3'b000;
                awvalid_reg <= 1'b1;
                wr_data_ready <= 1'b1;
            end

            // Handle write address handshake
            if (aw_handshake) begin
                awvalid_reg <= 1'b0;
            end

            // Handle write data
            if (wr_data_handshake && wr_burst_active) begin
                wdata_reg <= s_axis_write_data_tdata;
                wstrb_reg <= s_axis_write_data_tkeep;
                wlast_reg <= s_axis_write_data_tlast;
                wvalid_reg <= 1'b1;
                wr_burst_remaining <= wr_burst_remaining - 1;
                wr_addr <= wr_addr + AXI_DATA_BYTES;
                wr_remaining <= wr_remaining - 1;

                if (s_axis_write_data_tlast) begin
                    wr_burst_active <= 1'b0;
                    wr_data_ready <= 1'b0;
                    if (wr_remaining == 1) begin
                        wr_active <= 1'b0;
                        wr_status_valid <= 1'b1;
                        wr_status_len <= wr_len;
                        wr_status_tag <= wr_tag;
                        wr_status_id <= s_axis_write_data_tid;
                        wr_status_dest <= s_axis_write_data_tdest;
                        wr_status_user <= s_axis_write_data_tuser;
                        wr_status_error <= wr_error;
                    end
                end
            end

            // Handle write data handshake
            if (w_handshake) begin
                wvalid_reg <= 1'b0;
            end

            // Handle write response
            if (b_handshake) begin
                bready_reg <= 1'b0;
                if (m_axi_bresp != 2'b00) begin
                    wr_error <= 4'b0001;
                end
            end

            // Enable bready when write burst is active
            if (wr_burst_active) begin
                bready_reg <= 1'b1;
            end
        end
    end

endmodule
