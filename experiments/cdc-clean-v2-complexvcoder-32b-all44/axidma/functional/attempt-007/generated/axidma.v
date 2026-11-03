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

    // Internal registers
    reg [C_AXI_ADDR_WIDTH-1:0] src_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dst_addr;
    reg [LGLEN-1:0] length;
    reg [LGLENW-1:0] len_cnt;
    reg [2:0] state;
    reg [1:0] bresp_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg [C_AXIL_ADDR_WIDTH-1:0] reg_addr;

    // States
    localparam IDLE = 3'b000;
    localparam READ = 3'b001;
    localparam WRITE = 3'b010;
    localparam BRESP_WAIT = 3'b011;
    localparam RRESP_WAIT = 3'b100;

    // AXI Lite Register Addresses
    localparam REG_SRC_ADDR = 5'b00000;
    localparam REG_DST_ADDR = 5'b00001;
    localparam REG_LENGTH = 5'b00010;
    localparam REG_CTRL = 5'b00011;
    localparam REG_STATUS = 5'b00100;

    // AXI Lite Interface
    assign S_AXIL_AWREADY = (state == IDLE) & ~S_AXIL_ARVALID;
    assign S_AXIL_WREADY = S_AXIL_AWREADY;
    assign S_AXIL_ARREADY = (state == IDLE) & ~S_AXIL_AWVALID;
    assign S_AXIL_BRESP = bresp_reg;
    assign S_AXIL_RRESP = rresp_reg;

    // AXI Master Interface
    assign M_AXI_AWID = AXI_WRITE_ID;
    assign M_AXI_AWSIZE = 3'b010; // 32-bit
    assign M_AXI_AWBURST = 2'b01; // INCR
    assign M_AXI_AWLOCK = 1'b0;
    assign M_AXI_AWCACHE = 4'b0011; // Non-cacheable, bufferable, modifiable
    assign M_AXI_AWPROT = 3'b000;
    assign M_AXI_AWQOS = 4'b0000;
    assign M_AXI_WSTRB = {C_AXI_DATA_WIDTH/8{1'b1}};
    assign M_AXI_WLAST = (len_cnt == 1);
    assign M_AXI_ARID = AXI_READ_ID;
    assign M_AXI_ARSIZE = 3'b010; // 32-bit
    assign M_AXI_ARBURST = 2'b01; // INCR
    assign M_AXI_ARLOCK = 1'b0;
    assign M_AXI_ARCACHE = 4'b0011; // Non-cacheable, bufferable, modifiable
    assign M_AXI_ARPROT = 3'b000;
    assign M_AXI_ARQOS = 4'b0000;
    assign M_AXI_RREADY = 1;

    // AXI Lite Write Address Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            reg_addr <= 0;
        end else if (S_AXIL_AWVALID & S_AXIL_AWREADY) begin
            reg_addr <= S_AXIL_AWADDR;
        end
    end

    // AXI Lite Write Data Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            src_addr <= 0;
            dst_addr <= 0;
            length <= 0;
        end else if (S_AXIL_WVALID & S_AXIL_WREADY) begin
            case (reg_addr)
                REG_SRC_ADDR: src_addr <= S_AXIL_WDATA;
                REG_DST_ADDR: dst_addr <= S_AXIL_WDATA;
                REG_LENGTH: length <= S_AXIL_WDATA;
            endcase
        end
    end

    // AXI Lite Write Response Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_BVALID <= 0;
            bresp_reg <= 2'b00;
        end else if (S_AXIL_BVALID & S_AXIL_BREADY) begin
            S_AXIL_BVALID <= 0;
        end else if (state == BRESP_WAIT & M_AXI_BVALID) begin
            S_AXIL_BVALID <= 1;
            bresp_reg <= M_AXI_BRESP;
        end
    end

    // AXI Lite Read Address Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            reg_addr <= 0;
        end else if (S_AXIL_ARVALID & S_AXIL_ARREADY) begin
            reg_addr <= S_AXIL_ARADDR;
        end
    end

    // AXI Lite Read Data Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_RVALID <= 0;
            rdata_reg <= 0;
            rresp_reg <= 2'b00;
        end else if (S_AXIL_RVALID & S_AXIL_RREADY) begin
            S_AXIL_RVALID <= 0;
        end else if (state == RRESP_WAIT & M_AXI_RVALID & M_AXI_RLAST) begin
            S_AXIL_RVALID <= 1;
            rdata_reg <= M_AXI_RDATA;
            rresp_reg <= M_AXI_RRESP;
        end
    end

    // State Machine
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
            len_cnt <= 0;
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_BREADY <= 0;
            o_int <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (reg_addr == REG_CTRL & S_AXIL_WVALID & S_AXIL_WREADY & S_AXIL_WDATA[0]) begin
                        state <= READ;
                        len_cnt <= length >> ADDRLSB;
                        M_AXI_ARADDR <= src_addr;
                        M_AXI_ARVALID <= 1;
                    end
                end
                READ: begin
                    if (M_AXI_ARVALID & M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 0;
                        state <= RRESP_WAIT;
                    end
                end
                RRESP_WAIT: begin
                    if (M_AXI_RVALID & M_AXI_RREADY) begin
                        M_AXI_WDATA <= M_AXI_RDATA;
                        M_AXI_WVALID <= 1;
                        M_AXI_AWADDR <= dst_addr;
                        M_AXI_AWVALID <= 1;
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    if (M_AXI_AWVALID & M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 0;
                    end
                    if (M_AXI_WVALID & M_AXI_WREADY) begin
                        M_AXI_WVALID <= 0;
                        if (M_AXI_WLAST) begin
                            M_AXI_BREADY <= 1;
                            state <= BRESP_WAIT;
                        end else begin
                            dst_addr <= dst_addr + C_AXI_DATA_WIDTH/8;
                            src_addr <= src_addr + C_AXI_DATA_WIDTH/8;
                            len_cnt <= len_cnt - 1;
                            if (len_cnt != 1) begin
                                M_AXI_ARADDR <= src_addr;
                                M_AXI_ARVALID <= 1;
                                state <= READ;
                            end
                        end
                    end
                end
                BRESP_WAIT: begin
                    if (M_AXI_BVALID & M_AXI_BREADY) begin
                        M_AXI_BREADY <= 0;
                        state <= IDLE;
                        o_int <= 1;
                    end
                end
            endcase
        end
    end

endmodule
