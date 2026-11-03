module axidma #(
        parameter   C_AXI_ID_WIDTH = 1,
        parameter   C_AXI_ADDR_WIDTH = 32,
        parameter   C_AXI_DATA_WIDTH = 32,
        localparam  C_AXIL_ADDR_WIDTH = 5,
        localparam  C_AXIL_DATA_WIDTH = 32,
        parameter [0:0]   OPT_UNALIGNED = 1'b1,
        parameter [0:0]   OPT_WRAPMEM = 1'b1,
        parameter   LGFIFO = LGMAXBURST+1,
        parameter   LGLEN = C_AXI_ADDR_WIDTH,
        parameter [0:0]   OPT_LOWPOWER = 1'b0,
        parameter [0:0]   OPT_CLKGATE = OPT_LOWPOWER,
        parameter   [C_AXI_ID_WIDTH-1:0]  AXI_READ_ID = 0,
        parameter   [C_AXI_ID_WIDTH-1:0]  AXI_WRITE_ID = 0,
        parameter   [7:0]   ABORT_KEY  = 8'h6d,
        localparam  ADDRLSB= $clog2(C_AXI_DATA_WIDTH)-3,
        localparam  AXILLSB= $clog2(C_AXIL_DATA_WIDTH)-3,
        localparam  LGLENW= LGLEN-ADDRLSB
    ) (
        input   wire    S_AXI_ACLK,
        input   wire    S_AXI_ARESETN,
        input   wire                S_AXIL_AWVALID,
        output  wire                S_AXIL_AWREADY,
        input   wire [C_AXIL_ADDR_WIDTH-1:0]  S_AXIL_AWADDR,
        input   wire  [2:0]           S_AXIL_AWPROT,
        input   wire                S_AXIL_WVALID,
        output  wire                S_AXIL_WREADY,
        input   wire [C_AXIL_DATA_WIDTH-1:0]  S_AXIL_WDATA,
        input   wire [C_AXIL_DATA_WIDTH/8-1:0]  S_AXIL_WSTRB,
        output  reg                 S_AXIL_BVALID,
        input   wire                S_AXIL_BREADY,
        output  wire    [1:0]           S_AXIL_BRESP,
        input   wire                S_AXIL_ARVALID,
        output  wire                S_AXIL_ARREADY,
        input   wire [C_AXIL_ADDR_WIDTH-1:0]  S_AXIL_ARADDR,
        input   wire  [2:0]           S_AXIL_ARPROT,
        output  reg                 S_AXIL_RVALID,
        input   wire                S_AXIL_RREADY,
        output  reg [C_AXIL_DATA_WIDTH-1:0]  S_AXIL_RDATA,
        output  wire    [1:0]           S_AXIL_RRESP,
        output  reg                 M_AXI_AWVALID,
        input   wire                M_AXI_AWREADY,
        output  reg [C_AXI_ID_WIDTH-1:0]  M_AXI_AWID,
        output  reg [C_AXI_ADDR_WIDTH-1:0]  M_AXI_AWADDR,
        output  reg [2:0]           M_AXI_AWSIZE,
        output  reg [1:0]           M_AXI_AWBURST,
        output  reg                 M_AXI_AWLOCK,
        output  reg [3:0]           M_AXI_AWCACHE,
        output  reg [2:0]           M_AXI_AWPROT,
        output  reg [3:0]           M_AXI_AWQOS,
        output  reg                 M_AXI_WVALID,
        input   wire                M_AXI_WREADY,
        output  reg [C_AXI_DATA_WIDTH-1:0]  M_AXI_WDATA,
        output  reg [C_AXI_DATA_WIDTH/8-1:0]  M_AXI_WSTRB,
        output  reg                 M_AXI_WLAST,
        input   wire                M_AXI_BVALID,
        output  reg                 M_AXI_BREADY,
        input   wire [C_AXI_ID_WIDTH-1:0]  M_AXI_BID,
        input   wire [1:0]           M_AXI_BRESP,
        output  reg                 M_AXI_ARVALID,
        input   wire                M_AXI_ARREADY,
        output  wire [C_AXI_ID_WIDTH-1:0]  M_AXI_ARID,
        output  reg [C_AXI_ADDR_WIDTH-1:0]  M_AXI_ARADDR,
        output  wire [2:0]           M_AXI_ARSIZE,
        output  wire [1:0]           M_AXI_ARBURST,
        output  wire                M_AXI_ARLOCK,
        output  wire [3:0]           M_AXI_ARCACHE,
        output  wire [2:0]           M_AXI_ARPROT,
        output  wire [3:0]           M_AXI_ARQOS,
        input   wire                M_AXI_RVALID,
        output  wire                M_AXI_RREADY,
        input   wire [C_AXI_ID_WIDTH-1:0]  M_AXI_RID,
        input   wire [C_AXI_DATA_WIDTH-1:0]  M_AXI_RDATA,
        input   wire                M_AXI_RLAST,
        input   wire [1:0]           M_AXI_RRESP,
        output  reg                 o_int
    );

    // Internal signals
    reg                 s_axil_awready_reg;
    reg                 s_axil_wready_reg;
    reg                 s_axil_bvalid_reg;
    reg [1:0]           s_axil_bresp_reg;
    reg                 s_axil_arready_reg;
    reg                 s_axil_rvalid_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] s_axil_rdata_reg;
    reg [1:0]           s_axil_rresp_reg;
    reg                 m_axi_awvalid_reg;
    reg [C_AXI_ID_WIDTH-1:0]  m_axi_awid_reg;
    reg [C_AXI_ADDR_WIDTH-1:0]  m_axi_awaddr_reg;
    reg [2:0]           m_axi_awsize_reg;
    reg [1:0]           m_axi_awburst_reg;
    reg                 m_axi_awlock_reg;
    reg [3:0]           m_axi_awcache_reg;
    reg [2:0]           m_axi_awprot_reg;
    reg [3:0]           m_axi_awqos_reg;
    reg                 m_axi_wvalid_reg;
    reg [C_AXI_DATA_WIDTH-1:0]  m_axi_wdata_reg;
    reg [C_AXI_DATA_WIDTH/8-1:0]  m_axi_wstrb_reg;
    reg                 m_axi_wlast_reg;
    reg                 m_axi_bready_reg;
    reg                 m_axi_arvalid_reg;
    reg [C_AXI_ID_WIDTH-1:0]  m_axi_arid_reg;
    reg [C_AXI_ADDR_WIDTH-1:0]  m_axi_araddr_reg;
    reg [2:0]           m_axi_arsize_reg;
    reg [1:0]           m_axi_arburst_reg;
    reg                 m_axi_arlock_reg;
    reg [3:0]           m_axi_arcache_reg;
    reg [2:0]           m_axi_arprot_reg;
    reg [3:0]           m_axi_arqos_reg;
    reg                 m_axi_rready_reg;
    reg [C_AXIL_ADDR_WIDTH-1:0]  axi_cmd;
    reg [LGLENW-1:0]    axi_len;
    reg [C_AXI_ADDR_WIDTH-1:0]  axi_src_addr;
    reg [C_AXI_ADDR_WIDTH-1:0]  axi_dst_addr;
    reg [2:0]           state;
    reg [LGLEN-1:0]     read_cnt;
    reg [LGLEN-1:0]     write_cnt;
    reg [C_AXI_DATA_WIDTH-1:0]  data_reg;
    reg                 error_reg;

    // State definitions
    localparam  IDLE  = 3'b000;
    localparam  READ  = 3'b001;
    localparam  WRITE = 3'b010;
    localparam  DONE  = 3'b011;
    localparam  ERROR = 3'b100;

    // Reset and clock
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            // Reset all internal signals
            s_axil_awready_reg <= 0;
            s_axil_wready_reg <= 0;
            s_axil_bvalid_reg <= 0;
            s_axil_bresp_reg <= 0;
            s_axil_arready_reg <= 0;
            s_axil_rvalid_reg <= 0;
            s_axil_rdata_reg <= 0;
            s_axil_rresp_reg <= 0;
            m_axi_awvalid_reg <= 0;
            m_axi_awid_reg <= 0;
            m_axi_awaddr_reg <= 0;
            m_axi_awsize_reg <= 0;
            m_axi_awburst_reg <= 0;
            m_axi_awlock_reg <= 0;
            m_axi_awcache_reg <= 0;
            m_axi_awprot_reg <= 0;
            m_axi_awqos_reg <= 0;
            m_axi_wvalid_reg <= 0;
            m_axi_wdata_reg <= 0;
            m_axi_wstrb_reg <= 0;
            m_axi_wlast_reg <= 0;
            m_axi_bready_reg <= 0;
            m_axi_arvalid_reg <= 0;
            m_axi_arid_reg <= 0;
            m_axi_araddr_reg <= 0;
            m_axi_arsize_reg <= 0;
            m_axi_arburst_reg <= 0;
            m_axi_arlock_reg <= 0;
            m_axi_arcache_reg <= 0;
            m_axi_arprot_reg <= 0;
            m_axi_arqos_reg <= 0;
            m_axi_rready_reg <= 0;
            axi_cmd <= 0;
            axi_len <= 0;
            axi_src_addr <= 0;
            axi_dst_addr <= 0;
            state <= IDLE;
            read_cnt <= 0;
            write_cnt <= 0;
            data_reg <= 0;
            error_reg <= 0;
            S_AXIL_BVALID <= 0;
            S_AXIL_RVALID <= 0;
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_BREADY <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY <= 0;
            o_int <= 0;
        end else begin
            // AXI-Lite Write Address Channel
            if (S_AXIL_AWVALID && s_axil_awready_reg) begin
                axi_cmd <= S_AXIL_AWADDR;
            end

            // AXI-Lite Write Data Channel
            if (S_AXIL_WVALID && s_axil_wready_reg) begin
                if (axi_cmd[4]) begin // Write command
                    axi_dst_addr <= S_AXIL_WDATA;
                end else begin // Read command
                    axi_src_addr <= S_AXIL_WDATA;
                end
                axi_len <= S_AXIL_WDATA[LGLEN-1:LGLEN-LGLENW];
            end

            // AXI-Lite Write Response Channel
            if (s_axil_bvalid_reg && S_AXIL_BREADY) begin
                s_axil_bvalid_reg <= 0;
            end

            // AXI-Lite Read Address Channel
            if (S_AXIL_ARVALID && s_axil_arready_reg) begin
                // Handle read status command
            end

            // AXI-Lite Read Data Channel
            if (s_axil_rvalid_reg && S_AXIL_RREADY) begin
                s_axil_rvalid_reg <= 0;
            end

            // State machine
            case (state)
                IDLE: begin
                    if (S_AXIL_WVALID && s_axil_wready_reg) begin
                        if (axi_cmd[4]) begin
                            state <= WRITE;
                            m_axi_awvalid_reg <= 1;
                            m_axi_awaddr_reg <= axi_dst_addr;
                            m_axi_awsize_reg <= 2'b010; // 32-bit
                            m_axi_awburst_reg <= 2'b01; // INCR
                            m_axi_awlen_reg <= axi_len;
                        end else begin
                            state <= READ;
                            m_axi_arvalid_reg <= 1;
                            m_axi_araddr_reg <= axi_src_addr;
                            m_axi_arsize_reg <= 2'b010; // 32-bit
                            m_axi_arburst_reg <= 2'b01; // INCR
                            m_axi_arlen_reg <= axi_len;
                        end
                    end
                end

                READ: begin
                    if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                        m_axi_arvalid_reg <= 0;
                    end
                    if (M_AXI_RVALID) begin
                        data_reg <= M_AXI_RDATA;
                        if (M_AXI_RLAST) begin
                            state <= WRITE;
                            m_axi_awvalid_reg <= 1;
                            m_axi_awaddr_reg <= axi_dst_addr;
                            m_axi_awsize_reg <= 2'b010; // 32-bit
                            m_axi_awburst_reg <= 2'b01; // INCR
                            m_axi_awlen_reg <= axi_len;
                            write_cnt <= 0;
                        end else begin
                            read_cnt <= read_cnt + 1;
                        end
                    end
                end

                WRITE: begin
                    if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                        m_axi_awvalid_reg <= 0;
                    end
                    if (!m_axi_wvalid_reg) begin
                        m_axi_wvalid_reg <= 1;
                        m_axi_wdata_reg <= data_reg;
                        m_axi_wstrb_reg <= {C_AXI_DATA_WIDTH/8{1'b1}};
                        if (write_cnt == axi_len) begin
                            m_axi_wlast_reg <= 1;
                        end
                    end
                    if (M_AXI_WVALID && M_AXI_WREADY) begin
                        m_axi_wvalid_reg <= 0;
                        m_axi_wlast_reg <= 0;
                        if (M_AXI_WLAST) begin
                            state <= DONE;
                            m_axi_bready_reg <= 1;
                        end else begin
                            write_cnt <= write_cnt + 1;
                        end
                    end
                end

                DONE: begin
                    if (M_AXI_BVALID && m_axi_bready_reg) begin
                        m_axi_bready_reg <= 0;
                        state <= IDLE;
                        S_AXIL_BVALID <= 1;
                        S_AXIL_BRESP <= 2'b00; // OKAY
                        o_int <= 1;
                    end
                end

                ERROR: begin
                    // Handle error state
                    state <= IDLE;
                    S_AXIL_BVALID <= 1;
                    S_AXIL_BRESP <= 2'b10; // SLVERR
                    o_int <= 1;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // AXI-Lite Write Address Channel Ready
    assign S_AXIL_AWREADY = !s_axil_awready_reg && !S_AXIL_BVALID;

    // AXI-Lite Write Data Channel Ready
    assign S_AXIL_WREADY = !s_axil_wready_reg && !S_AXIL_BVALID;

    // AXI-Lite Write Response Channel Response
    assign S_AXIL_BRESP = s_axil_bresp_reg;

    // AXI-Lite Read Address Channel Ready
    assign S_AXIL_ARREADY = !s_axil_arready_reg && !S_AXIL_RVALID;

    // AXI-Lite Read Data Channel Response
    assign S_AXIL_RDATA = s_axil_rdata_reg;
    assign S_AXIL_RRESP = s_axil_rresp_reg;

    // AXI Write Address Channel
    assign M_AXI_AWID = m_axi_awid_reg;
    assign M_AXI_AWSIZE = m_axi_awsize_reg;
    assign M_AXI_AWBURST = m_axi_awburst_reg;
    assign M_AXI_AWLOCK = m_axi_awlock_reg;
    assign M_AXI_AWCACHE = m_axi_awcache_reg;
    assign M_AXI_AWPROT = m_axi_awprot_reg;
    assign M_AXI_AWQOS = m_axi_awqos_reg;

    // AXI Write Data Channel
    assign M_AXI_WDATA = m_axi_wdata_reg;
    assign M_AXI_WSTRB = m_axi_wstrb_reg;

    // AXI Write Response Channel Ready
    assign M_AXI_BREADY = m_axi_bready_reg;

    // AXI Read Address Channel
    assign M_AXI_ARID = m_axi_arid_reg;
    assign M_AXI_ARSIZE = m_axi_arsize_reg;
    assign M_AXI_ARBURST = m_axi_arburst_reg;
    assign M_AXI_ARLOCK = m_axi_arlock_reg;
    assign M_AXI_ARCACHE = m_axi_arcache_reg;
    assign M_AXI_ARPROT = m_axi_arprot_reg;
    assign M_AXI_ARQOS = m_axi_arqos_reg;

    // AXI Read Data Channel Ready
    assign M_AXI_RREADY = m_axi_rready_reg;

endmodule
