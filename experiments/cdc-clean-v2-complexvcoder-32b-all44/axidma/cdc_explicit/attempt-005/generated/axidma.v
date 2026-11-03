module axidma #(
        parameter   C_AXI_ID_WIDTH = 1,
        parameter   C_AXI_ADDR_WIDTH = 32,
        parameter   C_AXI_DATA_WIDTH = 32,
        localparam  C_AXIL_ADDR_WIDTH = 5,
        localparam  C_AXIL_DATA_WIDTH = 32,
        parameter [0:0] OPT_UNALIGNED = 1'b1,
        parameter [0:0] OPT_WRAPMEM = 1'b1,
        parameter   LGFIFO = 4, // Assuming LGMAXBURST+1 = 4 for example
        parameter   LGLEN = C_AXI_ADDR_WIDTH,
        parameter [0:0] OPT_LOWPOWER = 1'b0,
        parameter [0:0] OPT_CLKGATE = OPT_LOWPOWER,
        parameter   [C_AXI_ID_WIDTH-1:0] AXI_READ_ID = 0,
        parameter   [C_AXI_ID_WIDTH-1:0] AXI_WRITE_ID = 0,
        parameter   [7:0] ABORT_KEY  = 8'h6d,
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
        output  wire    [1:0]         S_AXIL_BRESP,
        input   wire                S_AXIL_ARVALID,
        output  wire                S_AXIL_ARREADY,
        input   wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_ARADDR,
        input   wire  [2:0]         S_AXIL_ARPROT,
        output  reg                 S_AXIL_RVALID,
        input   wire                S_AXIL_RREADY,
        output  reg [C_AXIL_DATA_WIDTH-1:0] S_AXIL_RDATA,
        output  wire    [1:0]         S_AXIL_RRESP,
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
        output  wire [2:0]          M_AXI_ARSIZE,
        output  wire [1:0]          M_AXI_ARBURST,
        output  wire                M_AXI_ARLOCK,
        output  wire [3:0]          M_AXI_ARCACHE,
        output  wire [2:0]          M_AXI_ARPROT,
        output  wire [3:0]          M_AXI_ARQOS,
        input   wire                M_AXI_RVALID,
        output  wire                M_AXI_RREADY,
        input   wire [C_AXI_ID_WIDTH-1:0] M_AXI_RID,
        input   wire [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
        input   wire                M_AXI_RLAST,
        input   wire [1:0]          M_AXI_RRESP,
        output  reg                 o_int
    );

    // AXILite controller signals
    reg [C_AXIL_DATA_WIDTH-1:0] axilite_reg [0:(2**C_AXIL_ADDR_WIDTH)-1];
    reg [C_AXIL_ADDR_WIDTH-1:0] axilite_awaddr_reg;
    reg [C_AXIL_ADDR_WIDTH-1:0] axilite_araddr_reg;
    reg axilite_awvalid_reg;
    reg axilite_arvalid_reg;
    reg axilite_awready_reg;
    reg axilite_arready_reg;
    reg axilite_wready_reg;
    reg axilite_bvalid_reg;
    reg [1:0] axilite_bresp_reg;
    reg axilite_rvalid_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] axilite_rdata_reg;
    reg [1:0] axilite_rresp_reg;

    // DMA engine signals
    reg [C_AXI_ADDR_WIDTH-1:0] dma_src_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dma_dst_addr;
    reg [LGLEN-1:0] dma_len;
    reg dma_start;
    reg dma_done;

    // AXILite Controller
    axilite_controller #(
        .C_AXIL_ADDR_WIDTH(C_AXIL_ADDR_WIDTH),
        .C_AXIL_DATA_WIDTH(C_AXIL_DATA_WIDTH)
    ) axilite_ctrl (
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXIL_AWVALID(S_AXIL_AWVALID),
        .S_AXIL_AWREADY(axilite_awready_reg),
        .S_AXIL_AWADDR(S_AXIL_AWADDR),
        .S_AXIL_AWPROT(S_AXIL_AWPROT),
        .S_AXIL_WVALID(S_AXIL_WVALID),
        .S_AXIL_WREADY(axilite_wready_reg),
        .S_AXIL_WDATA(S_AXIL_WDATA),
        .S_AXIL_WSTRB(S_AXIL_WSTRB),
        .S_AXIL_BVALID(axilite_bvalid_reg),
        .S_AXIL_BREADY(S_AXIL_BREADY),
        .S_AXIL_BRESP(axilite_bresp_reg),
        .S_AXIL_ARVALID(S_AXIL_ARVALID),
        .S_AXIL_ARREADY(axilite_arready_reg),
        .S_AXIL_ARADDR(S_AXIL_ARADDR),
        .S_AXIL_ARPROT(S_AXIL_ARPROT),
        .S_AXIL_RVALID(axilite_rvalid_reg),
        .S_AXIL_RREADY(S_AXIL_RREADY),
        .S_AXIL_RDATA(axilite_rdata_reg),
        .S_AXIL_RRESP(axilite_rresp_reg),
        .axilite_reg(axilite_reg),
        .axilite_awaddr_reg(axilite_awaddr_reg),
        .axilite_araddr_reg(axilite_araddr_reg),
        .axilite_awvalid_reg(axilite_awvalid_reg),
        .axilite_arvalid_reg(axilite_arvalid_reg)
    );

    // DMA Engine
    dma_engine #(
        .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
        .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
        .AXI_READ_ID(AXI_READ_ID),
        .AXI_WRITE_ID(AXI_WRITE_ID)
    ) dma_eng (
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .dma_src_addr(dma_src_addr),
        .dma_dst_addr(dma_dst_addr),
        .dma_len(dma_len),
        .dma_start(dma_start),
        .dma_done(dma_done),
        .M_AXI_AWVALID(M_AXI_AWVALID),
        .M_AXI_AWREADY(M_AXI_AWREADY),
        .M_AXI_AWID(M_AXI_AWID),
        .M_AXI_AWADDR(M_AXI_AWADDR),
        .M_AXI_AWSIZE(M_AXI_AWSIZE),
        .M_AXI_AWBURST(M_AXI_AWBURST),
        .M_AXI_AWLOCK(M_AXI_AWLOCK),
        .M_AXI_AWCACHE(M_AXI_AWCACHE),
        .M_AXI_AWPROT(M_AXI_AWPROT),
        .M_AXI_AWQOS(M_AXI_AWQOS),
        .M_AXI_WVALID(M_AXI_WVALID),
        .M_AXI_WREADY(M_AXI_WREADY),
        .M_AXI_WDATA(M_AXI_WDATA),
        .M_AXI_WSTRB(M_AXI_WSTRB),
        .M_AXI_WLAST(M_AXI_WLAST),
        .M_AXI_BVALID(M_AXI_BVALID),
        .M_AXI_BREADY(M_AXI_BREADY),
        .M_AXI_BID(M_AXI_BID),
        .M_AXI_BRESP(M_AXI_BRESP),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_ARREADY(M_AXI_ARREADY),
        .M_AXI_ARID(M_AXI_ARID),
        .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARSIZE(M_AXI_ARSIZE),
        .M_AXI_ARBURST(M_AXI_ARBURST),
        .M_AXI_ARLOCK(M_AXI_ARLOCK),
        .M_AXI_ARCACHE(M_AXI_ARCACHE),
        .M_AXI_ARPROT(M_AXI_ARPROT),
        .M_AXI_ARQOS(M_AXI_ARQOS),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RREADY(M_AXI_RREADY),
        .M_AXI_RID(M_AXI_RID),
        .M_AXI_RDATA(M_AXI_RDATA),
        .M_AXI_RLAST(M_AXI_RLAST),
        .M_AXI_RRESP(M_AXI_RRESP)
    );

    // AXILite interface to DMA engine
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_AWREADY <= 1'b0;
            S_AXIL_WREADY <= 1'b0;
            S_AXIL_BVALID <= 1'b0;
            S_AXIL_ARREADY <= 1'b0;
            S_AXIL_RVALID <= 1'b0;
            dma_src_addr <= 0;
            dma_dst_addr <= 0;
            dma_len <= 0;
            dma_start <= 1'b0;
            o_int <= 1'b0;
        end else begin
            // AXILite Write Interface
            S_AXIL_AWREADY <= axilite_awready_reg;
            S_AXIL_WREADY <= axilite_wready_reg;
            S_AXIL_BVALID <= axilite_bvalid_reg;
            S_AXIL_BRESP <= axilite_bresp_reg;

            if (axilite_awvalid_reg && axilite_awready_reg) begin
                case (axilite_awaddr_reg)
                    5'h00: dma_src_addr <= axilite_reg[axilite_awaddr_reg];
                    5'h04: dma_dst_addr <= axilite_reg[axilite_awaddr_reg];
                    5'h08: dma_len <= axilite_reg[axilite_awaddr_reg];
                    5'h0C: dma_start <= axilite_reg[axilite_awaddr_reg][0];
                endcase
            end

            // AXILite Read Interface
            S_AXIL_ARREADY <= axilite_arready_reg;
            S_AXIL_RVALID <= axilite_rvalid_reg;
            S_AXIL_RDATA <= axilite_rdata_reg;
            S_AXIL_RRESP <= axilite_rresp_reg;

            if (axilite_arvalid_reg && axilite_arready_reg) begin
                case (axilite_araddr_reg)
                    5'h0C: axilite_rdata_reg <= {31'd0, dma_done};
                endcase
            end

            // DMA Done Interrupt
            if (dma_done) begin
                o_int <= 1'b1;
            end else if (S_AXIL_BREADY && axilite_bvalid_reg) begin
                o_int <= 1'b0;
            end
        end
    end

