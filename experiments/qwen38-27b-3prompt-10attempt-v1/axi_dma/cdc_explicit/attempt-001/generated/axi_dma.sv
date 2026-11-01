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
    localparam AWLEN_WIDTH = 8;
    localparam BURST_LEN_WIDTH = 8;
    localparam DATA_BYTES = AXI_DATA_WIDTH / 8;
    localparam AXI_SIZE = $clog2(DATA_BYTES);
    localparam MAX_BURST = AXI_MAX_BURST_LEN;
    
    // Read channel state
    reg [AXI_ADDR_WIDTH-1:0] rd_addr;
    reg [LEN_WIDTH-1:0] rd_len;
    reg [TAG_WIDTH-1:0] rd_tag;
    reg [AXIS_ID_WIDTH-1:0] rd_id;
    reg [AXIS_DEST_WIDTH-1:0] rd_dest;
    reg [AXIS_USER_WIDTH-1:0] rd_user;
    reg [LEN_WIDTH-1:0] rd_remaining;
    reg [AXI_ADDR_WIDTH-1:0] rd_cur_addr;
    reg [7:0] rd_burst_len;
    reg [7:0] rd_burst_count;
    reg rd_active;
    reg rd_burst_active;
    reg [3:0] rd_error;
    reg rd_status_valid;
    reg [TAG_WIDTH-1:0] rd_status_tag;
    reg [3:0] rd_status_error;
    
    // Write channel state
    reg [AXI_ADDR_WIDTH-1:0] wr_addr;
    reg [LEN_WIDTH-1:0] wr_len;
    reg [TAG_WIDTH-1:0] wr_tag;
    reg [LEN_WIDTH-1:0] wr_remaining;
    reg [AXI_ADDR_WIDTH-1:0] wr_cur_addr;
    reg [7:0] wr_burst_len;
    reg [7:0] wr_burst_count;
    reg wr_active;
    reg wr_burst_active;
    reg [3:0] wr_error;
    reg wr_status_valid;
    reg [LEN_WIDTH-1:0] wr_status_len;
    reg [TAG_WIDTH-1:0] wr_status_tag;
    reg [3:0] wr_status_error;
    reg [AXIS_ID_WIDTH-1:0] wr_status_id;
    reg [AXIS_DEST_WIDTH-1:0] wr_status_dest;
    reg [AXIS_USER_WIDTH-1:0] wr_status_user;
    
    // FIFO for read data
    reg [AXIS_DATA_WIDTH-1:0] rd_fifo_data [0:255];
    reg [AXIS_KEEP_WIDTH-1:0] rd_fifo_keep [0:255];
    reg rd_fifo_last [0:255];
    reg [AXIS_ID_WIDTH-1:0] rd_fifo_id [0:255];
    reg [AXIS_DEST_WIDTH-1:0] rd_fifo_dest [0:255];
    reg [AXIS_USER_WIDTH-1:0] rd_fifo_user [0:255];
    reg [7:0] rd_fifo_wr_ptr;
    reg [7:0] rd_fifo_rd_ptr;
    reg rd_fifo_empty;
    reg rd_fifo_full;
    
    // FIFO for write data
    reg [AXIS_DATA_WIDTH-1:0] wr_fifo_data [0:255];
    reg [AXIS_KEEP_WIDTH-1:0] wr_fifo_keep [0:255];
    reg wr_fifo_last [0:255];
    reg [AXIS_ID_WIDTH-1:0] wr_fifo_id [0:255];
    reg [AXIS_DEST_WIDTH-1:0] wr_fifo_dest [0:255];
    reg [AXIS_USER_WIDTH-1:0] wr_fifo_user [0:255];
    reg [7:0] wr_fifo_wr_ptr;
    reg [7:0] wr_fifo_rd_ptr;
    reg wr_fifo_empty;
    reg wr_fifo_full;
    
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
    
    // Assign outputs
    assign s_axis_read_desc_ready = read_enable && !rd_active;
    assign m_axis_read_desc_status_tag = rd_status_tag;
    assign m_axis_read_desc_status_error = rd_status_error;
    assign m_axis_read_desc_status_valid = rd_status_valid;
    
    assign m_axis_read_data_tdata = rd_fifo_data[rd_fifo_rd_ptr];
    assign m_axis_read_data_tkeep = rd_fifo_keep[rd_fifo_rd_ptr];
    assign m_axis_read_data_tvalid = !rd_fifo_empty;
    assign m_axis_read_data_tlast = rd_fifo_last[rd_fifo_rd_ptr];
    assign m_axis_read_data_tid = rd_fifo_id[rd_fifo_rd_ptr];
    assign m_axis_read_data_tdest = rd_fifo_dest[rd_fifo_rd_ptr];
    assign m_axis_read_data_tuser = rd_fifo_user[rd_fifo_rd_ptr];
    
    assign s_axis_write_desc_ready = write_enable && !wr_active && !write_abort;
    assign m_axis_write_desc_status_len = wr_status_len;
    assign m_axis_write_desc_status_tag = wr_status_tag;
    assign m_axis_write_desc_status_id = wr_status_id;
    assign m_axis_write_desc_status_dest = wr_status_dest;
    assign m_axis_write_desc_status_user = wr_status_user;
    assign m_axis_write_desc_status_error = wr_status_error;
    assign m_axis_write_desc_status_valid = wr_status_valid;
    
    assign s_axis_write_data_tready = !wr_fifo_full && wr_active;
    
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
    
    // FIFO status
    assign rd_fifo_empty = (rd_fifo_wr_ptr == rd_fifo_rd_ptr);
    assign rd_fifo_full = (rd_fifo_wr_ptr[7] != rd_fifo_rd_ptr[7]) && 
                          (rd_fifo_wr_ptr[6:0] == rd_fifo_rd_ptr[6:0]);
    
    assign wr_fifo_empty = (wr_fifo_wr_ptr == wr_fifo_rd_ptr);
    assign wr_fifo_full = (wr_fifo_wr_ptr[7] != wr_fifo_rd_ptr[7]) && 
                          (wr_fifo_wr_ptr[6:0] == wr_fifo_rd_ptr[6:0]);
    
    // Read descriptor acceptance
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_active <= 1'b0;
            rd_burst_active <= 1'b0;
            rd_status_valid <= 1'b0;
            rd_status_tag <= {TAG_WIDTH{1'b0}};
            rd_status_error <= 4'b0000;
            rd_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_len <= {LEN_WIDTH{1'b0}};
            rd_tag <= {TAG_WIDTH{1'b0}};
            rd_id <= {AXIS_ID_WIDTH{1'b0}};
            rd_dest <= {AXIS_DEST_WIDTH{1'b0}};
            rd_user <= {AXIS_USER_WIDTH{1'b0}};
            rd_remaining <= {LEN_WIDTH{1'b0}};
            rd_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_burst_len <= 8'd0;
            rd_burst_count <= 8'd0;
            rd_error <= 4'b0000;
        end else begin
            // Accept new read descriptor
            if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                rd_active <= 1'b1;
                rd_addr <= s_axis_read_desc_addr;
                rd_len <= s_axis_read_desc_len;
                rd_tag <= s_axis_read_desc_tag;
                rd_id <= s_axis_read_desc_id;
                rd_dest <= s_axis_read_desc_dest;
                rd_user <= s_axis_read_desc_user;
                rd_remaining <= s_axis_read_desc_len;
                rd_cur_addr <= s_axis_read_desc_addr;
                rd_burst_active <= 1'b0;
                rd_status_valid <= 1'b0;
                rd_error <= 4'b0000;
            end
            
            // Handle read completion
            if (rd_active && !rd_burst_active && rd_remaining == 0) begin
                rd_active <= 1'b0;
                rd_status_valid <= 1'b1;
                rd_status_tag <= rd_tag;
                rd_status_error <= rd_error;
            end
            
            // Clear status when consumed
            if (rd_status_valid && m_axis_read_desc_status_valid) begin
                rd_status_valid <= 1'b0;
            end
        end
    end
    
    // Write descriptor acceptance
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_active <= 1'b0;
            wr_burst_active <= 1'b0;
            wr_status_valid <= 1'b0;
            wr_status_len <= {LEN_WIDTH{1'b0}};
            wr_status_tag <= {TAG_WIDTH{1'b0}};
            wr_status_error <= 4'b0000;
            wr_status_id <= {AXIS_ID_WIDTH{1'b0}};
            wr_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            wr_status_user <= {AXIS_USER_WIDTH{1'b0}};
            wr_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_len <= {LEN_WIDTH{1'b0}};
            wr_tag <= {TAG_WIDTH{1'b0}};
            wr_remaining <= {LEN_WIDTH{1'b0}};
            wr_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_burst_len <= 8'd0;
            wr_burst_count <= 8'd0;
            wr_error <= 4'b0000;
        end else begin
            // Accept new write descriptor
            if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                wr_active <= 1'b1;
                wr_addr <= s_axis_write_desc_addr;
                wr_len <= s_axis_write_desc_len;
                wr_tag <= s_axis_write_desc_tag;
                wr_remaining <= s_axis_write_desc_len;
                wr_cur_addr <= s_axis_write_desc_addr;
                wr_burst_active <= 1'b0;
                wr_status_valid <= 1'b0;
                wr_error <= 4'b0000;
            end
            
            // Handle write completion
            if (wr_active && !wr_burst_active && wr_remaining == 0) begin
                wr_active <= 1'b0;
                wr_status_valid <= 1'b1;
                wr_status_len <= wr_len;
                wr_status_tag <= wr_tag;
                wr_status_error <= wr_error;
                wr_status_id <= {AXIS_ID_WIDTH{1'b0}};
                wr_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
                wr_status_user <= {AXIS_USER_WIDTH{1'b0}};
            end
            
            // Clear status when consumed
            if (wr_status_valid && m_axis_write_desc_status_valid) begin
                wr_status_valid <= 1'b0;
            end
        end
    end
    
    // Read FIFO write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_fifo_wr_ptr <= 8'd0;
        end else if (m_axi_rvalid && m_axi_rready) begin
            rd_fifo_data[rd_fifo_wr_ptr] <= m_axi_rdata;
            rd_fifo_keep[rd_fifo_wr_ptr] <= {AXIS_KEEP_WIDTH{1'b1}};
            rd_fifo_last[rd_fifo_wr_ptr] <= m_axi_rlast;
            rd_fifo_id[rd_fifo_wr_ptr] <= rd_id;
            rd_fifo_dest[rd_fifo_wr_ptr] <= rd_dest;
            rd_fifo_user[rd_fifo_wr_ptr] <= rd_user;
            rd_fifo_wr_ptr <= rd_fifo_wr_ptr + 8'd1;
        end
    end
    
    // Read FIFO read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_fifo_rd_ptr <= 8'd0;
        end else if (m_axis_read_data_tvalid && m_axis_read_data_tready) begin
            rd_fifo_rd_ptr <= rd_fifo_rd_ptr + 8'd1;
        end
    end
    
    // Write FIFO write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_fifo_wr_ptr <= 8'd0;
        end else if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
            wr_fifo_data[wr_fifo_wr_ptr] <= s_axis_write_data_tdata;
            wr_fifo_keep[wr_fifo_wr_ptr] <= s_axis_write_data_tkeep;
            wr_fifo_last[wr_fifo_wr_ptr] <= s_axis_write_data_tlast;
            wr_fifo_id[wr_fifo_wr_ptr] <= s_axis_write_data_tid;
            wr_fifo_dest[wr_fifo_wr_ptr] <= s_axis_write_data_tdest;
            wr_fifo_user[wr_fifo_wr_ptr] <= s_axis_write_data_tuser;
            wr_fifo_wr_ptr <= wr_fifo_wr_ptr + 8'd1;
        end
    end
    
    // Write FIFO read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_fifo_rd_ptr <= 8'd0;
        end else if (m_axi_wvalid && m_axi_wready) begin
            wr_fifo_rd_ptr <= wr_fifo_rd_ptr + 8'd1;
        end
    end
    
    // AXI Write Address Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            awlen_reg <= 8'd0;
            awsize_reg <= 3'b000;
            awburst_reg <= 2'b01;
            awlock_reg <= 1'b0;
            awcache_reg <= 4'b0000;
            awprot_reg <= 3'b000;
            awvalid_reg <= 1'b0;
        end else begin
            if (awvalid_reg && m_axi_awready) begin
                awvalid_reg <= 1'b0;
            end
            
            if (wr_active && !wr_burst_active && !wr_fifo_empty && !awvalid_reg) begin
                awid_reg <= {AXI_ID_WIDTH{1'b0}};
                awaddr_reg <= wr_cur_addr;
                awlen_reg <= wr_burst_len - 8'd1;
                awsize_reg <= AXI_SIZE[2:0];
                awburst_reg <= 2'b01;
                awlock_reg <= 1'b0;
                awcache_reg <= 4'b0000;
                awprot_reg <= 3'b000;
                awvalid_reg <= 1'b1;
                wr_burst_active <= 1'b1;
            end
        end
    end
    
    // AXI Write Data Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wlast_reg <= 1'b0;
            wvalid_reg <= 1'b0;
        end else begin
            if (wvalid_reg && m_axi_wready) begin
                wvalid_reg <= 1'b0;
            end
            
            if (wr_burst_active && !wr_fifo_empty && !wvalid_reg) begin
                wdata_reg <= wr_fifo_data[wr_fifo_rd_ptr];
                wstrb_reg <= wr_fifo_keep[wr_fifo_rd_ptr];
                wlast_reg <= (wr_burst_count == wr_burst_len - 8'd1);
                wvalid_reg <= 1'b1;
            end
        end
    end
    
    // AXI Write Response Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bready_reg <= 1'b0;
        end else begin
            if (bready_reg && m_axi_bvalid) begin
                bready_reg <= 1'b0;
                if (m_axi_bresp != 2'b00) begin
                    wr_error <= 4'b0001;
                end
            end
            
            if (wr_burst_active && !bready_reg) begin
                bready_reg <= 1'b1;
            end
        end
    end
    
    // AXI Read Address Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            arlen_reg <= 8'd0;
            arsize_reg <= 3'b000;
            arburst_reg <= 2'b01;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'b0000;
            arprot_reg <= 3'b000;
            arvalid_reg <= 1'b0;
        end else begin
            if (arvalid_reg && m_axi_arready) begin
                arvalid_reg <= 1'b0;
            end
            
            if (rd_active && !rd_burst_active && !arvalid_reg) begin
                arid_reg <= {AXI_ID_WIDTH{1'b0}};
                araddr_reg <= rd_cur_addr;
                arlen_reg <= rd_burst_len - 8'd1;
                arsize_reg <= AXI_SIZE[2:0];
                arburst_reg <= 2'b01;
                arlock_reg <= 1'b0;
                arcache_reg <= 4'b0000;
                arprot_reg <= 3'b000;
                arvalid_reg <= 1'b1;
                rd_burst_active <= 1'b1;
            end
        end
    end
    
    // AXI Read Data Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rready_reg <= 1'b0;
        end else begin
            if (rd_burst_active) begin
                rready_reg <= 1'b1;
            end else begin
                rready_reg <= 1'b0;
            end
        end
    end
    
    // Burst length calculation and address update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_burst_len <= 8'd0;
            rd_burst_count <= 8'd0;
            wr_burst_len <= 8'd0;
            wr_burst_count <= 8'd0;
        end else begin
            // Read burst
            if (rd_active && !rd_burst_active) begin
                if (rd_remaining >= MAX_BURST) begin
                    rd_burst_len <= MAX_BURST[7:0];
                end else begin
                    rd_burst_len <= rd_remaining[7:0];
                end
                rd_burst_count <= 8'd0;
            end
            
            if (rd_burst_active && m_axi_rvalid && m_axi_rready) begin
                rd_burst_count <= rd_burst_count + 8'd1;
                rd_cur_addr <= rd_cur_addr + AXI_DATA_WIDTH[AXI_ADDR_WIDTH-1:0];
                rd_remaining <= rd_remaining - 1'b1;
                
                if (rd_burst_count == rd_burst_len - 8'd1) begin
                    rd_burst_active <= 1'b0;
                end
            end
            
            // Write burst
            if (wr_active && !wr_burst_active && !wr_fifo_empty) begin
                if (wr_remaining >= MAX_BURST) begin
                    wr_burst_len <= MAX_BURST[7:0];
                end else begin
                    wr_burst_len <= wr_remaining[7:0];
                end
                wr_burst_count <= 8'd0;
            end
            
            if (wr_burst_active && m_axi_wvalid && m_axi_wready) begin
                wr_burst_count <= wr_burst_count + 8'd1;
                wr_cur_addr <= wr_cur_addr + AXI_DATA_WIDTH[AXI_ADDR_WIDTH-1:0];
                wr_remaining <= wr_remaining - 1'b1;
                
                if (wr_burst_count == wr_burst_len - 8'd1) begin
                    wr_burst_active <= 1'b0;
                end
            end
        end
    end

endmodule
