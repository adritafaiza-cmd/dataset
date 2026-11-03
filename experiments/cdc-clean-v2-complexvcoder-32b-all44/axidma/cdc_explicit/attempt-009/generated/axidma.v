module axidma #(
        parameter C_AXI_ID_WIDTH = 1,
        parameter C_AXI_ADDR_WIDTH = 32,
        parameter C_AXI_DATA_WIDTH = 32,
        localparam C_AXIL_ADDR_WIDTH = 5,
        localparam C_AXIL_DATA_WIDTH = 32,
        parameter [0:0] OPT_UNALIGNED = 1'b1,
        parameter [0:0] OPT_WRAPMEM = 1'b1,
        parameter LGFIFO = LGMAXBURST+1,
        parameter LGLEN = C_AXI_ADDR_WIDTH,
        parameter [0:0] OPT_LOWPOWER = 1'b0,
        parameter [0:0] OPT_CLKGATE = OPT_LOWPOWER,
        parameter [C_AXI_ID_WIDTH-1:0] AXI_READ_ID = 0,
        parameter [C_AXI_ID_WIDTH-1:0] AXI_WRITE_ID = 0,
        parameter [7:0] ABORT_KEY = 8'h6d,
        localparam ADDRLSB= $clog2(C_AXI_DATA_WIDTH)-3,
        localparam AXILLSB= $clog2(C_AXIL_DATA_WIDTH)-3,
        localparam LGLENW= LGLEN-ADDRLSB
    ) (
        input wire S_AXI_ACLK,
        input wire S_AXI_ARESETN,
        input wire S_AXIL_AWVALID,
        output wire S_AXIL_AWREADY,
        input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_AWADDR,
        input wire [2:0] S_AXIL_AWPROT,
        input wire S_AXIL_WVALID,
        output wire S_AXIL_WREADY,
        input wire [C_AXIL_DATA_WIDTH-1:0] S_AXIL_WDATA,
        input wire [C_AXIL_DATA_WIDTH/8-1:0] S_AXIL_WSTRB,
        output reg S_AXIL_BVALID,
        input wire S_AXIL_BREADY,
        output wire [1:0] S_AXIL_BRESP,
        input wire S_AXIL_ARVALID,
        output wire S_AXIL_ARREADY,
        input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_ARADDR,
        input wire [2:0] S_AXIL_ARPROT,
        output reg S_AXIL_RVALID,
        input wire S_AXIL_RREADY,
        output reg [C_AXIL_DATA_WIDTH-1:0] S_AXIL_RDATA,
        output wire [1:0] S_AXIL_RRESP,
        output reg M_AXI_AWVALID,
        input wire M_AXI_AWREADY,
        output reg [C_AXI_ID_WIDTH-1:0] M_AXI_AWID,
        output reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
        output reg [2:0] M_AXI_AWSIZE,
        output reg [1:0] M_AXI_AWBURST,
        output reg M_AXI_AWLOCK,
        output reg [3:0] M_AXI_AWCACHE,
        output reg [2:0] M_AXI_AWPROT,
        output reg [3:0] M_AXI_AWQOS,
        output reg M_AXI_WVALID,
        input wire M_AXI_WREADY,
        output reg [C_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
        output reg [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
        output reg M_AXI_WLAST,
        input wire M_AXI_BVALID,
        output reg M_AXI_BREADY,
        input wire [C_AXI_ID_WIDTH-1:0] M_AXI_BID,
        input wire [1:0] M_AXI_BRESP,
        output reg M_AXI_ARVALID,
        input wire M_AXI_ARREADY,
        output wire [C_AXI_ID_WIDTH-1:0] M_AXI_ARID,
        output reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
        output wire [2:0] M_AXI_ARSIZE,
        output wire [1:0] M_AXI_ARBURST,
        output wire M_AXI_ARLOCK,
        output wire [3:0] M_AXI_ARCACHE,
        output wire [2:0] M_AXI_ARPROT,
        output wire [3:0] M_AXI_ARQOS,
        input wire M_AXI_RVALID,
        output wire M_AXI_RREADY,
        input wire [C_AXI_ID_WIDTH-1:0] M_AXI_RID,
        input wire [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
        input wire M_AXI_RLAST,
        input wire [1:0] M_AXI_RRESP,
        output reg o_int
    );

    // Internal state and registers
    reg [C_AXI_ADDR_WIDTH-1:0] source_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dest_addr;
    reg [LGLEN-1:0] length;
    reg [1:0] state;
    reg [1:0] next_state;
    reg [C_AXIL_DATA_WIDTH-1:0] control_reg;
    reg [1:0] bresp_reg;
    reg [1:0] rresp_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] rdata_reg;

    // State encoding
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;

    // AXIL control registers
    reg [C_AXIL_ADDR_WIDTH-1:0] axil_awaddr_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] axil_wdata_reg;

    // AXI master control
    reg [C_AXI_ADDR_WIDTH-1:0] axi_addr_reg;
    reg [LGLEN-1:0] axi_length_reg;
    reg [LGLENW-1:0] axi_counter_reg;

    // AXIL handshake signals
    reg axil_awready_reg;
    reg axil_wready_reg;

    // AXI master handshake signals
    reg axi_awvalid_reg;
    reg axi_wvalid_reg;
    reg axi_bready_reg;
    reg axi_arvalid_reg;
    reg axi_rready_reg;

    // AXIL write register
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axil_awaddr_reg <= 0;
            axil_wdata_reg <= 0;
        end else if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
            axil_awaddr_reg <= S_AXIL_AWADDR;
        end else if (S_AXIL_WVALID && S_AXIL_WREADY) begin
            axil_wdata_reg <= S_AXIL_WDATA;
        end
    end

    // Control register update
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            control_reg <= 0;
        end else if (S_AXIL_WVALID && S_AXIL_WREADY && axil_awaddr_reg[4:2] == 3'b000) begin
            control_reg <= axil_wdata_reg;
        end
    end

    // State machine
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (control_reg[31]) begin
                    next_state = READ;
                end else if (control_reg[30]) begin
                    next_state = WRITE;
                end
            end
            READ: begin
                if (M_AXI_BVALID && M_AXI_BREADY) begin
                    next_state = IDLE;
                end
            end
            WRITE: begin
                if (M_AXI_BVALID && M_AXI_BREADY) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Control signal generation
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_awvalid_reg <= 0;
            axi_wvalid_reg <= 0;
            axi_bready_reg <= 0;
            axi_arvalid_reg <= 0;
            axi_rready_reg <= 0;
            axi_addr_reg <= 0;
            axi_length_reg <= 0;
            axi_counter_reg <= 0;
            source_addr <= 0;
            dest_addr <= 0;
            length <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (control_reg[31]) begin
                        source_addr <= control_reg[31:0];
                        axi_addr_reg <= control_reg[31:0];
                        axi_length_reg <= control_reg[LGLEN-1:0];
                        axi_counter_reg <= control_reg[LGLEN-1:0];
                        axi_awvalid_reg <= 1;
                        axi_wvalid_reg <= 1;
                    end else if (control_reg[30]) begin
                        dest_addr <= control_reg[31:0];
                        axi_addr_reg <= control_reg[31:0];
                        axi_length_reg <= control_reg[LGLEN-1:0];
                        axi_counter_reg <= control_reg[LGLEN-1:0];
                        axi_awvalid_reg <= 1;
                        axi_wvalid_reg <= 1;
                    end
                end
                READ: begin
                    if (M_AXI_RVALID && M_AXI_RREADY) begin
                        axi_counter_reg <= axi_counter_reg - 1;
                        if (M_AXI_RLAST) begin
                            axi_bready_reg <= 1;
                        end
                    end
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        axi_awvalid_reg <= 0;
                        axi_wvalid_reg <= 0;
                        axi_bready_reg <= 0;
                    end
                end
                WRITE: begin
                    if (M_AXI_WREADY) begin
                        axi_counter_reg <= axi_counter_reg - 1;
                        if (axi_counter_reg == 1) begin
                            M_AXI_WLAST <= 1;
                        end
                    end
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        axi_awvalid_reg <= 0;
                        axi_wvalid_reg <= 0;
                        axi_bready_reg <= 0;
                    end
                end
            endcase
        end
    end

    // AXIL read path
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_RVALID <= 0;
            rdata_reg <= 0;
            rresp_reg <= 0;
        end else if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
            S_AXIL_RVALID <= 1;
            rdata_reg <= control_reg;
            rresp_reg <= 0;
        end else if (S_AXIL_RVALID && S_AXIL_RREADY) begin
            S_AXIL_RVALID <= 0;
        end
    end

    // AXIL write response path
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_BVALID <= 0;
            bresp_reg <= 0;
        end else if (M_AXI_BVALID && M_AXI_BREADY) begin
            S_AXIL_BVALID <= 1;
            bresp_reg <= M_AXI_BRESP;
        end else if (S_AXIL_BVALID && S_AXIL_BREADY) begin
            S_AXIL_BVALID <= 0;
        end
    end

    // AXIL handshake signals
    assign S_AXIL_AWREADY = ~axil_awvalid_reg & S_AXIL_AWVALID;
    assign S_AXIL_WREADY = ~axil_wvalid_reg & S_AXIL_WVALID;
    assign S_AXIL_BRESP = bresp_reg;
    assign S_AXIL_ARREADY = ~S_AXIL_ARVALID;
    assign S_AXIL_RRESP = rresp_reg;
    assign S_AXIL_RDATA = rdata_reg;

    // AXI master signals
    assign M_AXI_AWVALID = axi_awvalid_reg;
    assign M_AXI_AWID = AXI_WRITE_ID;
    assign M_AXI_AWADDR = axi_addr_reg;
    assign M_AXI_AWSIZE = 3'b010; // 32-bit
    assign M_AXI_AWBURST = 2'b01; // INCR
    assign M_AXI_AWLOCK = 1'b0;
    assign M_AXI_AWCACHE = 4'b0011; // Non-cacheable, no buffer
    assign M_AXI_AWPROT = 3'b000;
    assign M_AXI_AWQOS = 4'b0000;
    assign M_AXI_WVALID = axi_wvalid_reg;
    assign M_AXI_WDATA = M_AXI_RDATA; // For read-to-write transfer
    assign M_AXI_WSTRB = {C_AXI_DATA_WIDTH/8{1'b1}};
    assign M_AXI_WLAST = (axi_counter_reg == 1);
    assign M_AXI_BREADY = axi_bready_reg;
    assign M_AXI_ARVALID = axi_arvalid_reg;
    assign M_AXI_ARID = AXI_READ_ID;
    assign M_AXI_ARADDR = axi_addr_reg;
    assign M_AXI_ARSIZE = 3'b010; // 32-bit
    assign M_AXI_ARBURST = 2'b01; // INCR
    assign M_AXI_ARLOCK = 1'b0;
    assign M_AXI_ARCACHE = 4'b0011; // Non-cacheable, no buffer
    assign M_AXI_ARPROT = 3'b000;
    assign M_AXI_ARQOS = 4'b0000;
    assign M_AXI_RREADY = axi_rready_reg;

    // Interrupt signal
    assign o_int = (state == IDLE) ? 1'b1 : 1'b0;

endmodule
