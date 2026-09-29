module axi_dma #(
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
) (
    input  wire                       clk,
    input  wire                       rst,
    // Read descriptor interface
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_read_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_read_desc_tag,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_read_desc_id,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_read_desc_dest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_read_desc_user,
    input  wire                       s_axis_read_desc_valid,
    output wire                       s_axis_read_desc_ready,
    // Read descriptor status
    output wire [TAG_WIDTH-1:0]       m_axis_read_desc_status_tag,
    output wire [3:0]                 m_axis_read_desc_status_error,
    output wire                       m_axis_read_desc_status_valid,
    // Read data stream
    output wire [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep,
    output wire                       m_axis_read_data_tvalid,
    input  wire                       m_axis_read_data_tready,
    output wire                       m_axis_read_data_tlast,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser,
    // Write descriptor interface
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_write_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_write_desc_tag,
    input  wire                       s_axis_write_desc_valid,
    output wire                       s_axis_write_desc_ready,
    // Write descriptor status
    output wire [LEN_WIDTH-1:0]       m_axis_write_desc_status_len,
    output wire [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_write_desc_status_id,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user,
    output wire [3:0]                 m_axis_write_desc_status_error,
    output wire                       m_axis_write_desc_status_valid,
    // Write data stream
    input  wire [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input  wire                       s_axis_write_data_tvalid,
    output wire                       s_axis_write_data_tready,
    input  wire                       s_axis_write_data_tlast,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,
    // AXI master interface
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
    // Configuration
    input  wire                       read_enable,
    input  wire                       write_enable,
    input  wire                       write_abort
);

    // Read DMA state machine
    localparam R_IDLE = 0, R_AR_SEND = 1, R_RCV = 2, R_STATUS = 3;
    reg [1:0] r_state;
    reg [LEN_WIDTH-1:0] r_len;
    reg [AXI_ADDR_WIDTH-1:0] r_addr;
    reg [TAG_WIDTH-1:0] r_tag;

    // Write DMA state machine
    localparam W_IDLE = 0, W_AW_SEND = 1, W_W_SEND = 2, W_B_SEND = 3, W_STATUS = 4;
    reg [2:0] w_state;
    reg [LEN_WIDTH-1:0] w_len;
    reg [AXI_ADDR_WIDTH-1:0] w_addr;
    reg [TAG_WIDTH-1:0] w_tag;

    // Read signals
    assign s_axis_read_desc_ready = (r_state == R_IDLE) && read_enable;
    assign m_axis_read_desc_status_valid = (r_state == R_STATUS);
    assign m_axis_read_desc_status_tag = r_tag;
    assign m_axis_read_desc_status_error = 4'b0;

    // Read data stream
    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tkeep = AXIS_KEEP_ENABLE ? {AXIS_KEEP_WIDTH{1'b1}} : 0;
    assign m_axis_read_data_tvalid = m_axi_rvalid && (r_state == R_RCV);
    assign m_axis_read_data_tlast = m_axi_rlast;
    assign m_axis_read_data_tid = s_axis_read_desc_id;
    assign m_axis_read_data_tdest = s_axis_read_desc_dest;
    assign m_axis_read_data_tuser = s_axis_read_desc_user;

    // Read AR channel
    assign m_axi_arid = s_axis_read_desc_id;
    assign m_axi_araddr = r_addr;
    assign m_axi_arlen = (r_len / (AXI_DATA_WIDTH/8)) - 1;
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0010; // MOD
    assign m_axi_arprot = 3'b000; // Unprivileged, secure, data
    assign m_axi_arvalid = (r_state == R_AR_SEND);

    // Read R channel
    assign m_axi_rready = (r_state == R_RCV);

    // Write signals
    assign s_axis_write_desc_ready = (w_state == W_IDLE) && write_enable;
    assign m_axis_write_desc_status_valid = (w_state == W_STATUS);
    assign m_axis_write_desc_status_len = w_len;
    assign m_axis_write_desc_status_tag = w_tag;
    assign m_axis_write_desc_status_id = s_axis_write_desc_id;
    assign m_axis_write_desc_status_dest = s_axis_write_desc_dest;
    assign m_axis_write_desc_status_user = s_axis_write_desc_user;
    assign m_axis_write_desc_status_error = 4'b0;

    // Write AW channel
    assign m_axi_awid = s_axis_write_desc_id;
    assign m_axi_awaddr = w_addr;
    assign m_axi_awlen = (w_len / (AXI_DATA_WIDTH/8)) - 1;
    assign m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0010; // MOD
    assign m_axi_awprot = 3'b000; // Unprivileged, secure, data
    assign m_axi_awvalid = (w_state == W_AW_SEND);

    // Write W channel
    assign m_axi_wdata = s_axis_write_data_tdata;
    assign m_axi_wstrb = {AXI_STRB_WIDTH{1'b1}};
    assign m_axi_wlast = (w_data_count == w_len);
    assign m_axi_wvalid = (w_state == W_W_SEND) && (w_data_count < w_len);

    // Write B channel
    assign m_axi_bready = (w_state == W_B_SEND);

    // Write data stream
    assign s_axis_write_data_tready = (w_state == W_W_SEND) && (w_data_count < w_len);

    // Read state machine
    reg [LEN_WIDTH-1:0] r_data_count;
    always @(posedge clk) begin
        if (rst) begin
            r_state <= R_IDLE;
            r_len <= 0;
            r_addr <= 0;
            r_tag <= 0;
            r_data_count <= 0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                        r_addr <= s_axis_read_desc_addr;
                        r_len <= s_axis_read_desc_len;
                        r_tag <= s_axis_read_desc_tag;
                        r_state <= R_AR_SEND;
                    end
                end
                R_AR_SEND: begin
                    if (m_axi_arready) begin
                        r_state <= R_RCV;
                        r_data_count <= 0;
                    end
                end
                R_RCV: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        r_data_count <= r_data_count + 1;
                        if (m_axi_rlast) begin
                            r_state <= R_STATUS;
                        end
                    end
                end
                R_STATUS: begin
                    if (m_axis_read_desc_status_valid) begin
                        r_state <= R_IDLE;
                    end
                end
            endcase
        end
    end

    // Write state machine
    reg [LEN_WIDTH-1:0] w_data_count;
    always @(posedge clk) begin
        if (rst) begin
            w_state <= W_IDLE;
            w_len <= 0;
            w_addr <= 0;
            w_tag <= 0;
            w_data_count <= 0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                        w_addr <= s_axis_write_desc_addr;
                        w_len <= s_axis_write_desc_len;
                        w_tag <= s_axis_write_desc_tag;
                        w_state <= W_AW_SEND;
                    end
                end
                W_AW_SEND: begin
                    if (m_axi_awready) begin
                        w_state <= W_W_SEND;
                        w_data_count <= 0;
                    end
                end
                W_W_SEND: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        w_data_count <= w_data_count + 1;
                        if (m_axi_wlast) begin
                            w_state <= W_B_SEND;
                        end
                    end
                end
                W_B_SEND: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        w_state <= W_STATUS;
                    end
                end
                W_STATUS: begin
                    if (m_axis_write_desc_status_valid) begin
                        w_state <= W_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
