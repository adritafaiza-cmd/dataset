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
    localparam AXI_DATA_LOG2 = $clog2(AXI_DATA_WIDTH);
    localparam AXI_MAX_BURST_LEN_LOG2 = $clog2(AXI_MAX_BURST_LEN);
    
    // State definitions
    localparam ST_IDLE = 2'd0;
    localparam ST_DESC = 2'd1;
    localparam ST_AXI = 2'd2;
    localparam ST_DONE = 2'd3;

    // Read channel state
    reg [1:0] rd_state;
    reg [AXI_ADDR_WIDTH-1:0] rd_addr;
    reg [LEN_WIDTH-1:0] rd_len;
    reg [LEN_WIDTH-1:0] rd_remaining;
    reg [TAG_WIDTH-1:0] rd_tag;
    reg [AXIS_ID_WIDTH-1:0] rd_id;
    reg [AXIS_DEST_WIDTH-1:0] rd_dest;
    reg [AXIS_USER_WIDTH-1:0] rd_user;
    reg [7:0] rd_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] rd_axi_addr;
    reg [LEN_WIDTH-1:0] rd_axi_len;
    reg rd_axi_last;
    reg [3:0] rd_error;
    reg rd_status_valid;
    reg [TAG_WIDTH-1:0] rd_status_tag;
    reg [3:0] rd_status_error;

    // Write channel state
    reg [1:0] wr_state;
    reg [AXI_ADDR_WIDTH-1:0] wr_addr;
    reg [LEN_WIDTH-1:0] wr_len;
    reg [LEN_WIDTH-1:0] wr_remaining;
    reg [TAG_WIDTH-1:0] wr_tag;
    reg [AXIS_ID_WIDTH-1:0] wr_id;
    reg [AXIS_DEST_WIDTH-1:0] wr_dest;
    reg [AXIS_USER_WIDTH-1:0] wr_user;
    reg [7:0] wr_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] wr_axi_addr;
    reg [LEN_WIDTH-1:0] wr_axi_len;
    reg wr_axi_last;
    reg [3:0] wr_error;
    reg wr_status_valid;
    reg [LEN_WIDTH-1:0] wr_status_len;
    reg [TAG_WIDTH-1:0] wr_status_tag;
    reg [AXIS_ID_WIDTH-1:0] wr_status_id;
    reg [AXIS_DEST_WIDTH-1:0] wr_status_dest;
    reg [AXIS_USER_WIDTH-1:0] wr_status_user;
    reg [3:0] wr_status_error;

    // AXI read channel
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg arlock_reg;
    reg [3:0] arcache_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    reg rready_reg;
    reg [AXIS_DATA_WIDTH-1:0] rdata_reg;
    reg [AXIS_KEEP_WIDTH-1:0] rkeep_reg;
    reg rvalid_reg;
    reg rlast_reg;
    reg [AXIS_ID_WIDTH-1:0] rid_reg;
    reg [AXIS_DEST_WIDTH-1:0] rdest_reg;
    reg [AXIS_USER_WIDTH-1:0] ruser_reg;

    // AXI write channel
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg awlock_reg;
    reg [3:0] awcache_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;
    reg bready_reg;

    // Helper functions
    function [7:0] calc_burst_len;
        input [LEN_WIDTH-1:0] remaining;
        begin
            if (remaining > AXI_MAX_BURST_LEN)
                calc_burst_len = AXI_MAX_BURST_LEN - 1;
            else
                calc_burst_len = remaining - 1;
        end
    endfunction

    // Read descriptor ready
    assign s_axis_read_desc_ready = (rd_state == ST_IDLE) && read_enable;

    // Write descriptor ready
    assign s_axis_write_desc_ready = (wr_state == ST_IDLE) && write_enable;

    // Read data output
    assign m_axis_read_data_tdata = rdata_reg;
    assign m_axis_read_data_tkeep = rkeep_reg;
    assign m_axis_read_data_tvalid = rvalid_reg;
    assign m_axis_read_data_tlast = rlast_reg;
    assign m_axis_read_data_tid = rid_reg;
    assign m_axis_read_data_tdest = rdest_reg;
    assign m_axis_read_data_tuser = ruser_reg;

    // Write data ready
    assign s_axis_write_data_tready = (wr_state == ST_AXI) && wvalid_reg && m_axi_wready;

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
    assign m_axi_wdata = wdata_reg;
    assign m_axi_wstrb = wstrb_reg;
    assign m_axi_wlast = wlast_reg;
    assign m_axi_wvalid = wvalid_reg;
    assign m_axi_bready = bready_reg;

    // Read state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_state <= ST_IDLE;
            rd_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_len <= {LEN_WIDTH{1'b0}};
            rd_remaining <= {LEN_WIDTH{1'b0}};
            rd_tag <= {TAG_WIDTH{1'b0}};
            rd_id <= {AXIS_ID_WIDTH{1'b0}};
            rd_dest <= {AXIS_DEST_WIDTH{1'b0}};
            rd_user <= {AXIS_USER_WIDTH{1'b0}};
            rd_burst_len <= 8'd0;
            rd_axi_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_axi_len <= {LEN_WIDTH{1'b0}};
            rd_axi_last <= 1'b0;
            rd_error <= 4'd0;
            rd_status_valid <= 1'b0;
            rd_status_tag <= {TAG_WIDTH{1'b0}};
            rd_status_error <= 4'd0;
            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            arlen_reg <= 8'd0;
            arsize_reg <= 3'd0;
            arburst_reg <= 2'b0;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'd0;
            arprot_reg <= 3'd0;
            arvalid_reg <= 1'b0;
            rready_reg <= 1'b0;
            rdata_reg <= {AXIS_DATA_WIDTH{1'b0}};
            rkeep_reg <= {AXIS_KEEP_WIDTH{1'b0}};
            rvalid_reg <= 1'b0;
            rlast_reg <= 1'b0;
            rid_reg <= {AXIS_ID_WIDTH{1'b0}};
            rdest_reg <= {AXIS_DEST_WIDTH{1'b0}};
            ruser_reg <= {AXIS_USER_WIDTH{1'b0}};
        end else begin
            // Default assignments
            rd_status_valid <= 1'b0;
            arvalid_reg <= 1'b0;
            rvalid_reg <= 1'b0;
            rready_reg <= 1'b0;

            case (rd_state)
                ST_IDLE: begin
                    if (s_axis_read_desc_valid && read_enable) begin
                        rd_state <= ST_DESC;
                        rd_addr <= s_axis_read_desc_addr;
                        rd_len <= s_axis_read_desc_len;
                        rd_remaining <= s_axis_read_desc_len;
                        rd_tag <= s_axis_read_desc_tag;
                        rd_id <= s_axis_read_desc_id;
                        rd_dest <= s_axis_read_desc_dest;
                        rd_user <= s_axis_read_desc_user;
                    end
                end
                ST_DESC: begin
                    // Prepare first burst
                    rd_axi_addr <= rd_addr;
                    rd_axi_len <= rd_remaining;
                    rd_burst_len <= calc_burst_len(rd_remaining);
                    rd_axi_last <= (rd_remaining <= AXI_MAX_BURST_LEN);
                    rd_state <= ST_AXI;
                end
                ST_AXI: begin
                    // Issue AXI read address
                    if (!arvalid_reg) begin
                        arid_reg <= rd_tag[AXI_ID_WIDTH-1:0];
                        araddr_reg <= rd_axi_addr;
                        arlen_reg <= rd_burst_len;
                        arsize_reg <= AXI_DATA_LOG2[2:0];
                        arburst_reg <= 2'b01; // INCR
                        arlock_reg <= 1'b0;
                        arcache_reg <= 4'b0011;
                        arprot_reg <= 3'b000;
                        arvalid_reg <= 1'b1;
                    end

                    // Handle AXI read data
                    if (m_axi_rvalid) begin
                        rdata_reg <= m_axi_rdata;
                        rkeep_reg <= {AXIS_KEEP_WIDTH{1'b1}};
                        rvalid_reg <= 1'b1;
                        rlast_reg <= m_axi_rlast;
                        rid_reg <= rd_id;
                        rdest_reg <= rd_dest;
                        ruser_reg <= rd_user;
                        rready_reg <= 1'b1;

                        if (m_axis_read_data_tready) begin
                            // Data accepted
                            if (m_axi_rlast) begin
                                // Burst complete
                                rd_remaining <= rd_remaining - (rd_burst_len + 1);
                                rd_axi_addr <= rd_axi_addr + (rd_burst_len + 1) * AXI_DATA_BYTES;
                                if (rd_remaining - (rd_burst_len + 1) == 0) begin
                                    rd_state <= ST_DONE;
                                end else begin
                                    rd_state <= ST_DESC;
                                end
                            end
                        end
                    end
                end
                ST_DONE: begin
                    rd_status_valid <= 1'b1;
                    rd_status_tag <= rd_tag;
                    rd_status_error <= rd_error;
                    rd_state <= ST_IDLE;
                end
                default: rd_state <= ST_IDLE;
            endcase
        end
    end

    // Write state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_state <= ST_IDLE;
            wr_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_len <= {LEN_WIDTH{1'b0}};
            wr_remaining <= {LEN_WIDTH{1'b0}};
            wr_tag <= {TAG_WIDTH{1'b0}};
            wr_id <= {AXIS_ID_WIDTH{1'b0}};
            wr_dest <= {AXIS_DEST_WIDTH{1'b0}};
            wr_user <= {AXIS_USER_WIDTH{1'b0}};
            wr_burst_len <= 8'd0;
            wr_axi_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_axi_len <= {LEN_WIDTH{1'b0}};
            wr_axi_last <= 1'b0;
            wr_error <= 4'd0;
            wr_status_valid <= 1'b0;
            wr_status_len <= {LEN_WIDTH{1'b0}};
            wr_status_tag <= {TAG_WIDTH{1'b0}};
            wr_status_id <= {AXIS_ID_WIDTH{1'b0}};
            wr_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            wr_status_user <= {AXIS_USER_WIDTH{1'b0}};
            wr_status_error <= 4'd0;
            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            awlen_reg <= 8'd0;
            awsize_reg <= 3'd0;
            awburst_reg <= 2'b0;
            awlock_reg <= 1'b0;
            awcache_reg <= 4'd0;
            awprot_reg <= 3'd0;
            awvalid_reg <= 1'b1;
            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wlast_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;
        end else begin
            // Default assignments
            wr_status_valid <= 1'b0;
            awvalid_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;

            case (wr_state)
                ST_IDLE: begin
                    if (s_axis_write_desc_valid && write_enable) begin
                        wr_state <= ST_DESC;
                        wr_addr <= s_axis_write_desc_addr;
                        wr_len <= s_axis_write_desc_len;
                        wr_remaining <= s_axis_write_desc_len;
                        wr_tag <= s_axis_write_desc_tag;
                        wr_id <= s_axis_write_data_tid;
                        wr_dest <= s_axis_write_data_tdest;
                        wr_user <= s_axis_write_data_tuser;
                    end
                end
                ST_DESC: begin
                    // Prepare first burst
                    wr_axi_addr <= wr_addr;
                    wr_axi_len <= wr_remaining;
                    wr_burst_len <= calc_burst_len(wr_remaining);
                    wr_axi_last <= (wr_remaining <= AXI_MAX_BURST_LEN);
                    wr_state <= ST_AXI;
                end
                ST_AXI: begin
                    // Issue AXI write address
                    if (!awvalid_reg) begin
                        awid_reg <= wr_tag[AXI_ID_WIDTH-1:0];
                        awaddr_reg <= wr_axi_addr;
                        awlen_reg <= wr_burst_len;
                        awsize_reg <= AXI_DATA_LOG2[2:0];
                        awburst_reg <= 2'b01; // INCR
                        awlock_reg <= 1'b0;
                        awcache_reg <= 4'b0011;
                        awprot_reg <= 3'b000;
                        awvalid_reg <= 1'b1;
                    end

                    // Handle AXI write data
                    if (s_axis_write_data_tvalid) begin
                        wdata_reg <= s_axis_write_data_tdata;
                        wstrb_reg <= {AXI_STRB_WIDTH{1'b1}};
                        wlast_reg <= s_axis_write_data_tlast;
                        wvalid_reg <= 1'b1;

                        if (m_axi_wready) begin
                            // Data accepted
                            if (s_axis_write_data_tlast) begin
                                // Burst complete
                                wr_remaining <= wr_remaining - (wr_burst_len + 1);
                                wr_axi_addr <= wr_axi_addr + (wr_burst_len + 1) * AXI_DATA_BYTES;
                                if (wr_remaining - (wr_burst_len + 1) == 0) begin
                                    wr_state <= ST_DONE;
                                end else begin
                                    wr_state <= ST_DESC;
                                end
                            end
                        end
                    end

                    // Handle AXI write response
                    if (m_axi_bvalid) begin
                        bready_reg <= 1'b1;
                        if (m_axi_bresp != 2'b00) begin
                            wr_error <= {2'b00, m_axi_bresp};
                        end
                    end
                end
                ST_DONE: begin
                    wr_status_valid <= 1'b1;
                    wr_status_len <= wr_len;
                    wr_status_tag <= wr_tag;
                    wr_status_id <= wr_id;
                    wr_status_dest <= wr_dest;
                    wr_status_user <= wr_user;
                    wr_status_error <= wr_error;
                    wr_state <= ST_IDLE;
                end
                default: wr_state <= ST_IDLE;
            endcase
        end
    end

endmodule
