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

    reg [C_AXI_ADDR_WIDTH-1:0] source_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dest_addr;
    reg [LGLEN-1:0] transfer_len;
    reg [C_AXIL_DATA_WIDTH-1:0] control_reg;
    reg [2:0] state;
    reg [LGLEN-1:0] remaining_len;
    reg [C_AXI_ADDR_WIDTH-1:0] current_addr;
    reg [C_AXIL_ADDR_WIDTH-1:0] axil_addr_reg;

    localparam IDLE = 3'b000;
    localparam READ = 3'b001;
    localparam WRITE = 3'b010;
    localparam DONE = 3'b011;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
            S_AXIL_AWREADY <= 0;
            S_AXIL_WREADY <= 0;
            S_AXIL_BVALID <= 0;
            S_AXIL_ARREADY <= 0;
            S_AXIL_RVALID <= 0;
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_BREADY <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY <= 0;
            o_int <= 0;
        end else begin
            case (state)
                IDLE: begin
                    S_AXIL_AWREADY <= 1;
                    S_AXIL_WREADY <= 0;
                    S_AXIL_BVALID <= 0;
                    S_AXIL_ARREADY <= 1;
                    S_AXIL_RVALID <= 0;
                    M_AXI_AWVALID <= 0;
                    M_AXI_WVALID <= 0;
                    M_AXI_BREADY <= 0;
                    M_AXI_ARVALID <= 0;
                    M_AXI_RREADY <= 0;
                    o_int <= 0;

                    if (S_AXIL_AWVALID && S_AXIL_WVALID) begin
                        axil_addr_reg <= S_AXIL_AWADDR;
                        control_reg <= S_AXIL_WDATA;
                        S_AXIL_AWREADY <= 0;
                        S_AXIL_WREADY <= 1;
                    end

                    if (S_AXIL_WVALID && S_AXIL_BREADY) begin
                        S_AXIL_WREADY <= 0;
                        S_AXIL_BVALID <= 1;
                        S_AXIL_BRESP <= 2'b00;
                        state <= READ;
                        source_addr <= control_reg[31:0];
                        dest_addr <= control_reg[63:32];
                        transfer_len <= control_reg[95:64];
                        remaining_len <= transfer_len;
                        current_addr <= source_addr;
                    end

                    if (S_AXIL_ARVALID && S_AXIL_RREADY) begin
                        S_AXIL_ARREADY <= 0;
                        S_AXIL_RVALID <= 1;
                        S_AXIL_RDATA <= control_reg;
                        S_AXIL_RRESP <= 2'b00;
                    end
                end

                READ: begin
                    if (!M_AXI_ARVALID) begin
                        M_AXI_ARVALID <= 1;
                        M_AXI_ARID <= AXI_READ_ID;
                        M_AXI_ARADDR <= current_addr;
                        M_AXI_ARSIZE <= 3'b010; // 32 bits
                        M_AXI_ARBURST <= 2'b01; // INCR
                        M_AXI_ARLOCK <= 1'b0;
                        M_AXI_ARCACHE <= 4'b0011; // Normal Non-cacheable
                        M_AXI_ARPROT <= 3'b000;
                        M_AXI_ARQOS <= 4'b0000;
                    end

                    if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 0;
                    end

                    if (M_AXI_RVALID && !M_AXI_RREADY) begin
                        M_AXI_RREADY <= 1;
                    end

                    if (M_AXI_RVALID && M_AXI_RREADY) begin
                        M_AXI_RREADY <= 0;
                        current_addr <= current_addr + C_AXI_DATA_WIDTH/8;
                        remaining_len <= remaining_len - C_AXI_DATA_WIDTH/8;
                        M_AXI_WVALID <= 1;
                        M_AXI_WDATA <= M_AXI_RDATA;
                        M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b1}};
                        M_AXI_WLAST <= (remaining_len <= C_AXI_DATA_WIDTH/8);
                    end

                    if (M_AXI_WVALID && M_AXI_WREADY) begin
                        M_AXI_WVALID <= 0;
                        if (M_AXI_WLAST) begin
                            state <= WRITE;
                        end
                    end
                end

                WRITE: begin
                    if (M_AXI_BVALID) begin
                        M_AXI_BREADY <= 1;
                        state <= DONE;
                    end
                end

                DONE: begin
                    M_AXI_BREADY <= 0;
                    state <= IDLE;
                    o_int <= 1;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
