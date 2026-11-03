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
        input   wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_AWADDR,
        input   wire  [2:0]         S_AXIL_AWPROT,
        input   wire                S_AXIL_WVALID,
        output  wire                S_AXIL_WREADY,
        input   wire [C_AXIL_DATA_WIDTH-1:0] S_AXIL_WDATA,
        input   wire [C_AXIL_DATA_WIDTH/8-1:0] S_AXIL_WSTRB,
        output  reg                 S_AXIL_BVALID,
        input   wire                S_AXIL_BREADY,
        output  wire    [1:0]       S_AXIL_BRESP,
        input   wire                S_AXIL_ARVALID,
        output  wire                S_AXIL_ARREADY,
        input   wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_ARADDR,
        input   wire  [2:0]         S_AXIL_ARPROT,
        output  reg                 S_AXIL_RVALID,
        input   wire                S_AXIL_RREADY,
        output  reg [C_AXIL_DATA_WIDTH-1:0] S_AXIL_RDATA,
        output  wire    [1:0]       S_AXIL_RRESP,
        output  reg                 M_AXI_AWVALID,
        input   wire                M_AXI_AWREADY,
        output  reg [C_AXI_ID_WIDTH-1:0] M_AXI_AWID,
        output  reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
        output  reg [2:0]         M_AXI_AWSIZE,
        output  reg [1:0]         M_AXI_AWBURST,
        output  reg                 M_AXI_AWLOCK,
        output  reg [3:0]         M_AXI_AWCACHE,
        output  reg [2:0]         M_AXI_AWPROT,
        output  reg [3:0]         M_AXI_AWQOS,
        output  reg                 M_AXI_WVALID,
        input   wire                M_AXI_WREADY,
        output  reg [C_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
        output  reg [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
        output  reg                 M_AXI_WLAST,
        input   wire                M_AXI_BVALID,
        output  reg                 M_AXI_BREADY,
        input   wire [C_AXI_ID_WIDTH-1:0] M_AXI_BID,
        input   wire [1:0]          M_AXI_BRESP,
        output  reg                 M_AXI_ARVALID,
        input   wire                M_AXI_ARREADY,
        output  wire [C_AXI_ID_WIDTH-1:0] M_AXI_ARID,
        output  reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
        output  wire [2:0]         M_AXI_ARSIZE,
        output  wire [1:0]         M_AXI_ARBURST,
        output  wire                M_AXI_ARLOCK,
        output  wire [3:0]         M_AXI_ARCACHE,
        output  wire [2:0]         M_AXI_ARPROT,
        output  wire [3:0]         M_AXI_ARQOS,
        input   wire                M_AXI_RVALID,
        output  wire                M_AXI_RREADY,
        input   wire [C_AXI_ID_WIDTH-1:0] M_AXI_RID,
        input   wire [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
        input   wire                M_AXI_RLAST,
        input   wire [1:0]          M_AXI_RRESP,
        output  reg                 o_int
    );

    // Internal registers for AXILite interface
    reg [C_AXIL_DATA_WIDTH-1:0] axil_reg [0:(1<<C_AXIL_ADDR_WIDTH)-1];
    reg [C_AXIL_ADDR_WIDTH-1:0] axil_awaddr_reg;
    reg [C_AXIL_ADDR_WIDTH-1:0] axil_araddr_reg;
    reg axil_awvalid_reg;
    reg axil_arvalid_reg;
    reg axil_awready_reg;
    reg axil_arready_reg;

    // Internal registers for AXI interface
    reg [C_AXI_ADDR_WIDTH-1:0] axi_awaddr_reg;
    reg [C_AXI_ADDR_WIDTH-1:0] axi_araddr_reg;
    reg [C_AXI_ADDR_WIDTH-1:0] axi_addr_counter;
    reg [C_AXI_DATA_WIDTH-1:0] axi_wdata_reg;
    reg [C_AXI_DATA_WIDTH/8-1:0] axi_wstrb_reg;
    reg axi_awvalid_reg;
    reg axi_arvalid_reg;
    reg axi_wvalid_reg;
    reg axi_wlast_reg;
    reg axi_bready_reg;
    reg axi_rready_reg;
    reg [1:0] axi_state;

    // AXILite interface
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_AWREADY <= 0;
            S_AXIL_WREADY <= 0;
            S_AXIL_BVALID <= 0;
            S_AXIL_ARREADY <= 0;
            S_AXIL_RVALID <= 0;
            axil_awaddr_reg <= 0;
            axil_araddr_reg <= 0;
            axil_awvalid_reg <= 0;
            axil_arvalid_reg <= 0;
            axil_awready_reg <= 0;
            axil_arready_reg <= 0;
        end else begin
            // Write address channel
            if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
                axil_awaddr_reg <= S_AXIL_AWADDR;
                axil_awvalid_reg <= 1;
            end else if (axil_awvalid_reg && M_AXI_AWREADY) begin
                axil_awvalid_reg <= 0;
            end

            // Write data channel
            if (S_AXIL_WVALID && S_AXIL_WREADY) begin
                axil_reg[axil_awaddr_reg] <= S_AXIL_WDATA;
                S_AXIL_BVALID <= 1;
            end else if (S_AXIL_BVALID && S_AXIL_BREADY) begin
                S_AXIL_BVALID <= 0;
            end

            // Read address channel
            if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
                axil_araddr_reg <= S_AXIL_ARADDR;
                axil_arvalid_reg <= 1;
            end else if (axil_arvalid_reg && M_AXI_ARREADY) begin
                axil_arvalid_reg <= 0;
            end

            // Read data channel
            if (M_AXI_RVALID && M_AXI_RREADY) begin
                S_AXIL_RDATA <= M_AXI_RDATA;
                S_AXIL_RVALID <= 1;
            end else if (S_AXIL_RVALID && S_AXIL_RREADY) begin
                S_AXIL_RVALID <= 0;
            end

            // Ready signals
            S_AXIL_AWREADY <= !axil_awvalid_reg;
            S_AXIL_WREADY <= axil_awvalid_reg;
            S_AXIL_ARREADY <= !axil_arvalid_reg;
            S_AXIL_RRESP <= 2'b00;
            S_AXIL_BRESP <= 2'b00;
        end
    end

    // AXI interface
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_WLAST <= 0;
            M_AXI_BREADY <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY <= 0;
            axi_awaddr_reg <= 0;
            axi_araddr_reg <= 0;
            axi_addr_counter <= 0;
            axi_wdata_reg <= 0;
            axi_wstrb_reg <= 0;
            axi_awvalid_reg <= 0;
            axi_arvalid_reg <= 0;
            axi_wvalid_reg <= 0;
            axi_wlast_reg <= 0;
            axi_bready_reg <= 0;
            axi_rready_reg <= 0;
            axi_state <= 2'b00;
        end else begin
            case (axi_state)
                2'b00: begin // IDLE
                    if (axil_awvalid_reg) begin
                        axi_awaddr_reg <= axil_awaddr_reg;
                        axi_awvalid_reg <= 1;
                        axi_addr_counter <= 0;
                        axi_state <= 2'b01;
                    end else if (axil_arvalid_reg) begin
                        axi_araddr_reg <= axil_araddr_reg;
                        axi_arvalid_reg <= 1;
                        axi_addr_counter <= 0;
                        axi_state <= 2'b10;
                    end
                end
                2'b01: begin // WRITE
                    if (M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 0;
                        axi_wdata_reg <= axil_reg[axi_awaddr_reg];
                        axi_wstrb_reg <= {C_AXI_DATA_WIDTH/8{1'b1}};
                        axi_wvalid_reg <= 1;
                        if (axi_addr_counter == (C_AXI_ADDR_WIDTH/8 - 1)) begin
                            axi_wlast_reg <= 1;
                        end else begin
                            axi_addr_counter <= axi_addr_counter + 1;
                        end
                    end else if (M_AXI_WREADY) begin
                        axi_wvalid_reg <= 0;
                        axi_wlast_reg <= 0;
                        if (axi_wlast_reg) begin
                            axi_bready_reg <= 1;
                            axi_state <= 2'b00;
                        end
                    end else if (M_AXI_BVALID) begin
                        axi_bready_reg <= 0;
                    end
                end
                2'b10: begin // READ
                    if (M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 0;
                        axi_rready_reg <= 1;
                    end else if (M_AXI_RVALID) begin
                        axil_reg[axi_araddr_reg] <= M_AXI_RDATA;
                        axi_rready_reg <= 0;
                        if (M_AXI_RLAST) begin
                            axi_state <= 2'b00;
                        end else begin
                            axi_addr_counter <= axi_addr_counter + 1;
                        end
                    end
                end
            endcase

            // AXI write address channel
            if (axi_awvalid_reg) begin
                M_AXI_AWVALID <= 1;
                M_AXI_AWID <= AXI_WRITE_ID;
                M_AXI_AWADDR <= axi_awaddr_reg + (axi_addr_counter << ADDRLSB);
                M_AXI_AWSIZE <= 3'b010; // 4 bytes
                M_AXI_AWBURST <= 2'b01; // INCR
                M_AXI_AWLOCK <= 0;
                M_AXI_AWCACHE <= 4'b0011; // Non-cacheable, buffered, write-through
                M_AXI_AWPROT <= 3'b000;
                M_AXI_AWQOS <= 4'b0000;
            end

            // AXI write data channel
            if (axi_wvalid_reg) begin
                M_AXI_WVALID <= 1;
                M_AXI_WDATA <= axi_wdata_reg;
                M_AXI_WSTRB <= axi_wstrb_reg;
                M_AXI_WLAST <= axi_wlast_reg;
            end

            // AXI write response channel
            if (axi_bready_reg) begin
                M_AXI_BREADY <= 1;
            end

            // AXI read address channel
            if (axi_arvalid_reg) begin
                M_AXI_ARVALID <= 1;
                M_AXI_ARID <= AXI_READ_ID;
                M_AXI_ARADDR <= axi_araddr_reg + (axi_addr_counter << ADDRLSB);
                M_AXI_ARSIZE <= 3'b010; // 4 bytes
                M_AXI_ARBURST <= 2'b01; // INCR
                M_AXI_ARLOCK <= 0;
                M_AXI_ARCACHE <= 4'b0011; // Non-cacheable, buffered, write-through
                M_AXI_ARPROT <= 3'b000;
                M_AXI_ARQOS <= 4'b0000;
            end

            // AXI read data channel
            if (axi_rready_reg) begin
                M_AXI_RREADY <= 1;
            end
        end
    end

    // Interrupt output
    assign o_int = 0;

endmodule
