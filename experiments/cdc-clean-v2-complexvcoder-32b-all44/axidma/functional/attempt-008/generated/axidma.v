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

    // Internal state registers
    reg [C_AXI_ADDR_WIDTH-1:0] source_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dest_addr;
    reg [LGLEN-1:0] length;
    reg [1:0] state;
    reg [1:0] next_state;
    reg [1:0] bresp_reg;
    reg [1:0] rresp_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] rdata_reg;

    // State definitions
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;

    // AXIL Lite register file
    reg [C_AXIL_DATA_WIDTH-1:0] reg_file [0:3];

    // AXIL Lite address decoding
    wire [1:0] axil_reg_addr;
    assign axil_reg_addr = S_AXIL_AWADDR[2:1];

    // AXIL Lite write process
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            reg_file[0] <= 32'b0;
            reg_file[1] <= 32'b0;
            reg_file[2] <= 32'b0;
            reg_file[3] <= 32'b0;
        end else if (S_AXIL_AWVALID && S_AXIL_WVALID && S_AXIL_AWREADY) begin
            case (axil_reg_addr)
                2'b00: reg_file[0] <= S_AXIL_WDATA; // Source Address
                2'b01: reg_file[1] <= S_AXIL_WDATA; // Destination Address
                2'b10: reg_file[2] <= S_AXIL_WDATA; // Length
                2'b11: reg_file[3] <= S_AXIL_WDATA; // Control/Status
            endcase
        end
    end

    // AXIL Lite read process
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_RDATA <= 32'b0;
        end else if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
            case (axil_reg_addr)
                2'b00: S_AXIL_RDATA <= reg_file[0];
                2'b01: S_AXIL_RDATA <= reg_file[1];
                2'b10: S_AXIL_RDATA <= reg_file[2];
                2'b11: S_AXIL_RDATA <= reg_file[3];
            endcase
        end
    end

    // AXIL Lite handshake signals
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_AWREADY <= 1'b0;
            S_AXIL_WREADY <= 1'b0;
            S_AXIL_BVALID <= 1'b0;
            S_AXIL_ARREADY <= 1'b0;
            S_AXIL_RVALID <= 1'b0;
        end else begin
            S_AXIL_AWREADY <= S_AXIL_AWVALID;
            S_AXIL_WREADY <= S_AXIL_WVALID;
            S_AXIL_BVALID <= S_AXIL_BREADY ? 1'b0 : (S_AXIL_WVALID && S_AXIL_AWVALID && state == IDLE);
            S_AXIL_ARREADY <= S_AXIL_ARVALID;
            S_AXIL_RVALID <= S_AXIL_RREADY ? 1'b0 : S_AXIL_ARVALID;
        end
    end

    // AXIL Lite response signals
    assign S_AXIL_BRESP = bresp_reg;
    assign S_AXIL_RRESP = rresp_reg;

    // State machine
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (reg_file[3][0]) begin // Start write transfer
                    next_state = WRITE;
                end else if (reg_file[3][1]) begin // Start read transfer
                    next_state = READ;
                end
            end
            WRITE: begin
                if (M_AXI_BVALID) begin
                    next_state = IDLE;
                end
            end
            READ: begin
                if (M_AXI_RVALID && M_AXI_RLAST) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // AXI Write Address Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_AWVALID <= 1'b0;
            M_AXI_AWADDR <= 32'b0;
        end else begin
            M_AXI_AWVALID <= (state == WRITE) && !M_AXI_AWREADY ? M_AXI_AWVALID : (state == WRITE && M_AXI_AWREADY ? 1'b0 : 1'b0);
            if (state == WRITE && !M_AXI_AWVALID && M_AXI_AWREADY) begin
                M_AXI_AWADDR <= source_addr;
            end
        end
    end

    assign M_AXI_AWID = AXI_WRITE_ID;
    assign M_AXI_AWSIZE = 3'b010; // 32 bits
    assign M_AXI_AWBURST = 2'b01; // INCR
    assign M_AXI_AWLOCK = 1'b0;
    assign M_AXI_AWCACHE = 4'b0011; // Non-cacheable, non-bufferable, no allocate
    assign M_AXI_AWPROT = 3'b000;
    assign M_AXI_AWQOS = 4'b0000;

    // AXI Write Data Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_WVALID <= 1'b0;
            M_AXI_WDATA <= 32'b0;
            M_AXI_WSTRB <= 4'b0000;
            M_AXI_WLAST <= 1'b0;
        end else begin
            M_AXI_WVALID <= (state == WRITE) && !M_AXI_WREADY ? M_AXI_WVALID : (state == WRITE && M_AXI_WREADY ? (length > 0 ? 1'b1 : 1'b0) : 1'b0);
            M_AXI_WDATA <= M_AXI_WVALID ? M_AXI_WDATA : reg_file[0];
            M_AXI_WSTRB <= 4'b1111; // All bytes valid
            M_AXI_WLAST <= (length == C_AXI_DATA_WIDTH/8);
            if (M_AXI_WVALID && M_AXI_WREADY) begin
                source_addr <= source_addr + C_AXI_DATA_WIDTH/8;
                length <= length - (C_AXI_DATA_WIDTH/8);
            end
        end
    end

    // AXI Write Response Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_BREADY <= 1'b0;
            bresp_reg <= 2'b00;
        end else begin
            M_AXI_BREADY <= (state == WRITE) && M_AXI_BVALID ? 1'b1 : 1'b0;
            bresp_reg <= M_AXI_BRESP;
        end
    end

    // AXI Read Address Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_ARVALID <= 1'b0;
            M_AXI_ARADDR <= 32'b0;
        end else begin
            M_AXI_ARVALID <= (state == READ) && !M_AXI_ARREADY ? M_AXI_ARVALID : (state == READ && M_AXI_ARREADY ? 1'b0 : 1'b0);
            if (state == READ && !M_AXI_ARVALID && M_AXI_ARREADY) begin
                M_AXI_ARADDR <= dest_addr;
            end
        end
    end

    assign M_AXI_ARID = AXI_READ_ID;
    assign M_AXI_ARSIZE = 3'b010; // 32 bits
    assign M_AXI_ARBURST = 2'b01; // INCR
    assign M_AXI_ARLOCK = 1'b0;
    assign M_AXI_ARCACHE = 4'b0011; // Non-cacheable, non-bufferable, no allocate
    assign M_AXI_ARPROT = 3'b000;
    assign M_AXI_ARQOS = 4'b0000;

    // AXI Read Data Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_RREADY <= 1'b0;
            dest_addr <= 32'b0;
            rdata_reg <= 32'b0;
            rresp_reg <= 2'b00;
        end else begin
            M_AXI_RREADY <= (state == READ) && M_AXI_RVALID ? 1'b1 : 1'b0;
            if (M_AXI_RVALID && M_AXI_RREADY) begin
                dest_addr <= dest_addr + C_AXI_DATA_WIDTH/8;
                rdata_reg <= M_AXI_RDATA;
                rresp_reg <= M_AXI_RRESP;
            end
        end
    end

    // Interrupt signal
    assign o_int = (state == IDLE) && (M_AXI_BVALID || (M_AXI_RVALID && M_AXI_RLAST));

endmodule
