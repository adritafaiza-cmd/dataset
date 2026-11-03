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
        parameter   [7:0]                 ABORT_KEY  = 8'h6d,
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

    // Internal states and registers
    reg [1:0] state;
    reg [C_AXI_ADDR_WIDTH-1:0] src_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dst_addr;
    reg [LGLEN-1:0] length;
    reg [C_AXI_ADDR_WIDTH-1:0] current_addr;
    reg [LGLEN-1:0] current_length;
    reg [C_AXI_DATA_WIDTH-1:0] axil_buffer;

    // AXILite interface signals
    reg axil_awready;
    reg axil_wready;
    reg [1:0] axil_bresp;
    reg axil_rvalid;
    reg [C_AXIL_DATA_WIDTH-1:0] axil_rdata;
    reg [1:0] axil_rresp;

    // AXI interface signals
    reg axi_awvalid;
    reg [C_AXI_ID_WIDTH-1:0] axi_awid;
    reg [C_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg [2:0] axi_awsize;
    reg [1:0] axi_awburst;
    reg axi_awlock;
    reg [3:0] axi_awcache;
    reg [2:0] axi_awprot;
    reg [3:0] axi_awqos;
    reg axi_wvalid;
    reg [C_AXI_DATA_WIDTH-1:0] axi_wdata;
    reg [C_AXI_DATA_WIDTH/8-1:0] axi_wstrb;
    reg axi_wlast;
    reg axi_bready;
    reg axi_arvalid;
    reg [C_AXI_ID_WIDTH-1:0] axi_arid;
    reg [C_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg [2:0] axi_arsize;
    reg [1:0] axi_arburst;
    reg axi_arlock;
    reg [3:0] axi_arcache;
    reg [2:0] axi_arprot;
    reg [3:0] axi_arqos;
    reg axi_rready;

    // State encoding
    localparam IDLE = 2'b00;
    localparam CONFIGURING = 2'b01;
    localparam READING = 2'b10;
    localparam WRITING = 2'b11;

    // AXILite write register map
    localparam AXIL_REG_SRC_ADDR = 5'h00;
    localparam AXIL_REG_DST_ADDR = 5'h01;
    localparam AXIL_REG_LENGTH = 5'h02;
    localparam AXIL_REG_START = 5'h03;
    localparam AXIL_REG_STATUS = 5'h04;

    // AXILite read register map
    localparam AXIL_REG_READ_DATA = 5'h05;

    // AXILite write process
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axil_awready <= 0;
            axil_wready <= 0;
            S_AXIL_BVALID <= 0;
            axil_bresp <= 0;
        end else begin
            if (S_AXIL_AWVALID && axil_awready) begin
                case (S_AXIL_AWADDR)
                    AXIL_REG_SRC_ADDR: begin
                        if (S_AXIL_WVALID) begin
                            src_addr <= S_AXIL_WDATA;
                            axil_wready <= 1;
                        end else begin
                            axil_wready <= 0;
                        end
                    end
                    AXIL_REG_DST_ADDR: begin
                        if (S_AXIL_WVALID) begin
                            dst_addr <= S_AXIL_WDATA;
                            axil_wready <= 1;
                        end else begin
                            axil_wready <= 0;
                        end
                    end
                    AXIL_REG_LENGTH: begin
                        if (S_AXIL_WVALID) begin
                            length <= S_AXIL_WDATA;
                            axil_wready <= 1;
                        end else begin
                            axil_wready <= 0;
                        end
                    end
                    AXIL_REG_START: begin
                        if (S_AXIL_WVALID) begin
                            state <= CONFIGURING;
                            axil_wready <= 1;
                        end else begin
                            axil_wready <= 0;
                        end
                    end
                    default: begin
                        axil_wready <= 0;
                    end
                endcase
            end else begin
                axil_awready <= 1;
            end

            if (S_AXIL_WVALID && axil_wready) begin
                S_AXIL_BVALID <= 1;
                axil_bresp <= 2'b00;
            end else begin
                S_AXIL_BVALID <= 0;
            end

            if (S_AXIL_BVALID && S_AXIL_BREADY) begin
                S_AXIL_BVALID <= 0;
            end
        end
    end

    // AXILite read process
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axil_rvalid <= 0;
            axil_rdata <= 0;
            axil_rresp <= 0;
        end else begin
            if (S_AXIL_ARVALID) begin
                case (S_AXIL_ARADDR)
                    AXIL_REG_READ_DATA: begin
                        axil_rdata <= axil_buffer;
                        axil_rvalid <= 1;
                    end
                    AXIL_REG_STATUS: begin
                        axil_rdata <= {state, 31'b0};
                        axil_rvalid <= 1;
                    end
                    default: begin
                        axil_rdata <= 0;
                        axil_rvalid <= 0;
                    end
                endcase
            end else begin
                axil_rvalid <= 0;
            end

            if (S_AXIL_RVALID && S_AXIL_RREADY) begin
                axil_rvalid <= 0;
            end
        end
    end

    // AXI interface process
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
            current_addr <= 0;
            current_length <= 0;
            axi_awvalid <= 0;
            axi_awid <= AXI_WRITE_ID;
            axi_awaddr <= 0;
            axi_awsize <= 2'b10; // 32-bit
            axi_awburst <= 2'b01; // INCR
            axi_awlock <= 0;
            axi_awcache <= 3'b001; // Non-cacheable, buffered
            axi_awprot <= 3'b000; // Normal, secure, data
            axi_awqos <= 4'b0000; // Normal
            axi_wvalid <= 0;
            axi_wdata <= 0;
            axi_wstrb <= {C_AXI_DATA_WIDTH/8{1'b1}};
            axi_wlast <= 0;
            axi_bready <= 0;
            axi_arvalid <= 0;
            axi_arid <= AXI_READ_ID;
            axi_araddr <= 0;
            axi_arsize <= 2'b10; // 32-bit
            axi_arburst <= 2'b01; // INCR
            axi_arlock <= 0;
            axi_arcache <= 3'b001; // Non-cacheable, buffered
            axi_arprot <= 3'b000; // Normal, secure, data
            axi_arqos <= 4'b0000; // Normal
            axi_rready <= 0;
            o_int <= 0;
        end else begin
            case (state)
                IDLE: begin
                    axi_awvalid <= 0;
                    axi_wvalid <= 0;
                    axi_bready <= 0;
                    axi_arvalid <= 0;
                    axi_rready <= 0;
                end
                CONFIGURING: begin
                    current_addr <= src_addr;
                    current_length <= length;
                    state <= READING;
                end
                READING: begin
                    if (!axi_arvalid) begin
                        axi_araddr <= current_addr;
                        axi_arvalid <= 1;
                    end
                    if (axi_arvalid && axi_arready) begin
                        axi_arvalid <= 0;
                        axi_rready <= 1;
                    end
                    if (axi_rvalid && axi_rready) begin
                        axil_buffer <= axi_rdata;
                        axi_rready <= 0;
                        current_addr <= current_addr + C_AXI_DATA_WIDTH/8;
                        current_length <= current_length - C_AXI_DATA_WIDTH/8;
                        if (current_length == 0) begin
                            state <= WRITING;
                        end
                    end
                end
                WRITING: begin
                    if (!axi_awvalid) begin
                        axi_awaddr <= dst_addr;
                        axi_awvalid <= 1;
                    end
                    if (axi_awvalid && axi_awready) begin
                        axi_awvalid <= 0;
                        axi_wvalid <= 1;
                    end
                    if (axi_wvalid && axi_wready) begin
                        axi_wdata <= axil_buffer;
                        axi_wvalid <= 0;
                        axi_wlast <= 1;
                        axi_bready <= 1;
                    end
                    if (axi_bvalid && axi_bready) begin
                        axi_bready <= 0;
                        axi_wlast <= 0;
                        state <= IDLE;
                        o_int <= 1;
                    end
                end
            endcase
        end
    end

    // Assign outputs
    assign S_AXIL_AWREADY = axil_awready;
    assign S_AXIL_WREADY = axil_wready;
    assign S_AXIL_BRESP = axil_bresp;
    assign S_AXIL_ARREADY = 1; // Simple ready always
    assign S_AXIL_RVALID = axil_rvalid;
    assign S_AXIL_RDATA = axil_rdata;
    assign S_AXIL_RRESP = axil_rresp;

    assign M_AXI_AWVALID = axi_awvalid;
    assign M_AXI_AWID = axi_awid;
    assign M_AXI_AWADDR = axi_awaddr;
    assign M_AXI_AWSIZE = axi_awsize;
    assign M_AXI_AWBURST = axi_awburst;
    assign M_AXI_AWLOCK = axi_awlock;
    assign M_AXI_AWCACHE = axi_awcache;
    assign M_AXI_AWPROT = axi_awprot;
    assign M_AXI_AWQOS = axi_awqos;
    assign M_AXI_WVALID = axi_wvalid;
    assign M_AXI_WDATA = axi_wdata;
    assign M_AXI_WSTRB = axi_wstrb;
    assign M_AXI_WLAST = axi_wlast;
    assign M_AXI_BREADY = axi_bready;
    assign M_AXI_ARVALID = axi_arvalid;
    assign M_AXI_ARID = axi_arid;
    assign M_AXI_ARADDR = axi_araddr;
    assign M_AXI_ARSIZE = axi_arsize;
    assign M_AXI_ARBURST = axi_arburst;
    assign M_AXI_ARLOCK = axi_arlock;
    assign M_AXI_ARCACHE = axi_arcache;
    assign M_AXI_ARPROT = axi_arprot;
    assign M_AXI_ARQOS = axi_arqos;
    assign M_AXI_RREADY = axi_rready;

endmodule
