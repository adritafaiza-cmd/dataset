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

    // -----------------------------------------------------------------------
    // Internal Parameters and Constants
    // -----------------------------------------------------------------------
    localparam LOG2_AXI_MAX_BURST_LEN = $clog2(AXI_MAX_BURST_LEN);
    localparam LOG2_AXI_STRB_WIDTH    = $clog2(AXI_STRB_WIDTH);
    
    // State Machine States
    localparam IDLE = 3'd0;
    localparam AW_PREPARE = 3'd1;
    localparam AW_SEND = 3'd2;
    localparam W_PREPARE = 3'd3;
    localparam W_SEND = 3'd4;
    localparam B_WAIT = 3'd5;
    localparam AR_PREPARE = 3'd6;
    localparam AR_SEND = 3'd7;
    localparam R_PREPARE = 3'd8;
    localparam R_SEND = 3'd9;
    localparam R_WAIT = 3'd10;
    localparam FINISHED = 3'd11;

    // -----------------------------------------------------------------------
    // Internal Registers
    // -----------------------------------------------------------------------
    reg [2:0] state;
    reg [TAG_WIDTH-1:0] current_tag;
    reg [LEN_WIDTH-1:0] current_len;
    reg [AXI_ADDR_WIDTH-1:0] current_addr;
    reg [AXI_ID_WIDTH-1:0] current_id;
    reg [AXIS_DEST_WIDTH-1:0] current_dest;
    reg [AXIS_USER_WIDTH-1:0] current_user;
    reg [3:0] current_error;
    reg [7:0] axi_burst_len;
    reg [2:0] axi_burst_size;
    reg [1:0] axi_burst_type;
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg [AXI_DATA_WIDTH-1:0] rdata_reg;
    reg rlast_reg;
    reg [AXI_ID_WIDTH-1:0] rid_reg;
    reg rresp_reg;
    
    // AXI AW Channel State
    reg [7:0] aw_len_left;
    reg [2:0] aw_size_left;
    reg [1:0] aw_burst_type_left;
    reg aw_lock_left;
    reg aw_cache_left;
    reg aw_prot_left;
    reg aw_valid_left;
    reg aw_ready_left;
    
    // AXI W Channel State
    reg [7:0] w_len_left;
    reg w_last_left;
    reg w_valid_left;
    reg w_ready_left;
    
    // AXI B Channel State
    reg [1:0] b_resp_left;
    reg b_valid_left;
    reg b_ready_left;
    
    // AXI AR Channel State
    reg [7:0] ar_len_left;
    reg [2:0] ar_size_left;
    reg [1:0] ar_burst_type_left;
    reg ar_lock_left;
    reg ar_cache_left;
    reg ar_prot_left;
    reg ar_valid_left;
    reg ar_ready_left;
    
    // AXI R Channel State
    reg [7:0] r_len_left;
    reg r_last_left;
    reg r_valid_left;
    reg r_ready_left;
    
    // Stream Data Buffers
    reg [AXI_DATA_WIDTH-1:0] stream_data;
    reg [AXIS_KEEP_WIDTH-1:0] stream_keep;
    reg stream_last;
    reg stream_valid;
    reg stream_ready;
    reg stream_tdata_valid;
    reg stream_tkeep_valid;
    reg stream_tlast_valid;
    reg stream_tid_valid;
    reg stream_tdest_valid;
    reg stream_tuser_valid;
    
    // Write Stream Input Buffers
    reg [AXI_DATA_WIDTH-1:0] write_data_in;
    reg [AXIS_KEEP_WIDTH-1:0] write_keep_in;
    reg write_last_in;
    reg write_valid_in;
    reg write_tid_in;
    reg write_dest_in;
    reg write_user_in;
    reg write_ready_in;
    
    // Read Stream Output Buffers
    reg [AXI_DATA_WIDTH-1:0] read_data_out;
    reg [AXIS_KEEP_WIDTH-1:0] read_keep_out;
    reg read_last_out;
    reg read_valid_out;
    reg read_tid_out;
    reg read_dest_out;
    reg read_user_out;
    reg read_ready_out;
    
    // Status Output Buffers
    reg [LEN_WIDTH-1:0] write_status_len;
    reg [TAG_WIDTH-1:0] write_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_status_user;
    reg write_status_valid;
    reg write_status_ready;
    
    reg [TAG_WIDTH-1:0] read_status_tag;
    reg [3:0] read_status_error;
    reg read_status_valid;
    reg read_status_ready;

    // -----------------------------------------------------------------------
    // AXI Master Interface Logic
    // -----------------------------------------------------------------------
    
    // Address Width Mapping
    generate
        if (AXI_ADDR_WIDTH == 32) begin : addr_32
            assign m_axi_awaddr[31:0] = current_addr;
            assign m_axi_araddr[31:0] = current_addr;
        end
        else if (AXI_ADDR_WIDTH == 24) begin : addr_24
            assign m_axi_awaddr[23:0] = current_addr;
            assign m_axi_araddr[23:0] = current_addr;
        end
        else begin : addr_16
            assign m_axi_awaddr[15:0] = current_addr;
            assign m_axi_araddr[15:0] = current_addr;
        end
    endgenerate

    // AW Channel Control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            aw_len_left <= 8'd0;
            aw_size_left <= 3'd0;
            aw_burst_type_left <= 2'd0;
            aw_lock_left <= 1'b0;
            aw_cache_left <= 4'd0;
            aw_prot_left <= 3'd0;
            aw_valid_left <= 1'b0;
            aw_ready_left <= 1'b0;
        end else begin
            aw_len_left <= aw_len_left;
            aw_size_left <= aw_size_left;
            aw_burst_type_left <= aw_burst_type_left;
            aw_lock_left <= aw_lock_left;
            aw_cache_left <= aw_cache_left;
            aw_prot_left <= aw_prot_left;
            aw_valid_left <= aw_valid_left;
            aw_ready_left <= aw_ready_left;
        end
    end

    // W Channel Control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_len_left <= 8'd0;
            w_last_left <= 1'b0;
            w_valid_left <= 1'b0;
            w_ready_left <= 1'b0;
        end else begin
            w_len_left <= w_len_left;
            w_last_left <= w_last_left;
            w_valid_left <= w_valid_left;
            w_ready_left <= w_ready_left;
        end
    end

    // B Channel Control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            b_resp_left <= 2'd0;
            b_valid_left <= 1'b0;
            b_ready_left <= 1'b0;
        end else begin
            b_resp_left <= b_resp_left;
            b_valid_left <= b_valid_left;
            b_ready_left <= b_ready_left;
        end
    end

    // AR Channel Control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ar_len_left <= 8'd0;
            ar_size_left <= 3'd0;
            ar_burst_type_left <= 2'd0;
            ar_lock_left <= 1'b0;
            ar_cache_left <= 4'd0;
            ar_prot_left <= 3'd0;
            ar_valid_left <= 1'b0;
            ar_ready_left <= 1'b0;
        end else begin
            ar_len_left <= ar_len_left;
            ar_size_left <= ar_size_left;
            ar_burst_type_left <= ar_burst_type_left;
            ar_lock_left <= ar_lock_left;
            ar_cache_left <= ar_cache_left;
            ar_prot_left <= ar_prot_left;
            ar_valid_left <= ar_valid_left;
            ar_ready_left <= ar_ready_left;
        end
    end

    // R Channel Control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_len_left <= 8'd0;
            r_last_left <= 1'b0;
            r_valid_left <= 1'b0;
            r_ready_left <= 1'b0;
        end else begin
            r_len_left <= r_len_left;
            r_last_left <= r_last_left;
            r_valid_left <= r_valid_left;
            r_ready_left <= r_ready_left;
        end
    end

    // -----------------------------------------------------------------------
    // State Machine Logic
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            current_tag <= 8'd0;
            current_len <= 0;
            current_addr <= 0;
            current_id <= 0;
            current_dest <= 0;
            current_user <= 0;
            current_error <= 4'd0;
            axi_burst_len <= 8'd0;
            axi_burst_size <= 3'd0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wlast_reg <= 0;
            rdata_reg <= 0;
            rlast_reg <= 0;
            rid_reg <= 0;
            rresp_reg <= 2'd0;
            stream_data <= 0;
            stream_keep <= 0;
            stream_last <= 0;
            stream_valid <= 0;
            stream_tdata_valid <= 0;
            stream_tkeep_valid <= 0;
            stream_tlast_valid <= 0;
            stream_tid_valid <= 0;
            stream_tdest_valid <= 0;
            stream_tuser_valid <= 0;
            write_data_in <= 0;
            write_keep_in <= 0;
            write_last_in <= 0;
            write_valid_in <= 0;
            write_tid_in <= 0;
            write_dest_in <= 0;
            write_user_in <= 0;
            write_ready_in <= 0;
            read_data_out <= 0;
            read_keep_out <= 0;
            read_last_out <= 0;
            read_valid_out <= 0;
            read_tid_out <= 0;
            read_dest_out <= 0;
            read_user_out <= 0;
            read_ready_out <= 0;
            write_status_len <= 0;
            write_status_tag <= 0;
            write_status_id <= 0;
            write_status_dest <= 0;
            write_status_user <= 0;
            write_status_valid <= 0;
            write_status_ready <= 0;
            read_status_tag <= 0;
            read_status_error <= 4'd0;
            read_status_valid <= 0;
            read_status_ready <= 0;
        end else begin
            // State Transition Logic
            case (state)
                IDLE: begin
                    if (read_enable && s_axis_read_desc_valid && !s_axis_read_desc_ready) begin
                        s_axis_read_desc_ready <= 1'b1;
                        current_tag <= s_axis_read_desc_tag;
                        current_len <= s_axis_read_desc_len;
                        current_addr <= s_axis_read_desc_addr;
                        current_id <= s_axis_read_desc_id;
                        current_dest <= s_axis_read_desc_dest;
                        current_user <= s_axis_read_desc_user;
                        state <= AW_PREPARE;
                    end else if (write_enable && s_axis_write_desc_valid && !s_axis_write_desc_ready) begin
                        s_axis_write_desc_ready <= 1'b1;
                        current_tag <= s_axis_write_desc_tag;
                        current_len <= s_axis_write_desc_len;
                        current_addr <= s_axis_write_desc_addr;
                        current_id <= 0; // Write ID not used in desc input usually, but mapped to status
                        current_dest <= 0;
                        current_user <= 0;
                        state <= AW_PREPARE;
                    end else begin
                        s_axis_read_desc_ready <= 1'b0;
                        s_axis_write_desc_ready <= 1'b0;
                    end
                end

                AW_PREPARE: begin
                    if (m_axi_awready) begin
                        m_axi_awvalid <= 1'b1;
                        m_axi_awid <= current_id;
                        m_axi_awaddr <= current_addr;
                        m_axi_awlen <= axi_burst_len - 1;
                        m_axi_awsize <= axi_burst_size;
                        m_axi_awburst <= axi_burst_type;
                        m_axi_awlock <= 1'b0;
                        m_axi_awcache <= 4'd0;
                        m_axi_awprot <= 3'd0;
                        state <= AW_SEND;
                    end else begin
                        m_axi_awvalid <= 1'b0;
                    end
                end

                AW_SEND: begin
                    if (m_axi_awready) begin
                        m_axi_awvalid <= 1'b1;
                        m_axi_awid <= current_id;
                        m_axi_awaddr <= current_addr;
                        m_axi_awlen <= axi_burst_len - 1;
                        m_axi_awsize <= axi_burst_size;
                        m_axi_awburst <= axi_burst_type;
                        m_axi_awlock <= 1'b0;
                        m_axi_awcache <= 4'd0;
                        m_axi_awprot <= 3'd0;
                        state <= W_PREPARE;
                    end else begin
                        m_axi_awvalid <= 1'b0;
                    end
                end

                W_PREPARE: begin
                    if (m_axi_wready) begin
                        m_axi_wvalid <= 1'b1;
                        m_axi_wdata <= wdata_reg;
                        m_axi_wstrb <= wstrb_reg;
                        m_axi_wlast <= wlast_reg;
                        state <= W_SEND;
                    end else begin
                        m_axi_wvalid <= 1'b0;
                    end
                end

                W_SEND: begin
                    if (m_axi_wready) begin
                        m_axi_wvalid <= 1'b1;
                        m_axi_wdata <= wdata_reg;
                        m_axi_wstrb <= wstrb_reg;
                        m_axi_wlast <= wlast_reg;
                        state <= B_WAIT;
                    end else begin
                        m_axi_wvalid <= 1'b0;
                    end
                end

                B_WAIT: begin
                    if (m_axi_bvalid && !m_axi_bready) begin
                        m_axi_bready <= 1'b1;
                        b_resp_left <= m_axi_bresp;
                        b_valid_left <= 1'b1;
                        state <= AR_PREPARE;
                    end else begin
                        m_axi_bready <= 1'b0;
                    end
                end

                AR_PREPARE: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 1'b1;
                        m_axi_arid <= current_id;
                        m_axi_araddr <= current_addr;
                        m_axi_arlen <= axi_burst_len - 1;
                        m_axi_arsize <= axi_burst_size;
                        m_axi_arburst <= axi_burst_type;
                        m_axi_arlock <= 1'b0;
                        m_axi_arcache <= 4'd0;
                        m_axi_arprot <= 3'd0;
                        state <= AR_SEND;
                    end else begin
                        m_axi_arvalid <= 1'b0;
                    end
                end

                AR_SEND: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 1'b1;
                        m_axi_arid <= current_id;
                        m_axi_araddr <= current_addr;
                        m_axi_arlen <= axi_burst_len - 1;
                        m_axi_arsize <= axi_burst_size;
                        m_axi_arburst <= axi_burst_type;
                        m_axi_arlock <= 1'b0;
                        m_axi_arcache <= 4'd0;
                        m_axi_arprot <= 3'd0;
                        state <= R_PREPARE;
                    end else begin
                        m_axi_arvalid <= 1'b0;
                    end
                end

                R_PREPARE: begin
                    if (m_axi_rready) begin
                        m_axi_rvalid <= 1'b1;
                        state <= R_SEND;
                    end else begin
                        m_axi_rvalid <= 1'b0;
                    end
                end

                R_SEND: begin
                    if (m_axi_rready) begin
                        m_axi_rvalid <= 1'b1;
                        state <= R_WAIT;
                    end else begin
                        m_axi_rvalid <= 1'b0;
                    end
                end

                R_WAIT: begin
                    if (m_axi_rvalid && !m_axi_rready) begin
                        m_axi_rready <= 1'b1;
                        rdata_reg <= m_axi_rdata;
                        rlast_reg <= m_axi_rlast;
                        rid_reg <= m_axi_rid;
                        rresp_reg <= m_axi_rresp;
                        state <= FINISHED;
                    end else begin
                        m_axi_rready <= 1'b0;
                    end
                end

                FINISHED: begin
                    // Generate Status
                    write_status_len <= current_len;
                    write_status_tag <= current_tag;
                    write_status_id <= current_id;
                    write_status_dest <= current_dest;
                    write_status_user <= current_user;
                    write_status_error <= current_error;
                    write_status_valid <= 1'b1;
                    write_status_ready <= 1'b0;
                    
                    read_status_tag <= current_tag;
                    read_status_error <= current_error;
                    read_status_valid <= 1'b1;
                    read_status_ready <= 1'b0;
                    
                    state <= IDLE;
                end
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // AXI Master Interface Output Logic
    // -----------------------------------------------------------------------
    
    // AW Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_awid <= 0;
            m_axi_awaddr <= 0;
            m_axi_awlen <= 0;
            m_axi_awsize <= 0;
            m_axi_awburst <= 0;
            m_axi_awlock <= 0;
            m_axi_awcache <= 0;
            m_axi_awprot <= 0;
            m_axi_awvalid <= 0;
            m_axi_awready <= 0;
        end else begin
            m_axi_awid <= m_axi_awid;
            m_axi_awaddr <= m_axi_awaddr;
            m_axi_awlen <= m_axi_awlen;
            m_axi_awsize <= m_axi_awsize;
            m_axi_awburst <= m_axi_awburst;
            m_axi_awlock <= m_axi_awlock;
            m_axi_awcache <= m_axi_awcache;
            m_axi_awprot <= m_axi_awprot;
            m_axi_awvalid <= m_axi_awvalid;
            m_axi_awready <= m_axi_awready;
        end
    end

    // W Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_wdata <= 0;
            m_axi_wstrb <= 0;
            m_axi_wlast <= 0;
            m_axi_wvalid <= 0;
            m_axi_wready <= 0;
        end else begin
            m_axi_wdata <= m_axi_wdata;
            m_axi_wstrb <= m_axi_wstrb;
            m_axi_wlast <= m_axi_wlast;
            m_axi_wvalid <= m_axi_wvalid;
            m_axi_wready <= m_axi_wready;
        end
    end

    // B Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_bid <= 0;
            m_axi_bresp <= 0;
            m_axi_bvalid <= 0;
            m_axi_bready <= 0;
        end else begin
            m_axi_bid <= m_axi_bid;
            m_axi_bresp <= m_axi_bresp;
            m_axi_bvalid <= m_axi_bvalid;
            m_axi_bready <= m_axi_bready;
        end
    end

    // AR Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_arid <= 0;
            m_axi_araddr <= 0;
            m_axi_arlen <= 0;
            m_axi_arsize <= 0;
            m_axi_arburst <= 0;
            m_axi_arlock <= 0;
            m_axi_arcache <= 0;
            m_axi_arprot <= 0;
            m_axi_arvalid <= 0;
            m_axi_arready <= 0;
        end else begin
            m_axi_arid <= m_axi_arid;
            m_axi_araddr <= m_axi_araddr;
            m_axi_arlen <= m_axi_arlen;
            m_axi_arsize <= m_axi_arsize;
            m_axi_arburst <= m_axi_arburst;
            m_axi_arlock <= m_axi_arlock;
            m_axi_arcache <= m_axi_arcache;
            m_axi_arprot <= m_axi_arprot;
            m_axi_arvalid <= m_axi_arvalid;
            m_axi_arready <= m_axi_arready;
        end
    end

    // R Channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_rid <= 0;
            m_axi_rdata <= 0;
            m_axi_rresp <= 0;
            m_axi_rlast <= 0;
            m_axi_rvalid <= 0;
            m_axi_rready <= 0;
        end else begin
            m_axi_rid <= m_axi_rid;
            m_axi_rdata <= m_axi_rdata;
            m_axi_rresp <= m_axi_rresp;
            m_axi_rlast <= m_axi_rlast;
            m_axi_rvalid <= m_axi_rvalid;
            m_axi_rready <= m_axi_rready;
        end
    end

    // -----------------------------------------------------------------------
    // Stream Data Logic (Read Path)
    // -----------------------------------------------------------------------
    
    // Calculate AXI Burst Parameters
    always @(*) begin
        axi_burst_len = 8'd0;
        axi_burst_size = 3'd0;
        axi_burst_type = 2'd0; // FIXED
        wdata_reg = 0;
        wstrb_reg = 0;
        wlast_reg = 0;
        
        if (current_len == 0) begin
            axi_burst_len = 0;
        end else begin
            // Align length to AXI burst length
            if (ENABLE_UNALIGNED) begin
                axi_burst_len = current_len - 1;
            end else begin
                // Round up to nearest multiple of AXI_MAX_BURST_LEN
                localparam LOG2_MAX = $clog2(AXI_MAX_BURST_LEN);
                localparam ALIGN_MASK = (1 << LOG2_MAX) - 1;
                localparam ALIGNED_LEN = (current_len + AXI_MAX_BURST_LEN - 1) & ~ALIGN_MASK;
                axi_burst_len = ALIGNED_LEN - 1;
            end
            
            // Determine size based on alignment
            if (ENABLE_UNALIGNED) begin
                axi_burst_size = 3'd0; // Byte
            end else begin
                // Find largest power of 2 size that fits
                localparam SIZE_256 = 3'd8;
                localparam SIZE_128 = 3'd7;
                localparam SIZE_64 = 3'd6;
                localparam SIZE_32 = 3'd5;
                localparam SIZE_16 = 3'd4;
                localparam SIZE_8 = 3'd3;
                localparam SIZE_4 = 3'd2;
                localparam SIZE_2 = 3'd1;
                localparam SIZE_1 = 3'd0;
                
                if (current_len >= 256) axi_burst_size = SIZE_256;
                else if (current_len >= 128) axi_burst_size = SIZE_128;
                else if (current_len >= 64) axi_burst_size = SIZE_64;
                else if (current_len >= 32) axi_burst_size = SIZE_32;
                else if (current_len >= 16) axi_burst_size = SIZE_16;
                else if (current_len >= 8) axi_burst_size = SIZE_8;
                else if (current_len >= 4) axi_burst_size = SIZE_4;
                else if (current_len >= 2) axi_burst_size = SIZE_2;
                else axi_burst_size = SIZE_1;
            end
            
            // Generate Write Data and Strb for first beat
            if (current_len > 0) begin
                wdata_reg = 0;
                wstrb_reg = 0;
                // In a real implementation, this would fetch data from memory or buffer.
                // Since this is a DMA engine moving data, we assume data comes from the AXI read response
                // or an external source. For this simplified model, we initialize with 0.
                // A full implementation would require a FIFO between the AXI read response and the stream output.
                // Here we assume the data is available in rdata_reg after the read completes.
                // However, the state machine structure above is slightly simplified for a single-file constraint.
                // We will assume the data path is handled by the R_WAIT state feeding the stream.
            end
        end
    end

    // Stream Output Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_read_data_tdata <= 0;
            m_axis_read_data_tkeep <= 0;
            m_axis_read_data_tvalid <= 0;
            m_axis_read_data_tlast <= 0;
            m_axis_read_data_tid <= 0;
            m_axis_read_data_tdest <= 0;
            m_axis_read_data_tuser <= 0;
            read_valid_out <= 0;
            read_ready_out <= 0;
        end else begin
            m_axis_read_data_tdata <= m_axis_read_data_tdata;
            m_axis_read_data_tkeep <= m_axis_read_data_tkeep;
            m_axis_read_data_tvalid <= m_axis_read_data_tvalid;
            m_axis_read_data_tlast <= m_axis_read_data_tlast;
            m_axis_read_data_tid <= m_axis_read_data_tid;
            m_axis_read_data_tdest <= m_axis_read_data_tdest;
            m_axis_read_data_tuser <= m_axis_read_data_tuser;
            read_valid_out <= read_valid_out;
            read_ready_out <= read_ready_out;
        end
    end

    // Stream Input Logic (Write Path)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_data_in <= 0;
            write_keep_in <=