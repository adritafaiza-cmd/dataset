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
    input wire clk,
    input wire rst,
    // Read descriptor input
    input wire [AXI_ADDR_WIDTH-1:0] s_axis_read_desc_addr,
    input wire [LEN_WIDTH-1:0] s_axis_read_desc_len,
    input wire [TAG_WIDTH-1:0] s_axis_read_desc_tag,
    input wire [AXIS_ID_WIDTH-1:0] s_axis_read_desc_id,
    input wire [AXIS_DEST_WIDTH-1:0] s_axis_read_desc_dest,
    input wire [AXIS_USER_WIDTH-1:0] s_axis_read_desc_user,
    input wire s_axis_read_desc_valid,
    output wire s_axis_read_desc_ready,
    // Read descriptor status output
    output wire [TAG_WIDTH-1:0] m_axis_read_desc_status_tag,
    output wire [3:0] m_axis_read_desc_status_error,
    output wire m_axis_read_desc_status_valid,
    // Read data output
    output wire [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep,
    output wire m_axis_read_data_tvalid,
    input wire m_axis_read_data_tready,
    output wire m_axis_read_data_tlast,
    output wire [AXIS_ID_WIDTH-1:0] m_axis_read_data_tid,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser,
    // Write descriptor input
    input wire [AXI_ADDR_WIDTH-1:0] s_axis_write_desc_addr,
    input wire [LEN_WIDTH-1:0] s_axis_write_desc_len,
    input wire [TAG_WIDTH-1:0] s_axis_write_desc_tag,
    input wire s_axis_write_desc_valid,
    output wire s_axis_write_desc_ready,
    // Write descriptor status output
    output wire [LEN_WIDTH-1:0] m_axis_write_desc_status_len,
    output wire [TAG_WIDTH-1:0] m_axis_write_desc_status_tag,
    output wire [AXIS_ID_WIDTH-1:0] m_axis_write_desc_status_id,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user,
    output wire [3:0] m_axis_write_desc_status_error,
    output wire m_axis_write_desc_status_valid,
    // Write data input
    input wire [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input wire s_axis_write_data_tvalid,
    output wire s_axis_write_data_tready,
    input wire s_axis_write_data_tlast,
    input wire [AXIS_ID_WIDTH-1:0] s_axis_write_data_tid,
    input wire [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
    input wire [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,
    // AXI master interface
    output wire [AXI_ID_WIDTH-1:0] m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output wire [7:0] m_axi_awlen,
    output wire [2:0] m_axi_awsize,
    output wire [1:0] m_axi_awburst,
    output wire m_axi_awlock,
    output wire [3:0] m_axi_awcache,
    output wire [2:0] m_axi_awprot,
    output wire m_axi_awvalid,
    input wire m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0] m_axi_wstrb,
    output wire m_axi_wlast,
    output wire m_axi_wvalid,
    input wire m_axi_wready,
    input wire [AXI_ID_WIDTH-1:0] m_axi_bid,
    input wire [1:0] m_axi_bresp,
    input wire m_axi_bvalid,
    output wire m_axi_bready,
    output wire [AXI_ID_WIDTH-1:0] m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,
    output wire [1:0] m_axi_arburst,
    output wire m_axi_arlock,
    output wire [3:0] m_axi_arcache,
    output wire [2:0] m_axi_arprot,
    output wire m_axi_arvalid,
    input wire m_axi_arready,
    input wire [AXI_ID_WIDTH-1:0] m_axi_rid,
    input wire [AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input wire [1:0] m_axi_rresp,
    input wire m_axi_rlast,
    input wire m_axi_rvalid,
    output wire m_axi_rready,
    // Configuration
    input wire read_enable,
    input wire write_enable,
    input wire write_abort
);

    // Read descriptor handling
    reg read_desc_ready;
    assign s_axis_read_desc_ready = read_desc_ready;

    reg [AXI_ADDR_WIDTH-1:0] read_addr_reg;
    reg [LEN_WIDTH-1:0] read_len_reg;
    reg [TAG_WIDTH-1:0] read_tag_reg;

    always @(posedge clk) begin
        if (rst) begin
            read_desc_ready <= 1;
        end else begin
            if (s_axis_read_desc_valid && read_desc_ready) begin
                read_addr_reg <= s_axis_read_desc_addr;
                read_len_reg <= s_axis_read_desc_len;
                read_tag_reg <= s_axis_read_desc_tag;
                read_desc_ready <= 0;
            end
        end
    end

    reg [TAG_WIDTH-1:0] read_status_tag;
    reg [3:0] read_status_error;
    reg read_status_valid;
    assign m_axis_read_desc_status_tag = read_status_tag;
    assign m_axis_read_desc_status_error = read_status_error;
    assign m_axis_read_desc_status_valid = read_status_valid;

    localparam READ_IDLE = 0;
    localparam READ_START = 1;
    localparam READ_WAIT = 2;
    localparam READ_DONE = 3;
    reg [1:0] read_state;

    reg [AXI_ADDR_WIDTH-1:0] m_axi_araddr_reg;
    reg [7:0] m_axi_arlen_reg;
    reg [2:0] m_axi_arsize_reg;
    reg [1:0] m_axi_arburst_reg;
    reg m_axi_arvalid_reg;

    assign m_axi_araddr = m_axi_araddr_reg;
    assign m_axi_arlen = m_axi_arlen_reg;
    assign m_axi_arsize = m_axi_arsize_reg;
    assign m_axi_arburst = m_axi_arburst_reg;
    assign m_axi_arvalid = m_axi_arvalid_reg;

    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tvalid = m_axi_rvalid;
    assign m_axis_read_data_tlast = m_axi_rlast;
    assign m_axis_read_data_tkeep = '0;
    assign m_axis_read_data_tid = '0;
    assign m_axis_read_data_tdest = '0;
    assign m_axis_read_data_tuser = '0;

    // Write descriptor handling
    reg write_desc_ready;
    assign s_axis_write_desc_ready = write_desc_ready;

    reg [AXI_ADDR_WIDTH-1:0] write_addr_reg;
    reg [LEN_WIDTH-1:0] write_len_reg;
    reg [TAG_WIDTH-1:0] write_tag_reg;

    always @(posedge clk) begin
        if (rst) begin
            write_desc_ready <= 1;
        end else begin
            if (s_axis_write_desc_valid && write_desc_ready) begin
                write_addr_reg <= s_axis_write_desc_addr;
                write_len_reg <= s_axis_write_desc_len;
                write_tag_reg <= s_axis_write_desc_tag;
                write_desc_ready <= 0;
            end
        end
    end

    reg [LEN_WIDTH-1:0] write_status_len;
    reg [TAG_WIDTH-1:0] write_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_status_user;
    reg [3:0] write_status_error;
    reg write_status_valid;
    assign m_axis_write_desc_status_len = write_status_len;
    assign m_axis_write_desc_status_tag = write_status_tag;
    assign m_axis_write_desc_status_id = write_status_id;
    assign m_axis_write_desc_status_dest = write_status_dest;
    assign m_axis_write_desc_status_user = write_status_user;
    assign m_axis_write_desc_status_error = write_status_error;
    assign m_axis_write_desc_status_valid = write_status_valid;

    localparam WRITE_IDLE = 0;
    localparam WRITE_START = 1;
    localparam WRITE_WAIT = 2;
    localparam WRITE_DONE = 3;
    reg [1:0] write_state;

    reg [AXI_ADDR_WIDTH-1:0] m_axi_awaddr_reg;
    reg [7:0] m_axi_awlen_reg;
    reg [2:0] m_axi_awsize_reg;
    reg [1:0] m_axi_awburst_reg;
    reg m_axi_awvalid_reg;
    reg [AXI_ID_WIDTH-1:0] m_axi_awid_reg;

    assign m_axi_awaddr = m_axi_awaddr_reg;
    assign m_axi_awlen = m_axi_awlen_reg;
    assign m_axi_awsize = m_axi_awsize_reg;
    assign m_axi_awburst = m_axi_awburst_reg;
    assign m_axi_awvalid = m_axi_awvalid_reg;
    assign m_axi_awid = m_axi_awid_reg;

    reg [AXI_DATA_WIDTH-1:0] m_axi_wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] m_axi_wstrb_reg;
    reg m_axi_wlast_reg;
    reg m_axi_wvalid_reg;

    assign m_axi_wdata = m_axi_wdata_reg;
    assign m_axi_wstrb = m_axi_wstrb_reg;
    assign m_axi_wlast = m_axi_wlast_reg;
    assign m_axi_wvalid = m_axi_wvalid_reg;

    assign s_axis_write_data_tready = m_axi_wready;

    assign m_axi_rready = 1;
    assign m_axi_bready = 1;

    // Read state machine
    always @(posedge clk) begin
        if (rst) begin
            read_state <= READ_IDLE;
            m_axi_arvalid_reg <= 0;
            read_status_valid <= 0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (!read_desc_ready) begin
                        m_axi_araddr_reg <= read_addr_reg;
                        m_axi_arlen_reg <= read_len_reg - 1;
                        m_axi_arsize_reg <= $clog2(AXI_DATA_WIDTH/8);
                        m_axi_arburst_reg <= 2'b01;
                        m_axi_arvalid_reg <= 1;
                        read_state <= READ_START;
                    end
                end
                READ_START: begin
                    if (m_axi_arready && m_axi_arvalid_reg) begin
                        m_axi_arvalid_reg <= 0;
                        read_state <= READ_WAIT;
                    end
                end
                READ_WAIT: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        if (m_axi_rlast) begin
                            read_status_tag <= read_tag_reg;
                            read_status_error <= 0;
                            read_status_valid <= 1;
                            read_state <= READ_DONE;
                        end
                    end
                end
                READ_DONE: begin
                    read_status_valid <= 0;
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end

    // Write state machine
    always @(posedge clk) begin
        if (rst) begin
            write_state <= WRITE_IDLE;
            m_axi_awvalid_reg <= 0;
            write_status_valid <= 0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (!write_desc_ready) begin
                        m_axi_awaddr_reg <= write_addr_reg;
                        m_axi_awlen_reg <= write_len_reg - 1;
                        m_axi_awsize_reg <= $clog2(AXI_DATA_WIDTH/8);
                        m_axi_awburst_reg <= 2'b01;
                        m_axi_awvalid_reg <= 1;
                        m_axi_awid_reg <= 0;
                        write_state <= WRITE_START;
                    end
                end
                WRITE_START: begin
                    if (m_axi_awready && m_axi_awvalid_reg) begin
                        m_axi_awvalid_reg <= 0;
                        m_axi_wvalid_reg <= 1;
                        m_axi_wlast_reg <= 0;
                        m_axi_wdata_reg <= s_axis_write_data_tdata;
                        m_axi_wstrb_reg <= s_axis_write_data_tkeep;
                        write_state <= WRITE_WAIT;
                    end
                end
                WRITE_WAIT: begin
                    if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                        if (s_axis_write_data_tlast) begin
                            m_axi_wlast_reg <= 1;
                        end
                        if (m_axi_wvalid_reg && m_axi_wready) begin
                            m_axi_wvalid_reg <= 0;
                            if (m_axi_wlast_reg) begin
                                write_status_len <= write_len_reg;
                                write_status_tag <= write_tag_reg;
                                write_status_id <= s_axis_write_data_tid;
                                write_status_dest <= s_axis_write_data_tdest;
                                write_status_user <= s_axis_write_data_tuser;
                                write_status_error <= 0;
                                write_status_valid <= 1;
                                write_state <= WRITE_DONE;
                            end
                        end
                    end
                end
                WRITE_DONE: begin
                    write_status_valid <= 0;
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end

endmodule
