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

    /*
     * Internal signals
     */
    reg  [TAG_WIDTH-1:0]              read_desc_status_tag;
    reg  [3:0]                        read_desc_status_error;
    reg                               read_desc_status_valid;
    reg  [AXIS_DATA_WIDTH-1:0]        read_data_tdata;
    reg  [AXIS_KEEP_WIDTH-1:0]        read_data_tkeep;
    reg                               read_data_tvalid;
    reg                               read_data_tlast;
    reg  [AXIS_ID_WIDTH-1:0]          read_data_tid;
    reg  [AXIS_DEST_WIDTH-1:0]        read_data_tdest;
    reg  [AXIS_USER_WIDTH-1:0]        read_data_tuser;
    reg                               read_desc_ready;

    reg  [LEN_WIDTH-1:0]              write_desc_status_len;
    reg  [TAG_WIDTH-1:0]              write_desc_status_tag;
    reg  [AXIS_ID_WIDTH-1:0]          write_desc_status_id;
    reg  [AXIS_DEST_WIDTH-1:0]        write_desc_status_dest;
    reg  [AXIS_USER_WIDTH-1:0]        write_desc_status_user;
    reg  [3:0]                        write_desc_status_error;
    reg                               write_desc_status_valid;
    reg                               write_data_tready;
    reg                               write_desc_ready;

    /*
     * Instantiate read engine
     */
    read_engine #(
        .AXI_DATA_WIDTH   (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH),
        .AXI_STRB_WIDTH   (AXI_STRB_WIDTH),
        .AXI_ID_WIDTH     (AXI_ID_WIDTH),
        .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
        .AXIS_DATA_WIDTH  (AXIS_DATA_WIDTH),
        .AXIS_KEEP_WIDTH  (AXIS_KEEP_WIDTH),
        .AXIS_LAST_ENABLE (AXIS_LAST_ENABLE),
        .AXIS_ID_WIDTH    (AXIS_ID_WIDTH),
        .AXIS_DEST_WIDTH  (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH  (AXIS_USER_WIDTH),
        .LEN_WIDTH        (LEN_WIDTH),
        .TAG_WIDTH        (TAG_WIDTH),
        .ENABLE_UNALIGNED (ENABLE_UNALIGNED)
    ) read_engine_inst (
        .clk                  (clk),
        .rst                  (rst),
        .s_axis_read_desc_addr(s_axis_read_desc_addr),
        .s_axis_read_desc_len (s_axis_read_desc_len),
        .s_axis_read_desc_tag (s_axis_read_desc_tag),
        .s_axis_read_desc_valid(s_axis_read_desc_valid),
        .s_axis_read_desc_ready(s_axis_read_desc_ready),
        .m_axis_read_desc_status_tag(read_desc_status_tag),
        .m_axis_read_desc_status_error(read_desc_status_error),
        .m_axis_read_desc_status_valid(read_desc_status_valid),
        .m_axis_read_data_tdata(read_data_tdata),
        .m_axis_read_data_tkeep(read_data_tkeep),
        .m_axis_read_data_tvalid(read_data_tvalid),
        .m_axis_read_data_tready(m_axis_read_data_tready),
        .m_axis_read_data_tlast(read_data_tlast),
        .m_axis_read_data_tid(read_data_tid),
        .m_axis_read_data_tdest(read_data_tdest),
        .m_axis_read_data_tuser(read_data_tuser),
        .m_axi_araddr         (m_axi_araddr),
        .m_axi_arlen          (m_axi_arlen),
        .m_axi_arsize         (m_axi_arsize),
        .m_axi_arburst        (m_axi_arburst),
        .m_axi_arlock         (m_axi_arlock),
        .m_axi_arcache        (m_axi_arcache),
        .m_axi_arprot         (m_axi_arprot),
        .m_axi_arvalid        (m_axi_arvalid),
        .m_axi_arready        (m_axi_arready),
        .m_axi_rdata          (m_axi_rdata),
        .m_axi_rresp          (m_axi_rresp),
        .m_axi_rlast          (m_axi_rlast),
        .m_axi_rvalid         (m_axi_rvalid),
        .m_axi_rready         (m_axi_rready),
        .read_enable          (read_enable)
    );

    /*
     * Instantiate write engine
     */
    write_engine #(
        .AXI_DATA_WIDTH   (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH),
        .AXI_STRB_WIDTH   (AXI_STRB_WIDTH),
        .AXI_ID_WIDTH     (AXI_ID_WIDTH),
        .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
        .AXIS_DATA_WIDTH  (AXIS_DATA_WIDTH),
        .AXIS_KEEP_WIDTH  (AXIS_KEEP_WIDTH),
        .AXIS_LAST_ENABLE (AXIS_LAST_ENABLE),
        .AXIS_ID_WIDTH    (AXIS_ID_WIDTH),
        .AXIS_DEST_WIDTH  (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH  (AXIS_USER_WIDTH),
        .LEN_WIDTH        (LEN_WIDTH),
        .TAG_WIDTH        (TAG_WIDTH),
        .ENABLE_UNALIGNED (ENABLE_UNALIGNED)
    ) write_engine_inst (
        .clk                  (clk),
        .rst                  (rst),
        .s_axis_write_desc_addr(s_axis_write_desc_addr),
        .s_axis_write_desc_len (s_axis_write_desc_len),
        .s_axis_write_desc_tag (s_axis_write_desc_tag),
        .s_axis_write_desc_valid(s_axis_write_desc_valid),
        .s_axis_write_desc_ready(s_axis_write_desc_ready),
        .m_axis_write_desc_status_len(write_desc_status_len),
        .m_axis_write_desc_status_tag(write_desc_status_tag),
        .m_axis_write_desc_status_id(write_desc_status_id),
        .m_axis_write_desc_status_dest(write_desc_status_dest),
        .m_axis_write_desc_status_user(write_desc_status_user),
        .m_axis_write_desc_status_error(write_desc_status_error),
        .m_axis_write_desc_status_valid(write_desc_status_valid),
        .s_axis_write_data_tdata(s_axis_write_data_tdata),
        .s_axis_write_data_tkeep(s_axis_write_data_tkeep),
        .s_axis_write_data_tvalid(s_axis_write_data_tvalid),
        .s_axis_write_data_tready(s_axis_write_data_tready),
        .s_axis_write_data_tlast(s_axis_write_data_tlast),
        .s_axis_write_data_tid(s_axis_write_data_tid),
        .s_axis_write_data_tdest(s_axis_write_data_tdest),
        .s_axis_write_data_tuser(s_axis_write_data_tuser),
        .m_axi_awaddr         (m_axi_awaddr),
        .m_axi_awlen          (m_axi_awlen),
        .m_axi_awsize         (m_axi_awsize),
        .m_axi_awburst        (m_axi_awburst),
        .m_axi_awlock         (m_axi_awlock),
        .m_axi_awcache        (m_axi_awcache),
        .m_axi_awprot         (m_axi_awprot),
        .m_axi_awvalid        (m_axi_awvalid),
        .m_axi_awready        (m_axi_awready),
        .m_axi_wdata          (m_axi_wdata),
        .m_axi_wstrb          (m_axi_wstrb),
        .m_axi_wlast          (m_axi_wlast),
        .m_axi_wvalid         (m_axi_wvalid),
        .m_axi_wready         (m_axi_wready),
        .m_axi_bid            (m_axi_bid),
        .m_axi_bresp          (m_axi_bresp),
        .m_axi_bvalid         (m_axi_bvalid),
        .m_axi_bready         (m_axi_bready),
        .write_enable         (write_enable),
        .write_abort          (write_abort)
    );

    /*
     * Assign outputs
     */
    assign m_axis_read_desc_status_tag    = read_desc_status_tag;
    assign m_axis_read_desc_status_error  = read_desc_status_error;
    assign m_axis_read_desc_status_valid  = read_desc_status_valid;
    assign m_axis_read_data_tdata         = read_data_tdata;
    assign m_axis_read_data_tkeep         = read_data_tkeep;
    assign m_axis_read_data_tvalid        = read_data_tvalid;
    assign m_axis_read_data_tlast         = read_data_tlast;
    assign m_axis_read_data_tid           = read_data_tid;
    assign m_axis_read_data_tdest         = read_data_tdest;
    assign m_axis_read_data_tuser         = read_data_tuser;

    assign m_axis_write_desc_status_len   = write_desc_status_len;
    assign m_axis_write_desc_status_tag   = write_desc_status_tag;
    assign m_axis_write_desc_status_id    = write_desc_status_id;
    assign m_axis_write_desc_status_dest  = write_desc_status_dest;
    assign m_axis_write_desc_status_user  = write_desc_status_user;
    assign m_axis_write_desc_status_error = write_desc_status_error;
    assign m_axis_write_desc_status_valid = write_desc_status_valid;
    assign s_axis_write_data_tready       = write_data_tready;

    assign m_axi_awid                     = s_axis_write_desc_id;
    assign m_axi_arid                     = s_axis_read_desc_id;