endmodule

// AXILite Controller Module
module axilite_controller #(
    parameter   C_AXIL_ADDR_WIDTH = 5,
    parameter   C_AXIL_DATA_WIDTH = 32
) (
    input   wire    S_AXI_ACLK,
    input   wire    S_AXI_ARESETN,
    input   wire                S_AXIL_AWVALID,
    output  reg                 S_AXIL_AWREADY,
    input   wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_AWADDR,
    input   wire  [2:0]         S_AXIL_AWPROT,
    input   wire                S_AXIL_WVALID,
    output  reg                 S_AXIL_WREADY,
    input   wire [C_AXIL_DATA_WIDTH-1:0] S_AXIL_WDATA,
    input   wire [C_AXIL_DATA_WIDTH/8-1:0] S_AXIL_WSTRB,
    output  reg                 S_AXIL_BVALID,
    input   wire                S_AXIL_BREADY,
    output  reg [1:0]         S_AXIL_BRESP,
    input   wire                S_AXIL_ARVALID,
    output  reg                 S_AXIL_ARREADY,
    input   wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_ARADDR,
    input   wire  [2:0]         S_AXIL_ARPROT,
    output  reg                 S_AXIL_RVALID,
    input   wire                S_AXIL_RREADY,
    output  reg [C_AXIL_DATA_WIDTH-1:0] S_AXIL_RDATA,
    output  reg [1:0]         S_AXIL_RRESP,
    inout   reg [C_AXIL_DATA_WIDTH-1:0] axilite_reg [0:(2**C_AXIL_ADDR_WIDTH)-1],
    output  reg [C_AXIL_ADDR_WIDTH-1:0] axilite_awaddr_reg,
    output  reg [C_AXIL_ADDR_WIDTH-1:0] axilite_araddr_reg,
    output  reg                 axilite_awvalid_reg,
    output  reg                 axilite_arvalid_reg
);

    reg [1:0] state;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= 2'b00;
            S_AXIL_AWREADY <= 1'b0;
            S_AXIL_WREADY <= 1'b0;
            S_AXIL_BVALID <= 1'b0;
            S_AXIL_BRESP <= 2'b00;
            S_AXIL_ARREADY <= 1'b0;
            S_AXIL_RVALID <= 1'b0;
            S_AXIL_RDATA <= 32'b0;
            S_AXIL_RRESP <= 2'b00;
            axilite_awaddr_reg <= 0;
            axilite_araddr_reg <= 0;
            axilite_awvalid_reg <= 0;
            axilite_arvalid_reg <= 0;
        end else begin
            case (state)
                2'b00: begin // IDLE
                    if (S_AXIL_AWVALID) begin
                        state <= 2'b01;
                        axilite_awaddr_reg <= S_AXIL_AWADDR;
                        axilite_awvalid_reg <= 1'b1;
                    end else if (S_AXIL_ARVALID) begin
                        state <= 2'b10;
                        axilite_araddr_reg <= S_AXIL_ARADDR;
                        axilite_arvalid_reg <= 1'b1;
                    end
                end
                2'b01: begin // WRITE
                    if (S_AXIL_WVALID) begin
                        S_AXIL_AWREADY <= 1'b1;
                        S_AXIL_WREADY <= 1'b1;
                        axilite_reg[axilite_awaddr_reg] <= S_AXIL_WDATA;
                        axilite_awvalid_reg <= 1'b0;
                        state <= 2'b11;
                    end
                end
                2'b10: begin // READ
                    S_AXIL_ARREADY <= 1'b1;
                    S_AXIL_RVALID <= 1'b1;
                    S_AXIL_RDATA <= axilite_reg[axilite_araddr_reg];
                    axilite_arvalid_reg <= 1'b0;
                    state <= 2'b11;
                end
                2'b11: begin // RESPONSE
                    if (S_AXIL_BREADY) begin
                        S_AXIL_BVALID <= 1'b0;
                        S_AXIL_RVALID <= 1'b0;
                        state <= 2'b00;
                    end else if (S_AXIL_BREADY && S_AXIL_BVALID) begin
                        S_AXIL_BVALID <= 1'b1;
                        S_AXIL_BRESP <= 2'b00;
                    end else if (S_AXIL_RREADY && S_AXIL_RVALID) begin
                        S_AXIL_RVALID <= 1'b1;
                        S_AXIL_RRESP <= 2'b00;
                    end
                end
            endcase
        end
    end

