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
    
    // Read Channel State
    localparam R_IDLE = 2'd0;
    localparam R_DESC = 2'd1;
    localparam R_AR   = 2'd2;
    localparam R_DATA = 2'd3;
    localparam R_DONE = 2'd4;

    // Write Channel State
    localparam W_IDLE = 2'd0;
    localparam W_DESC = 2'd1;
    localparam W_AW   = 2'd2;
    localparam W_DATA = 2'd3;
    localparam W_BRESP= 2'd4;
    localparam W_DONE = 2'd5;

    // Read State Register
    reg [1:0] r_state;
    reg [AXI_ADDR_WIDTH-1:0] r_addr;
    reg [LEN_WIDTH-1:0] r_len;
    reg [LEN_WIDTH-1:0] r_remaining;
    reg [TAG_WIDTH-1:0] r_tag;
    reg [AXIS_ID_WIDTH-1:0] r_id;
    reg [AXIS_DEST_WIDTH-1:0] r_dest;
    reg [AXIS_USER_WIDTH-1:0] r_user;
    reg [7:0] r_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] r_cur_addr;
    reg [LEN_WIDTH-1:0] r_burst_remaining;
    reg [3:0] r_error;
    reg r_status_valid;
    reg [TAG_WIDTH-1:0] r_status_tag;
    reg [3:0] r_status_error;

    // Write State Register
    reg [2:0] w_state;
    reg [AXI_ADDR_WIDTH-1:0] w_addr;
    reg [LEN_WIDTH-1:0] w_len;
    reg [LEN_WIDTH-1:0] w_remaining;
    reg [TAG_WIDTH-1:0] w_tag;
    reg [7:0] w_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] w_cur_addr;
    reg [LEN_WIDTH-1:0] w_burst_remaining;
    reg [3:0] w_error;
    reg w_status_valid;
    reg [LEN_WIDTH-1:0] w_status_len;
    reg [TAG_WIDTH-1:0] w_status_tag;
    reg [AXIS_ID_WIDTH-1:0] w_status_id;
    reg [AXIS_DEST_WIDTH-1:0] w_status_dest;
    reg [AXIS_USER_WIDTH-1:0] w_status_user;
    reg [3:0] w_status_error;

    // AXI Read Data Buffer
    reg [AXIS_DATA_WIDTH-1:0] r_data_buf;
    reg [AXIS_KEEP_WIDTH-1:0] r_keep_buf;
    reg r_data_valid;
    reg r_data_last;

    // AXI Write Data Buffer
    reg [AXIS_DATA_WIDTH-1:0] w_data_buf;
    reg [AXIS_KEEP_WIDTH-1:0] w_keep_buf;
    reg w_data_valid;
    reg w_data_last;

    // Handshake Signals
    wire r_desc_handshake = s_axis_read_desc_valid && s_axis_read_desc_ready;
    wire w_desc_handshake = s_axis_write_desc_valid && s_axis_write_desc_ready;
    wire r_data_handshake = m_axis_read_data_tvalid && m_axis_read_data_tready;
    wire w_data_handshake = s_axis_write_data_tvalid && s_axis_write_data_tready;

    // Read Descriptor Ready
    assign s_axis_read_desc_ready = (r_state == R_IDLE) && read_enable;

    // Write Descriptor Ready
    assign s_axis_write_desc_ready = (w_state == W_IDLE) && write_enable;

    // Read Data Output
    assign m_axis_read_data_tdata = r_data_buf;
    assign m_axis_read_data_tkeep = r_keep_buf;
    assign m_axis_read_data_tvalid = r_data_valid;
    assign m_axis_read_data_tlast = r_data_last;
    assign m_axis_read_data_tid = r_id;
    assign m_axis_read_data_tdest = r_dest;
    assign m_axis_read_data_tuser = r_user;

    // Write Data Ready
    assign s_axis_write_data_tready = (w_state == W_DATA) && w_data_valid;

    // Read Status Output
    assign m_axis_read_desc_status_tag = r_status_tag;
    assign m_axis_read_desc_status_error = r_status_error;
    assign m_axis_read_desc_status_valid = r_status_valid;

    // Write Status Output
    assign m_axis_write_desc_status_len = w_status_len;
    assign m_axis_write_desc_status_tag = w_status_tag;
    assign m_axis_write_desc_status_id = w_status_id;
    assign m_axis_write_desc_status_dest = w_status_dest;
    assign m_axis_write_desc_status_user = w_status_user;
    assign m_axis_write_desc_status_error = w_status_error;
    assign m_axis_write_desc_status_valid = w_status_valid;

    // AXI Read Address Channel
    assign m_axi_arid = {AXI_ID_WIDTH{1'b0}};
    assign m_axi_araddr = r_cur_addr;
    assign m_axi_arlen = r_burst_len - 1;
    assign m_axi_arsize = AXI_DATA_LOG2[2:0];
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011;
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = (r_state == R_AR);

    // AXI Read Data Channel
    assign m_axi_rready = (r_state == R_DATA);

    // AXI Write Address Channel
    assign m_axi_awid = {AXI_ID_WIDTH{1'b0}};
    assign m_axi_awaddr = w_cur_addr;
    assign m_axi_awlen = w_burst_len - 1;
    assign m_axi_awsize = AXI_DATA_LOG2[2:0];
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011;
    assign m_axi_awprot = 3'b000;
    assign m_axi_awvalid = (w_state == W_AW);

    // AXI Write Data Channel
    assign m_axi_wdata = w_data_buf;
    assign m_axi_wstrb = w_keep_buf;
    assign m_axi_wlast = w_data_last;
    assign m_axi_wvalid = (w_state == W_DATA) && w_data_valid;

    // AXI Write Response Channel
    assign m_axi_bready = (w_state == W_BRESP);

    // Read State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_state <= R_IDLE;
            r_addr <= {AXI_ADDR_WIDTH{1'b0}};
            r_len <= {LEN_WIDTH{1'b0}};
            r_remaining <= {LEN_WIDTH{1'b0}};
            r_tag <= {TAG_WIDTH{1'b0}};
            r_id <= {AXIS_ID_WIDTH{1'b0}};
            r_dest <= {AXIS_DEST_WIDTH{1'b0}};
            r_user <= {AXIS_USER_WIDTH{1'b0}};
            r_burst_len <= 8'd0;
            r_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            r_burst_remaining <= {LEN_WIDTH{1'b0}};
            r_error <= 4'd0;
            r_status_valid <= 1'b0;
            r_status_tag <= {TAG_WIDTH{1'b0}};
            r_status_error <= 4'd0;
            r_data_buf <= {AXIS_DATA_WIDTH{1'b0}};
            r_keep_buf <= {AXIS_KEEP_WIDTH{1'b0}};
            r_data_valid <= 1'b0;
            r_data_last <= 1'b0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    if (r_desc_handshake) begin
                        r_state <= R_DESC;
                        r_addr <= s_axis_read_desc_addr;
                        r_len <= s_axis_read_desc_len;
                        r_remaining <= s_axis_read_desc_len;
                        r_tag <= s_axis_read_desc_tag;
                        r_id <= s_axis_read_desc_id;
                        r_dest <= s_axis_read_desc_dest;
                        r_user <= s_axis_read_desc_user;
                        r_error <= 4'd0;
                    end
                end
                R_DESC: begin
                    if (r_remaining == 0) begin
                        r_state <= R_DONE;
                        r_status_valid <= 1'b1;
                        r_status_tag <= r_tag;
                        r_status_error <= r_error;
                    end else begin
                        r_state <= R_AR;
                        r_cur_addr <= r_addr;
                        if (r_remaining > AXI_MAX_BURST_LEN) begin
                            r_burst_len <= AXI_MAX_BURST_LEN[7:0];
                            r_burst_remaining <= AXI_MAX_BURST_LEN[LEN_WIDTH-1:0];
                        end else begin
                            r_burst_len <= r_remaining[7:0];
                            r_burst_remaining <= r_remaining;
                        end
                    end
                end
                R_AR: begin
                    if (m_axi_arready) begin
                        r_state <= R_DATA;
                    end
                end
                R_DATA: begin
                    if (m_axi_rvalid) begin
                        r_data_buf <= m_axi_rdata;
                        r_keep_buf <= {AXIS_KEEP_WIDTH{1'b1}};
                        r_data_valid <= 1'b1;
                        r_data_last <= m_axi_rlast;
                        
                        if (m_axi_rlast) begin
                            r_remaining <= r_remaining - r_burst_remaining;
                            r_addr <= r_addr + (r_burst_remaining * AXI_DATA_BYTES);
                            if (r_remaining == 0) begin
                                r_state <= R_DONE;
                                r_status_valid <= 1'b1;
                                r_status_tag <= r_tag;
                                r_status_error <= r_error;
                            end else begin
                                r_state <= R_AR;
                                r_cur_addr <= r_addr;
                                if (r_remaining > AXI_MAX_BURST_LEN) begin
                                    r_burst_len <= AXI_MAX_BURST_LEN[7:0];
                                    r_burst_remaining <= AXI_MAX_BURST_LEN[LEN_WIDTH-1:0];
                                end else begin
                                    r_burst_len <= r_remaining[7:0];
                                    r_burst_remaining <= r_remaining;
                                end
                            end
                        end
                    end
                end
                R_DONE: begin
                    r_state <= R_IDLE;
                    r_status_valid <= 1'b0;
                end
                default: begin
                    r_state <= R_IDLE;
                end
            endcase
            
            // Handle read data output handshake
            if (r_data_valid && r_data_handshake) begin
                r_data_valid <= 1'b0;
            end
        end
    end

    // Write State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_state <= W_IDLE;
            w_addr <= {AXI_ADDR_WIDTH{1'b0}};
            w_len <= {LEN_WIDTH{1'b0}};
            w_remaining <= {LEN_WIDTH{1'b0}};
            w_tag <= {TAG_WIDTH{1'b0}};
            w_burst_len <= 8'd0;
            w_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            w_burst_remaining <= {LEN_WIDTH{1'b0}};
            w_error <= 4'd0;
            w_status_valid <= 1'b0;
            w_status_len <= {LEN_WIDTH{1'b0}};
            w_status_tag <= {TAG_WIDTH{1'b0}};
            w_status_id <= {AXIS_ID_WIDTH{1'b0}};
            w_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            w_status_user <= {AXIS_USER_WIDTH{1'b0}};
            w_status_error <= 4'd0;
            w_data_buf <= {AXIS_DATA_WIDTH{1'b0}};
            w_keep_buf <= {AXIS_KEEP_WIDTH{1'b0}};
            w_data_valid <= 1'b0;
            w_data_last <= 1'b0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    if (w_desc_handshake) begin
                        w_state <= W_DESC;
                        w_addr <= s_axis_write_desc_addr;
                        w_len <= s_axis_write_desc_len;
                        w_remaining <= s_axis_write_desc_len;
                        w_tag <= s_axis_write_desc_tag;
                        w_error <= 4'd0;
                    end
                end
                W_DESC: begin
                    if (w_remaining == 0) begin
                        w_state <= W_DONE;
                        w_status_valid <= 1'b1;
                        w_status_len <= w_len;
                        w_status_tag <= w_tag;
                        w_status_id <= {AXIS_ID_WIDTH{1'b0}};
                        w_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
                        w_status_user <= {AXIS_USER_WIDTH{1'b0}};
                        w_status_error <= w_error;
                    end else begin
                        w_state <= W_AW;
                        w_cur_addr <= w_addr;
                        if (w_remaining > AXI_MAX_BURST_LEN) begin
                            w_burst_len <= AXI_MAX_BURST_LEN[7:0];
                            w_burst_remaining <= AXI_MAX_BURST_LEN[LEN_WIDTH-1:0];
                        end else begin
                            w_burst_len <= w_remaining[7:0];
                            w_burst_remaining <= w_remaining;
                        end
                    end
                end
                W_AW: begin
                    if (m_axi_awready) begin
                        w_state <= W_DATA;
                    end
                end
                W_DATA: begin
                    if (w_data_valid && w_data_handshake) begin
                        w_data_valid <= 1'b0;
                        if (w_data_last) begin
                            w_remaining <= w_remaining - w_burst_remaining;
                            w_addr <= w_addr + (w_burst_remaining * AXI_DATA_BYTES);
                            if (w_remaining == 0) begin
                                w_state <= W_BRESP;
                            end else begin
                                w_state <= W_AW;
                                w_cur_addr <= w_addr;
                                if (w_remaining > AXI_MAX_BURST_LEN) begin
                                    w_burst_len <= AXI_MAX_BURST_LEN[7:0];
                                    w_burst_remaining <= AXI_MAX_BURST_LEN[LEN_WIDTH-1:0];
                                end else begin
                                    w_burst_len <= w_remaining[7:0];
                                    w_burst_remaining <= w_remaining;
                                end
                            end
                        end
                    end else if (s_axis_write_data_tvalid && !w_data_valid) begin
                        w_data_buf <= s_axis_write_data_tdata;
                        w_keep_buf <= s_axis_write_data_tkeep;
                        w_data_valid <= 1'b1;
                        w_data_last <= s_axis_write_data_tlast;
                    end
                end
                W_BRESP: begin
                    if (m_axi_bvalid) begin
                        if (m_axi_bresp != 2'b00) begin
                            w_error <= 4'd1;
                        end
                        w_state <= W_DONE;
                        w_status_valid <= 1'b1;
                        w_status_len <= w_len;
                        w_status_tag <= w_tag;
                        w_status_id <= {AXIS_ID_WIDTH{1'b0}};
                        w_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
                        w_status_user <= {AXIS_USER_WIDTH{1'b0}};
                        w_status_error <= w_error;
                    end
                end
                W_DONE: begin
                    w_state <= W_IDLE;
                    w_status_valid <= 1'b0;
                end
                default: begin
                    w_state <= W_IDLE;
                end
            endcase
            
            // Handle write abort
            if (write_abort && (w_state == W_DATA || w_state == W_AW)) begin
                w_state <= W_IDLE;
                w_data_valid <= 1'b0;
                w_status_valid <= 1'b1;
                w_status_len <= w_len;
                w_status_tag <= w_tag;
                w_status_id <= {AXIS_ID_WIDTH{1'b0}};
                w_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
                w_status_user <= {AXIS_USER_WIDTH{1'b0}};
                w_status_error <= 4'd2;
            end
        end
    end

endmodule