endmodule

module read_engine #(
    parameter AXI_DATA_WIDTH   = 32,
    parameter AXI_ADDR_WIDTH   = 16,
    parameter AXI_STRB_WIDTH   = 4,
    parameter AXI_ID_WIDTH     = 8,
    parameter AXI_MAX_BURST_LEN= 16,
    parameter AXIS_DATA_WIDTH  = 32,
    parameter AXIS_KEEP_WIDTH  = 4,
    parameter AXIS_LAST_ENABLE = 1,
    parameter AXIS_ID_WIDTH    = 8,
    parameter AXIS_DEST_WIDTH  = 8,
    parameter AXIS_USER_WIDTH  = 1,
    parameter LEN_WIDTH        = 20,
    parameter TAG_WIDTH        = 8,
    parameter ENABLE_UNALIGNED = 0
)
(
    input  wire                       clk,
    input  wire                       rst,
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_read_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_read_desc_tag,
    input  wire                       s_axis_read_desc_valid,
    output wire                       s_axis_read_desc_ready,
    output wire [TAG_WIDTH-1:0]       m_axis_read_desc_status_tag,
    output wire [3:0]                 m_axis_read_desc_status_error,
    output wire                       m_axis_read_desc_status_valid,
    output wire [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep,
    output wire                       m_axis_read_data_tvalid,
    input  wire                       m_axis_read_data_tready,
    output wire                       m_axis_read_data_tlast,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output wire [7:0]                 m_axi_arlen,
    output wire [2:0]                 m_axi_arsize,
    output wire [1:0]                 m_axi_arburst,
    output wire                       m_axi_arlock,
    output wire [3:0]                 m_axi_arcache,
    output wire [2:0]                 m_axi_arprot,
    output wire                       m_axi_arvalid,
    input  wire                       m_axi_arready,
    input  wire [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                 m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output wire                       m_axi_rready,
    input  wire                       read_enable
);

    /*
     * States
     */
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam DONE = 2'b10;

    /*
     * Registers
     */
    reg [1:0]                         state;
    reg [AXI_ADDR_WIDTH-1:0]          addr_reg;
    reg [LEN_WIDTH-1:0]               len_reg;
    reg [TAG_WIDTH-1:0]               tag_reg;
    reg [AXIS_ID_WIDTH-1:0]           id_reg;
    reg [AXIS_DEST_WIDTH-1:0]         dest_reg;
    reg [AXIS_USER_WIDTH-1:0]         user_reg;
    reg [AXI_ADDR_WIDTH-1:0]          addr_cnt;
    reg [LEN_WIDTH-1:0]               len_cnt;

    /*
     * Internal signals
     */
    wire                              arvalid;
    wire                              rready;
    wire                              desc_ready;
    wire                              desc_status_valid;

    /*
     * State machine
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            addr_reg <= 0;
            len_reg <= 0;
            tag_reg <= 0;
            id_reg <= 0;
            dest_reg <= 0;
            user_reg <= 0;
            addr_cnt <= 0;
            len_cnt <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_read_desc_valid && read_enable) begin
                        addr_reg <= s_axis_read_desc_addr;
                        len_reg <= s_axis_read_desc_len;
                        tag_reg <= s_axis_read_desc_tag;
                        id_reg <= s_axis_read_desc_id;
                        dest_reg <= s_axis_read_desc_dest;
                        user_reg <= s_axis_read_desc_user;
                        addr_cnt <= s_axis_read_desc_addr;
                        len_cnt <= s_axis_read_desc_len;
                        state <= READ;
                    end
                end
                READ: begin
                    if (m_axi_rvalid && m_axis_read_data_tready) begin
                        addr_cnt <= addr_cnt + AXI_DATA_WIDTH/8;
                        len_cnt <= len_cnt - AXI_DATA_WIDTH/8;
                        if (len_cnt <= AXI_DATA_WIDTH/8) begin
                            state <= DONE;
                        end
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    /*
     * Assignments
     */
    assign arvalid = (state == READ) && !m_axi_arready;
    assign rready = (state == READ) && m_axi_rvalid;

    assign m_axi_araddr = addr_reg;
    assign m_axi_arlen = len_reg / (AXI_DATA_WIDTH/8) - 1;
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011; // Normal, Non-cacheable, Bufferable
    assign m_axi_arprot = 3'b000; // Normal, Non-secure, Data
    assign m_axi_arvalid = arvalid;

    assign m_axi_rready = rready;

    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
    assign m_axis_read_data_tvalid = m_axi_rvalid && (state == READ);
    assign m_axis_read_data_tlast = m_axi_rlast;
    assign m_axis_read_data_tid = id_reg;
    assign m_axis_read_data_tdest = dest_reg;
    assign m_axis_read_data_tuser = user_reg;

    assign m_axis_read_desc_status_tag = tag_reg;
    assign m_axis_read_desc_status_error = (m_axi_rresp != 2'b00) ? 4'b0001 : 4'b0000;
    assign m_axis_read_desc_status_valid = (state == DONE);

    assign desc_ready = (state == IDLE);
    assign desc_status_valid = (state == DONE);

    assign s_axis_read_desc_ready = desc_ready;

endmodule

module write_engine #(
    parameter AXI_DATA_WIDTH   = 32,
    parameter AXI_ADDR_WIDTH   = 16,
    parameter AXI_STRB_WIDTH   = 4,
    parameter AXI_ID_WIDTH     = 8,
    parameter AXI_MAX_BURST_LEN= 16,
    parameter AXIS_DATA_WIDTH  = 32,
    parameter AXIS_KEEP_WIDTH  = 4,
    parameter AXIS_LAST_ENABLE = 1,
    parameter AXIS_ID_WIDTH    = 8,
    parameter AXIS_DEST_WIDTH  = 8,
    parameter AXIS_USER_WIDTH  = 1,
    parameter LEN_WIDTH        = 20,
    parameter TAG_WIDTH        = 8,
    parameter ENABLE_UNALIGNED = 0
)
(
    input  wire                       clk,
    input  wire                       rst,
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_write_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_write_desc_tag,
    input  wire                       s_axis_write_desc_valid,
    output wire                       s_axis_write_desc_ready,
    output wire [LEN_WIDTH-1:0]       m_axis_write_desc_status_len,
    output wire [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_write_desc_status_id,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user,
    output wire [3:0]                 m_axis_write_desc_status_error,
    output wire                       m_axis_write_desc_status_valid,
    input  wire [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input  wire                       s_axis_write_data_tvalid,
    output wire                       s_axis_write_data_tready,
    input  wire                       s_axis_write_data_tlast,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,
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
    input  wire                       write_enable,
    input  wire                       write_abort
);

    /*
     * States
     */
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam DONE = 2'b10;

    /*
     * Registers
     */
    reg [1:0]                         state;
    reg [AXI_ADDR_WIDTH-1:0]          addr_reg;
    reg [LEN_WIDTH-1:0]               len_reg;
    reg [TAG_WIDTH-1:0]               tag_reg;
    reg [AXIS_ID_WIDTH-1:0]           id_reg;
    reg [AXIS_DEST_WIDTH-1:0]         dest_reg;
    reg [AXIS_USER_WIDTH-1:0]         user_reg;
    reg [AXI_ADDR_WIDTH-1:0]          addr_cnt;
    reg [LEN_WIDTH-1:0]               len_cnt;

    /*
     * Internal signals
     */
    wire                              awvalid;
    wire                              wvalid;
    wire                              bready;
    wire                              desc_ready;
    wire                              desc_status_valid;

    /*
     * State machine
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            addr_reg <= 0;
            len_reg <= 0;
            tag_reg <= 0;
            id_reg <= 0;
            dest_reg <= 0;
            user_reg <= 0;
            addr_cnt <= 0;
            len_cnt <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_write_desc_valid && write_enable) begin
                        addr_reg <= s_axis_write_desc_addr;
                        len_reg <= s_axis_write_desc_len;
                        tag_reg <= s_axis_write_desc_tag;
                        id_reg <= s_axis_write_desc_id;
                        dest_reg <= s_axis_write_desc_dest;
                        user_reg <= s_axis_write_desc_user;
                        addr_cnt <= s_axis_write_desc_addr;
                        len_cnt <= s_axis_write_desc_len;
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        addr_cnt <= addr_cnt + AXI_DATA_WIDTH/8;
                        len_cnt <= len_cnt - AXI_DATA_WIDTH/8;
                        if (len_cnt <= AXI_DATA_WIDTH/8) begin
                            state <= DONE;
                        end
                    end
                    if (write_abort) begin
                        state <= IDLE;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    /*
     * Assignments
     */
    assign awvalid = (state == WRITE) && !m_axi_awready;
    assign wvalid = (state == WRITE) && s_axis_write_data_tvalid;
    assign bready = (state == DONE) && m_axi_bvalid;

    assign m_axi_awaddr = addr_reg;
    assign m_axi_awlen = len_reg / (AXI_DATA_WIDTH/8) - 1;
    assign m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011; // Normal, Non-cacheable, Bufferable
    assign m_axi_awprot = 3'b000; // Normal, Non-secure, Data
    assign m_axi_awvalid = awvalid;

    assign m_axi_wdata = s_axis_write_data_tdata;
    assign m_axi_wstrb = s_axis_write_data_tkeep;
    assign m_axi_wlast = (len_cnt <= AXI_DATA_WIDTH/8);
    assign m_axi_wvalid = wvalid;

    assign m_axi_bready = bready;

    assign s_axis_write_data_tready = (state == WRITE);

    assign m_axis_write_desc_status_len = len_reg;
    assign m_axis_write_desc_status_tag = tag_reg;
    assign m_axis_write_desc_status_id = id_reg;
    assign m_axis_write_desc_status_dest = dest_reg;
    assign m_axis_write_desc_status_user = user_reg;
    assign m_axis_write_desc_status_error = (m_axi_bresp != 2'b00) ? 4'b0001 : 4'b0000;
    assign m_axis_write_desc_status_valid = (state == DONE);

    assign desc_ready = (state == IDLE);
    assign desc_status_valid = (state == DONE);

    assign s_axis_write_desc_ready = desc_ready;

endmodule
