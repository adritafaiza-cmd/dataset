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

    // Internal parameters
    localparam LOG2_AXI_MAX_BURST_LEN = $clog2(AXI_MAX_BURST_LEN);
    localparam LOG2_AXI_STRB_WIDTH    = $clog2(AXI_STRB_WIDTH);

    // State encoding
    localparam IDLE = 3'd0;
    localparam AW_PREPARE = 3'd1;
    localparam AW_SEND = 3'd2;
    localparam W_PREPARE = 3'd3;
    localparam W_SEND = 3'd4;
    localparam B_WAIT = 3'd5;
    localparam AR_PREPARE = 3'd6;
    localparam AR_SEND = 3'd7;
    localparam R_PREPARE = 3'd8;
    localparam R_WAIT = 3'd9;
    localparam R_DONE = 3'd10;
    localparam WRITE_ABORT = 3'd11;

    reg [2:0] state;
    reg [TAG_WIDTH-1:0] current_tag;
    reg [LEN_WIDTH-1:0] current_len;
    reg [AXI_ADDR_WIDTH-1:0] current_addr;
    reg [AXIS_ID_WIDTH-1:0] current_id;
    reg [AXIS_DEST_WIDTH-1:0] current_dest;
    reg [AXIS_USER_WIDTH-1:0] current_user;
    reg [AXI_ID_WIDTH-1:0] current_axi_id;
    reg [3:0] current_error;
    reg write_in_progress;
    reg read_in_progress;
    reg write_abort_flag;

    // AXI Write State Machine
    reg [7:0] axi_wlen;
    reg [2:0] axi_wsize;
    reg [1:0] axi_wburst;
    reg axi_wlock;
    reg [3:0] axi_wcache;
    reg [2:0] axi_wprot;
    reg axi_wlast;
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    reg wlast_reg;
    reg wready_reg;
    reg wvalid_pending;

    // AXI Read State Machine
    reg [7:0] axi_arlen;
    reg [2:0] axi_arsize;
    reg [1:0] axi_arburst;
    reg axi_arlock;
    reg [3:0] axi_arcache;
    reg [2:0] axi_arprot;
    reg axi_arvalid_reg;
    reg axi_arready_reg;
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [AXI_DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rlast_reg;
    reg rvalid_reg;
    reg rready_reg;
    reg rvalid_pending;

    // Stream Write State
    reg [7:0] stream_wlen;
    reg [2:0] stream_wsize;
    reg [1:0] stream_wburst;
    reg stream_wlock;
    reg [3:0] stream_wcache;
    reg [2:0] stream_wprot;
    reg stream_wlast;
    reg [AXI_DATA_WIDTH-1:0] stream_wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] stream_wstrb_reg;
    reg stream_wvalid_reg;
    reg stream_wlast_reg;
    reg stream_wready_reg;
    reg stream_wvalid_pending;

    // Stream Read State
    reg [7:0] stream_rlen;
    reg [2:0] stream_rsize;
    reg [1:0] stream_rburst;
    reg stream_rlock;
    reg [3:0] stream_rcache;
    reg [2:0] stream_rprot;
    reg stream_rvalid_reg;
    reg stream_rready_reg;
    reg stream_rvalid_pending;
    reg [AXI_DATA_WIDTH-1:0] stream_rdata_reg;
    reg [1:0] stream_rresp_reg;
    reg stream_rlast_reg;

    // AXI Write Data Buffer
    reg [AXI_DATA_WIDTH-1:0] wdata_buf [AXI_MAX_BURST_LEN];
    reg [AXI_STRB_WIDTH-1:0] wstrb_buf [AXI_MAX_BURST_LEN];
    reg [AXI_DATA_WIDTH-1:0] wdata_ptr;
    reg [AXI_DATA_WIDTH-1:0] wstrb_ptr;
    reg [AXI_DATA_WIDTH-1:0] wdata_next;
    reg [AXI_STRB_WIDTH-1:0] wstrb_next;
    reg wdata_valid;
    reg wstrb_valid;
    reg wdata_ready;
    reg wstrb_ready;

    // AXI Read Data Buffer
    reg [AXI_DATA_WIDTH-1:0] rdata_buf [AXI_MAX_BURST_LEN];
    reg [1:0] rresp_buf [AXI_MAX_BURST_LEN];
    reg rlast_buf [AXI_MAX_BURST_LEN];
    reg [AXI_DATA_WIDTH-1:0] rdata_ptr;
    reg [AXI_DATA_WIDTH-1:0] rdata_next;
    reg [1:0] rresp_next;
    reg rlast_next;
    reg rdata_valid;
    reg rdata_ready;
    reg rdata_ptr_valid;

    // Stream Write Data Buffer
    reg [AXI_DATA_WIDTH-1:0] swdata_buf [AXI_MAX_BURST_LEN];
    reg [AXI_STRB_WIDTH-1:0] swstrb_buf [AXI_MAX_BURST_LEN];
    reg [AXI_DATA_WIDTH-1:0] swdata_ptr;
    reg [AXI_DATA_WIDTH-1:0] swstrb_ptr;
    reg [AXI_DATA_WIDTH-1:0] swdata_next;
    reg [AXI_STRB_WIDTH-1:0] swstrb_next;
    reg swdata_valid;
    reg swstrb_valid;
    reg swdata_ready;
    reg swstrb_ready;

    // Stream Read Data Buffer
    reg [AXI_DATA_WIDTH-1:0] srdata_buf [AXI_MAX_BURST_LEN];
    reg [1:0] srresp_buf [AXI_MAX_BURST_LEN];
    reg srlast_buf [AXI_MAX_BURST_LEN];
    reg [AXI_DATA_WIDTH-1:0] srdata_ptr;
    reg [AXI_DATA_WIDTH-1:0] srdata_next;
    reg [1:0] srresp_next;
    reg srlast_next;
    reg srdata_valid;
    reg srdata_ready;
    reg srdata_ptr_valid;

    // AXI Write Data Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_valid <= 1'b0;
            wstrb_valid <= 1'b0;
            wdata_ptr <= 0;
            wstrb_ptr <= 0;
            wdata_next <= 0;
            wstrb_next <= 0;
            wdata_ready <= 1'b1;
            wstrb_ready <= 1'b1;
        end else begin
            wdata_valid <= wdata_valid | wdata_next;
            wstrb_valid <= wstrb_valid | wstrb_next;
            wdata_ptr <= wdata_ptr + wdata_next;
            wstrb_ptr <= wstrb_ptr + wstrb_next;
            wdata_ready <= 1'b1;
            wstrb_ready <= 1'b1;
        end
    end

    // AXI Read Data Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_valid <= 1'b0;
            rdata_ptr <= 0;
            rdata_next <= 0;
            rdata_ready <= 1'b1;
            rdata_ptr_valid <= 1'b0;
        end else begin
            rdata_valid <= rdata_valid | rdata_next;
            rdata_ptr <= rdata_ptr + rdata_next;
            rdata_ready <= 1'b1;
            rdata_ptr_valid <= rdata_ptr_valid | rdata_next;
        end
    end

    // Stream Write Data Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            swdata_valid <= 1'b0;
            swstrb_valid <= 1'b0;
            swdata_ptr <= 0;
            swstrb_ptr <= 0;
            swdata_next <= 0;
            swstrb_next <= 0;
            swdata_ready <= 1'b1;
            swstrb_ready <= 1'b1;
        end else begin
            swdata_valid <= swdata_valid | swdata_next;
            swstrb_valid <= swstrb_valid | swstrb_next;
            swdata_ptr <= swdata_ptr + swdata_next;
            swstrb_ptr <= swstrb_ptr + swstrb_next;
            swdata_ready <= 1'b1;
            swstrb_ready <= 1'b1;
        end
    end

    // Stream Read Data Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srdata_valid <= 1'b0;
            srdata_ptr <= 0;
            srdata_next <= 0;
            srdata_ready <= 1'b1;
            srdata_ptr_valid <= 1'b0;
        end else begin
            srdata_valid <= srdata_valid | srdata_next;
            srdata_ptr <= srdata_ptr + srdata_next;
            srdata_ready <= 1'b1;
            srdata_ptr_valid <= srdata_ptr_valid | srdata_next;
        end
    end

    // AXI Write Data Buffer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer i = 0; i < AXI_MAX_BURST_LEN; i = i + 1) begin
                wdata_buf[i] <= 0;
                wstrb_buf[i] <= 0;
            end
        end else begin
            if (wdata_valid) begin
                wdata_buf[wdata_ptr] <= wdata_next;
                wstrb_buf[wstrb_ptr] <= wstrb_next;
            end
        end
    end

    // AXI Read Data Buffer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer i = 0; i < AXI_MAX_BURST_LEN; i = i + 1) begin
                rdata_buf[i] <= 0;
                rresp_buf[i] <= 0;
                rlast_buf[i] <= 0;
            end
        end else begin
            if (rdata_valid) begin
                rdata_buf[rdata_ptr] <= rdata_next;
                rresp_buf[rresp_ptr] <= rresp_next;
                rlast_buf[rdata_ptr] <= rlast_next;
            end
        end
    end

    // Stream Write Data Buffer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer i = 0; i < AXI_MAX_BURST_LEN; i = i + 1) begin
                swdata_buf[i] <= 0;
                swstrb_buf[i] <= 0;
            end
        end else begin
            if (swdata_valid) begin
                swdata_buf[swdata_ptr] <= swdata_next;
                swstrb_buf[swstrb_ptr] <= swstrb_next;
            end
        end
    end

    // Stream Read Data Buffer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer i = 0; i < AXI_MAX_BURST_LEN; i = i + 1) begin
                srdata_buf[i] <= 0;
                srresp_buf[i] <= 0;
                srlast_buf[i] <= 0;
            end
        end else begin
            if (srdata_valid) begin
                srdata_buf[srdata_ptr] <= srdata_next;
                srresp_buf[srresp_ptr] <= srresp_next;
                srlast_buf[srdata_ptr] <= srlast_next;
            end
        end
    end

    // AXI Write Data Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_next <= 0;
            wstrb_next <= 0;
        end else begin
            if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                wdata_next <= 1'b1;
                wstrb_next <= 1'b1;
            end else begin
                wdata_next <= 1'b0;
                wstrb_next <= 1'b0;
            end
        end
    end

    // AXI Read Data Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_next <= 0;
        end else begin
            if (m_axi_rvalid && m_axi_rready) begin
                rdata_next <= 1'b1;
            end else begin
                rdata_next <= 1'b0;
            end
        end
    end

    // Stream Write Data Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            swdata_next <= 0;
            swstrb_next <= 0;
        end else begin
            if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                swdata_next <= 1'b1;
                swstrb_next <= 1'b1;
            end else begin
                swdata_next <= 1'b0;
                swstrb_next <= 1'b0;
            end
        end
    end

    // Stream Read Data Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srdata_next <= 0;
        end else begin
            if (m_axi_rvalid && m_axi_rready) begin
                srdata_next <= 1'b1;
            end else begin
                srdata_next <= 1'b0;
            end
        end
    end

    // AXI Write Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_ptr <= 0;
            wstrb_ptr <= 0;
        end else begin
            if (wdata_valid) begin
                wdata_ptr <= wdata_ptr + 1;
                wstrb_ptr <= wstrb_ptr + 1;
            end
        end
    end

    // AXI Read Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_ptr <= 0;
        end else begin
            if (rdata_valid) begin
                rdata_ptr <= rdata_ptr + 1;
            end
        end
    end

    // Stream Write Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            swdata_ptr <= 0;
            swstrb_ptr <= 0;
        end else begin
            if (swdata_valid) begin
                swdata_ptr <= swdata_ptr + 1;
                swstrb_ptr <= swstrb_ptr + 1;
            end
        end
    end

    // Stream Read Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srdata_ptr <= 0;
        end else begin
            if (srdata_valid) begin
                srdata_ptr <= srdata_ptr + 1;
            end
        end
    end

    // AXI Write Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_valid <= 1'b0;
            wstrb_valid <= 1'b0;
        end else begin
            if (wdata_ptr < AXI_MAX_BURST_LEN && wstrb_ptr < AXI_MAX_BURST_LEN) begin
                wdata_valid <= 1'b1;
                wstrb_valid <= 1'b1;
            end else begin
                wdata_valid <= 1'b0;
                wstrb_valid <= 1'b0;
            end
        end
    end

    // AXI Read Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_valid <= 1'b0;
        end else begin
            if (rdata_ptr < AXI_MAX_BURST_LEN) begin
                rdata_valid <= 1'b1;
            end else begin
                rdata_valid <= 1'b0;
            end
        end
    end

    // Stream Write Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            swdata_valid <= 1'b0;
            swstrb_valid <= 1'b0;
        end else begin
            if (swdata_ptr < AXI_MAX_BURST_LEN && swstrb_ptr < AXI_MAX_BURST_LEN) begin
                swdata_valid <= 1'b1;
                swstrb_valid <= 1'b1;
            end else begin
                swdata_valid <= 1'b0;
                swstrb_valid <= 1'b0;
            end
        end
    end

    // Stream Read Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srdata_valid <= 1'b0;
        end else begin
            if (srdata_ptr < AXI_MAX_BURST_LEN) begin
                srdata_valid <= 1'b1;
            end else begin
                srdata_valid <= 1'b0;
            end
        end
    end

    // AXI Write Data Buffer Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_next <= 1'b0;
            wstrb_next <= 1'b0;
        end else begin
            if (wdata_valid && wdata_ptr < AXI_MAX_BURST_LEN - 1) begin
                wdata_next <= 1'b1;
                wstrb_next <= 1'b1;
            end else begin
                wdata_next <= 1'b0;
                wstrb_next <= 1'b0;
            end
        end
    end

    // AXI Read Data Buffer Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_next <= 1'b0;
        end else begin
            if (rdata_valid && rdata_ptr < AXI_MAX_BURST_LEN - 1) begin
                rdata_next <= 1'b1;
            end else begin
                rdata_next <= 1'b0;
            end
        end
    end

    // Stream Write Data Buffer Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            swdata_next <= 1'b0;
            swstrb_next <= 1'b0;
        end else begin
            if (swdata_valid && swdata_ptr < AXI_MAX_BURST_LEN - 1) begin
                swdata_next <= 1'b1;
                swstrb_next <= 1'b1;
            end else begin
                swdata_next <= 1'b0;
                swstrb_next <= 1'b0;
            end
        end
    end

    // Stream Read Data Buffer Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srdata_next <= 1'b0;
        end else begin
            if (srdata_valid && srdata_ptr < AXI_MAX_BURST_LEN - 1) begin
                srdata_next <= 1'b1;
            end else begin
                srdata_next <= 1'b0;
            end
        end
    end

    // AXI Write Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_ptr <= 0;
            wstrb_ptr <= 0;
        end else begin
            if (wdata_valid) begin
                wdata_ptr <= wdata_ptr + 1;
                wstrb_ptr <= wstrb_ptr + 1;
            end
        end
    end

    // AXI Read Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_ptr <= 0;
        end else begin
            if (rdata_valid) begin
                rdata_ptr <= rdata_ptr + 1;
            end
        end
    end

    // Stream Write Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            swdata_ptr <= 0;
            swstrb_ptr <= 0;
        end else begin
            if (swdata_valid) begin
                swdata_ptr <= swdata_ptr + 1;
                swstrb_ptr <= swstrb_ptr + 1;
            end
        end
    end

    // Stream Read Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srdata_ptr <= 0;
        end else begin
            if (srdata_valid) begin
                srdata_ptr <= srdata_ptr + 1;
            end
        end
    end

    // AXI Write Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_valid <= 1'b0;
            wstrb_valid <= 1'b0;
        end else begin
            if (wdata_ptr < AXI_MAX_BURST_LEN && wstrb_ptr < AXI_MAX_BURST_LEN) begin
                wdata_valid <= 1'b1;
                wstrb_valid <= 1'b1;
            end else begin
                wdata_valid <= 1'b0;
                wstrb_valid <= 1'b0;
            end
        end
    end

    // AXI Read Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_valid <= 1'b0;
        end else begin
            if (rdata_ptr < AXI_MAX_BURST_LEN) begin
                rdata_valid <= 1'b1;
            end else begin
                rdata_valid <= 1'b0;
            end
        end
    end

    // Stream Write Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            swdata_valid <= 1'b0;
            swstrb_valid <= 1'b0;
        end else begin
            if (swdata_ptr < AXI_MAX_BURST_LEN && swstrb_ptr < AXI_MAX_BURST_LEN) begin
                swdata_valid <= 1'b1;
                swstrb_valid <= 1'b1;
            end else begin
                swdata_valid <= 1'b0;
                swstrb_valid <= 1'b0;
            end
        end
    end

    // Stream Read Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srdata_valid <= 1'b0;
        end else begin
            if (srdata_ptr < AXI_MAX_BURST_LEN) begin
                srdata_valid <= 1'b1;
            end else begin
                srdata_valid <= 1'b0;
            end
        end
    end

    // AXI Write Data Buffer Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_next <= 1'b0;
            wstrb_next <= 1'b0;
        end else begin
            if (wdata_valid && wdata_ptr < AXI_MAX_BURST_LEN - 1) begin
                wdata_next <= 1'b1;
                wstrb_next <= 1'b1;
            end else begin
                wdata_next <= 1'b0;
                wstrb_next <= 1'b0;
            end
        end
    end

    // AXI Read Data Buffer Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_next <= 1'b0;
        end else begin
            if (rdata_valid && rdata_ptr < AXI_MAX_BURST_LEN - 1) begin
                rdata_next <= 1'b1;
            end else begin
                rdata_next <= 1'b0;
            end
        end
    end

    // Stream Write Data Buffer Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            swdata_next <= 1'b0;
            swstrb_next <= 1'b0;
        end else begin
            if (swdata_valid && swdata_ptr < AXI_MAX_BURST_LEN - 1) begin
                swdata_next <= 1'b1;
                swstrb_next <= 1'b1;
            end else begin
                swdata_next <= 1'b0;
                swstrb_next <= 1'b0;
            end
        end
    end

    // Stream Read Data Buffer Next Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srdata_next <= 1'b0;
        end else begin
            if (srdata_valid && srdata_ptr < AXI_MAX_BURST_LEN - 1) begin
                srdata_next <= 1'b1;
            end else begin
                srdata_next <= 1'b0;
            end
        end
    end

    // AXI Write Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_ptr <= 0;
            wstrb_ptr <= 0;
        end else begin
            if (wdata_valid) begin
                wdata_ptr <= wdata_ptr + 1;
                wstrb_ptr <= wstrb_ptr + 1;
            end
        end
    end

    // AXI Read Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata_ptr <= 0;
        end else begin
            if (rdata_valid) begin
                rdata_ptr <= rdata_ptr + 1;
            end
        end
    end

    // Stream Write Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            swdata_ptr <= 0;
            swstrb_ptr <= 0;
        end else begin
            if (swdata_valid) begin
                swdata_ptr <= swdata_ptr + 1;
                swstrb_ptr <= swstrb_ptr + 1;
            end
        end
    end

    // Stream Read Data Buffer Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srdata_ptr <= 0;
        end else begin
            if (srdata_valid) begin
                srdata_ptr <= srdata_ptr + 1;
            end
        end
    end

    // AXI Write Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wdata_valid <= 1'b0;
            wstrb_valid <= 1'b0;
        end else begin
            if (wdata_ptr < AXI_MAX_BURST_LEN && wstrb_ptr < AXI_MAX_BURST_LEN) begin
                wdata_valid <= 1'b1;
                wstrb_valid <= 1'b1;
            end else begin
                wdata_valid <= 1'b0;
                wstrb_valid <= 1'b0;
            end
        end
    end

    // AXI Read Data Buffer Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin