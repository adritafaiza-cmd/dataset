```verilog
`timescale 1ns/1ps

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
    localparam AXIS_KEEP_WIDTH_LOG = $clog2(AXIS_KEEP_WIDTH + 1);
    localparam AXIS_USER_WIDTH_LOG = $clog2(AXIS_USER_WIDTH + 1);
    localparam AXIS_DEST_WIDTH_LOG = $clog2(AXIS_DEST_WIDTH + 1);
    localparam AXIS_ID_WIDTH_LOG   = $clog2(AXIS_ID_WIDTH + 1);
    localparam AXI_STRB_WIDTH_LOG  = $clog2(AXI_STRB_WIDTH + 1);
    localparam AXI_ADDR_WIDTH_LOG  = $clog2(AXI_ADDR_WIDTH + 1);
    localparam AXI_ID_WIDTH_LOG    = $clog2(AXI_ID_WIDTH + 1);

    // State Machine States
    localparam IDLE = 2'b00;
    localparam READ_DESC = 2'b01;
    localparam WRITE_DESC = 2'b10;
    localparam TRANSFER_READ = 2'b11;
    localparam TRANSFER_WRITE = 2'b100;
    localparam FINISHED = 2'b101;

    reg [1:0] state;
    reg [LEN_WIDTH-1:0] remaining_len;
    reg [AXI_ADDR_WIDTH-1:0] current_addr;
    reg [TAG_WIDTH-1:0] current_tag;
    reg [AXIS_ID_WIDTH-1:0] current_id;
    reg [AXIS_DEST_WIDTH-1:0] current_dest;
    reg [AXIS_USER_WIDTH-1:0] current_user;
    reg [AXI_ID_WIDTH-1:0] current_axi_id;
    reg [3:0] current_error;
    reg read_mode; // 1 for read, 0 for write
    reg burst_complete;
    reg [7:0] burst_len;
    reg [2:0] burst_size;
    reg [1:0] burst_type;
    reg [3:0] burst_cache;
    reg [2:0] burst_prot;
    reg [AXI_ADDR_WIDTH-1:0] last_addr;
    reg [AXI_DATA_WIDTH-1:0] last_data;
    reg [1:0] last_resp;
    reg [AXI_ID_WIDTH-1:0] last_bid;
    reg [AXI_ID_WIDTH-1:0] last_rid;
    reg [AXI_ADDR_WIDTH-1:0] last_araddr;
    reg [7:0] last_arlen;
    reg [2:0] last_arsize;
    reg [1:0] last_arburst;
    reg [AXI_ID_WIDTH-1:0] last_awid;
    reg [AXI_ADDR_WIDTH-1:0] last_awaddr;
    reg [7:0] last_awlen;
    reg [2:0] last_awsize;
    reg [1:0] last_awburst;
    reg [AXI_ID_WIDTH-1:0] last_bid_reg;
    reg [AXI_DATA_WIDTH-1:0] last_wdata;
    reg [AXI_STRB_WIDTH-1:0] last_wstrb;
    reg last_wlast;

    // AXI Master Control Signals
    reg m_axi_awvalid;
    reg m_axi_arvalid;
    reg m_axi_wvalid;
    reg m_axi_bready;
    reg m_axi_rready;
    reg m_axi_wlast;
    reg m_axi_wvalid_next;
    reg m_axi_awvalid_next;
    reg m_axi_arvalid_next;
    reg m_axi_bready_next;
    reg m_axi_rready_next;
    reg m_axi_wlast_next;

    // Stream Output Registers
    reg [AXIS_DATA_WIDTH-1:0] reg_tdata;
    reg [AXIS_KEEP_WIDTH-1:0] reg_tkeep;
    reg reg_tvalid;
    reg reg_tlast;
    reg [AXIS_ID_WIDTH-1:0] reg_tid;
    reg [AXIS_DEST_WIDTH-1:0] reg_tdest;
    reg [AXIS_USER_WIDTH-1:0] reg_tuser;

    // Stream Input Registers
    reg [AXI_DATA_WIDTH-1:0] reg_wdata;
    reg [AXI_STRB_WIDTH-1:0] reg_wstrb;
    reg reg_wvalid;
    reg reg_wlast;
    reg [AXIS_ID_WIDTH-1:0] reg_wid;
    reg [AXIS_DEST_WIDTH-1:0] reg_wdest;
    reg [AXIS_USER_WIDTH-1:0] reg_wuser;

    // AXI Master State for Burst Handling
    localparam AW_STATE_IDLE = 3'b000;
    localparam AW_STATE_BUSY = 3'b001;
    localparam AR_STATE_IDLE = 3'b010;
    localparam AR_STATE_BUSY = 3'b011;
    localparam W_STATE_IDLE = 3'b100;
    localparam W_STATE_BUSY = 3'b101;
    localparam B_STATE_IDLE = 3'b110;
    localparam R_STATE_IDLE = 3'b111;

    reg [2:0] aw_state;
    reg [2:0] ar_state;
    reg [2:0] w_state;
    reg [2:0] b_state;
    reg [2:0] r_state;

    // AXI Write Buffer
    reg [AXI_DATA_WIDTH-1:0] w_buf [AXI_MAX_BURST_LEN];
    reg [AXI_STRB_WIDTH-1:0] w_strb_buf [AXI_MAX_BURST_LEN];
    reg [AXI_ID_WIDTH-1:0] w_id_buf [AXI_MAX_BURST_LEN];
    reg [AXI_STRB_WIDTH-1:0] w_strb_buf_valid;
    reg [AXI_ID_WIDTH-1:0] w_id_buf_valid;
    reg [AXI_DATA_WIDTH-1:0] w_data_ptr;
    reg [AXI_STRB_WIDTH-1:0] w_strb_ptr;
    reg [AXI_ID_WIDTH-1:0] w_id_ptr;
    reg w_buf_valid;
    reg w_buf_full;

    // AXI Read Buffer
    reg [AXI_DATA_WIDTH-1:0] r_buf [AXI_MAX_BURST_LEN];
    reg [AXI_ID_WIDTH-1:0] r_id_buf [AXI_MAX_BURST_LEN];
    reg [AXI_DATA_WIDTH-1:0] r_data_ptr;
    reg [AXI_ID_WIDTH-1:0] r_id_ptr;
    reg r_buf_valid;
    reg r_buf_full;

    // Read Descriptor Status Buffer
    reg [TAG_WIDTH-1:0] read_status_tag;
    reg [3:0] read_status_error;
    reg read_status_valid;

    // Write Descriptor Status Buffer
    reg [LEN_WIDTH-1:0] write_status_len;
    reg [TAG_WIDTH-1:0] write_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_status_user;
    reg [3:0] write_status_error;
    reg write_status_valid;

    // AXI Write Buffer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_buf_valid <= 1'b0;
            w_buf_full <= 1'b0;
            w_data_ptr <= 0;
            w_strb_ptr <= 0;
            w_id_ptr <= 0;
        end else begin
            w_buf_valid <= w_buf_full;
            w_buf_full <= w_buf_valid && (w_state == W_STATE_IDLE);
            w_data_ptr <= w_data_ptr + 1;
            w_strb_ptr <= w_strb_ptr + 1;
            w_id_ptr <= w_id_ptr + 1;
        end
    end

    // AXI Read Buffer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_buf_valid <= 1'b0;
            r_buf_full <= 1'b0;
            r_data_ptr <= 0;
            r_id_ptr <= 0;
        end else begin
            r_buf_valid <= r_buf_full;
            r_buf_full <= r_buf_valid && (r_state == R_STATE_IDLE);
            r_data_ptr <= r_data_ptr + 1;
            r_id_ptr <= r_id_ptr + 1;
        end
    end

    // AXI Write Buffer Fill Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_buf_valid <= 1'b0;
            w_buf_full <= 1'b0;
            w_data_ptr <= 0;
            w_strb_ptr <= 0;
            w_id_ptr <= 0;
            for (integer i = 0; i < AXI_MAX_BURST_LEN; i = i + 1) begin
                w_buf[i] <= 0;
                w_strb_buf[i] <= 0;
                w_id_buf[i] <= 0;
            end
        end else begin
            if (s_axis_write_data_tvalid && s_axis_write_data_tready && !w_buf_full) begin
                w_buf[w_data_ptr] <= s_axis_write_data_tdata;
                w_strb_buf[w_strb_ptr] <= s_axis_write_data_tkeep;
                w_id_buf[w_id_ptr] <= s_axis_write_data_tid;
                w_buf_valid <= 1'b1;
            end
        end
    end

    // AXI Read Buffer Fill Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_buf_valid <= 1'b0;
            r_buf_full <= 1'b0;
            r_data_ptr <= 0;
            r_id_ptr <= 0;
            for (integer i = 0; i < AXI_MAX_BURST_LEN; i = i + 1) begin
                r_buf[i] <= 0;
                r_id_buf[i] <= 0;
            end
        end else begin
            if (m_axi_rvalid && m_axi_rready && !r_buf_full) begin
                r_buf[r_data_ptr] <= m_axi_rdata;
                r_id_buf[r_id_ptr] <= m_axi_rid;
                r_buf_valid <= 1'b1;
            end
        end
    end

    // AXI Master Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_awvalid <= 1'b0;
            m_axi_arvalid <= 1'b0;
            m_axi_wvalid <= 1'b0;
            m_axi_bready <= 1'b0;
            m_axi_rready <= 1'b0;
            m_axi_wlast <= 1'b0;
            m_axi_awvalid_next <= 1'b0;
            m_axi_arvalid_next <= 1'b0;
            m_axi_wlast_next <= 1'b0;
            m_axi_wvalid_next <= 1'b0;
            m_axi_bready_next <= 1'b0;
            m_axi_rready_next <= 1'b0;
        end else begin
            m_axi_awvalid <= m_axi_awvalid_next;
            m_axi_arvalid <= m_axi_arvalid_next;
            m_axi_wvalid <= m_axi_wvalid_next;
            m_axi_bready <= m_axi_bready_next;
            m_axi_rready <= m_axi_rready_next;
            m_axi_wlast <= m_axi_wlast_next;
        end
    end

    // AXI Master Control Logic Next State
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_awvalid_next <= 1'b0;
            m_axi_arvalid_next <= 1'b0;
            m_axi_wvalid_next <= 1'b0;
            m_axi_wlast_next <= 1'b0;
            m_axi_bready_next <= 1'b0;
            m_axi_rready_next <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (read_enable && s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                        m_axi_awvalid_next <= 1'b0;
                        m_axi_arvalid_next <= 1'b1;
                        m_axi_arid <= current_axi_id;
                        m_axi_araddr <= current_addr;
                        m_axi_arlen <= burst_len;
                        m_axi_arsize <= burst_size;
                        m_axi_arburst <= burst_type;
                        m_axi_arlock <= 1'b0;
                        m_axi_arcache <= burst_cache;
                        m_axi_arprot <= burst_prot;
                        s_axis_read_desc_ready <= 1'b1;
                    end else if (write_enable && s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                        m_axi_awvalid_next <= 1'b1;
                        m_axi_arvalid_next <= 1'b0;
                        m_axi_awid <= current_axi_id;
                        m_axi_awaddr <= current_addr;
                        m_axi_awlen <= burst_len;
                        m_axi_awsize <= burst_size;
                        m_axi_awburst <= burst_type;
                        m_axi_awlock <= 1'b0;
                        m_axi_awcache <= burst_cache;
                        m_axi_awprot <= burst_prot;
                        s_axis_write_desc_ready <= 1'b1;
                    end else begin
                        m_axi_awvalid_next <= 1'b0;
                        m_axi_arvalid_next <= 1'b0;
                        s_axis_read_desc_ready <= 1'b0;
                        s_axis_write_desc_ready <= 1'b0;
                    end
                end

                READ_DESC: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid_next <= 1'b1;
                        m_axi_arid <= current_axi_id;
                        m_axi_araddr <= current_addr;
                        m_axi_arlen <= burst_len;
                        m_axi_arsize <= burst_size;
                        m_axi_arburst <= burst_type;
                        m_axi_arlock <= 1'b0;
                        m_axi_arcache <= burst_cache;
                        m_axi_arprot <= burst_prot;
                        s_axis_read_desc_ready <= 1'b0;
                    end else begin
                        m_axi_arvalid_next <= 1'b0;
                        s_axis_read_desc_ready <= 1'b0;
                    end
                end

                WRITE_DESC: begin
                    if (m_axi_awready) begin
                        m_axi_awvalid_next <= 1'b1;
                        m_axi_awid <= current_axi_id;
                        m_axi_awaddr <= current_addr;
                        m_axi_awlen <= burst_len;
                        m_axi_awsize <= burst_size;
                        m_axi_awburst <= burst_type;
                        m_axi_awlock <= 1'b0;
                        m_axi_awcache <= burst_cache;
                        m_axi_awprot <= burst_prot;
                        s_axis_write_desc_ready <= 1'b0;
                    end else begin
                        m_axi_awvalid_next <= 1'b0;
                        s_axis_write_desc_ready <= 1'b0;
                    end
                end

                TRANSFER_READ: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        m_axi_rready_next <= 1'b1;
                        if (r_buf_full) begin
                            m_axis_read_data_tvalid <= 1'b1;
                            m_axis_read_data_tdata <= r_buf[r_data_ptr];
                            m_axis_read_data_tkeep <= 8'hFF; // Assuming full width keep
                            m_axis_read_data_tlast <= (remaining_len == 0) ? 1'b1 : 1'b0;
                            m_axis_read_data_tid <= current_id;
                            m_axis_read_data_tdest <= current_dest;
                            m_axis_read_data_tuser <= current_user;
                            r_data_ptr <= r_data_ptr + 1;
                            remaining_len <= remaining_len - 1;
                        end else begin
                            m_axis_read_data_tvalid <= 1'b0;
                        end
                    end else begin
                        m_axi_rready_next <= 1'b0;
                        m_axis_read_data_tvalid <= 1'b0;
                    end
                end

                TRANSFER_WRITE: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid_next <= 1'b1;
                        m_axi_wdata <= w_buf[w_data_ptr];
                        m_axi_wstrb <= w_strb_buf[w_strb_ptr];
                        m_axi_wlast <= (remaining_len == 0) ? 1'b1 : 1'b0;
                        w_data_ptr <= w_data_ptr + 1;
                        w_strb_ptr <= w_strb_ptr + 1;
                        remaining_len <= remaining_len - 1;
                    end else begin
                        m_axi_wvalid_next <= 1'b0;
                    end
                end

                FINISHED: begin
                    if (read_mode) begin
                        m_axis_read_desc_status_tag <= current_tag;
                        m_axis_read_desc_status_error <= current_error;
                        m_axis_read_desc_status_valid <= 1'b1;
                        s_axis_read_desc_ready <= 1'b0;
                    end else begin
                        m_axis_write_desc_status_len <= write_status_len;
                        m_axis_write_desc_status_tag <= write_status_tag;
                        m_axis_write_desc_status_id <= write_status_id;
                        m_axis_write_desc_status_dest <= write_status_dest;
                        m_axis_write_desc_status_user <= write_status_user;
                        m_axis_write_desc_status_error <= write_status_error;
                        m_axis_write_desc_status_valid <= 1'b1;
                        s_axis_write_desc_ready <= 1'b0;
                    end
                end

                default: begin
                    m_axi_awvalid_next <= 1'b0;
                    m_axi_arvalid_next <= 1'b0;
                    m_axi_wvalid_next <= 1'b0;
                    m_axi_wlast_next <= 1'b0;
                    m_axi_bready_next <= 1'b0;
                    m_axi_rready_next <= 1'b0;
                    s_axis_read_desc_ready <= 1'b0;
                    s_axis_write_desc_ready <= 1'b0;
                end
            endcase
        end
    end

    // AXI Master Control Logic Next State (Burst Handling)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            burst_complete <= 1'b0;
            burst_len <= 0;
            burst_size <= 0;
            burst_type <= 0;
            burst_cache <= 0;
            burst_prot <= 0;
            current_addr <= 0;
            current_tag <= 0;
            current_id <= 0;
            current_dest <= 0;
            current_user <= 0;
            current_axi_id <= 0;
            current_error <= 0;
            read_mode <= 0;
            remaining_len <= 0;
            last_addr <= 0;
            last_data <= 0;
            last_resp <= 0;
            last_bid <= 0;
            last_rid <= 0;
            last_araddr <= 0;
            last_arlen <= 0;
            last_arsize <= 0;
            last_arburst <= 0;
            last_awid <= 0;
            last_awaddr <= 0;
            last_awlen <= 0;
            last_awsize <= 0;
            last_awburst <= 0;
            last_bid_reg <= 0;
            last_wdata <= 0;
            last_wstrb <= 0;
            last_wlast <= 0;
            w_buf_valid <= 0;
            w_buf_full <= 0;
            r_buf_valid <= 0;
            r_buf_full <= 0;
            w_data_ptr <= 0;
            w_strb_ptr <= 0;
            w_id_ptr <= 0;
            r_data_ptr <= 0;
            r_id_ptr <= 0;
            reg_tvalid <= 0;
            reg_tlast <= 0;
            reg_tid <= 0;
            reg_tdest <= 0;
            reg_tuser <= 0;
            reg_tdata <= 0;
            reg_tkeep <= 0;
            reg_wvalid <= 0;
            reg_wlast <= 0;
            reg_wid <= 0;
            reg_wdest <= 0;
            reg_wuser <= 0;
            reg_wdata <= 0;
            reg_wstrb <= 0;
            read_status_valid <= 0;
            write_status_valid <= 0;
            state <= IDLE;
            aw_state <= AW_STATE_IDLE;
            ar_state <= AR_STATE_IDLE;
            w_state <= W_STATE_IDLE;
            b_state <= B_STATE_IDLE;
            r_state <= R_STATE_IDLE;
        end else begin
            // Burst Length Calculation
            if (state == IDLE) begin
                burst_len <= s_axis_read_desc_len[7:0]; // Assuming 8-bit burst length for simplicity
                burst_size <= 3'b000; // Assuming 32-bit transfer size
                burst_type <= 2'b01; // Fixed burst
                burst_cache <= 4'b0000; // Write-back
                burst_prot <= 3'b000; // Normal
                current_addr <= s_axis_read_desc_addr;
                current_tag <= s_axis_read_desc_tag;
                current_id <= s_axis_read_desc_id;
                current_dest <= s_axis_read_desc_dest;
                current_user <= s_axis_read_desc_user;
                current_axi_id <= s_axis_read_desc_id;
                current_error <= 0;
                read_mode <= 1;
                remaining_len <= s_axis_read_desc_len;
                state <= READ_DESC;
            end else if (state == WRITE_DESC) begin
                burst_len <= s_axis_write_desc_len[7:0];
                burst_size <= 3'b000;
                burst_type <= 2'b01;
                burst_cache <= 4'b0000;
                burst_prot <= 3'b000;
                current_addr <= s_axis_write_desc_addr;
                current_tag <= s_axis_write_desc_tag;
                current_id <= s_axis_write_desc_id;
                current_dest <= s_axis_write_desc_dest;
                current_user <= s_axis_write_desc_user;
                current_axi_id <= s_axis_write_desc_id;
                current_error <= 0;
                read_mode <= 0;
                remaining_len <= s_axis_write_desc_len;
                state <= WRITE_DESC;
            end

            // Burst Completion Check
            if (state == READ_DESC && m_axi_rvalid && m_axi_rlast) begin
                burst_complete <= 1'b1;
                state <= TRANSFER_READ;
            end else if (state == WRITE_DESC && m_axi_wvalid && m_axi_wlast) begin
                burst_complete <= 1'b1;
                state <= TRANSFER_WRITE;
            end

            // Transfer Read Logic
            if (state == TRANSFER_READ) begin
                if (remaining_len == 0) begin
                    state <= FINISHED;
                end
            end

            // Transfer Write Logic
            if (state == TRANSFER_WRITE) begin
                if (remaining_len == 0) begin
                    state <= FINISHED;
                end
            end

            // Write Descriptor Status Logic
            if (state == FINISHED && !read_mode) begin
                write_status_len <= remaining_len;
                write_status_tag <= current_tag;
                write_status_id <= current_id;
                write_status_dest <= current_dest;
                write_status_user <= current_user;
                write_status_error <= current_error;
                write_status_valid <= 1'b1;
                state <= IDLE;
            end

            // Read Descriptor Status Logic
            if (state == FINISHED && read_mode) begin
                read_status_tag <= current_tag;
                read_status_error <= current_error;
                read_status_valid <= 1'b1;
                state <= IDLE;
            end
        end
    end

    // Stream Output Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tvalid <= 1'b0;
            reg_tlast <= 1'b0;
            reg_tid <= 0;
            reg_tdest <= 0;
            reg_tuser <= 0;
            reg_tdata <= 0;
            reg_tkeep <= 0;
        end else begin
            if (state == TRANSFER_READ) begin
                if (m_axis_read_data_tready) begin
                    reg_tvalid <= 1'b1;
                    reg_tdata <= m_axis_read_data_tdata;
                    reg_tkeep <= m_axis_read_data_tkeep;
                    reg_tlast <= m_axis_read_data_tlast;
                    reg_tid <= m_axis_read_data_tid;
                    reg_tdest <= m_axis_read_data_tdest;
                    reg_tuser <= m_axis_read_data_tuser;
                end else begin
                    reg_tvalid <= 1'b0;
                end
            end else begin
                reg_tvalid <= 1'b0;
                reg_tlast <= 1'b0;
                reg_tid <= 0;
                reg_tdest <= 0;
                reg_tuser <= 0;
                reg_tdata <= 0;
                reg_tkeep <= 0;
            end
        end
    end

    // Stream Input Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_wvalid <= 1'b0;
            reg_wlast <= 1'b0;
            reg_wid <= 0;
            reg_wdest <= 0;
            reg_wuser <= 0;
            reg_wdata <= 0;
            reg_wstrb <= 0;
        end else begin
            if (state == WRITE_DESC) begin
                if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                    reg_wvalid <= 1'b1;
                    reg_wdata <= s_axis_write_data_tdata;
                    reg_wstrb <= s_axis_write_data_tkeep;
                    reg_wlast <= s_axis_write_data_tlast;
                    reg_wid <= s_axis_write_data_tid;
                    reg_wdest <= s_axis_write_data_tdest;
                    reg_wuser <= s_axis_write_data_tuser;
                end else begin
                    reg_wvalid <= 1'b0;
                end
            end else begin
                reg_wvalid <= 1'b0;
                reg_wlast <= 1'b0;
                reg_wid <= 0;
                reg_wdest <= 0;
                reg_wuser <= 0;
                reg_wdata <= 0;
                reg_wstrb <= 0;
            end
        end
    end

    // AXI Master Control Signals Assignment
    assign m_axi_awid = current_axi_id;
    assign m_axi_awaddr = current_addr;
    assign m_axi_awlen = burst_len;
    assign m_axi_awsize = burst_size;
    assign m_axi_awburst = burst_type;
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = burst_cache;
    assign m_axi_awprot = burst_prot;
    assign m_axi_awvalid = m_axi_awvalid_next;
    assign m_axi_wdata = w_buf[w_data_ptr];
    assign m_axi_wstrb = w_strb_buf[w_strb_ptr];
    assign m_axi_wlast = m_axi_wlast_next;
    assign m_axi_wvalid = m_axi_wvalid_next;
    assign m_axi_bready = m_axi_bready_next;
    assign m_axi_arid = current_axi_id;
    assign m_axi_araddr = current_addr;
    assign m_axi_arlen = burst_len;
    assign m_axi_arsize = burst_size;
    assign m_axi_arburst = burst_type;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = burst_cache;
    assign m_axi_arprot = burst_prot;
    assign m_axi_arvalid = m_axi_arvalid_next