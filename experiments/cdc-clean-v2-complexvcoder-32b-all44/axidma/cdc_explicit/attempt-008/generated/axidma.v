module axidma #(
        parameter   C_AXI_ID_WIDTH = 1,
        parameter   C_AXI_ADDR_WIDTH = 32,
        parameter   C_AXI_DATA_WIDTH = 32,
        localparam  C_AXIL_ADDR_WIDTH = 5,
        localparam  C_AXIL_DATA_WIDTH = 32,
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
        input   wire    S_AXI_ACLK,
        input   wire    S_AXI_ARESETN,
        input   wire                S_AXIL_AWVALID,
        output  wire                S_AXIL_AWREADY,
        input   wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_AWADDR,
        input   wire  [2:0]            S_AXIL_AWPROT,
        input   wire                S_AXIL_WVALID,
        output  wire                S_AXIL_WREADY,
        input   wire [C_AXIL_DATA_WIDTH-1:0] S_AXIL_WDATA,
        input   wire [C_AXIL_DATA_WIDTH/8-1:0] S_AXIL_WSTRB,
        output  reg                 S_AXIL_BVALID,
        input   wire                S_AXIL_BREADY,
        output  wire    [1:0]            S_AXIL_BRESP,
        input   wire                S_AXIL_ARVALID,
        output  wire                S_AXIL_ARREADY,
        input   wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_ARADDR,
        input   wire  [2:0]            S_AXIL_ARPROT,
        output  reg                 S_AXIL_RVALID,
        input   wire                S_AXIL_RREADY,
        output  reg [C_AXIL_DATA_WIDTH-1:0] S_AXIL_RDATA,
        output  wire    [1:0]            S_AXIL_RRESP,
        output  reg                 M_AXI_AWVALID,
        input   wire                M_AXI_AWREADY,
        output  reg [C_AXI_ID_WIDTH-1:0] M_AXI_AWID,
        output  reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
        output  reg [2:0]            M_AXI_AWSIZE,
        output  reg [1:0]            M_AXI_AWBURST,
        output  reg                 M_AXI_AWLOCK,
        output  reg [3:0]            M_AXI_AWCACHE,
        output  reg [2:0]            M_AXI_AWPROT,
        output  reg [3:0]            M_AXI_AWQOS,
        output  reg                 M_AXI_WVALID,
        input   wire                M_AXI_WREADY,
        output  reg [C_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
        output  reg [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
        output  reg                 M_AXI_WLAST,
        input   wire                M_AXI_BVALID,
        output  reg                 M_AXI_BREADY,
        input   wire [C_AXI_ID_WIDTH-1:0] M_AXI_BID,
        input   wire [1:0]            M_AXI_BRESP,
        output  reg                 M_AXI_ARVALID,
        input   wire                M_AXI_ARREADY,
        output  wire [C_AXI_ID_WIDTH-1:0] M_AXI_ARID,
        output  reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
        output  wire [2:0]            M_AXI_ARSIZE,
        output  wire [1:0]            M_AXI_ARBURST,
        output  wire                M_AXI_ARLOCK,
        output  wire [3:0]            M_AXI_ARCACHE,
        output  wire [2:0]            M_AXI_ARPROT,
        output  wire [3:0]            M_AXI_ARQOS,
        input   wire                M_AXI_RVALID,
        output  wire                M_AXI_RREADY,
        input   wire [C_AXI_ID_WIDTH-1:0] M_AXI_RID,
        input   wire [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
        input   wire                M_AXI_RLAST,
        input   wire [1:0]            M_AXI_RRESP,
        output  reg                 o_int
    );

    // Control registers
    reg [C_AXI_ADDR_WIDTH-1:0] src_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dst_addr;
    reg [LGLEN-1:0] len;

    // Control signals
    reg start_transfer;
    reg transfer_complete;
    reg [1:0] bresp_reg;
    reg [1:0] rresp_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] rdata_reg;

    // AXILite control logic
    reg axil_awready_reg;
    reg axil_wready_reg;

    // AXI control logic
    reg axi_awvalid_reg;
    reg axi_wvalid_reg;
    reg axi_bready_reg;
    reg axi_arvalid_reg;
    reg axi_rready_reg;

    // State machine
    typedef enum reg [2:0] {
        IDLE,
        WRITE_ADDR,
        WRITE_DATA,
        WRITE_RESPONSE,
        READ_ADDR,
        READ_DATA,
        READ_RESPONSE
    } state_t;

    state_t state, next_state;

    // AXI Lite control
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axil_awready_reg <= 1'b0;
            axil_wready_reg <= 1'b0;
            S_AXIL_BVALID <= 1'b0;
            S_AXIL_RVALID <= 1'b0;
            S_AXIL_BRESP <= 2'b00;
            S_AXIL_RDATA <= 32'b0;
            S_AXIL_RRESP <= 2'b00;
            start_transfer <= 1'b0;
        end else begin
            axil_awready_reg <= S_AXIL_AWVALID;
            axil_wready_reg <= S_AXIL_WVALID & axil_awready_reg;
            S_AXIL_BVALID <= M_AXI_BVALID & axi_bready_reg;
            S_AXIL_RVALID <= M_AXI_RVALID & axi_rready_reg;
            S_AXIL_BRESP <= bresp_reg;
            S_AXIL_RDATA <= rdata_reg;
            S_AXIL_RRESP <= rresp_reg;

            if (S_AXIL_AWVALID && axil_awready_reg) begin
                if (S_AXIL_AWADDR[2:0] == 3'b000) src_addr <= S_AXIL_WDATA;
                else if (S_AXIL_AWADDR[2:0] == 3'b001) dst_addr <= S_AXIL_WDATA;
                else if (S_AXIL_AWADDR[2:0] == 3'b010) len <= S_AXIL_WDATA[LGLEN-1:0];
                else if (S_AXIL_AWADDR[2:0] == 3'b011) start_transfer <= 1'b1;
            end

            if (start_transfer && transfer_complete) begin
                start_transfer <= 1'b0;
            end
        end
    end

    // AXI state machine
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
            axi_awvalid_reg <= 1'b0;
            axi_wvalid_reg <= 1'b0;
            axi_bready_reg <= 1'b0;
            axi_arvalid_reg <= 1'b0;
            axi_rready_reg <= 1'b0;
            transfer_complete <= 1'b0;
            M_AXI_AWADDR <= 32'b0;
            M_AXI_AWPROT <= 3'b0;
            M_AXI_WDATA <= 32'b0;
            M_AXI_WSTRB <= 4'b0;
            M_AXI_WLAST <= 1'b0;
            M_AXI_ARADDR <= 32'b0;
            M_AXI_ARPROT <= 3'b0;
            bresp_reg <= 2'b00;
            rdata_reg <= 32'b0;
            rresp_reg <= 2'b00;
        end else begin
            state <= next_state;
            axi_awvalid_reg <= (state == WRITE_ADDR) ? 1'b1 : 1'b0;
            axi_wvalid_reg <= (state == WRITE_DATA) ? 1'b1 : 1'b0;
            axi_bready_reg <= (state == WRITE_RESPONSE) ? 1'b1 : 1'b0;
            axi_arvalid_reg <= (state == READ_ADDR) ? 1'b1 : 1'b0;
            axi_rready_reg <= (state == READ_DATA) ? 1'b1 : 1'b0;
            transfer_complete <= (state == READ_RESPONSE) ? 1'b1 : 1'b0;

            case (state)
                IDLE: begin
                    if (start_transfer) begin
                        M_AXI_AWADDR <= src_addr;
                        M_AXI_AWPROT <= 3'b0;
                        M_AXI_WSTRB <= 4'b1111;
                        M_AXI_AWBURST <= 2'b01; // INCR
                        M_AXI_AWSIZE <= 3'b010; // 32 bits
                        M_AXI_AWLOCK <= 1'b0;
                        M_AXI_AWCACHE <= 4'b0011; // Non-cacheable
                        M_AXI_AWQOS <= 4'b0000;
                        M_AXI_AWID <= AXI_WRITE_ID;
                        next_state = WRITE_ADDR;
                    end else begin
                        next_state = IDLE;
                    end
                end
                WRITE_ADDR: begin
                    if (M_AXI_AWREADY) begin
                        M_AXI_WDATA <= M_AXI_RDATA; // Assuming read-modify-write for simplicity
                        next_state = WRITE_DATA;
                    end else begin
                        next_state = WRITE_ADDR;
                    end
                end
                WRITE_DATA: begin
                    if (M_AXI_WREADY) begin
                        if (len == 1) begin
                            M_AXI_WLAST <= 1'b1;
                            next_state = WRITE_RESPONSE;
                        end else begin
                            M_AXI_WLAST <= 1'b0;
                            next_state = WRITE_DATA;
                        end
                    end else begin
                        next_state = WRITE_DATA;
                    end
                end
                WRITE_RESPONSE: begin
                    if (M_AXI_BVALID) begin
                        bresp_reg <= M_AXI_BRESP;
                        M_AXI_ARADDR <= dst_addr;
                        M_AXI_ARPROT <= 3'b0;
                        M_AXI_ARBURST <= 2'b01; // INCR
                        M_AXI_ARSIZE <= 3'b010; // 32 bits
                        M_AXI_ARLOCK <= 1'b0;
                        M_AXI_ARCACHE <= 4'b0011; // Non-cacheable
                        M_AXI_ARQOS <= 4'b0000;
                        M_AXI_ARID <= AXI_READ_ID;
                        next_state = READ_ADDR;
                    end else begin
                        next_state = WRITE_RESPONSE;
                    end
                end
                READ_ADDR: begin
                    if (M_AXI_ARREADY) begin
                        next_state = READ_DATA;
                    end else begin
                        next_state = READ_ADDR;
                    end
                end
                READ_DATA: begin
                    if (M_AXI_RVALID) begin
                        rdata_reg <= M_AXI_RDATA;
                        rresp_reg <= M_AXI_RRESP;
                        if (M_AXI_RLAST) begin
                            next_state = READ_RESPONSE;
                        end else begin
                            next_state = READ_DATA;
                        end
                    end else begin
                        next_state = READ_DATA;
                    end
                end
                READ_RESPONSE: begin
                    next_state = IDLE;
                end
                default: next_state = IDLE;
            endcase
        end
    end

    // Assignments
    assign S_AXIL_AWREADY = axil_awready_reg;
    assign S_AXIL_WREADY = axil_wready_reg;
    assign M_AXI_AWVALID = axi_awvalid_reg;
    assign M_AXI_WVALID = axi_wvalid_reg;
    assign M_AXI_BREADY = axi_bready_reg;
    assign M_AXI_ARVALID = axi_arvalid_reg;
    assign M_AXI_RREADY = axi_rready_reg;
    assign M_AXI_AWID = AXI_WRITE_ID;
    assign M_AXI_ARID = AXI_READ_ID;
    assign S_AXIL_BRESP = bresp_reg;
    assign S_AXIL_RDATA = rdata_reg;
    assign S_AXIL_RRESP = rresp_reg;
    assign o_int = transfer_complete;

endmodule