endmodule

// DMA Engine Module
module dma_engine #(
    parameter   C_AXI_ID_WIDTH = 1,
    parameter   C_AXI_ADDR_WIDTH = 32,
    parameter   C_AXI_DATA_WIDTH = 32,
    parameter   AXI_READ_ID = 0,
    parameter   AXI_WRITE_ID = 0
) (
    input   wire    S_AXI_ACLK,
    input   wire    S_AXI_ARESETN,
    input   wire [C_AXI_ADDR_WIDTH-1:0] dma_src_addr,
    input   wire [C_AXI_ADDR_WIDTH-1:0] dma_dst_addr,
    input   wire [31:0] dma_len,
    input   wire                dma_start,
    output  reg                 dma_done,
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
    output  reg [C_AXI_ID_WIDTH-1:0] M_AXI_ARID,
    output  reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
    output  reg [2:0]         M_AXI_ARSIZE,
    output  reg [1:0]         M_AXI_ARBURST,
    output  reg                 M_AXI_ARLOCK,
    output  reg [3:0]         M_AXI_ARCACHE,
    output  reg [2:0]         M_AXI_ARPROT,
    output  reg [3:0]         M_AXI_ARQOS,
    input   wire                M_AXI_RVALID,
    output  reg                 M_AXI_RREADY,
    input   wire [C_AXI_ID_WIDTH-1:0] M_AXI_RID,
    input   wire [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
    input   wire                M_AXI_RLAST,
    input   wire [1:0]          M_AXI_RRESP
);

    reg [C_AXI_ADDR_WIDTH-1:0] read_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] write_addr;
    reg [31:0] len_counter;
    reg [C_AXI_DATA_WIDTH-1:0] read_data;
    reg read_valid;
    reg [1:0] state;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= 2'b00;
            dma_done <= 1'b0;
            M_AXI_AWVALID <= 1'b0;
            M_AXI_AWID <= AXI_WRITE_ID;
            M_AXI_AWADDR <= 0;
            M_AXI_AWSIZE <= 3'b010; // 4 bytes
            M_AXI_AWBURST <= 2'b01; // INCR
            M_AXI_AWLOCK <= 1'b0;
            M_AXI_AWCACHE <= 4'b0011; // Non-cacheable, buffered, write allocate
            M_AXI_AWPROT <= 3'b000; // Normal, non-secure, data
            M_AXI_AWQOS <= 4'b0000; // No QoS
            M_AXI_WVALID <= 1'b0;
            M_AXI_WDATA <= 0;
            M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b1}};
            M_AXI_WLAST <= 1'b0;
            M_AXI_BREADY <= 1'b0;
            M_AXI_ARVALID <= 1'b0;
            M_AXI_ARID <= AXI_READ_ID;
            M_AXI_ARADDR <= 0;
            M_AXI_ARSIZE <= 3'b010; // 4 bytes
            M_AXI_ARBURST <= 2'b01; // INCR
            M_AXI_ARLOCK <= 1'b0;
            M_AXI_ARCACHE <= 4'b0011; // Non-cacheable, buffered, write allocate
            M_AXI_ARPROT <= 3'b000; // Normal, non-secure, data
            M_AXI_ARQOS <= 4'b0000; // No QoS
            M_AXI_RREADY <= 1'b0;
            read_addr <= 0;
            write_addr <= 0;
            len_counter <= 0;
            read_data <= 0;
            read_valid <= 1'b0;
        end else begin
            case (state)
                2'b00: begin // IDLE
                    if (dma_start) begin
                        state <= 2'b01;
                        read_addr <= dma_src_addr;
                        write_addr <= dma_dst_addr;
                        len_counter <= dma_len;
                    end
                end
                2'b01: begin // READ
                    M_AXI_ARVALID <= 1'b1;
                    M_AXI_ARADDR <= read_addr;

                    if (M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 1'b0;
                        state <= 2'b10;
                    end
                end
                2'b10: begin // WAIT_READ_DATA
                    if (M_AXI_RVALID) begin
                        read_data <= M_AXI_RDATA;
                        read_valid <= 1'b1;
                        M_AXI_RREADY <= 1'b1;

                        if (M_AXI_RLAST) begin
                            state <= 2'b11;
                        end
                    end
                end
                2'b11: begin // WRITE
                    M_AXI_WVALID <= 1'b1;
                    M_AXI_WDATA <= read_data;
                    M_AXI_WLAST <= (len_counter == 1) ? 1'b1 : 1'b0;

                    if (M_AXI_WREADY) begin
                        M_AXI_WVALID <= 1'b0;
                        read_valid <= 1'b0;

                        if (M_AXI_WLAST) begin
                            state <= 2'b100;
                        end else begin
                            read_addr <= read_addr + C_AXI_DATA_WIDTH/8;
                            write_addr <= write_addr + C_AXI_DATA_WIDTH/8;
                            len_counter <= len_counter - 1;
                            state <= 2'b01;
                        end
                    end
                end
                2'b100: begin // WAIT_WRITE_RESPONSE
                    if (M_AXI_BVALID) begin
                        M_AXI_BREADY <= 1'b1;
                        state <= 2'b00;
                        dma_done <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
