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
    localparam LGLENW = LGLEN-ADDRLSB
) (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    // AXI-Lite Control Port
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
    // AXI4-Master Port
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

    // Configuration registers
    reg [31:0] source_addr;
    reg [31:0] dest_addr;
    reg [31:0] length;
    reg start;
    reg busy;
    reg done;

    // AXI-Lite Write Handling
    reg [31:0] control_reg;
    reg [31:0] status_reg;

    // AXI4 State Machine
    localparam IDLE = 0;
    localparam READ = 1;
    localparam WRITE = 2;
    reg [1:0] state;

    reg [C_AXI_ADDR_WIDTH-1:0] current_source;
    reg [C_AXI_ADDR_WIDTH-1:0] current_dest;
    reg [31:0] remaining;
    reg [C_AXI_DATA_WIDTH-1:0] read_data;

    // AXI-Lite Ready signals
    assign S_AXIL_AWREADY = 1'b1; // Always ready for simplicity
    assign S_AXIL_WREADY = 1'b1;
    assign S_AXIL_BRESP = 2'b00; // OKAY
    assign S_AXIL_BVALID = 1'b1; // Always ready to accept writes
    assign S_AXIL_ARREADY = 1'b1; // Always ready for simplicity
    assign S_AXIL_RRESP = 2'b00; // OKAY
    assign M_AXI_ARID = AXI_READ_ID;
    assign M_AXI_ARSIZE = 3; // 32-bit transfers (log2(4))
    assign M_AXI_ARBURST = 2'b01; // INCR
    assign M_AXI_ARLOCK = 1'b0;
    assign M_AXI_ARCACHE = 4'b0010; // Normal, readable, writable
    assign M_AXI_ARPROT = 3'b000; // Unprivileged, secure, data access
    assign M_AXI_ARQOS = 4'b0000; // QoS 0

    assign M_AXI_RREADY = 1'b1;

    // AXI4 Write Channel
    assign M_AXI_AWID = AXI_WRITE_ID;
    assign M_AXI_AWSIZE = 3; // 32-bit transfers (log2(4))
    assign M_AXI_AWBURST = 2'b01; // INCR
    assign M_AXI_AWLOCK = 1'b0;
    assign M_AXI_AWCACHE = 4'b0010; // Normal, readable, writable
    assign M_AXI_AWPROT = 3'b000; // Unprivileged, secure, data access
    assign M_AXI_AWQOS = 4'b0000; // QoS 0

    // AXI-Lite Read Handling
    always @* begin
        S_AXIL_RDATA = 32'h0;
        case (S_AXIL_ARADDR)
            32'h00: S_AXIL_RDATA = {31'b0, done};
            32'h04: S_AXIL_RDATA = source_addr;
            32'h08: S_AXIL_RDATA = dest_addr;
            32'h0C: S_AXIL_RDATA = length;
            default: S_AXIL_RDATA = 32'h0;
        endcase
    end

    // AXI-Lite Write Handling
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            source_addr <= 0;
            dest_addr <= 0;
            length <= 0;
            control_reg <= 0;
            status_reg <= 0;
            busy <= 0;
            done <= 0;
        end else begin
            if (S_AXIL_AWVALID && S_AXIL_WVALID && S_AXIL_BREADY) begin
                case (S_AXIL_AWADDR)
                    32'h00: control_reg <= S_AXIL_WDATA;
                    32'h04: source_addr <= S_AXIL_WDATA;
                    32'h08: dest_addr <= S_AXIL_WDATA;
                    32'h0C: length <= S_AXIL_WDATA;
                endcase
            end
            if (control_reg[0] && !busy) begin
                busy <= 1;
                control_reg[0] <= 0;
            end
            if (busy) begin
                if (remaining == 0) begin
                    busy <= 0;
                    done <= 1;
                end
            end
        end
    end

    // AXI4 Transfer State Machine
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
            current_source <= 0;
            current_dest <= 0;
            remaining <= 0;
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_BREADY <= 0;
            M_AXI_WLAST <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (busy) begin
                        current_source <= source_addr;
                        current_dest <= dest_addr;
                        remaining <= length;
                        state <= READ;
                    end
                end
                READ: begin
                    M_AXI_ARADDR <= current_source;
                    M_AXI_ARVALID <= 1;
                    if (M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 0;
                        state <= WAIT_READ;
                    end
                end
                WAIT_READ: begin
                    if (M_AXI_RVALID) begin
                        read_data <= M_AXI_RDATA;
                        current_source <= current_source + 4;
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    M_AXI_AWADDR <= current_dest;
                    M_AXI_WDATA <= read_data;
                    M_AXI_WLAST <= 1;
                    M_AXI_AWVALID <= 1;
                    M_AXI_WVALID <= 1;
                    if (M_AXI_AWREADY && M_AXI_WREADY) begin
                        M_AXI_AWVALID <= 0;
                        M_AXI_WVALID <= 0;
                        M_AXI_WLAST <= 0;
                        current_dest <= current_dest +4;
                        remaining <= remaining -1;
                        if (remaining == 1) begin
                            state <= IDLE;
                            done <= 1;
                        end else begin
                            state <= READ;
                        end
                    end
                end
            endcase
        end
    end

endmodule
