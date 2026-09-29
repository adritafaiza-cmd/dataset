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
)(
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

    // Read descriptor handling
    reg [LEN_WIDTH-1:0] read_len;
    reg [AXI_ADDR_WIDTH-1:0] read_addr;
    reg [TAG_WIDTH-1:0] read_tag;
    reg [AXIS_ID_WIDTH-1:0] read_id;
    reg [AXIS_DEST_WIDTH-1:0] read_dest;
    reg [AXIS_USER_WIDTH-1:0] read_user;
    localparam R_IDLE = 0, R_AR = 1, R_DATA = 2, R_STATUS = 3;
    reg [1:0] read_state;

    assign s_axis_read_desc_ready = (read_state == R_IDLE) && read_enable;

    always @(posedge clk) begin
        if (rst) begin
            read_state <= R_IDLE;
        end else begin
            case (read_state)
                R_IDLE: begin
                    if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                        read_addr <= s_axis_read_desc_addr;
                        read_len <= s_axis_read_desc_len;
                        read_tag <= s_axis_read_desc_tag;
                        read_id <= s_axis_read_desc_id;
                        read_dest <= s_axis_read_desc_dest;
                        read_user <= s_axis_read_desc_user;
                        read_state <= R_AR;
                    end
                end
                R_AR: begin
                    if (m_axi_arready) begin
                        read_state <= R_DATA;
                    end
                end
                R_DATA: begin
                    if (m_axi_rvalid && m_axi_rlast) begin
                        read_state <= R_STATUS;
                    end
                end
                R_STATUS: begin
                    read_state <= R_IDLE;
                end
            endcase
        end
    end

    assign m_axi_arid = read_id;
    assign m_axi_araddr = read_addr;
    assign m_axi_arlen = read_len - 1;
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01;
    assign m_axi_arlock = 0;
    assign m_axi_arcache = 4'b0010;
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = (read_state == R_AR);

    assign m_axi_rready = (read_state == R_DATA) ? m_axis_read_data_tready : 0;

    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tvalid = (read_state == R_DATA) && m_axi_rvalid;
    assign m_axis_read_data_tlast = m_axi_rlast;

    generate
        if (AXIS_KEEP_ENABLE) begin
            assign m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
        end else begin
            assign m_axis_read_data_tkeep = 0;
        end
    endgenerate

    assign m_axis_read_data_tid = read_id;
    assign m_axis_read_data_tdest = read_dest;
    assign m_axis_read_data_tuser = read_user;

    assign m_axis_read_desc_status_tag = read_tag;
    assign m_axis_read_desc_status_error = 4'b0;
    assign m_axis_read_desc_status_valid = (read_state == R_STATUS);

    // Write descriptor handling
    reg [LEN_WIDTH-1:0] write_len;
    reg [AXI_ADDR_WIDTH-1:0] write_addr;
    reg [TAG_WIDTH-1:0] write_tag;
    reg [AXIS_ID_WIDTH-1:0] write_id;
    reg [AXIS_DEST_WIDTH-1:0] write_dest;
    reg [AXIS_USER_WIDTH-1:0] write_user;
    reg [LEN_WIDTH-1:0] write_count;
    localparam W_IDLE = 0, W_AW = 1, W_W = 2, W_B = 3, W_STATUS =4;
    reg [2:0] write_state;

    assign s_axis_write_desc_ready = (write_state == W_IDLE) && write_enable;

    always @(posedge clk) begin
        if (rst) begin
            write_state <= W_IDLE;
            write_count <= 0;
        end else begin
            case (write_state)
                W_IDLE: begin
                    if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                        write_addr <= s_axis_write_desc_addr;
                        write_len <= s_axis_write_desc_len;
                        write_tag <= s_axis_write_desc_tag;
                        write_id <= s_axis_write_desc_id;
                        write_dest <= s_axis_write_desc_dest;
                        write_user <= s_axis_write_desc_user;
                        write_count <= 0;
                        write_state <= W_AW;
                    end
                end
                W_AW: begin
                    if (m_axi_awready) begin
                        write_state <= W_W;
                    end
                end
                W_W: begin
                    if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                        if (write_count == write_len -1) begin
                            m_axi_wlast <= 1;
                        end
                        if (m_axi_wvalid && m_axi_wready) begin
                            write_count <= write_count + 1;
                            if (write_count == write_len -1) begin
                                write_state <= W_B;
                            end
                        end
                    end
                end
                W_B: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        write_state <= W_STATUS;
                    end
                end
                W_STATUS: begin
                    write_state <= W_IDLE;
                end
            endcase
        end
    end

    assign m_axi_awid = write_id;
    assign m_axi_awaddr = write_addr;
    assign m_axi_awlen = write_len - 1;
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01;
    assign m_axi_awlock = 0;
    assign m_axi_awcache = 4'b0010;
    assign m_axi_awprot = 3'b000;
    assign m_axi_awvalid = (write_state == W_AW);

    assign m_axi_wdata = s_axis_write_data_tdata;
    assign m_axi_wstrb = {AXI_STRB_WIDTH{1'b1}};
    assign m_axi_wvalid = (write_state == W_W) && s_axis_write_data_tvalid;
    assign m_axi_wlast = (write_count == write_len -1);
    assign s_axis_write_data_tready = (write_state == W_W) && m_axi_wready;

    assign m_axis_write_desc_status_len = write_len;
    assign m_axis_write_desc_status_tag = write_tag;
    assign m_axis_write_desc_status_id = write_id;
    assign m_axis_write_desc_status_dest = write_dest;
    assign m_axis_write_desc_status_user = write_user;
    assign m_axis_write_desc_status_error = m_axi_bresp;
    assign m_axis_write_desc_status_valid = (write_state == W_STATUS);

    // Stream control signals for write
    assign m_axis_write_data_tready = (write_state == W_W) && m_axi_wready;

    // Default assignments for unused signals
    assign m_axi_bready = 1;
    assign m_axi_rready = 1;

endmodule
