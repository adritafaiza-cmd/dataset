module axidma #(
    parameter C_AXI_ID_WIDTH = 1,
    parameter C_AXI_ADDR_WIDTH = 32,
    parameter C_AXI_DATA_WIDTH = 32,
    localparam C_AXIL_ADDR_WIDTH = 5,
    localparam C_AXIL_DATA_WIDTH = 32,
    parameter [0:0] OPT_UNALIGNED = 1'b1,
    parameter [0:0] OPT_WRAPMEM = 1'b1,
    parameter LGFIFO = LGMAXBURST + 1,
    parameter LGLEN = C_AXI_ADDR_WIDTH,
    parameter [0:0] OPT_LOWPOWER = 1'b0,
    parameter [0:0] OPT_CLKGATE = OPT_LOWPOWER,
    parameter [C_AXI_ID_WIDTH-1:0] AXI_READ_ID = 0,
    parameter [C_AXI_ID_WIDTH-1:0] AXI_WRITE_ID = 0,
    parameter [7:0] ABORT_KEY = 8'h6d,
    localparam ADDRLSB = $clog2(C_AXI_DATA_WIDTH) - 3,
    localparam AXILLSB = $clog2(C_AXIL_DATA_WIDTH) - 3,
    localparam LGLENW = LGLEN - ADDRLSB
) (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    // AXI4-Lite Interface
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
    // AXI4 Master Interface
    output reg S_AXIL_BRESP,
    output reg S_AXIL_RRESP,
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

    // Internal registers for DMA configuration
    reg [C_AXI_ADDR_WIDTH-1:0] source_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dest_addr;
    reg [LGLENW-1:0] length;
    reg [31:0] control_reg;

    // State machine states
    localparam IDLE = 0;
    localparam TRANSFER = 1;
    reg state;

    // AXI4-Lite write handling
    reg [C_AXIL_ADDR_WIDTH-1:0] awaddr_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] wdata_reg;
    reg awvalid_reg, wvalid_reg, bvalid_reg;

    assign S_AXIL_AWREADY = ~awvalid_reg;
    assign S_AXIL_WREADY = ~wvalid_reg;
    assign S_AXIL_BVALID = bvalid_reg;
    assign S_AXIL_BRESP = 2'b00; // OKAY response

    // AXI4-Lite write transaction
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            awvalid_reg <= 0;
            wvalid_reg <= 0;
            bvalid_reg <= 0;
            source_addr <= 0;
            dest_addr <= 0;
            length <= 0;
            control_reg <= 0;
        end else begin
            if (S_AXIL_AWVALID && S_AXIL_WVALID && S_AXIL_BREADY && !bvalid_reg) begin
                awaddr_reg <= S_AXIL_AWADDR;
                wdata_reg <= S_AXIL_WDATA;
                awvalid_reg <= 0;
                wvalid_reg <= 0;
                bvalid_reg <= 1;
                case (S_AXIL_AWADDR)
                    0: source_addr <= S_AXIL_WDATA;
                    4: dest_addr <= S_AXIL_WDATA;
                    8: length <= S_AXIL_WDATA;
                    12: control_reg <= S_AXIL_WDATA;
                endcase
            end else if (S_AXIL_AWVALID && !awvalid_reg) begin
                awvalid_reg <= 1;
            end else if (S_AXIL_WVALID && !wvalid_reg) begin
                wvalid_reg <= 1;
            end else if (S_AXIL_BREADY && bvalid_reg) begin
                bvalid_reg <= 0;
            end
        end
    end

    // DMA state machine
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            state <= IDLE;
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_BREADY <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY <= 0;
            o_int <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (control_reg[0]) begin
                        state <= TRANSFER;
                        M_AXI_AWID <= AXI_WRITE_ID;
                        M_AXI_ARID <= AXI_READ_ID;
                        M_AXI_AWADDR <= source_addr;
                        M_AXI_ARADDR <= source_addr;
                        M_AXI_AWSIZE <= 3; // 4 bytes
                        M_AXI_AWBURST <= 2; // INCR
                        M_AXI_ARSIZE <= 3;
                        M_AXI_ARBURST <= 2;
                        M_AXI_AWVALID <= 1;
                        M_AXI_ARVALID <= 1;
                        M_AXI_RREADY <= 1;
                        M_AXI_BREADY <= 1;
                    end
                end
                TRANSFER: begin
                    if (M_AXI_BVALID && M_AXI_AWVALID && M_AXI_ARVALID) begin
                        M_AXI_WDATA <= M_AXI_RDATA;
                        M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b1}};
                        M_AXI_WLAST <= (length == 1);
                        M_AXI_AWADDR <= dest_addr;
                        M_AXI_WVALID <= 1;
                        M_AXI_AWVALID <= 0;
                        M_AXI_ARVALID <= 0;
                        if (M_AXI_RLAST) begin
                            state <= IDLE;
                            control_reg[0] <= 0;
                            o_int <= 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule
