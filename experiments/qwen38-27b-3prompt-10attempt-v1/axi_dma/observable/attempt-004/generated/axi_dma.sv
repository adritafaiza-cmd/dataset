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

    localparam AXI_DATA_BYTES = AXI_DATA_WIDTH / 8;
    localparam AXI_DATA_SIZE_LOG2 = $clog2(AXI_DATA_BYTES);
    localparam AXI_BURST_LEN_WIDTH = 8;
    localparam AXI_BURST_MAX = 256; // Max burst length for AXI4

    // State machine states
    localparam ST_IDLE = 2'd0;
    localparam ST_READ_DESC = 2'd1;
    localparam ST_WRITE_DESC = 2'd2;
    localparam ST_DONE = 2'd3;

    // Read channel state
    localparam RST_IDLE = 2'd0;
    localparam RST_ADDR = 2'd1;
    localparam RST_DATA = 2'd2;
    localparam RST_DONE = 2'd3;

    // Write channel state
    localparam WST_IDLE = 2'd0;
    localparam WST_ADDR = 2'd1;
    localparam WST_DATA = 2'd2;
    localparam WST_RESP = 2'd3;
    localparam WST_DONE = 2'd4;

    // Read state machine
    reg [1:0] r_state;
    reg [AXI_ADDR_WIDTH-1:0] r_addr;
    reg [LEN_WIDTH-1:0] r_len;
    reg [LEN_WIDTH-1:0] r_remaining;
    reg [TAG_WIDTH-1:0] r_tag;
    reg [AXIS_ID_WIDTH-1:0] r_id;
    reg [AXIS_DEST_WIDTH-1:0] r_dest;
    reg [AXIS_USER_WIDTH-1:0] r_user;
    reg [7:0] r_burst_len;
    reg [7:0] r_burst_count;
    reg r_burst_last;
    reg [AXI_ADDR_WIDTH-1:0] r_cur_addr;
    reg [LEN_WIDTH-1:0] r_bytes_in_burst;
    reg [LEN_WIDTH-1:0] r_bytes_sent;
    reg r_read_error;
    reg [3:0] r_error_code;

    // Write state machine
    reg [1:0] w_state;
    reg [AXI_ADDR_WIDTH-1:0] w_addr;
    reg [LEN_WIDTH-1:0] w_len;
    reg [LEN_WIDTH-1:0] w_remaining;
    reg [TAG_WIDTH-1:0] w_tag;
    reg [AXIS_ID_WIDTH-1:0] w_id;
    reg [AXIS_DEST_WIDTH-1:0] w_dest;
    reg [AXIS_USER_WIDTH-1:0] w_user;
    reg [7:0] w_burst_len;
    reg [7:0] w_burst_count;
    reg w_burst_last;
    reg [AXI_ADDR_WIDTH-1:0] w_cur_addr;
    reg [LEN_WIDTH-1:0] w_bytes_in_burst;
    reg [LEN_WIDTH-1:0] w_bytes_sent;
    reg w_write_error;
    reg [3:0] w_error_code;
    reg [AXI_DATA_WIDTH-1:0] w_data_reg;
    reg [AXI_STRB_WIDTH-1:0] w_strb_reg;
    reg w_wlast_reg;

    // Descriptor status
    reg [TAG_WIDTH-1:0] r_status_tag;
    reg [3:0] r_status_error;
    reg r_status_valid;
    reg [LEN_WIDTH-1:0] w_status_len;
    reg [TAG_WIDTH-1:0] w_status_tag;
    reg [AXIS_ID_WIDTH-1:0] w_status_id;
    reg [AXIS_DEST_WIDTH-1:0] w_status_dest;
    reg [AXIS_USER_WIDTH-1:0] w_status_user;
    reg [3:0] w_status_error;
    reg w_status_valid;

    // Read data output
    reg [AXIS_DATA_WIDTH-1:0] r_data_out;
    reg [AXIS_KEEP_WIDTH-1:0] r_keep_out;
    reg r_valid_out;
    reg r_last_out;
    reg [AXIS_ID_WIDTH-1:0] r_id_out;
    reg [AXIS_DEST_WIDTH-1:0] r_dest_out;
    reg [AXIS_USER_WIDTH-1:0] r_user_out;

    // Write data input
    reg w_ready_out;

    // AXI signals
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

    // Helper functions
    function [7:0] calc_burst_len;
        input [LEN_WIDTH-1:0] remaining;
        input [LEN_WIDTH-1:0] bytes_per_beat;
        begin
            if (remaining == 0)
                calc_burst_len = 0;
            else if (remaining <= bytes_per_beat)
                calc_burst_len = 1;
            else
                calc_burst_len = (remaining + bytes_per_beat - 1) / bytes_per_beat;
        end
    endfunction

    function [7:0] min_burst_len;
        input [7:0] len;
        begin
            if (len > AXI_MAX_BURST_LEN)
                min_burst_len = AXI_MAX_BURST_LEN;
            else
                min_burst_len = len;
        end
    endfunction

    // Read descriptor ready
    assign s_axis_read_desc_ready = (r_state == RST_IDLE) && read_enable;

    // Write descriptor ready
    assign s_axis_write_desc_ready = (w_state == WST_IDLE) && write_enable;

    // Read data output
    assign m_axis_read_data_tdata = r_data_out;
    assign m_axis_read_data_tkeep = r_keep_out;
    assign m_axis_read_data_tvalid = r_valid_out;
    assign m_axis_read_data_tlast = r_last_out;
    assign m_axis_read_data_tid = r_id_out;
    assign m_axis_read_data_tdest = r_dest_out;
    assign m_axis_read_data_tuser = r_user_out;

    // Write data ready
    assign s_axis_write_data_tready = w_ready_out;

    // Read status output
    assign m_axis_read_desc_status_tag = r_status_tag;
    assign m_axis_read_desc_status_error = r_status_error;
    assign m_axis_read_desc_status_valid = r_status_valid;

    // Write status output
    assign m_axis_write_desc_status_len = w_status_len;
    assign m_axis_write_desc_status_tag = w_status_tag;
    assign m_axis_write_desc_status_id = w_status_id;
    assign m_axis_write_desc_status_dest = w_status_dest;
    assign m_axis_write_desc_status_user = w_status_user;
    assign m_axis_write_desc_status_error = w_status_error;
    assign m_axis_write_desc_status_valid = w_status_valid;

    // AXI address channel
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

    // Read state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_state <= RST_IDLE;
            r_addr <= {AXI_ADDR_WIDTH{1'b0}};
            r_len <= {LEN_WIDTH{1'b0}};
            r_remaining <= {LEN_WIDTH{1'b0}};
            r_tag <= {TAG_WIDTH{1'b0}};
            r_id <= {AXIS_ID_WIDTH{1'b0}};
            r_dest <= {AXIS_DEST_WIDTH{1'b0}};
            r_user <= {AXIS_USER_WIDTH{1'b0}};
            r_burst_len <= 8'd0;
            r_burst_count <= 8'd0;
            r_burst_last <= 1'b0;
            r_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            r_bytes_in_burst <= {LEN_WIDTH{1'b0}};
            r_bytes_sent <= {LEN_WIDTH{1'b0}};
            r_read_error <= 1'b0;
            r_error_code <= 4'd0;
            r_data_out <= {AXIS_DATA_WIDTH{1'b0}};
            r_keep_out <= {AXIS_KEEP_WIDTH{1'b0}};
            r_valid_out <= 1'b0;
            r_last_out <= 1'b0;
            r_id_out <= {AXIS_ID_WIDTH{1'b0}};
            r_dest_out <= {AXIS_DEST_WIDTH{1'b0}};
            r_user_out <= {AXIS_USER_WIDTH{1'b0}};
            r_status_tag <= {TAG_WIDTH{1'b0}};
            r_status_error <= 4'd0;
            r_status_valid <= 1'b0;
            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            arlen_reg <= 8'd0;
            arsize_reg <= 3'd0;
            arburst_reg <= 2'd0;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'd0;
            arprot_reg <= 3'd0;
            arvalid_reg <= 1'b0;
            rready_reg <= 1'b0;
        end else begin
            r_status_valid <= 1'b0;

            case (r_state)
                RST_IDLE: begin
                    r_valid_out <= 1'b0;
                    r_last_out <= 1'b0;
                    rready_reg <= 1'b0;
                    arvalid_reg <= 1'b0;
                    if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                        r_addr <= s_axis_read_desc_addr;
                        r_len <= s_axis_read_desc_len;
                        r_remaining <= s_axis_read_desc_len;
                        r_tag <= s_axis_read_desc_tag;
                        r_id <= s_axis_read_desc_id;
                        r_dest <= s_axis_read_desc_dest;
                        r_user <= s_axis_read_desc_user;
                        r_cur_addr <= s_axis_read_desc_addr;
                        r_bytes_sent <= {LEN_WIDTH{1'b0}};
                        r_read_error <= 1'b0;
                        r_error_code <= 4'd0;
                        r_state <= RST_ADDR;
                    end
                end

                RST_ADDR: begin
                    if (r_remaining == 0) begin
                        r_state <= RST_DONE;
                    end else begin
                        // Calculate burst length
                        r_burst_len <= min_burst_len(calc_burst_len(r_remaining, AXI_DATA_BYTES));
                        r_burst_count <= r_burst_len;
                        r_burst_last <= (r_burst_len >= r_remaining / AXI_DATA_BYTES) ? 1'b1 : 1'b0;
                        r_bytes_in_burst <= r_burst_len * AXI_DATA_BYTES;
                        
                        // Prepare AXI read address
                        arid_reg <= {AXI_ID_WIDTH{1'b0}};
                        araddr_reg <= r_cur_addr;
                        arlen_reg <= r_burst_len - 1;
                        arsize_reg <= AXI_DATA_SIZE_LOG2[2:0];
                        arburst_reg <= 2'b01; // INCR
                        arlock_reg <= 1'b0;
                        arcache_reg <= 4'b0011;
                        arprot_reg <= 3'b000;
                        arvalid_reg <= 1'b1;
                        rready_reg <= 1'b1;
                        r_state <= RST_DATA;
                    end
                end

                RST_DATA: begin
                    if (arvalid_reg && m_axi_arready) begin
                        arvalid_reg <= 1'b0;
                    end
                    
                    if (m_axi_rvalid && rready_reg) begin
                        r_data_out <= m_axi_rdata;
                        r_keep_out <= {AXIS_KEEP_WIDTH{1'b1}};
                        r_id_out <= r_id;
                        r_dest_out <= r_dest;
                        r_user_out <= r_user;
                        r_valid_out <= 1'b1;
                        
                        if (m_axi_rlast) begin
                            r_last_out <= 1'b1;
                            r_burst_count <= r_burst_count - 1;
                            r_cur_addr <= r_cur_addr + (r_burst_count * AXI_DATA_BYTES);
                            r_bytes_sent <= r_bytes_sent + (r_burst_count * AXI_DATA_BYTES);
                            r_remaining <= r_remaining - (r_burst_count * AXI_DATA_BYTES);
                            
                            if (r_remaining == 0) begin
                                r_state <= RST_DONE;
                            end else begin
                                r_state <= RST_ADDR;
                            end
                        end else begin
                            r_last_out <= 1'b0;
                            r_burst_count <= r_burst_count - 1;
                            r_cur_addr <= r_cur_addr + AXI_DATA_BYTES;
                            r_bytes_sent <= r_bytes_sent + AXI_DATA_BYTES;
                            r_remaining <= r_remaining - AXI_DATA_BYTES;
                        end
                        
                        if (m_axi_rresp != 2'b00) begin
                            r_read_error <= 1'b1;
                            r_error_code <= 4'd1;
                        end
                    end
                end

                RST_DONE: begin
                    r_valid_out <= 1'b0;
                    r_last_out <= 1'b0;
                    rready_reg <= 1'b0;
                    r_status_tag <= r_tag;
                    r_status_error <= r_read_error ? r_error_code : 4'd0;
                    r_status_valid <= 1'b1;
                    r_state <= RST_IDLE;
                end

                default: r_state <= RST_IDLE;
            endcase
        end
    end

    // Write state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_state <= WST_IDLE;
            w_addr <= {AXI_ADDR_WIDTH{1'b0}};
            w_len <= {LEN_WIDTH{1'b0}};
            w_remaining <= {LEN_WIDTH{1'b0}};
            w_tag <= {TAG_WIDTH{1'b0}};
            w_id <= {AXIS_ID_WIDTH{1'b0}};
            w_dest <= {AXIS_DEST_WIDTH{1'b0}};
            w_user <= {AXIS_USER_WIDTH{1'b0}};
            w_burst_len <= 8'd0;
            w_burst_count <= 8'd0;
            w_burst_last <= 1'b0;
            w_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            w_bytes_in_burst <= {LEN_WIDTH{1'b0}};
            w_bytes_sent <= {LEN_WIDTH{1'b0}};
            w_write_error <= 1'b0;
            w_error_code <= 4'd0;
            w_data_reg <= {AXI_DATA_WIDTH{1'b0}};
            w_strb_reg <= {AXI_STRB_WIDTH{1'b0}};
            w_wlast_reg <= 1'b0;
            w_ready_out <= 1'b0;
            w_status_len <= {LEN_WIDTH{1'b0}};
            w_status_tag <= {TAG_WIDTH{1'b0}};
            w_status_id <= {AXIS_ID_WIDTH{1'b0}};
            w_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            w_status_user <= {AXIS_USER_WIDTH{1'b0}};
            w_status_error <= 4'd0;
            w_status_valid <= 1'b0;
            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            awlen_reg <= 8'd0;
            awsize_reg <= 3'd0;
            awburst_reg <= 2'd0;
            awlock_reg <= 1'b0;
            awcache_reg <= 4'd0;
            awprot_reg <= 3'd0;
            awvalid_reg <= 1'b0;
            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wlast_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;
        end else begin
            w_status_valid <= 1'b0;

            case (w_state)
                WST_IDLE: begin
                    w_ready_out <= 1'b0;
                    wvalid_reg <= 1'b0;
                    awvalid_reg <= 1'b0;
                    bready_reg <= 1'b0;
                    if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                        w_addr <= s_axis_write_desc_addr;
                        w_len <= s_axis_write_desc_len;
                        w_remaining <= s_axis_write_desc_len;
                        w_tag <= s_axis_write_desc_tag;
                        w_id <= s_axis_write_data_tid;
                        w_dest <= s_axis_write_data_tdest;
                        w_user <= s_axis_write_data_tuser;
                        w_cur_addr <= s_axis_write_desc_addr;
                        w_bytes_sent <= {LEN_WIDTH{1'b0}};
                        w_write_error <= 1'b0;
                        w_error_code <= 4'd0;
                        w_state <= WST_ADDR;
                    end
                end

                WST_ADDR: begin
                    if (w_remaining == 0) begin
                        w_state <= WST_DONE;
                    end else begin
                        // Calculate burst length
                        w_burst_len <= min_burst_len(calc_burst_len(w_remaining, AXI_DATA_BYTES));
                        w_burst_count <= w_burst_len;
                        w_burst_last <= (w_burst_len >= w_remaining / AXI_DATA_BYTES) ? 1'b1 : 1'b0;
                        w_bytes_in_burst <= w_burst_len * AXI_DATA_BYTES;
                        
                        // Prepare AXI write address
                        awid_reg <= {AXI_ID_WIDTH{1'b0}};
                        awaddr_reg <= w_cur_addr;
                        awlen_reg <= w_burst_len - 1;
                        awsize_reg <= AXI_DATA_SIZE_LOG2[2:0];
                        awburst_reg <= 2'b01; // INCR
                        awlock_reg <= 1'b0;
                        awcache_reg <= 4'b0011;
                        awprot_reg <= 3'b000;
                        awvalid_reg <= 1'b1;
                        w_ready_out <= 1'b1;
                        w_state <= WST_DATA;
                    end
                end

                WST_DATA: begin
                    if (awvalid_reg && m_axi_awready) begin
                        awvalid_reg <= 1'b0;
                    end
                    
                    if (s_axis_write_data_tvalid && w_ready_out) begin
                        wdata_reg <= s_axis_write_data_tdata;
                        wstrb_reg <= {AXI_STRB_WIDTH{1'b1}};
                        wlast_reg <= s_axis_write_data_tlast;
                        wvalid_reg <= 1'b1;
                        
                        if (s_axis_write_data_tlast) begin
                            w_burst_count <= w_burst_count - 1;
                            w_cur_addr <= w_cur_addr + (w_burst_count * AXI_DATA_BYTES);
                            w_bytes_sent <= w_bytes_sent + (w_burst_count * AXI_DATA_BYTES);
                            w_remaining <= w_remaining - (w_burst_count * AXI_DATA_BYTES);
                            
                            if (w_remaining == 0) begin
                                w_state <= WST_RESP;
                            end else begin
                                w_state <= WST_ADDR;
                            end
                        end else begin
                            w_burst_count <= w_burst_count - 1;
                            w_cur_addr <= w_cur_addr + AXI_DATA_BYTES;
                            w_bytes_sent <= w_bytes_sent + AXI_DATA_BYTES;
                            w_remaining <= w_remaining - AXI_DATA_BYTES;
                        end
                    end
                    
                    if (wvalid_reg && m_axi_wready) begin
                        wvalid_reg <= 1'b0;
                    end
                end

                WST_RESP: begin
                    bready_reg <= 1'b1;
                    if (m_axi_bvalid && bready_reg) begin
                        if (m_axi_bresp != 2'b00) begin
                            w_write_error <= 1'b1;
                            w_error_code <= 4'd1;
                        end
                        w_state <= WST_DONE;
                    end
                end

                WST_DONE: begin
                    w_ready_out <= 1'b0;
                    wvalid_reg <= 1'b0;
                    bready_reg <= 1'b0;
                    w_status_len <= w_len;
                    w_status_tag <= w_tag;
                    w_status_id <= w_id;
                    w_status_dest <= w_dest;
                    w_status_user <= w_user;
                    w_status_error <= w_write_error ? w_error_code : 4'd0;
                    w_status_valid <= 1'b1;
                    w_state <= WST_IDLE;
                end

                default: w_state <= WST_IDLE;
            endcase
        end
    end

endmodule
