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
    localparam ST_AXI  = 2'd2;
    localparam ST_DONE = 2'd3;

    // Read channel state
    reg [1:0] read_state;
    reg [AXI_ADDR_WIDTH-1:0] read_addr;
    reg [LEN_WIDTH-1:0] read_len;
    reg [LEN_WIDTH-1:0] read_remaining;
    reg [TAG_WIDTH-1:0] read_tag;
    reg [AXIS_ID_WIDTH-1:0] read_id;
    reg [AXIS_DEST_WIDTH-1:0] read_dest;
    reg [AXIS_USER_WIDTH-1:0] read_user;
    reg [7:0] read_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] read_cur_addr;
    reg [LEN_WIDTH-1:0] read_burst_remaining;
    reg read_burst_last;
    reg [3:0] read_error;
    reg read_status_valid;
    reg [TAG_WIDTH-1:0] read_status_tag;
    reg [3:0] read_status_error;

    // Write channel state
    reg [1:0] write_state;
    reg [AXI_ADDR_WIDTH-1:0] write_addr;
    reg [LEN_WIDTH-1:0] write_len;
    reg [LEN_WIDTH-1:0] write_remaining;
    reg [TAG_WIDTH-1:0] write_tag;
    reg [AXIS_ID_WIDTH-1:0] write_id;
    reg [AXIS_DEST_WIDTH-1:0] write_dest;
    reg [AXIS_USER_WIDTH-1:0] write_user;
    reg [7:0] write_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] write_cur_addr;
    reg [LEN_WIDTH-1:0] write_burst_remaining;
    reg write_burst_last;
    reg [3:0] write_error;
    reg write_status_valid;
    reg [LEN_WIDTH-1:0] write_status_len;
    reg [TAG_WIDTH-1:0] write_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_status_user;
    reg [3:0] write_status_error;

    // AXI write data buffer
    reg [AXIS_DATA_WIDTH-1:0] wdata_buf;
    reg [AXIS_KEEP_WIDTH-1:0] wkeep_buf;
    reg wlast_buf;
    reg wdata_valid;

    // AXI read data buffer
    reg [AXIS_DATA_WIDTH-1:0] rdata_buf;
    reg [AXIS_KEEP_WIDTH-1:0] rkeep_buf;
    reg rlast_buf;
    reg rdata_valid;

    // Helper functions
    function [7:0] calc_burst_len;
        input [LEN_WIDTH-1:0] remaining;
        begin
            if (remaining >= AXI_MAX_BURST_LEN)
                calc_burst_len = AXI_MAX_BURST_LEN - 1;
            else
                calc_burst_len = remaining[7:0] - 1;
        end
    endfunction

    // Read descriptor ready
    assign s_axis_read_desc_ready = (read_state == ST_IDLE) && read_enable;

    // Write descriptor ready
    assign s_axis_write_desc_ready = (write_state == ST_IDLE) && write_enable;

    // Read data output
    assign m_axis_read_data_tdata = rdata_buf;
    assign m_axis_read_data_tkeep = rkeep_buf;
    assign m_axis_read_data_tvalid = rdata_valid;
    assign m_axis_read_data_tlast = rlast_buf;
    assign m_axis_read_data_tid = read_id;
    assign m_axis_read_data_tdest = read_dest;
    assign m_axis_read_data_tuser = read_user;

    // Write data ready
    assign s_axis_write_data_tready = (write_state == ST_AXI) && !wdata_valid && m_axi_wready;

    // Read status output
    assign m_axis_read_desc_status_tag = read_status_tag;
    assign m_axis_read_desc_status_error = read_status_error;
    assign m_axis_read_desc_status_valid = read_status_valid;

    // Write status output
    assign m_axis_write_desc_status_len = write_status_len;
    assign m_axis_write_desc_status_tag = write_status_tag;
    assign m_axis_write_desc_status_id = write_status_id;
    assign m_axis_write_desc_status_dest = write_status_dest;
    assign m_axis_write_desc_status_user = write_status_user;
    assign m_axis_write_desc_status_error = write_status_error;
    assign m_axis_write_desc_status_valid = write_status_valid;

    // AXI AW channel
    assign m_axi_awid = {AXI_ID_WIDTH{1'b0}};
    assign m_axi_awaddr = write_cur_addr;
    assign m_axi_awlen = write_burst_len;
    assign m_axi_awsize = AXI_DATA_LOG2[2:0];
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011;
    assign m_axi_awprot = 3'b000;
    assign m_axi_awvalid = (write_state == ST_AXI) && !wdata_valid && !m_axi_wready;

    // AXI W channel
    assign m_axi_wdata = wdata_buf;
    assign m_axi_wstrb = wkeep_buf;
    assign m_axi_wlast = wlast_buf;
    assign m_axi_wvalid = wdata_valid;

    // AXI B channel
    assign m_axi_bready = (write_state == ST_AXI);

    // AXI AR channel
    assign m_axi_arid = {AXI_ID_WIDTH{1'b0}};
    assign m_axi_araddr = read_cur_addr;
    assign m_axi_arlen = read_burst_len;
    assign m_axi_arsize = AXI_DATA_LOG2[2:0];
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011;
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = (read_state == ST_AXI) && !rdata_valid;

    // AXI R channel
    assign m_axi_rready = (read_state == ST_AXI) && !rdata_valid;

    // Read state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= ST_IDLE;
            read_addr <= {AXI_ADDR_WIDTH{1'b0}};
            read_len <= {LEN_WIDTH{1'b0}};
            read_remaining <= {LEN_WIDTH{1'b0}};
            read_tag <= {TAG_WIDTH{1'b0}};
            read_id <= {AXIS_ID_WIDTH{1'b0}};
            read_dest <= {AXIS_DEST_WIDTH{1'b0}};
            read_user <= {AXIS_USER_WIDTH{1'b0}};
            read_burst_len <= 8'd0;
            read_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            read_burst_remaining <= {LEN_WIDTH{1'b0}};
            read_burst_last <= 1'b0;
            read_error <= 4'd0;
            read_status_valid <= 1'b0;
            read_status_tag <= {TAG_WIDTH{1'b0}};
            read_status_error <= 4'd0;
            rdata_valid <= 1'b0;
            rdata_buf <= {AXIS_DATA_WIDTH{1'b0}};
            rkeep_buf <= {AXIS_KEEP_WIDTH{1'b0}};
            rlast_buf <= 1'b0;
        end else begin
            // Clear status valid when consumed
            if (read_status_valid) begin
                read_status_valid <= 1'b0;
            end

            case (read_state)
                ST_IDLE: begin
                    if (s_axis_read_desc_valid && read_enable) begin
                        read_state <= ST_DESC;
                        read_addr <= s_axis_read_desc_addr;
                        read_len <= s_axis_read_desc_len;
                        read_remaining <= s_axis_read_desc_len;
                        read_tag <= s_axis_read_desc_tag;
                        read_id <= s_axis_read_desc_id;
                        read_dest <= s_axis_read_desc_dest;
                        read_user <= s_axis_read_desc_user;
                        read_error <= 4'd0;
                    end
                end
                ST_DESC: begin
                    if (read_len == 0) begin
                        read_state <= ST_DONE;
                        read_status_valid <= 1'b1;
                        read_status_tag <= read_tag;
                        read_status_error <= read_error;
                    end else begin
                        read_state <= ST_AXI;
                        read_cur_addr <= read_addr;
                        read_burst_len <= calc_burst_len(read_remaining);
                        read_burst_remaining <= read_burst_len + 1;
                        read_burst_last <= (read_burst_len + 1 >= read_remaining);
                    end
                end
                ST_AXI: begin
                    // Issue AR when ready
                    if (m_axi_arready && !rdata_valid) begin
                        // Wait for R data
                    end

                    // Handle R data
                    if (m_axi_rvalid && m_axi_rready) begin
                        rdata_valid <= 1'b1;
                        rdata_buf <= m_axi_rdata;
                        rkeep_buf <= {AXIS_KEEP_WIDTH{1'b1}};
                        rlast_buf <= m_axi_rlast;
                    end

                    // Consume R data
                    if (rdata_valid && m_axis_read_data_tready) begin
                        rdata_valid <= 1'b0;
                        read_burst_remaining <= read_burst_remaining - 1;
                        read_remaining <= read_remaining - 1;
                        read_cur_addr <= read_cur_addr + AXI_DATA_BYTES;

                        if (m_axi_rlast) begin
                            if (read_remaining == 0) begin
                                read_state <= ST_DONE;
                                read_status_valid <= 1'b1;
                                read_status_tag <= read_tag;
                                read_status_error <= read_error;
                            end else begin
                                read_cur_addr <= read_addr + (read_len - read_remaining) * AXI_DATA_BYTES;
                                read_burst_len <= calc_burst_len(read_remaining);
                                read_burst_remaining <= read_burst_len + 1;
                                read_burst_last <= (read_burst_len + 1 >= read_remaining);
                            end
                        end
                    end
                end
                ST_DONE: begin
                    read_state <= ST_IDLE;
                end
                default: begin
                    read_state <= ST_IDLE;
                end
            endcase
        end
    end

    // Write state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= ST_IDLE;
            write_addr <= {AXI_ADDR_WIDTH{1'b0}};
            write_len <= {LEN_WIDTH{1'b0}};
            write_remaining <= {LEN_WIDTH{1'b0}};
            write_tag <= {TAG_WIDTH{1'b0}};
            write_id <= {AXIS_ID_WIDTH{1'b0}};
            write_dest <= {AXIS_DEST_WIDTH{1'b0}};
            write_user <= {AXIS_USER_WIDTH{1'b0}};
            write_burst_len <= 8'd0;
            write_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            write_burst_remaining <= {LEN_WIDTH{1'b0}};
            write_burst_last <= 1'b0;
            write_error <= 4'd0;
            write_status_valid <= 1'b0;
            write_status_len <= {LEN_WIDTH{1'b0}};
            write_status_tag <= {TAG_WIDTH{1'b0}};
            write_status_id <= {AXIS_ID_WIDTH{1'b0}};
            write_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            write_status_user <= {AXIS_USER_WIDTH{1'b0}};
            write_status_error <= 4'd0;
            wdata_valid <= 1'b0;
            wdata_buf <= {AXIS_DATA_WIDTH{1'b0}};
            wkeep_buf <= {AXIS_KEEP_WIDTH{1'b0}};
            wlast_buf <= 1'b0;
        end else begin
            // Clear status valid when consumed
            if (write_status_valid) begin
                write_status_valid <= 1'b0;
            end

            // Handle write abort
            if (write_abort && write_state != ST_IDLE) begin
                write_state <= ST_IDLE;
                wdata_valid <= 1'b0;
                write_status_valid <= 1'b1;
                write_status_len <= write_len - write_remaining;
                write_status_tag <= write_tag;
                write_status_id <= write_id;
                write_status_dest <= write_dest;
                write_status_user <= write_user;
                write_status_error <= 4'd1;
            end else begin
                case (write_state)
                    ST_IDLE: begin
                        if (s_axis_write_desc_valid && write_enable) begin
                            write_state <= ST_DESC;
                            write_addr <= s_axis_write_desc_addr;
                            write_len <= s_axis_write_desc_len;
                            write_remaining <= s_axis_write_desc_len;
                            write_tag <= s_axis_write_desc_tag;
                            write_id <= s_axis_write_data_tid;
                            write_dest <= s_axis_write_data_tdest;
                            write_user <= s_axis_write_data_tuser;
                            write_error <= 4'd0;
                        end
                    end
                    ST_DESC: begin
                        if (write_len == 0) begin
                            write_state <= ST_DONE;
                            write_status_valid <= 1'b1;
                            write_status_len <= write_len;
                            write_status_tag <= write_tag;
                            write_status_id <= write_id;
                            write_status_dest <= write_dest;
                            write_status_user <= write_user;
                            write_status_error <= write_error;
                        end else begin
                            write_state <= ST_AXI;
                            write_cur_addr <= write_addr;
                            write_burst_len <= calc_burst_len(write_remaining);
                            write_burst_remaining <= write_burst_len + 1;
                            write_burst_last <= (write_burst_len + 1 >= write_remaining);
                        end
                    end
                    ST_AXI: begin
                        // Issue AW when ready
                        if (m_axi_awready && !wdata_valid) begin
                            // Wait for W data
                        end

                        // Accept W data from AXIS
                        if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                            wdata_valid <= 1'b1;
                            wdata_buf <= s_axis_write_data_tdata;
                            wkeep_buf <= s_axis_write_data_tkeep;
                            wlast_buf <= s_axis_write_data_tlast;
                        end

                        // Send W data to AXI
                        if (wdata_valid && m_axi_wready) begin
                            wdata_valid <= 1'b0;
                            write_burst_remaining <= write_burst_remaining - 1;
                            write_remaining <= write_remaining - 1;
                            write_cur_addr <= write_cur_addr + AXI_DATA_BYTES;

                            if (s_axis_write_data_tlast) begin
                                if (write_remaining == 0) begin
                                    write_state <= ST_DONE;
                                    write_status_valid <= 1'b1;
                                    write_status_len <= write_len;
                                    write_status_tag <= write_tag;
                                    write_status_id <= write_id;
                                    write_status_dest <= write_dest;
                                    write_status_user <= write_user;
                                    write_status_error <= write_error;
                                end else begin
                                    write_cur_addr <= write_addr + (write_len - write_remaining) * AXI_DATA_BYTES;
                                    write_burst_len <= calc_burst_len(write_remaining);
                                    write_burst_remaining <= write_burst_len + 1;
                                    write_burst_last <= (write_burst_len + 1 >= write_remaining);
                                end
                            end
                        end

                        // Handle B response
                        if (m_axi_bvalid && m_axi_bready) begin
                            if (m_axi_bresp != 2'b00) begin
                                write_error <= {2'b00, m_axi_bresp};
                            end
                        end
                    end
                    ST_DONE: begin
                        write_state <= ST_IDLE;
                    end
                    default: begin
                        write_state <= ST_IDLE;
                    end
                endcase
            end
        end
    end

endmodule
