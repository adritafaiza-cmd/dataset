```verilog
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

    // Internal parameters
    localparam LOG2_AXI_MAX_BURST_LEN = $clog2(AXI_MAX_BURST_LEN);
    localparam LOG2_AXI_DATA_WIDTH    = $clog2(AXI_DATA_WIDTH);
    localparam LOG2_AXI_STRB_WIDTH    = $clog2(AXI_STRB_WIDTH);

    // State encoding
    localparam IDLE = 3'd0;
    localparam AW_PREPARE = 3'd1;
    localparam AW_SEND = 3'd2;
    localparam W_PREPARE = 3'd3;
    localparam W_SEND = 3'd4;
    localparam B_WAIT = 3'd5;
    localparam AR_PREPARE = 3'd6;
    localparam AR_SEND = 3'd7;
    localparam R_PREPARE = 3'd8;
    localparam R_WAIT = 3'd9;
    localparam R_DONE = 3'd10;
    localparam WRITE_ABORT = 3'd11;

    // Internal state registers
    reg [2:0] state;
    reg [TAG_WIDTH-1:0] tag;
    reg [LEN_WIDTH-1:0] len;
    reg [AXI_ADDR_WIDTH-1:0] addr;
    reg [AXI_ID_WIDTH-1:0] axi_id;
    reg [AXIS_DEST_WIDTH-1:0] dest;
    reg [AXIS_USER_WIDTH-1:0] user;
    reg [3:0] error_code;
    reg [7:0] axi_len;
    reg [2:0] axi_size;
    reg [1:0] axi_burst;
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;
    reg wready_reg;
    reg [AXI_DATA_WIDTH-1:0] rdata_reg;
    reg rlast_reg;
    reg rvalid_reg;
    reg rready_reg;
    reg [AXI_ID_WIDTH-1:0] bid_reg;
    reg [1:0] bresp_reg;
    reg bready_reg;
    reg [AXI_DATA_WIDTH-1:0] rdata_out_reg;
    reg rlast_out_reg;
    reg rvalid_out_reg;
    reg rready_out_reg;
    reg [AXI_ID_WIDTH-1:0] rid_reg;
    reg [1:0] rresp_reg;
    reg rlast_in_reg;
    reg rvalid_in_reg;
    reg rready_in_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg arvalid_reg;
    reg arready_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg awvalid_reg;
    reg awready_reg;
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [3:0] awcache_reg;
    reg [2:0] awprot_reg;
    reg [1:0] awlock_reg;
    reg [AXI_ID_WIDTH-1:0] awid_out_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_out_reg;
    reg [7:0] awlen_out_reg;
    reg [2:0] awsize_out_reg;
    reg [1:0] awburst_out_reg;
    reg [1:0] awlock_out_reg;
    reg [3:0] awcache_out_reg;
    reg [2:0] awprot_out_reg;
    reg awvalid_out_reg;
    reg awready_out_reg;
    reg [AXI_DATA_WIDTH-1:0] wdata_out_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_out_reg;
    reg wlast_out_reg;
    reg wvalid_out_reg;
    reg wready_out_reg;
    reg [AXI_DATA_WIDTH-1:0] rdata_out_reg;
    reg rlast_out_reg;
    reg rvalid_out_reg;
    reg rready_out_reg;
    reg [AXI_ID_WIDTH-1:0] rid_out_reg;
    reg [1:0] rresp_out_reg;
    reg rlast_in_reg;
    reg rvalid_in_reg;
    reg rready_in_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_reg;
    reg [7:0] arlen_out_reg;
    reg [2:0] arsize_out_reg;
    reg [1:0] arburst_out_reg;
    reg arvalid_out_reg;
    reg arready_out_reg;
    reg [AXI_ID_WIDTH-1:0] awid_out_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_out_reg;
    reg [7:0] awlen_out_reg;
    reg [2:0] awsize_out_reg;
    reg [1:0] awburst_out_reg;
    reg [1:0] awlock_out_reg;
    reg [3:0] awcache_out_reg;
    reg [2:0] awprot_out_reg;
    reg awvalid_out_reg;
    reg awready_out_reg;
    reg [AXI_DATA_WIDTH-1:0] wdata_out_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_out_reg;
    reg wlast_out_reg;
    reg wvalid_out_reg;
    reg wready_out_reg;
    reg [AXI_DATA_WIDTH-1:0] rdata_out_reg;
    reg rlast_out_reg;
    reg rvalid_out_reg;
    reg rready_out_reg;
    reg [AXI_ID_WIDTH-1:0] rid_out_reg;
    reg [1:0] rresp_out_reg;
    reg rlast_in_reg;
    reg rvalid_in_reg;
    reg rready_in_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_reg;
    reg [7:0] arlen_out_reg;
    reg [2:0] arsize_out_reg;
    reg [1:0] arburst_out_reg;
    reg arvalid_out_reg;
    reg arready_out_reg;
    reg [AXI_ID_WIDTH-1:0] awid_out_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_out_reg;
    reg [7:0] awlen_out_reg;
    reg [2:0] awsize_out_reg;
    reg [1:0] awburst_out_reg;
    reg [1:0] awlock_out_reg;
    reg [3:0] awcache_out_reg;
    reg [2:0] awprot_out_reg;
    reg awvalid_out_reg;
    reg awready_out_reg;
    reg [AXI_DATA_WIDTH-1:0] wdata_out_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_out_reg;
    reg wlast_out_reg;
    reg wvalid_out_reg;
    reg wready_out_reg;
    reg [AXI_DATA_WIDTH-1:0] rdata_out_reg;
    reg rlast_out_reg;
    reg rvalid_out_reg;
    reg rready_out_reg;
    reg [AXI_ID_WIDTH-1:0] rid_out_reg;
    reg [1:0] rresp_out_reg;
    reg rlast_in_reg;
    reg rvalid_in_reg;
    reg rready_in_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_reg;
    reg [7:0] arlen_out_reg;
    reg [2:0] arsize_out_reg;
    reg [1:0] arburst_out_reg;
    reg arvalid_out_reg;
    reg arready_out_reg;

    // Simplified state machine logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tag <= 0;
            len <= 0;
            addr <= 0;
            axi_id <= 0;
            dest <= 0;
            user <= 0;
            error_code <= 0;
            axi_len <= 0;
            axi_size <= 0;
            axi_burst <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wlast_reg <= 0;
            wvalid_reg <= 0;
            wready_reg <= 0;
            wdata_out_reg <= 0;
            wstrb_out_reg <= 0;
            wlast_out_reg <= 0;
            wvalid_out_reg <= 0;
            wready_out_reg <= 0;
            rdata_out_reg <= 0;
            rlast_out_reg <= 0;
            rvalid_out_reg <= 0;
            rready_out_reg <= 0;
            rid_out_reg <= 0;
            rresp_out_reg <= 0;
            rlast_in_reg <= 0;
            rvalid_in_reg <= 0;
            rready_in_reg <= 0;
            araddr_out_reg <= 0;
            arlen_out_reg <= 0;
            arsize_out_reg <= 0;
            arburst_out_reg <= 0;
            arvalid_out_reg <= 0;
            arready_out_reg <= 0;
            awid_out_reg <= 0;
            awaddr_out_reg <= 0;
            awlen_out_reg <= 0;
            awsize_out_reg <= 0;
            awburst_out_reg <= 0;
            awlock_out_reg <= 0;
            awcache_out_reg <= 0;
            awprot_out_reg <= 0;
            awvalid_out_reg <= 0;
            awready_out_reg <= 0;
            m_axis_read_desc_status_valid <= 0;
            m_axis_read_desc_status_tag <= 0;
            m_axis_read_desc_status_error <= 0;
            m_axis_write_desc_status_valid <= 0;
            m_axis_write_desc_status_len <= 0;
            m_axis_write_desc_status_tag <= 0;
            m_axis_write_desc_status_id <= 0;
            m_axis_write_desc_status_dest <= 0;
            m_axis_write_desc_status_user <= 0;
            m_axis_write_desc_status_error <= 0;
            s_axis_read_desc_ready <= 0;
            s_axis_write_desc_ready <= 0;
            m_axis_read_data_tvalid <= 0;
            m_axis_read_data_tlast <= 0;
            m_axis_read_data_tid <= 0;
            m_axis_read_data_tdest <= 0;
            m_axis_read_data_tuser <= 0;
            m_axis_read_data_tkeep <= 0;
            m_axis_read_data_tdata <= 0;
            m_axis_write_desc_status_valid <= 0;
            m_axis_write_desc_status_len <= 0;
            m_axis_write_desc_status_tag <= 0;
            m_axis_write_desc_status_id <= 0;
            m_axis_write_desc_status_dest <= 0;
            m_axis_write_desc_status_user <= 0;
            m_axis_write_desc_status_error <= 0;
            s_axis_write_data_tready <= 0;
            m_axi_awid <= 0;
            m_axi_awaddr <= 0;
            m_axi_awlen <= 0;
            m_axi_awsize <= 0;
            m_axi_awburst <= 0;
            m_axi_awlock <= 0;
            m_axi_awcache <= 0;
            m_axi_awprot <= 0;
            m_axi_awvalid <= 0;
            m_axi_wdata <= 0;
            m_axi_wstrb <= 0;
            m_axi_wlast <= 0;
            m_axi_wvalid <= 0;
            m_axi_bready <= 0;
            m_axi_arid <= 0;
            m_axi_araddr <= 0;
            m_axi_arlen <= 0;
            m_axi_arsize <= 0;
            m_axi_arburst <= 0;
            m_axi_arlock <= 0;
            m_axi_arcache <= 0;
            m_axi_arprot <= 0;
            m_axi_arvalid <= 0;
            m_axi_rready <= 0;
        end
        else begin
            // Read Descriptor Input
            if (read_enable && s_axis_read_desc_valid && !s_axis_read_desc_ready) begin
                s_axis_read_desc_ready <= 1;
                tag <= s_axis_read_desc_tag;
                len <= s_axis_read_desc_len;
                addr <= s_axis_read_desc_addr;
                axi_id <= s_axis_read_desc_id;
                dest <= s_axis_read_desc_dest;
                user <= s_axis_read_desc_user;
                if (len == 0) begin
                    error_code <= 1; // Invalid length
                    state <= IDLE;
                end else begin
                    state <= AW_PREPARE;
                end
            end else if (read_enable && s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                s_axis_read_desc_ready <= 0;
                tag <= s_axis_read_desc_tag;
                len <= s_axis_read_desc_len;
                addr <= s_axis_read_desc_addr;
                axi_id <= s_axis_read_desc_id;
                dest <= s_axis_read_desc_dest;
                user <= s_axis_read_desc_user;
                if (len == 0) begin
                    error_code <= 1;
                    state <= IDLE;
                end else begin
                    state <= AW_PREPARE;
                end
            end

            // Write Descriptor Input
            if (write_enable && s_axis_write_desc_valid && !s_axis_write_desc_ready) begin
                s_axis_write_desc_ready <= 1;
                tag <= s_axis_write_desc_tag;
                len <= s_axis_write_desc_len;
                addr <= s_axis_write_desc_addr;
                axi_id <= s_axis_write_data_tid;
                dest <= s_axis_write_data_tdest;
                user <= s_axis_write_data_tuser;
                if (len == 0) begin
                    error_code <= 2; // Invalid length
                    state <= IDLE;
                end else begin
                    state <= AW_PREPARE;
                end
            end else if (write_enable && s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                s_axis_write_desc_ready <= 0;
                tag <= s_axis_write_desc_tag;
                len <= s_axis_write_desc_len;
                addr <= s_axis_write_desc_addr;
                axi_id <= s_axis_write_data_tid;
                dest <= s_axis_write_data_tdest;
                user <= s_axis_write_data_tuser;
                if (len == 0) begin
                    error_code <= 2;
                    state <= IDLE;
                end else begin
                    state <= AW_PREPARE;
                end
            end

            // Write Data Input
            if (write_enable && s_axis_write_data_tvalid && !s_axis_write_data_tready) begin
                s_axis_write_data_tready <= 1;
                wdata_reg <= s_axis_write_data_tdata;
                wstrb_reg <= s_axis_write_data_tkeep;
                wlast_reg <= s_axis_write_data_tlast;
                if (s_axis_write_data_tlast) begin
                    wvalid_reg <= 1;
                end
            end else if (write_enable && s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                s_axis_write_data_tready <= 0;
                wdata_reg <= s_axis_write_data_tdata;
                wstrb_reg <= s_axis_write_data_tkeep;
                wlast_reg <= s_axis_write_data_tlast;
                if (s_axis_write_data_tlast) begin
                    wvalid_reg <= 1;
                end
            end

            // AXI Read Data Output
            if (m_axis_read_data_tready && m_axis_read_data_tvalid) begin
                m_axis_read_data_tvalid <= 0;
                m_axis_read_data_tdata <= rdata_out_reg;
                m_axis_read_data_tkeep <= {AXIS_KEEP_WIDTH{1'b1}};
                m_axis_read_data_tlast <= rlast_out_reg;
                m_axis_read_data_tid <= rid_out_reg;
                m_axis_read_data_tdest <= dest;
                m_axis_read_data_tuser <= user;
            end else if (!m_axis_read_data_tready || !m_axis_read_data_tvalid) begin
                m_axis_read_data_tvalid <= 0;
                m_axis_read_data_tdata <= 0;
                m_axis_read_data_tkeep <= 0;
                m_axis_read_data_tlast <= 0;
                m_axis_read_data_tid <= 0;
                m_axis_read_data_tdest <= 0;
                m_axis_read_data_tuser <= 0;
            end

            // AXI Write Descriptor Status Output
            if (write_enable && m_axis_write_desc_status_valid) begin
                m_axis_write_desc_status_valid <= 0;
                m_axis_write_desc_status_len <= len;
                m_axis_write_desc_status_tag <= tag;
                m_axis_write_desc_status_id <= axi_id;
                m_axis_write_desc_status_dest <= dest;
                m_axis_write_desc_status_user <= user;
                m_axis_write_desc_status_error <= error_code;
            end else if (!write_enable || !m_axis_write_desc_status_valid) begin
                m_axis_write_desc_status_valid <= 0;
                m_axis_write_desc_status_len <= 0;
                m_axis_write_desc_status_tag <= 0;
                m_axis_write_desc_status_id <= 0;
                m_axis_write_desc_status_dest <= 0;
                m_axis_write_desc_status_user <= 0;
                m_axis_write_desc_status_error <= 0;
            end

            // AXI Read Descriptor Status Output
            if (read_enable && m_axis_read_desc_status_valid) begin
                m_axis_read_desc_status_valid <= 0;
                m_axis_read_desc_status_tag <= tag;
                m_axis_read_desc_status_error <= error_code;
            end else if (!read_enable || !m_axis_read_desc_status_valid) begin
                m_axis_read_desc_status_valid <= 0;
                m_axis_read_desc_status_tag <= 0;
                m_axis_read_desc_status_error <= 0;
            end

            // AXI Write Data Ready
            if (write_enable && s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                s_axis_write_data_tready <= 0;
                wdata_reg <= s_axis_write_data_tdata;
                wstrb_reg <= s_axis_write_data_tkeep;
                wlast_reg <= s_axis_write_data_tlast;
                if (s_axis_write_data_tlast) begin
                    wvalid_reg <= 1;
                end
            end else if (write_enable && s_axis_write_data_tvalid && !s_axis_write_data_tready) begin
                s_axis_write_data_tready <= 0;
                wdata_reg <= s_axis_write_data_tdata;
                wstrb_reg <= s_axis_write_data_tkeep;
                wlast_reg <= s_axis_write_data_tlast;
                if (s_axis_write_data_tlast) begin
                    wvalid_reg <= 1;
                end
            end

            // AXI Master Interface Outputs
            if (write_enable && m_axi_awready && m_axi_awvalid) begin
                m_axi_awvalid <= 0;
                m_axi_awid <= awid_out_reg;
                m_axi_awaddr <= awaddr_out_reg;
                m_axi_awlen <= awlen_out_reg;
                m_axi_awsize <= awsize_out_reg;
                m_axi_awburst <= awburst_out_reg;
                m_axi_awlock <= awlock_out_reg;
                m_axi_awcache <= awcache_out_reg;
                m_axi_awprot <= awprot_out_reg;
            end else if (!write_enable || !m_axi_awready || !m_axi_awvalid) begin
                m_axi_awvalid <= 0;
                m_axi_awid <= 0;
                m_axi_awaddr <= 0;
                m_axi_awlen <= 0;
                m_axi_awsize <= 0;
                m_axi_awburst <= 0;
                m_axi_awlock <= 0;
                m_axi_awcache <= 0;
                m_axi_awprot <= 0;
            end

            if (write_enable && m_axi_wready && m_axi_wvalid) begin
                m_axi_wvalid <= 0;
                m_axi_wdata <= wdata_out_reg;
                m_axi_wstrb <= wstrb_out_reg;
                m_axi_wlast <= wlast_out_reg;
            end else if (!write_enable || !m_axi_wready || !m_axi_wvalid) begin
                m_axi_wvalid <= 0;
                m_axi_wdata <= 0;
                m_axi_wstrb <= 0;
                m_axi_wlast <= 0;
            end

            if (write_enable && m_axi_bready && m_axi_bvalid) begin
                m_axi_bready <= 0;
                bid_reg <= m_axi_bid;
                bresp_reg <= m_axi_bresp;
            end else if (!write_enable || !m_axi_bready || !m_axi_bvalid) begin
                m_axi_bready <= 0;
                bid_reg <= 0;
                bresp_reg <= 0;
            end

            if (read_enable && m_axi_arready && m_axi_arvalid) begin
                m_axi_arvalid <= 0;
                m_axi_arid <= arid_out_reg;
                m_axi_araddr <= araddr_out_reg;
                m_axi_arlen <= arlen_out_reg;
                m_axi_arsize <= arsize_out_reg;
                m_axi_arburst <= arburst_out_reg;
                m_axi_arlock <= arlock_out_reg;
                m_axi_arcache <= arcache_out_reg;
                m_axi_arprot => arprot_out_reg;
            end else if (!read_enable || !m_axi_arready || !m_axi_arvalid) begin
                m_axi_arvalid <= 0;
                m_axi_arid <= 0;
                m_axi_araddr <= 0;
                m_axi_arlen <= 0;
                m_axi_arsize <= 0;
                m_axi_arburst <= 0;
                m_axi_arlock <= 0;
                m_axi_arcache <= 0;
                m_axi_arprot <= 0;
            end

            if (read_enable && m_axi_rready && m_axi_rvalid) begin
                m_axi_rready <= 0;
                rdata_out_reg <= m_axi_rdata;
                rlast_out_reg <= m_axi_rlast;
                rvalid_out_reg <= 1;
                rid_out_reg <= m_axi_rid;
                rresp_out_reg <= m_axi_rresp;
            end else if (!read_enable || !m_axi_rready || !m_axi_rvalid) begin
                m_axi_rready <= 0;
                rdata_out_reg <= 0;
                rlast_out_reg <= 0;
                rvalid_out_reg <= 0;
                rid_out_reg <= 0;
                rresp_out_reg <= 0;
            end

            // State Machine Logic
            case (state)
                IDLE: begin
                    if (read_enable && s_axis_read_desc_valid && !s_axis_read_desc_ready) begin
                        s_axis_read_desc_ready <= 1;
                        tag <= s_axis_read_desc_tag;
                        len <= s_axis_read_desc_len;
                        addr <= s_axis_read_desc_addr;
                        axi_id <= s_axis_read_desc_id;
                        dest <= s_axis_read_desc_dest;
                        user <= s_axis_read_desc_user;
                        if (len == 0) begin
                            error_code <= 1;
                            state <= IDLE;
                        end else begin
                            state <= AW_PREPARE;
                        end
                    end else if (write_enable && s_axis_write_desc_valid && !s_axis_write_desc_ready) begin
                        s_axis_write_desc_ready <= 1;
                        tag <= s_axis_write_desc_tag;
                        len <= s_axis_write_desc_len;
                        addr <= s_axis_write_desc_addr;
                        axi_id <= s_axis_write_data_tid;
                        dest <= s_axis_write_data_tdest;
                        user <= s_axis_write_data_tuser;
                        if (len == 0) begin
                            error_code <= 2;
                            state <= IDLE;
                        end else begin
                            state <= AW_PREPARE;
                        end
                    end
                end

                AW_PREPARE: begin
                    if (read_enable && s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                        s_axis_read_desc_ready <= 0;
                        tag <= s_axis_read_desc_tag;
                        len <= s_axis_read_desc_len;
                        addr <= s_axis_read_desc_addr;
                        axi_id <= s_axis_read_desc_id;
                        dest <= s_axis_read_desc_dest;
                        user <= s_axis_read_desc_user;
                        if (len == 0) begin
                            error_code <= 1;
                            state <= IDLE;
                        end else begin
                            state <= AW_SEND;
                        end
                    end else if (write_enable && s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                        s_axis_write_desc_ready <= 0;
                        tag <= s_axis_write_desc_tag;
                        len <= s_axis_write_desc_len;
                        addr <= s_axis_write_desc_addr;
                        axi_id <= s_axis_write_data_tid;
                        dest <= s_axis_write_data_tdest;
                        user <= s_axis_write_data_tuser;
                        if (len == 0) begin
                            error_code <= 2;
                            state <= IDLE;
                        end else begin
                            state <= AW_SEND;
                        end
                    end
                end

                AW_SEND: begin
                    if (write_enable && m_axi_awready) begin
                        m_axi_awvalid <= 1;
                        m_axi_awid <= axi_id;
                        m_axi_awaddr <= addr;
                        m_axi_awlen <= axi_len;
                        m_axi_awsize <= axi_size;
                        m_axi_awburst <= axi_burst;
                        m_axi_awlock <= 0;
                        m_axi_awcache <= 0;
                        m_axi_awprot <= 0;
                        state <= W_PREPARE;
                    end else if (write_enable && m_axi_awvalid && !m_axi_awready) begin
                        // Wait for ready
                    end else if (write_enable && m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 0;
                        state <= W_PREPARE;
                    end
                end

                W_PREPARE: begin
                    if (write_enable && s_axis_write_data_tvalid && !s_axis_write_data_tready) begin
                        s_axis_write_data_tready <= 1;
                        wdata_reg <= s_axis_write_data_tdata;
                        wstrb_reg <= s_axis_write_data_tkeep;
                        wlast_reg <= s_axis_write_data_tlast;
                        if (s_axis_write_data_tlast) begin
                            wvalid_reg <= 1;
                        end
                        state <= W_SEND;
                    end else if (write_enable && s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                        s_axis_write_data_tready <= 0;
                        wdata_reg <= s_axis_write_data_tdata;
                        wstrb_reg <= s_axis_write_data_tkeep;
                        wlast_reg <= s_axis_write_data_tlast;
                        if (s_axis_write_data_tlast) begin
                            wvalid_reg <= 1;
                        end
                        state <= W_SEND;
                    end
                end

                W_SEND: begin
                    if (write_enable && m_axi_wready && wvalid_reg) begin
                        m_axi_wvalid <= 1;
                        m_axi_wdata <= wdata_reg;
                        m_axi_wstrb <= wstrb_reg;
                        m_axi_wlast <= wlast_reg;
                        state <= B_WAIT;
                   