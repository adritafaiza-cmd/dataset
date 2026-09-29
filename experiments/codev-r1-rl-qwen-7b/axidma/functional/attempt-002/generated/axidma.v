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
    localparam ADDRLSB = $clog2(C_AXI_DATA_WIDTH)-3,
    localparam AXILLSB = $clog2(C_AXIL_DATA_WIDTH)-3,
    localparam LGLENW = LGLEN - ADDRLSB
) (
    // Clock and Reset
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,

    // AXI4-Lite Interface
    // Write Address Channel
    input wire S_AXIL_AWVALID,
    output wire S_AXIL_AWREADY,
    input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_AWADDR,
    input wire [2:0] S_AXIL_AWPROT,

    // Write Data Channel
    input wire S_AXIL_WVALID,
    output wire S_AXIL_WREADY,
    input wire [C_AXIL_DATA_WIDTH-1:0] S_AXIL_WDATA,
    input wire [C_AXIL_DATA_WIDTH/8-1:0] S_AXIL_WSTRB,

    // Write Response Channel
    output reg S_AXIL_BVALID,
    input wire S_AXIL_BREADY,
    output wire [1:0] S_AXIL_BRESP,

    // Read Address Channel
    input wire S_AXIL_ARVALID,
    output wire S_AXIL_ARREADY,
    input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_ARADDR,
    input wire [2:0] S_AXIL_ARPROT,

    // Read Data Channel
    output reg S_AXIL_RVALID,
    input wire S_AXIL_RREADY,
    output reg [C_AXIL_DATA_WIDTH-1:0] S_AXIL_RDATA,
    output wire [1:0] S_AXIL_RRESP,

    // AXI4 Master Interface
    // Write Address Channel
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

    // Write Data Channel
    output reg M_AXI_WVALID,
    input wire M_AXI_WREADY,
    output reg [C_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
    output reg [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
    output reg M_AXI_WLAST,

    // Write Response Channel
    input wire M_AXI_BVALID,
    output reg M_AXI_BREADY,
    input wire [C_AXI_ID_WIDTH-1:0] M_AXI_BID,
    input wire [1:0] M_AXI_BRESP,

    // Read Address Channel
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

    // Read Data Channel
    input wire M_AXI_RVALID,
    output wire M_AXI_RREADY,
    input wire [C_AXI_ID_WIDTH-1:0] M_AXI_RID,
    input wire [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
    input wire M_AXI_RLAST,
    input wire [1:0] M_AXI_RRESP,

    // Other Outputs
    output reg o_int
);

    // Internal Registers
    reg [31:0] source_addr;
    reg [31:0] dest_addr;
    reg [31:0] length;
    reg start;
    reg done;

    // State Machine
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam TRANSFER = 2'b10;
    reg [1:0] state;

    // AXI4-Lite Write Handling
    reg awready, wready;
    assign S_AXIL_AWREADY = awready;
    assign S_AXIL_WREADY = wready;

    // AXI4-Lite Read Handling
    reg rvalid;
    assign S_AXIL_RVALID = rvalid;
    assign S_AXIL_RRESP = 2'b00; // OKAY response

    // AXI4 Master Defaults
    assign S_AXIL_BRESP = 2'b00; // OKAY response
    assign M_AXI_ARID = AXI_READ_ID;
    assign M_AXI_ARPROT = 3'b000;
    assign M_AXI_ARQOS = 4'b0;
    assign M_AXI_ARSIZE = 3'b010; // 4 bytes
    assign M_AXI_ARBURST = 2'b01; // INCR
    assign M_AXI_ARLOCK = 1'b0;
    assign M_AXI_ARCACHE = 4'b0010; // Normal, Read, Bufferable
    assign M_AXI_RREADY = 1'b1;

    // State Machine and DMA Logic
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
            source_addr <= 0;
            dest_addr <= 0;
            length <= 0;
            start <= 0;
            done <= 0;
            o_int <= 0;
            awready <= 0;
            wready <= 0;
            S_AXIL_BVALID <= 0;
            rvalid <= 0;
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_BREADY <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_WLAST <= 0;
        end else begin
            case (state)
                IDLE: begin
                    o_int <= 0;
                    if (start) begin
                        state <= START;
                    end
                end
                START: begin
                    // Initialize AXI transactions
                    M_AXI_AWADDR <= source_addr;
                    M_AXI_WDATA <= 0;
                    M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b1}};
                    M_AXI_AWVALID <= 1;
                    M_AXI_WVALID <= 1;
                    state <= TRANSFER;
                end
                TRANSFER: begin
                    if (M_AXI_AWREADY && M_AXI_WREADY) begin
                        // Assume data transfer done
                        done <= 1;
                        o_int <= 1;
                        state <= IDLE;
                    end
                end
            endcase

            // AXI4-Lite Write Handling
            if (S_AXIL_AWVALID && S_AXIL_WVALID && awready && wready) begin
                case (S_AXIL_AWADDR)
                    0: source_addr <= S_AXIL_WDATA;
                    4: dest_addr <= S_AXIL_WDATA;
                    8: length <= S_AXIL_WDATA;
                    12: start <= S_AXIL_WDATA[0];
                endcase
                awready <= 0;
                wready <= 0;
                S_AXIL_BVALID <= 1;
            end else if (S_AXIL_AWVALID && S_AXIL_WVALID) begin
                awready <= 1;
                wready <= 1;
            end else begin
                awready <= 0;
                wready <= 0;
                S_AXIL_BVALID <= 0;
            end

            // AXI4-Lite Read Handling
            if (S_AXIL_ARVALID) begin
                case (S_AXIL_ARADDR)
                    16: S_AXIL_RDATA <= {31'd0, done};
                endcase
                rvalid <= 1;
            end else begin
                rvalid <= 0;
            end
        end
    end

endmodule
