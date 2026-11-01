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

    // Local parameters
    localparam DATA_BYTES = AXI_DATA_WIDTH / 8;
    localparam AWLEN_MAX = AXI_MAX_BURST_LEN - 1;
    localparam AWLEN_WIDTH = $clog2(AXI_MAX_BURST_LEN);
    localparam AWLEN_WIDTH_ACTUAL = (AWLEN_WIDTH < 8) ? 8 : AWLEN_WIDTH;
    
    // Read channel state
    reg [AXI_ADDR_WIDTH-1:0] rd_addr;
    reg [LEN_WIDTH-1:0] rd_len;
    reg [LEN_WIDTH-1:0] rd_len_remaining;
    reg [TAG_WIDTH-1:0] rd_tag;
    reg [AXIS_ID_WIDTH-1:0] rd_id;
    reg [AXIS_DEST_WIDTH-1:0] rd_dest;
    reg [AXIS_USER_WIDTH-1:0] rd_user;
    reg rd_active;
    reg [7:0] rd_burst_count;
    reg [7:0] rd_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] rd_next_addr;
    reg rd_burst_last;
    reg rd_done;
    reg [3:0] rd_error;
    reg rd_status_valid;
    reg [TAG_WIDTH-1:0] rd_status_tag;
    reg [3:0] rd_status_error;

    // Write channel state
    reg [AXI_ADDR_WIDTH-1:0] wr_addr;
    reg [LEN_WIDTH-1:0] wr_len;
    reg [LEN_WIDTH-1:0] wr_len_remaining;
    reg [TAG_WIDTH-1:0] wr_tag;
    reg wr_active;
    reg [7:0] wr_burst_count;
    reg [7:0] wr_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] wr_next_addr;
    reg wr_burst_last;
    reg wr_done;
    reg [3:0] wr_error;
    reg wr_status_valid;
    reg [LEN_WIDTH-1:0] wr_status_len;
    reg [TAG_WIDTH-1:0] wr_status_tag;
    reg [AXIS_ID_WIDTH-1:0] wr_status_id;
    reg [AXIS_DEST_WIDTH-1:0] wr_status_dest;
    reg [AXIS_USER_WIDTH-1:0] wr_status_user;
    reg [3:0] wr_status_error;

    // AXI read address channel
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg arlock_reg;
    reg [3:0] arcache_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;

    // AXI read data channel
    reg rready_reg;

    // AXI write address channel
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg awlock_reg;
    reg [3:0] awcache_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;

    // AXI write data channel
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;

    // AXI write response channel
    reg bready_reg;

    // Read data FIFO (simple register-based)
    reg [AXIS_DATA_WIDTH-1:0] rd_data_fifo [0:3];
    reg [AXIS_KEEP_WIDTH-1:0] rd_keep_fifo [0:3];
    reg rd_data_valid [0:3];
    reg [1:0] rd_data_wr_ptr;
    reg [1:0] rd_data_rd_ptr;
    reg rd_data_empty;
    reg rd_data_full;

    // Write data FIFO
    reg [AXIS_DATA_WIDTH-1:0] wr_data_fifo [0:3];
    reg [AXIS_KEEP_WIDTH-1:0] wr_keep_fifo [0:3];
    reg wr_data_valid [0:3];
    reg [1:0] wr_data_wr_ptr;
    reg [1:0] wr_data_rd_ptr;
    reg wr_data_empty;
    reg wr_data_full;

    // Read data output
    reg [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata_reg;
    reg [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep_reg;
    reg m_axis_read_data_tvalid_reg;
    reg m_axis_read_data_tlast_reg;
    reg [AXIS_ID_WIDTH-1:0] m_axis_read_data_tid_reg;
    reg [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest_reg;
    reg [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser_reg;

    // Write data input ready
    reg s_axis_write_data_tready_reg;

    // Descriptor ready
    reg s_axis_read_desc_ready_reg;
    reg s_axis_write_desc_ready_reg;

    // Status outputs
    reg m_axis_read_desc_status_valid_reg;
    reg [TAG_WIDTH-1:0] m_axis_read_desc_status_tag_reg;
    reg [3:0] m_axis_read_desc_status_error_reg;

    reg m_axis_write_desc_status_valid_reg;
    reg [LEN_WIDTH-1:0] m_axis_write_desc_status_len_reg;
    reg [TAG_WIDTH-1:0] m_axis_write_desc_status_tag_reg;
    reg [AXIS_ID_WIDTH-1:0] m_axis_write_desc_status_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user_reg;
    reg [3:0] m_axis_write_desc_status_error_reg;

    // AXI outputs
    reg [AXI_ID_WIDTH-1:0] m_axi_awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] m_axi_awaddr_reg;
    reg [7:0] m_axi_awlen_reg;
    reg [2:0] m_axi_awsize_reg;
    reg [1:0] m_axi_awburst_reg;
    reg m_axi_awlock_reg;
    reg [3:0] m_axi_awcache_reg;
    reg [2:0] m_axi_awprot_reg;
    reg m_axi_awvalid_reg;

    reg [AXI_DATA_WIDTH-1:0] m_axi_wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] m_axi_wstrb_reg;
    reg m_axi_wlast_reg;
    reg m_axi_wvalid_reg;
    reg m_axi_bready_reg;

    reg [AXI_ID_WIDTH-1:0] m_axi_arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] m_axi_araddr_reg;
    reg [7:0] m_axi_arlen_reg;
    reg [2:0] m_axi_arsize_reg;
    reg [1:0] m_axi_arburst_reg;
    reg m_axi_arlock_reg;
    reg [3:0] m_axi_arcache_reg;
    reg [2:0] m_axi_arprot_reg;
    reg m_axi_arvalid_reg;
    reg m_axi_rready_reg;

    // Assign outputs
    assign s_axis_read_desc_ready = s_axis_read_desc_ready_reg;
    assign m_axis_read_desc_status_tag = m_axis_read_desc_status_tag_reg;
    assign m_axis_read_desc_status_error = m_axis_read_desc_status_error_reg;
    assign m_axis_read_desc_status_valid = m_axis_read_desc_status_valid_reg;

    assign m_axis_read_data_tdata = m_axis_read_data_tdata_reg;
    assign m_axis_read_data_tkeep = m_axis_read_data_tkeep_reg;
    assign m_axis_read_data_tvalid = m_axis_read_data_tvalid_reg;
    assign m_axis_read_data_tlast = m_axis_read_data_tlast_reg;
    assign m_axis_read_data_tid = m_axis_read_data_tid_reg;
    assign m_axis_read_data_tdest = m_axis_read_data_tdest_reg;
    assign m_axis_read_data_tuser = m_axis_read_data_tuser_reg;

    assign s_axis_write_desc_ready = s_axis_write_desc_ready_reg;
    assign m_axis_write_desc_status_len = m_axis_write_desc_status_len_reg;
    assign m_axis_write_desc_status_tag = m_axis_write_desc_status_tag_reg;
    assign m_axis_write_desc_status_id = m_axis_write_desc_status_id_reg;
    assign m_axis_write_desc_status_dest = m_axis_write_desc_status_dest_reg;
    assign m_axis_write_desc_status_user = m_axis_write_desc_status_user_reg;
    assign m_axis_write_desc_status_error = m_axis_write_desc_status_error_reg;
    assign m_axis_write_desc_status_valid = m_axis_write_desc_status_valid_reg;

    assign s_axis_write_data_tready = s_axis_write_data_tready_reg;

    assign m_axi_awid = m_axi_awid_reg;
    assign m_axi_awaddr = m_axi_awaddr_reg;
    assign m_axi_awlen = m_axi_awlen_reg;
    assign m_axi_awsize = m_axi_awsize_reg;
    assign m_axi_awburst = m_axi_awburst_reg;
    assign m_axi_awlock = m_axi_awlock_reg;
    assign m_axi_awcache = m_axi_awcache_reg;
    assign m_axi_awprot = m_axi_awprot_reg;
    assign m_axi_awvalid = m_axi_awvalid_reg;

    assign m_axi_wdata = m_axi_wdata_reg;
    assign m_axi_wstrb = m_axi_wstrb_reg;
    assign m_axi_wlast = m_axi_wlast_reg;
    assign m_axi_wvalid = m_axi_wvalid_reg;
    assign m_axi_bready = m_axi_bready_reg;

    assign m_axi_arid = m_axi_arid_reg;
    assign m_axi_araddr = m_axi_araddr_reg;
    assign m_axi_arlen = m_axi_arlen_reg;
    assign m_axi_arsize = m_axi_arsize_reg;
    assign m_axi_arburst = m_axi_arburst_reg;
    assign m_axi_arlock = m_axi_arlock_reg;
    assign m_axi_arcache = m_axi_arcache_reg;
    assign m_axi_arprot = m_axi_arprot_reg;
    assign m_axi_arvalid = m_axi_arvalid_reg;
    assign m_axi_rready = m_axi_rready_reg;

    // Read data FIFO empty/full
    wire rd_data_empty_wire = (rd_data_wr_ptr == rd_data_rd_ptr);
    wire rd_data_full_wire = (rd_data_wr_ptr[1] != rd_data_rd_ptr[1]) && 
                              (rd_data_wr_ptr[0] == rd_data_rd_ptr[0]);

    // Write data FIFO empty/full
    wire wr_data_empty_wire = (wr_data_wr_ptr == wr_data_rd_ptr);
    wire wr_data_full_wire = (wr_data_wr_ptr[1] != wr_data_rd_ptr[1]) && 
                              (wr_data_wr_ptr[0] == wr_data_rd_ptr[0]);

    // Read data output ready
    wire rd_data_out_ready = m_axis_read_data_tready;

    // Write data input ready
    wire wr_data_in_ready = !wr_data_full_wire && wr_active && write_enable && !write_abort;

    // Read descriptor ready
    wire rd_desc_ready = !rd_active && read_enable;

    // Write descriptor ready
    wire wr_desc_ready = !wr_active && write_enable && !write_abort;

    // Read data FIFO write
    wire rd_data_wr_en = m_axi_rvalid && m_axi_rready && !rd_data_full_wire;

    // Read data FIFO read
    wire rd_data_rd_en = !rd_data_empty_wire && rd_data_out_ready;

    // Write data FIFO write
    wire wr_data_wr_en = s_axis_write_data_tvalid && wr_data_in_ready;

    // Write data FIFO read
    wire wr_data_rd_en = !wr_data_empty_wire && m_axi_wvalid && m_axi_wready;

    // AXI read address valid
    wire ar_valid = arvalid_reg;
    wire ar_ready = m_axi_arready;

    // AXI write address valid
    wire aw_valid = awvalid_reg;
    wire aw_ready = m_axi_awready;

    // AXI write data valid
    wire w_valid = wvalid_reg;
    wire w_ready = m_axi_wready;

    // AXI write response valid
    wire b_valid = m_axi_bvalid;
    wire b_ready = m_axi_bready_reg;

    // AXI read data valid
    wire r_valid = m_axi_rvalid;
    wire r_ready = m_axi_rready_reg;

    // Calculate burst length
    function [7:0] calc_burst_len;
        input [LEN_WIDTH-1:0] remaining;
        begin
            if (remaining >= AWLEN_MAX + 1)
                calc_burst_len = AWLEN_MAX;
            else
                calc_burst_len = remaining[7:0] - 1;
        end
    endfunction

    // Calculate next address
    function [AXI_ADDR_WIDTH-1:0] calc_next_addr;
        input [AXI_ADDR_WIDTH-1:0] addr;
        input [7:0] burst_len;
        begin
            calc_next_addr = addr + (burst_len + 1) * DATA_BYTES;
        end
    endfunction

    // Main clocked process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers
            rd_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_len <= {LEN_WIDTH{1'b0}};
            rd_len_remaining <= {LEN_WIDTH{1'b0}};
            rd_tag <= {TAG_WIDTH{1'b0}};
            rd_id <= {AXIS_ID_WIDTH{1'b0}};
            rd_dest <= {AXIS_DEST_WIDTH{1'b0}};
            rd_user <= {AXIS_USER_WIDTH{1'b0}};
            rd_active <= 1'b0;
            rd_burst_count <= 8'd0;
            rd_burst_len <= 8'd0;
            rd_next_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_burst_last <= 1'b0;
            rd_done <= 1'b0;
            rd_error <= 4'd0;
            rd_status_valid <= 1'b0;
            rd_status_tag <= {TAG_WIDTH{1'b0}};
            rd_status_error <= 4'd0;

            wr_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_len <= {LEN_WIDTH{1'b0}};
            wr_len_remaining <= {LEN_WIDTH{1'b0}};
            wr_tag <= {TAG_WIDTH{1'b0}};
            wr_active <= 1'b0;
            wr_burst_count <= 8'd0;
            wr_burst_len <= 8'd0;
            wr_next_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_burst_last <= 1'b0;
            wr_done <= 1'b0;
            wr_error <= 4'd0;
            wr_status_valid <= 1'b0;
            wr_status_len <= {LEN_WIDTH{1'b0}};
            wr_status_tag <= {TAG_WIDTH{1'b0}};
            wr_status_id <= {AXIS_ID_WIDTH{1'b0}};
            wr_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            wr_status_user <= {AXIS_USER_WIDTH{1'b0}};
            wr_status_error <= 4'd0;

            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            arlen_reg <= 8'd0;
            arsize_reg <= 3'd0;
            arburst_reg <= 2'b01;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'b0011;
            arprot_reg <= 3'b000;
            arvalid_reg <= 1'b0;

            rready_reg <= 1'b0;

            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            awlen_reg <= 8'd0;
            awsize_reg <= 3'd0;
            awburst_reg <= 2'b01;
            awlock_reg <= 1'b0;
            awcache_reg <= 4'b0011;
            awprot_reg <= 3'b000;
            awvalid_reg <= 1'b0;

            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wlast_reg <= 1'b0;
            wvalid_reg <= 1'b0;

            bready_reg <= 1'b0;

            rd_data_wr_ptr <= 2'd0;
            rd_data_rd_ptr <= 2'd0;
            rd_data_valid[0] <= 1'b0;
            rd_data_valid[1] <= 1'b0;
            rd_data_valid[2] <= 1'b0;
            rd_data_valid[3] <= 1'b0;

            wr_data_wr_ptr <= 2'd0;
            wr_data_rd_ptr <= 2'd0;
            wr_data_valid[0] <= 1'b0;
            wr_data_valid[1] <= 1'b0;
            wr_data_valid[2] <= 1'b0;
            wr_data_valid[3] <= 1'b0;

            m_axis_read_data_tdata_reg <= {AXIS_DATA_WIDTH{1'b0}};
            m_axis_read_data_tkeep_reg <= {AXIS_KEEP_WIDTH{1'b0}};
            m_axis_read_data_tvalid_reg <= 1'b0;
            m_axis_read_data_tlast_reg <= 1'b0;
            m_axis_read_data_tid_reg <= {AXIS_ID_WIDTH{1'b0}};
            m_axis_read_data_tdest_reg <= {AXIS_DEST_WIDTH{1'b0}};
            m_axis_read_data_tuser_reg <= {AXIS_USER_WIDTH{1'b0}};

            s_axis_write_data_tready_reg <= 1'b0;
            s_axis_read_desc_ready_reg <= 1'b0;
            s_axis_write_desc_ready_reg <= 1'b0;

            m_axis_read_desc_status_valid_reg <= 1'b0;
            m_axis_read_desc_status_tag_reg <= {TAG_WIDTH{1'b0}};
            m_axis_read_desc_status_error_reg <= 4'd0;

            m_axis_write_desc_status_valid_reg <= 1'b0;
            m_axis_write_desc_status_len_reg <= {LEN_WIDTH{1'b0}};
            m_axis_write_desc_status_tag_reg <= {TAG_WIDTH{1'b0}};
            m_axis_write_desc_status_id_reg <= {AXIS_ID_WIDTH{1'b0}};
            m_axis_write_desc_status_dest_reg <= {AXIS_DEST_WIDTH{1'b0}};
            m_axis_write_desc_status_user_reg <= {AXIS_USER_WIDTH{1'b0}};
            m_axis_write_desc_status_error_reg <= 4'd0;

            m_axi_awid_reg <= {AXI_ID_WIDTH{1'b0}};
            m_axi_awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            m_axi_awlen_reg <= 8'd0;
            m_axi_awsize_reg <= 3'd0;
            m_axi_awburst_reg <= 2'b01;
            m_axi_awlock_reg <= 1'b0;
            m_axi_awcache_reg <= 4'b0011;
            m_axi_awprot_reg <= 3'b000;
            m_axi_awvalid_reg <= 1'b0;

            m_axi_wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            m_axi_wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            m_axi_wlast_reg <= 1'b0;
            m_axi_wvalid_reg <= 1'b0;
            m_axi_bready_reg <= 1'b0;

            m_axi_arid_reg <= {AXI_ID_WIDTH{1'b0}};
            m_axi_araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            m_axi_arlen_reg <= 8'd0;
            m_axi_arsize_reg <= 3'd0;
            m_axi_arburst_reg <= 2'b01;
            m_axi_arlock_reg <= 1'b0;
            m_axi_arcache_reg <= 4'b0011;
            m_axi_arprot_reg <= 3'b000;
            m_axi_arvalid_reg <= 1'b0;
            m_axi_rready_reg <= 1'b0;
        end else begin
            // Read data FIFO write
            if (rd_data_wr_en) begin
                rd_data_fifo[rd_data_wr_ptr[0]] <= m_axi_rdata[AXIS_DATA_WIDTH-1:0];
                rd_keep_fifo[rd_data_wr_ptr[0]] <= {AXIS_KEEP_WIDTH{1'b1}};
                rd_data_valid[rd_data_wr_ptr[0]] <= 1'b1;
                rd_data_wr_ptr <= rd_data_wr_ptr + 2'd1;
            end

            // Read data FIFO read
            if (rd_data_rd_en) begin
                m_axis_read_data_tdata_reg <= rd_data_fifo[rd_data_rd_ptr[0]];
                m_axis_read_data_tkeep_reg <= rd_keep_fifo[rd_data_rd_ptr[0]];
                m_axis_read_data_tid_reg <= rd_id;
                m_axis_read_data_tdest_reg <= rd_dest;
                m_axis_read_data_tuser_reg <= rd_user;
                m_axis_read_data_tvalid_reg <= 1'b1;
                rd_data_valid[rd_data_rd_ptr[0]] <= 1'b0;
                rd_data_rd_ptr <= rd_data_rd_ptr + 2'd1;
            end else begin
                m_axis_read_data_tvalid_reg <= 1'b0;
            end

            // Read data tlast
            if (rd_data_rd_en) begin
                m_axis_read_data_tlast_reg <= (rd_len_remaining == DATA_BYTES);
            end

            // Write data FIFO write
            if (wr_data_wr_en) begin
                wr_data_fifo[wr_data_wr_ptr[0]] <= s_axis_write_data_tdata;
                wr_keep_fifo[wr_data_wr_ptr[0]] <= s_axis_write_data_tkeep;
                wr_data_valid[wr_data_wr_ptr[0]] <= 1'b1;
                wr_data_wr_ptr <= wr_data_wr_ptr + 2'd1;
            end

            // Write data FIFO read
            if (wr_data_rd_en) begin
                m_axi_wdata_reg <= wr_data_fifo[wr_data_rd_ptr[0]];
                m_axi_wstrb_reg <= wr_keep_fifo[wr_data_rd_ptr[0]];
                m_axi_wlast_reg <= s_axis_write_data_tlast;
                m_axi_wvalid_reg <= 1'b1;
                wr_data_valid[wr_data_rd_ptr[0]] <= 1'b0;
                wr_data_rd_ptr <= wr_data_rd_ptr + 2'd1;
            end else begin
                m_axi_wvalid_reg <= 1'b0;
            end

            // Read descriptor acceptance
            if (s_axis_read_desc_valid && rd_desc_ready) begin
                rd_addr <= s_axis_read_desc_addr;
                rd_len <= s_axis_read_desc_len;
                rd_len_remaining <= s_axis_read_desc_len;
                rd_tag <= s_axis_read_desc_tag;
                rd_id <= s_axis_read_desc_id;
                rd_dest <= s_axis_read_desc_dest;
                rd_user <= s_axis_read_desc_user;
                rd_active <= 1'b1;
                rd_done <= 1'b0;
                rd_error <= 4'd0;
                rd_burst_count <= 8'd0;
                rd_next_addr <= s_axis_read_desc_addr;
                rd_burst_last <= 1'b0;
                rd_status_valid <= 1'b0;
            end

            // Write descriptor acceptance
            if (s_axis_write_desc_valid && wr_desc_ready) begin
                wr_addr <= s_axis_write_desc_addr;
                wr_len <= s_axis_write_desc_len;
                wr_len_remaining <= s_axis_write_desc_len;
                wr_tag <= s_axis_write_desc_tag;
                wr_active <= 1'b1;
                wr_done <= 1'b0;
                wr_error <= 4'd0;
                wr_burst_count <= 8'd0;
                wr_next_addr <= s_axis_write_desc_addr;
                wr_burst_last <= 1'b0;
                wr_status_valid <= 1'b0;
            end

            // Read channel: Issue AXI read address
            if (rd_active && !arvalid_reg && !rd_done) begin
                if (rd_len_remaining > 0) begin
                    arid_reg <= {AXI_ID_WIDTH{1'b0}};
                    araddr_reg <= rd_next_addr;
                    arlen_reg <= calc_burst_len(rd_len_remaining);
                    arsize_reg <= $clog2(DATA_BYTES);
                    arburst_reg <= 2'b01; // INCR
                    arlock_reg <= 1'b0;
                    arcache_reg <= 4'b0011;
                    arprot_reg <= 3'b000;
                    arvalid_reg <= 1'b1;
                    rd_burst_len <= calc_burst_len(rd_len_remaining);
                end
            end

            // Read channel: AXI read address handshake
            if (arvalid_reg && m_axi_arready) begin
                arvalid_reg <= 1'b0;
                rd_len_remaining <= rd_len_remaining - (rd_burst_len + 1) * DATA_BYTES;
                rd_next_addr <= calc_next_addr(rd_next_addr, rd_burst_len);
                rd_burst_count <= rd_burst_len;
                rd_burst_last <= (rd_len_remaining <= (rd_burst_len + 1) * DATA_BYTES);
                rready_reg <= 1'b1;
            end

            // Read channel: AXI read data
            if (m_axi_rvalid && m_axi_rready) begin
                if (m_axi_rlast) begin
                    rready_reg <= 1'b0;
                    if (rd_len_remaining == 0) begin
                        rd_done <= 1'b1;
                        rd_active <= 1'b0;
                        rd_status_valid <= 1'b1;
                        rd_status_tag <= rd_tag;
                        rd_status_error <= rd_error;
                    end
                end
            end

            // Write channel: Issue AXI write address
            if (wr_active && !awvalid_reg && !wr_done && !wr_data_empty_wire) begin
                if (wr_len_remaining > 0) begin
                    awid_reg <= {AXI_ID_WIDTH{1'b0}};
                    awaddr_reg <= wr_next_addr;
                    awlen_reg <= calc_burst_len(wr_len_remaining);
                    awsize_reg <= $clog2(DATA_BYTES);
                    awburst_reg <= 2'b01; // INCR
                    awlock_reg <= 1'b0;
                    awcache_reg <= 4'b0011;
                    awprot_reg <= 3'b000;
                    awvalid_reg <= 1'b1;
                    wr_burst_len <= calc_burst_len(wr_len_remaining);
                end
            end

            // Write channel: AXI write address handshake
            if (awvalid_reg && m_axi_awready) begin
                awvalid_reg <= 1'b0;
                wr_len_remaining <= wr_len_remaining - (wr_burst_len + 1) * DATA_BYTES;
                wr_next_addr <= calc_next_addr(wr_next_addr, wr_burst_len);
                wr_burst_count <= wr_burst_len;
                wr_burst_last <= (wr_len_remaining <= (wr_burst_len + 1) * DATA