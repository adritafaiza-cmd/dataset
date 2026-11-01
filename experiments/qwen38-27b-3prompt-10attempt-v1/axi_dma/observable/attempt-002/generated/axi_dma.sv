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
    localparam AXI_MAX_BURST = (AXI_MAX_BURST_LEN > 1) ? AXI_MAX_BURST_LEN : 1;

    // State machine states
    localparam ST_IDLE = 2'd0;
    localparam ST_READ_DESC = 2'd1;
    localparam ST_WRITE_DESC = 2'd2;
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
    reg [3:0] read_error;
    reg read_status_valid;
    reg [TAG_WIDTH-1:0] read_status_tag;

    // Write channel state
    reg [1:0] write_state;
    reg [AXI_ADDR_WIDTH-1:0] write_addr;
    reg [LEN_WIDTH-1:0] write_len;
    reg [LEN_WIDTH-1:0] write_remaining;
    reg [TAG_WIDTH-1:0] write_tag;
    reg [AXIS_ID_WIDTH-1:0] write_id;
    reg [AXIS_DEST_WIDTH-1:0] write_dest;
    reg [AXIS_USER_WIDTH-1:0] write_user;
    reg [3:0] write_error;
    reg write_status_valid;
    reg [LEN_WIDTH-1:0] write_status_len;
    reg [TAG_WIDTH-1:0] write_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_status_user;

    // AXI Read Channel
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg arvalid_reg;
    reg arready_int;
    reg [LEN_WIDTH-1:0] ar_burst_remaining;
    reg [LEN_WIDTH-1:0] ar_total_remaining;
    reg [AXI_ADDR_WIDTH-1:0] ar_next_addr;
    reg ar_burst_active;

    // AXI Write Channel
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg awvalid_reg;
    reg awready_int;
    reg [LEN_WIDTH-1:0] aw_burst_remaining;
    reg [LEN_WIDTH-1:0] aw_total_remaining;
    reg [AXI_ADDR_WIDTH-1:0] aw_next_addr;
    reg aw_burst_active;
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;
    reg wready_int;
    reg [LEN_WIDTH-1:0] w_beat_count;
    reg [LEN_WIDTH-1:0] w_burst_len;

    // Read data FIFO (simple register-based)
    reg [AXIS_DATA_WIDTH-1:0] rdata_fifo [0:AXI_MAX_BURST_LEN-1];
    reg [AXIS_KEEP_WIDTH-1:0] rkeep_fifo [0:AXI_MAX_BURST_LEN-1];
    reg [LEN_WIDTH-1:0] rdata_fifo_wr_ptr;
    reg [LEN_WIDTH-1:0] rdata_fifo_rd_ptr;
    reg [LEN_WIDTH-1:0] rdata_fifo_count;
    reg rdata_fifo_empty;
    reg rdata_fifo_full;

    // Write data FIFO
    reg [AXIS_DATA_WIDTH-1:0] wdata_fifo [0:AXI_MAX_BURST_LEN-1];
    reg [AXIS_KEEP_WIDTH-1:0] wkeep_fifo [0:AXI_MAX_BURST_LEN-1];
    reg [LEN_WIDTH-1:0] wdata_fifo_wr_ptr;
    reg [LEN_WIDTH-1:0] wdata_fifo_rd_ptr;
    reg [LEN_WIDTH-1:0] wdata_fifo_count;
    reg wdata_fifo_empty;
    reg wdata_fifo_full;

    // Helper functions
    function [7:0] calc_burst_len;
        input [LEN_WIDTH-1:0] remaining;
        begin
            if (remaining >= AXI_MAX_BURST)
                calc_burst_len = AXI_MAX_BURST - 1;
            else
                calc_burst_len = remaining - 1;
        end
    endfunction

    function [AXI_STRB_WIDTH-1:0] calc_strb;
        input [AXIS_KEEP_WIDTH-1:0] keep;
        integer i;
        begin
            calc_strb = {AXI_STRB_WIDTH{1'b0}};
            for (i = 0; i < AXI_STRB_WIDTH; i = i + 1) begin
                if (keep[i])
                    calc_strb[i] = 1'b1;
            end
        end
    endfunction

    // Read descriptor ready
    assign s_axis_read_desc_ready = (read_state == ST_IDLE) && read_enable;

    // Write descriptor ready
    assign s_axis_write_desc_ready = (write_state == ST_IDLE) && write_enable;

    // Read status output
    assign m_axis_read_desc_status_tag = read_status_tag;
    assign m_axis_read_desc_status_error = read_error;
    assign m_axis_read_desc_status_valid = read_status_valid;

    // Write status output
    assign m_axis_write_desc_status_len = write_status_len;
    assign m_axis_write_desc_status_tag = write_status_tag;
    assign m_axis_write_desc_status_id = write_status_id;
    assign m_axis_write_desc_status_dest = write_status_dest;
    assign m_axis_write_desc_status_user = write_status_user;
    assign m_axis_write_desc_status_error = write_error;
    assign m_axis_write_desc_status_valid = write_status_valid;

    // Read data output
    assign m_axis_read_data_tdata = rdata_fifo[rdata_fifo_rd_ptr];
    assign m_axis_read_data_tkeep = rkeep_fifo[rdata_fifo_rd_ptr];
    assign m_axis_read_data_tvalid = !rdata_fifo_empty;
    assign m_axis_read_data_tlast = (rdata_fifo_count == 1);
    assign m_axis_read_data_tid = read_id;
    assign m_axis_read_data_tdest = read_dest;
    assign m_axis_read_data_tuser = read_user;

    // Write data input ready
    assign s_axis_write_data_tready = !wdata_fifo_full && (write_state != ST_IDLE);

    // AXI Read Address Channel
    assign m_axi_arid = arid_reg;
    assign m_axi_araddr = araddr_reg;
    assign m_axi_arlen = arlen_reg;
    assign m_axi_arsize = arsize_reg;
    assign m_axi_arburst = arburst_reg;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011;
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = arvalid_reg;
    assign arready_int = m_axi_arready;

    // AXI Read Data Channel
    assign m_axi_rready = !rdata_fifo_full;

    // AXI Write Address Channel
    assign m_axi_awid = awid_reg;
    assign m_axi_awaddr = awaddr_reg;
    assign m_axi_awlen = awlen_reg;
    assign m_axi_awsize = awsize_reg;
    assign m_axi_awburst = awburst_reg;
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011;
    assign m_axi_awprot = 3'b000;
    assign m_axi_awvalid = awvalid_reg;
    assign awready_int = m_axi_awready;

    // AXI Write Data Channel
    assign m_axi_wdata = wdata_reg;
    assign m_axi_wstrb = wstrb_reg;
    assign m_axi_wlast = wlast_reg;
    assign m_axi_wvalid = wvalid_reg;
    assign wready_int = m_axi_wready;

    // AXI Write Response Channel
    assign m_axi_bready = 1'b1;

    // FIFO empty/full signals
    assign rdata_fifo_empty = (rdata_fifo_count == 0);
    assign rdata_fifo_full = (rdata_fifo_count == AXI_MAX_BURST_LEN);
    assign wdata_fifo_empty = (wdata_fifo_count == 0);
    assign wdata_fifo_full = (wdata_fifo_count == AXI_MAX_BURST_LEN);

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
            read_error <= 4'b0000;
            read_status_valid <= 1'b0;
            read_status_tag <= {TAG_WIDTH{1'b0}};
            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            arlen_reg <= 8'd0;
            arsize_reg <= 3'd0;
            arburst_reg <= 2'b01;
            arvalid_reg <= 1'b0;
            ar_burst_remaining <= {LEN_WIDTH{1'b0}};
            ar_total_remaining <= {LEN_WIDTH{1'b0}};
            ar_next_addr <= {AXI_ADDR_WIDTH{1'b0}};
            ar_burst_active <= 1'b0;
        end else begin
            // Default: clear status valid
            read_status_valid <= 1'b0;

            case (read_state)
                ST_IDLE: begin
                    if (s_axis_read_desc_valid && read_enable) begin
                        read_state <= ST_READ_DESC;
                        read_addr <= s_axis_read_desc_addr;
                        read_len <= s_axis_read_desc_len;
                        read_remaining <= s_axis_read_desc_len;
                        read_tag <= s_axis_read_desc_tag;
                        read_id <= s_axis_read_desc_id;
                        read_dest <= s_axis_read_desc_dest;
                        read_user <= s_axis_read_desc_user;
                        read_error <= 4'b0000;
                        ar_total_remaining <= s_axis_read_desc_len;
                        ar_burst_active <= 1'b0;
                        arvalid_reg <= 1'b0;
                    end
                end

                ST_READ_DESC: begin
                    if (!ar_burst_active) begin
                        if (ar_total_remaining > 0) begin
                            // Start new burst
                            ar_burst_active <= 1'b1;
                            arid_reg <= read_id;
                            araddr_reg <= ar_next_addr;
                            arlen_reg <= calc_burst_len(ar_total_remaining);
                            arsize_reg <= AXI_SIZE[2:0];
                            arburst_reg <= 2'b01; // INCR
                            arvalid_reg <= 1'b1;
                            ar_burst_remaining <= calc_burst_len(ar_total_remaining) + 1;
                        end else begin
                            // Done
                            read_state <= ST_IDLE;
                            read_status_valid <= 1'b1;
                            read_status_tag <= read_tag;
                        end
                    end else begin
                        if (arvalid_reg && m_axi_arready) begin
                            arvalid_reg <= 1'b0;
                        end
                    end
                end

                default: begin
                    read_state <= ST_IDLE;
                end
            endcase

            // Update ar_next_addr when burst completes
            if (ar_burst_active && m_axi_rvalid && m_axi_rlast && m_axi_rready) begin
                ar_burst_active <= 1'b0;
                ar_total_remaining <= ar_total_remaining - ar_burst_remaining;
                ar_next_addr <= ar_next_addr + (ar_burst_remaining * AXI_DATA_BYTES);
            end

            // Initialize ar_next_addr when starting read
            if (read_state == ST_IDLE && s_axis_read_desc_valid && read_enable) begin
                ar_next_addr <= s_axis_read_desc_addr;
            end
        end
    end

    // Read data FIFO write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_fifo_wr_ptr <= {LEN_WIDTH{1'b0}};
            rdata_fifo_rd_ptr <= {LEN_WIDTH{1'b0}};
            rdata_fifo_count <= {LEN_WIDTH{1'b0}};
        end else begin
            if (m_axi_rvalid && m_axi_rready) begin
                rdata_fifo[rdata_fifo_wr_ptr] <= m_axi_rdata;
                rkeep_fifo[rdata_fifo_wr_ptr] <= {AXIS_KEEP_WIDTH{1'b1}};
                rdata_fifo_wr_ptr <= rdata_fifo_wr_ptr + 1;
                rdata_fifo_count <= rdata_fifo_count + 1;
            end
            if (m_axis_read_data_tvalid && m_axis_read_data_tready) begin
                rdata_fifo_rd_ptr <= rdata_fifo_rd_ptr + 1;
                rdata_fifo_count <= rdata_fifo_count - 1;
            end
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
            write_error <= 4'b0000;
            write_status_valid <= 1'b0;
            write_status_len <= {LEN_WIDTH{1'b0}};
            write_status_tag <= {TAG_WIDTH{1'b0}};
            write_status_id <= {AXIS_ID_WIDTH{1'b0}};
            write_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            write_status_user <= {AXIS_USER_WIDTH{1'b0}};
            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            awlen_reg <= 8'd0;
            awsize_reg <= 3'd0;
            awburst_reg <= 2'b01;
            awvalid_reg <= 1'b0;
            aw_burst_remaining <= {LEN_WIDTH{1'b0}};
            aw_total_remaining <= {LEN_WIDTH{1'b0}};
            aw_next_addr <= {AXI_ADDR_WIDTH{1'b0}};
            aw_burst_active <= 1'b0;
            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wlast_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            w_beat_count <= {LEN_WIDTH{1'b0}};
            w_burst_len <= {LEN_WIDTH{1'b0}};
        end else begin
            // Default: clear status valid
            write_status_valid <= 1'b0;

            case (write_state)
                ST_IDLE: begin
                    if (s_axis_write_desc_valid && write_enable) begin
                        write_state <= ST_WRITE_DESC;
                        write_addr <= s_axis_write_desc_addr;
                        write_len <= s_axis_write_desc_len;
                        write_remaining <= s_axis_write_desc_len;
                        write_tag <= s_axis_write_desc_tag;
                        write_id <= s_axis_write_desc_id;
                        write_dest <= s_axis_write_desc_dest;
                        write_user <= s_axis_write_desc_user;
                        write_error <= 4'b0000;
                        aw_total_remaining <= s_axis_write_desc_len;
                        aw_burst_active <= 1'b0;
                        awvalid_reg <= 1'b0;
                        wvalid_reg <= 1'b0;
                    end
                end

                ST_WRITE_DESC: begin
                    // Handle write abort
                    if (write_abort) begin
                        write_state <= ST_IDLE;
                        write_status_valid <= 1'b1;
                        write_status_len <= write_remaining;
                        write_status_tag <= write_tag;
                        write_status_id <= write_id;
                        write_status_dest <= write_dest;
                        write_status_user <= write_user;
                        write_error <= 4'b0001; // Abort error
                        awvalid_reg <= 1'b0;
                        wvalid_reg <= 1'b0;
                    end else if (!aw_burst_active) begin
                        if (aw_total_remaining > 0) begin
                            // Start new burst
                            aw_burst_active <= 1'b1;
                            awid_reg <= write_id;
                            awaddr_reg <= aw_next_addr;
                            awlen_reg <= calc_burst_len(aw_total_remaining);
                            awsize_reg <= AXI_SIZE[2:0];
                            awburst_reg <= 2'b01; // INCR
                            awvalid_reg <= 1'b1;
                            aw_burst_remaining <= calc_burst_len(aw_total_remaining) + 1;
                            w_burst_len <= calc_burst_len(aw_total_remaining) + 1;
                            w_beat_count <= {LEN_WIDTH{1'b0}};
                        end else begin
                            // Done
                            write_state <= ST_IDLE;
                            write_status_valid <= 1'b1;
                            write_status_len <= write_len;
                            write_status_tag <= write_tag;
                            write_status_id <= write_id;
                            write_status_dest <= write_dest;
                            write_status_user <= write_user;
                        end
                    end else begin
                        if (awvalid_reg && m_axi_awready) begin
                            awvalid_reg <= 1'b0;
                        end
                    end
                end

                default: begin
                    write_state <= ST_IDLE;
                end
            endcase

            // Update aw_next_addr when burst completes
            if (aw_burst_active && m_axi_bvalid && m_axi_bready) begin
                aw_burst_active <= 1'b0;
                aw_total_remaining <= aw_total_remaining - aw_burst_remaining;
                aw_next_addr <= aw_next_addr + (aw_burst_remaining * AXI_DATA_BYTES);
            end

            // Initialize aw_next_addr when starting write
            if (write_state == ST_IDLE && s_axis_write_desc_valid && write_enable) begin
                aw_next_addr <= s_axis_write_desc_addr;
            end
        end
    end

    // Write data FIFO write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_fifo_wr_ptr <= {LEN_WIDTH{1'b0}};
            wdata_fifo_rd_ptr <= {LEN_WIDTH{1'b0}};
            wdata_fifo_count <= {LEN_WIDTH{1'b0}};
        end else begin
            if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                wdata_fifo[wdata_fifo_wr_ptr] <= s_axis_write_data_tdata;
                wkeep_fifo[wdata_fifo_wr_ptr] <= s_axis_write_data_tkeep;
                wdata_fifo_wr_ptr <= wdata_fifo_wr_ptr + 1;
                wdata_fifo_count <= wdata_fifo_count + 1;
            end
            if (wvalid_reg && m_axi_wready) begin
                wdata_fifo_rd_ptr <= wdata_fifo_rd_ptr + 1;
                wdata_fifo_count <= wdata_fifo_count - 1;
            end
        end
    end

    // Write data output from FIFO
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wlast_reg <= 1'b0;
            wvalid_reg <= 1'b0;
        end else begin
            if (aw_burst_active && !wdata_fifo_empty) begin
                wdata_reg <= wdata_fifo[wdata_fifo_rd_ptr];
                wstrb_reg <= calc_strb(wkeep_fifo[wdata_fifo_rd_ptr]);
                wlast_reg <= (w_beat_count == w_burst_len - 1);
                wvalid_reg <= 1'b1;
            end else begin
                wvalid_reg <= 1'b0;
            end

            if (wvalid_reg && m_axi_wready) begin
                w_beat_count <= w_beat_count + 1;
            end
        end
    end

endmodule
