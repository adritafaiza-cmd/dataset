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
    localparam AXI_SIZE = $clog2(AXI_DATA_BYTES);
    localparam AXI_BURST_LEN_WIDTH = 8;
    localparam AXI_MAX_BURST = (AXI_MAX_BURST_LEN > 256) ? 256 : AXI_MAX_BURST_LEN;

    // State machine states
    localparam ST_IDLE = 2'd0;
    localparam ST_READ = 2'd1;
    localparam ST_WRITE = 2'd2;

    // Read channel state
    reg [1:0] read_state;
    reg [AXI_ADDR_WIDTH-1:0] read_addr;
    reg [LEN_WIDTH-1:0] read_len_remaining;
    reg [LEN_WIDTH-1:0] read_len_total;
    reg [TAG_WIDTH-1:0] read_tag;
    reg [AXIS_ID_WIDTH-1:0] read_id;
    reg [AXIS_DEST_WIDTH-1:0] read_dest;
    reg [AXIS_USER_WIDTH-1:0] read_user;
    reg [7:0] read_burst_len;
    reg [LEN_WIDTH-1:0] read_bytes_in_burst;
    reg [LEN_WIDTH-1:0] read_bytes_sent;
    reg [3:0] read_error;
    reg read_status_valid;
    reg [TAG_WIDTH-1:0] read_status_tag;
    reg [3:0] read_status_error;

    // Write channel state
    reg [1:0] write_state;
    reg [AXI_ADDR_WIDTH-1:0] write_addr;
    reg [LEN_WIDTH-1:0] write_len_remaining;
    reg [LEN_WIDTH-1:0] write_len_total;
    reg [TAG_WIDTH-1:0] write_tag;
    reg [7:0] write_burst_len;
    reg [LEN_WIDTH-1:0] write_bytes_in_burst;
    reg [LEN_WIDTH-1:0] write_bytes_sent;
    reg [3:0] write_error;
    reg write_status_valid;
    reg [LEN_WIDTH-1:0] write_status_len;
    reg [TAG_WIDTH-1:0] write_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_status_user;
    reg [3:0] write_status_error;

    // AXI read channel registers
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

    // AXI write channel registers
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

    // Read data FIFO (simple register-based)
    reg [AXIS_DATA_WIDTH-1:0] read_data_fifo [0:AXI_MAX_BURST_LEN-1];
    reg [AXIS_KEEP_WIDTH-1:0] read_keep_fifo [0:AXI_MAX_BURST_LEN-1];
    reg [7:0] read_fifo_wr_ptr;
    reg [7:0] read_fifo_rd_ptr;
    reg [7:0] read_fifo_count;

    // Write data FIFO
    reg [AXI_DATA_WIDTH-1:0] write_data_fifo [0:AXI_MAX_BURST_LEN-1];
    reg [AXI_STRB_WIDTH-1:0] write_strb_fifo [0:AXI_MAX_BURST_LEN-1];
    reg [7:0] write_fifo_wr_ptr;
    reg [7:0] write_fifo_rd_ptr;
    reg [7:0] write_fifo_count;

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

    // Read data output
    assign m_axis_read_data_tdata = read_data_fifo[read_fifo_rd_ptr];
    assign m_axis_read_data_tkeep = read_keep_fifo[read_fifo_rd_ptr];
    assign m_axis_read_data_tvalid = (read_fifo_count > 0);
    assign m_axis_read_data_tlast = (read_fifo_count == 1) && (read_bytes_sent == read_len_total);
    assign m_axis_read_data_tid = read_id;
    assign m_axis_read_data_tdest = read_dest;
    assign m_axis_read_data_tuser = read_user;

    // Write data input ready
    assign s_axis_write_data_tready = (write_state == ST_WRITE) && (write_fifo_count < AXI_MAX_BURST_LEN);

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
            read_state <= ST_IDLE;
            read_addr <= {AXI_ADDR_WIDTH{1'b0}};
            read_len_remaining <= {LEN_WIDTH{1'b0}};
            read_len_total <= {LEN_WIDTH{1'b0}};
            read_tag <= {TAG_WIDTH{1'b0}};
            read_id <= {AXIS_ID_WIDTH{1'b0}};
            read_dest <= {AXIS_DEST_WIDTH{1'b0}};
            read_user <= {AXIS_USER_WIDTH{1'b0}};
            read_burst_len <= 8'd0;
            read_bytes_in_burst <= {LEN_WIDTH{1'b0}};
            read_bytes_sent <= {LEN_WIDTH{1'b0}};
            read_error <= 4'd0;
            read_status_valid <= 1'b0;
            read_status_tag <= {TAG_WIDTH{1'b0}};
            read_status_error <= 4'd0;
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
            // Default: clear status valid
            read_status_valid <= 1'b0;

            case (read_state)
                ST_IDLE: begin
                    if (s_axis_read_desc_valid && read_enable) begin
                        read_state <= ST_READ;
                        read_addr <= s_axis_read_desc_addr;
                        read_len_remaining <= s_axis_read_desc_len;
                        read_len_total <= s_axis_read_desc_len;
                        read_tag <= s_axis_read_desc_tag;
                        read_id <= s_axis_read_desc_id;
                        read_dest <= s_axis_read_desc_dest;
                        read_user <= s_axis_read_desc_user;
                        read_bytes_sent <= {LEN_WIDTH{1'b0}};
                        read_error <= 4'd0;
                        read_burst_len <= calc_burst_len(s_axis_read_desc_len);
                        read_bytes_in_burst <= (read_burst_len + 1) * AXI_DATA_BYTES;
                        arid_reg <= {AXI_ID_WIDTH{1'b0}};
                        araddr_reg <= s_axis_read_desc_addr;
                        arlen_reg <= read_burst_len;
                        arsize_reg <= AXI_SIZE[2:0];
                        arburst_reg <= 2'b01; // INCR
                        arlock_reg <= 1'b0;
                        arcache_reg <= 4'b0011;
                        arprot_reg <= 3'b000;
                        arvalid_reg <= 1'b1;
                        rready_reg <= 1'b1;
                    end
                end
                ST_READ: begin
                    // Handle AR handshake
                    if (arvalid_reg && m_axi_arready) begin
                        arvalid_reg <= 1'b0;
                    end

                    // Handle R channel
                    if (m_axi_rvalid && rready_reg) begin
                        // Store data in FIFO
                        read_data_fifo[read_fifo_wr_ptr] <= m_axi_rdata;
                        read_keep_fifo[read_fifo_wr_ptr] <= {AXIS_KEEP_WIDTH{1'b1}};
                        read_fifo_wr_ptr <= read_fifo_wr_ptr + 1;
                        read_fifo_count <= read_fifo_count + 1;
                        read_bytes_sent <= read_bytes_sent + AXI_DATA_BYTES;

                        if (m_axi_rlast) begin
                            // Burst complete
                            read_len_remaining <= read_len_remaining - (read_burst_len + 1) * AXI_DATA_BYTES;
                            read_addr <= read_addr + (read_burst_len + 1) * AXI_DATA_BYTES;

                            if (read_len_remaining == 0) begin
                                // All data transferred
                                read_state <= ST_IDLE;
                                read_status_valid <= 1'b1;
                                read_status_tag <= read_tag;
                                read_status_error <= read_error;
                                rready_reg <= 1'b0;
                            end else begin
                                // Start next burst
                                read_burst_len <= calc_burst_len(read_len_remaining);
                                read_bytes_in_burst <= (read_burst_len + 1) * AXI_DATA_BYTES;
                                araddr_reg <= read_addr;
                                arlen_reg <= read_burst_len;
                                arvalid_reg <= 1'b1;
                            end
                        end
                    end

                    // Check for errors
                    if (m_axi_rvalid && (m_axi_rresp != 2'b00)) begin
                        read_error <= 4'd1;
                    end
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
            write_len_remaining <= {LEN_WIDTH{1'b0}};
            write_len_total <= {LEN_WIDTH{1'b0}};
            write_tag <= {TAG_WIDTH{1'b0}};
            write_burst_len <= 8'd0;
            write_bytes_in_burst <= {LEN_WIDTH{1'b0}};
            write_bytes_sent <= {LEN_WIDTH{1'b0}};
            write_error <= 4'd0;
            write_status_valid <= 1'b0;
            write_status_len <= {LEN_WIDTH{1'b0}};
            write_status_tag <= {TAG_WIDTH{1'b0}};
            write_status_id <= {AXIS_ID_WIDTH{1'b0}};
            write_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            write_status_user <= {AXIS_USER_WIDTH{1'b0}};
            write_status_error <= 4'd0;
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
            // Default: clear status valid
            write_status_valid <= 1'b0;

            case (write_state)
                ST_IDLE: begin
                    if (s_axis_write_desc_valid && write_enable) begin
                        write_state <= ST_WRITE;
                        write_addr <= s_axis_write_desc_addr;
                        write_len_remaining <= s_axis_write_desc_len;
                        write_len_total <= s_axis_write_desc_len;
                        write_tag <= s_axis_write_desc_tag;
                        write_bytes_sent <= {LEN_WIDTH{1'b0}};
                        write_error <= 4'd0;
                        write_burst_len <= calc_burst_len(s_axis_write_desc_len);
                        write_bytes_in_burst <= (write_burst_len + 1) * AXI_DATA_BYTES;
                        awid_reg <= {AXI_ID_WIDTH{1'b0}};
                        awaddr_reg <= s_axis_write_desc_addr;
                        awlen_reg <= write_burst_len;
                        awsize_reg <= AXI_SIZE[2:0];
                        awburst_reg <= 2'b01; // INCR
                        awlock_reg <= 1'b0;
                        awcache_reg <= 4'b0011;
                        awprot_reg <= 3'b000;
                        awvalid_reg <= 1'b1;
                        bready_reg <= 1'b1;
                    end
                end
                ST_WRITE: begin
                    // Handle AW handshake
                    if (awvalid_reg && m_axi_awready) begin
                        awvalid_reg <= 1'b0;
                    end

                    // Handle W channel
                    if (write_fifo_count > 0) begin
                        wdata_reg <= write_data_fifo[write_fifo_rd_ptr];
                        wstrb_reg <= write_strb_fifo[write_fifo_rd_ptr];
                        wlast_reg <= (write_fifo_count == 1) && (write_bytes_sent + AXI_DATA_BYTES >= write_len_total);
                        wvalid_reg <= 1'b1;
                    end else begin
                        wvalid_reg <= 1'b0;
                    end

                    if (m_axi_wvalid && m_axi_wready) begin
                        write_fifo_rd_ptr <= write_fifo_rd_ptr + 1;
                        write_fifo_count <= write_fifo_count - 1;
                        write_bytes_sent <= write_bytes_sent + AXI_DATA_BYTES;

                        if (m_axi_wlast) begin
                            // Burst complete
                            write_len_remaining <= write_len_remaining - (write_burst_len + 1) * AXI_DATA_BYTES;
                            write_addr <= write_addr + (write_burst_len + 1) * AXI_DATA_BYTES;

                            if (write_len_remaining == 0) begin
                                // All data transferred
                                write_state <= ST_IDLE;
                                write_status_valid <= 1'b1;
                                write_status_len <= write_len_total;
                                write_status_tag <= write_tag;
                                write_status_id <= {AXIS_ID_WIDTH{1'b0}};
                                write_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
                                write_status_user <= {AXIS_USER_WIDTH{1'b0}};
                                write_status_error <= write_error;
                                bready_reg <= 1'b0;
                            end else begin
                                // Start next burst
                                write_burst_len <= calc_burst_len(write_len_remaining);
                                write_bytes_in_burst <= (write_burst_len + 1) * AXI_DATA_BYTES;
                                awaddr_reg <= write_addr;
                                awlen_reg <= write_burst_len;
                                awvalid_reg <= 1'b1;
                            end
                        end
                    end

                    // Handle B channel
                    if (m_axi_bvalid && bready_reg) begin
                        if (m_axi_bresp != 2'b00) begin
                            write_error <= 4'd1;
                        end
                    end

                    // Handle abort
                    if (write_abort) begin
                        write_state <= ST_IDLE;
                        write_status_valid <= 1'b1;
                        write_status_len <= write_len_total - write_len_remaining;
                        write_status_tag <= write_tag;
                        write_status_id <= {AXIS_ID_WIDTH{1'b0}};
                        write_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
                        write_status_user <= {AXIS_USER_WIDTH{1'b0}};
                        write_status_error <= 4'd2;
                        bready_reg <= 1'b0;
                        wvalid_reg <= 1'b0;
                        awvalid_reg <= 1'b0;
                    end
                end
                default: begin
                    write_state <= ST_IDLE;
                end
            endcase
        end
    end

    // Write data FIFO write logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_fifo_wr_ptr <= 8'd0;
            write_fifo_rd_ptr <= 8'd0;
            write_fifo_count <= 8'd0;
        end else begin
            // Write to FIFO
            if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                write_data_fifo[write_fifo_wr_ptr] <= s_axis_write_data_tdata;
                write_strb_fifo[write_fifo_wr_ptr] <= {AXI_STRB_WIDTH{1'b1}};
                write_fifo_wr_ptr <= write_fifo_wr_ptr + 1;
                write_fifo_count <= write_fifo_count + 1;
            end

            // Read from FIFO
            if (m_axi_wvalid && m_axi_wready && (write_fifo_count > 0)) begin
                write_fifo_rd_ptr <= write_fifo_rd_ptr + 1;
                write_fifo_count <= write_fifo_count - 1;
            end

            // Reset FIFO pointers on state change to IDLE
            if (write_state == ST_IDLE) begin
                write_fifo_wr_ptr <= 8'd0;
                write_fifo_rd_ptr <= 8'd0;
                write_fifo_count <= 8'd0;
            end
        end
    end

    // Read data FIFO read logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_fifo_wr_ptr <= 8'd0;
            read_fifo_rd_ptr <= 8'd0;
            read_fifo_count <= 8'd0;
        end else begin
            // Write to FIFO
            if (m_axi_rvalid && rready_reg) begin
                read_fifo_wr_ptr <= read_fifo_wr_ptr + 1;
                read_fifo_count <= read_fifo_count + 1;
            end

            // Read from FIFO
            if (m_axis_read_data_tvalid && m_axis_read_data_tready) begin
                read_fifo_rd_ptr <= read_fifo_rd_ptr + 1;
                read_fifo_count <= read_fifo_count - 1;
            end

            // Reset FIFO pointers on state change to IDLE
            if (read_state == ST_IDLE) begin
                read_fifo_wr_ptr <= 8'd0;
                read_fifo_rd_ptr <= 8'd0;
                read_fifo_count <= 8'd0;
            end
        end
    end

endmodule
