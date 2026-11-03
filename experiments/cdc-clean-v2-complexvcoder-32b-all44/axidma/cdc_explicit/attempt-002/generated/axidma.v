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

    // Internal registers for AXI Lite control
    reg [C_AXI_ADDR_WIDTH-1:0] source_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dest_addr;
    reg [LGLEN-1:0] length;
    reg start_transfer;
    reg [1:0] state;

    // FSM states
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;

    // AXI Lite registers
    reg [C_AXIL_DATA_WIDTH-1:0] axil_reg [0:(1<<C_AXIL_ADDR_WIDTH)-1];

    // AXI Lite control signals
    reg [C_AXIL_ADDR_WIDTH-1:0] axil_addr_reg;
    reg axil_wready_reg;
    reg axil_awready_reg;
    reg axil_arready_reg;
    reg axil_bvalid_reg;
    reg [1:0] axil_bresp_reg;
    reg axil_rvalid_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] axil_rdata_reg;
    reg [1:0] axil_rresp_reg;

    // AXI Master control signals
    reg [C_AXI_ADDR_WIDTH-1:0] axi_addr_reg;
    reg [LGLEN-1:0] axi_length_reg;
    reg [C_AXI_DATA_WIDTH-1:0] axi_wdata_reg;
    reg [C_AXI_DATA_WIDTH/8-1:0] axi_wstrb_reg;
    reg axi_wlast_reg;
    reg axi_awvalid_reg;
    reg axi_wvalid_reg;
    reg axi_bready_reg;
    reg axi_arvalid_reg;
    reg axi_rready_reg;

    // AXI Lite control logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axil_addr_reg <= 0;
            axil_wready_reg <= 0;
            axil_awready_reg <= 0;
            axil_arready_reg <= 0;
            axil_bvalid_reg <= 0;
            axil_bresp_reg <= 0;
            axil_rvalid_reg <= 0;
            axil_rdata_reg <= 0;
            axil_rresp_reg <= 0;
            start_transfer <= 0;
        end else begin
            // Address Write Channel
            if (S_AXIL_AWVALID && axil_awready_reg) begin
                axil_addr_reg <= S_AXIL_AWADDR;
                axil_awready_reg <= 0;
            end else if (!axil_awready_reg) begin
                axil_awready_reg <= 1;
            end

            // Write Channel
            if (S_AXIL_WVALID && axil_wready_reg) begin
                axil_reg[axil_addr_reg] <= S_AXIL_WDATA;
                if (axil_addr_reg == 0) begin
                    source_addr <= S_AXIL_WDATA;
                end else if (axil_addr_reg == 4) begin
                    dest_addr <= S_AXIL_WDATA;
                end else if (axil_addr_reg == 8) begin
                    length <= S_AXIL_WDATA[LGLEN-1:0];
                    start_transfer <= 1;
                end
                axil_wready_reg <= 0;
            end else if (!axil_wready_reg) begin
                axil_wready_reg <= 1;
            end

            // Write Response Channel
            if (axil_bvalid_reg && S_AXIL_BREADY) begin
                axil_bvalid_reg <= 0;
            end else if (start_transfer) begin
                axil_bvalid_reg <= 1;
                axil_bresp_reg <= 2'b00;
                start_transfer <= 0;
            end

            // Read Address Channel
            if (S_AXIL_ARVALID && axil_arready_reg) begin
                axil_addr_reg <= S_AXIL_ARADDR;
                axil_arready_reg <= 0;
            end else if (!axil_arready_reg) begin
                axil_arready_reg <= 1;
            end

            // Read Data Channel
            if (axil_rvalid_reg && S_AXIL_RREADY) begin
                axil_rvalid_reg <= 0;
            end else if (S_AXIL_ARVALID && axil_arready_reg) begin
                axil_rvalid_reg <= 1;
                axil_rdata_reg <= axil_reg[axil_addr_reg];
                axil_rresp_reg <= 2'b00;
            end
        end
    end

    // AXI Master control logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
            axi_addr_reg <= 0;
            axi_length_reg <= 0;
            axi_wdata_reg <= 0;
            axi_wstrb_reg <= 0;
            axi_wlast_reg <= 0;
            axi_awvalid_reg <= 0;
            axi_wvalid_reg <= 0;
            axi_bready_reg <= 0;
            axi_arvalid_reg <= 0;
            axi_rready_reg <= 0;
            M_AXI_AWID <= 0;
            M_AXI_AWADDR <= 0;
            M_AXI_AWSIZE <= 2'b10; // 32-bit
            M_AXI_AWBURST <= 2'b01; // INCR
            M_AXI_AWLOCK <= 0;
            M_AXI_AWCACHE <= 3'b001; // Non-cacheable
            M_AXI_AWPROT <= 0;
            M_AXI_AWQOS <= 0;
            M_AXI_WDATA <= 0;
            M_AXI_WSTRB <= 0;
            M_AXI_WLAST <= 0;
            M_AXI_BREADY <= 0;
            M_AXI_ARID <= 0;
            M_AXI_ARADDR <= 0;
            M_AXI_ARSIZE <= 2'b10; // 32-bit
            M_AXI_ARBURST <= 2'b01; // INCR
            M_AXI_ARLOCK <= 0;
            M_AXI_ARCACHE <= 3'b001; // Non-cacheable
            M_AXI_ARPROT <= 0;
            M_AXI_ARQOS <= 0;
            M_AXI_RREADY <= 0;
            o_int <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_transfer) begin
                        axi_addr_reg <= source_addr;
                        axi_length_reg <= length;
                        state <= READ;
                    end
                end
                READ: begin
                    if (!axi_arvalid_reg) begin
                        axi_arvalid_reg <= 1;
                        M_AXI_ARADDR <= axi_addr_reg;
                    end
                    if (axi_arvalid_reg && M_AXI_ARREADY) begin
                        axi_arvalid_reg <= 0;
                    end
                    if (M_AXI_RVALID) begin
                        axi_wdata_reg <= M_AXI_RDATA;
                        axi_wstrb_reg <= {C_AXI_DATA_WIDTH/8{1'b1}};
                        if (axi_length_reg == C_AXI_DATA_WIDTH/8) begin
                            axi_wlast_reg <= 1;
                        end
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    if (!axi_awvalid_reg) begin
                        axi_awvalid_reg <= 1;
                        M_AXI_AWADDR <= dest_addr;
                    end
                    if (axi_awvalid_reg && M_AXI_AWREADY) begin
                        axi_awvalid_reg <= 0;
                    end
                    if (!axi_wvalid_reg) begin
                        axi_wvalid_reg <= 1;
                        M_AXI_WDATA <= axi_wdata_reg;
                        M_AXI_WSTRB <= axi_wstrb_reg;
                        M_AXI_WLAST <= axi_wlast_reg;
                    end
                    if (axi_wvalid_reg && M_AXI_WREADY) begin
                        axi_wvalid_reg <= 0;
                        axi_wlast_reg <= 0;
                        axi_length_reg <= axi_length_reg - C_AXI_DATA_WIDTH/8;
                        axi_addr_reg <= axi_addr_reg + C_AXI_DATA_WIDTH/8;
                        dest_addr <= dest_addr + C_AXI_DATA_WIDTH/8;
                        if (axi_length_reg == 0) begin
                            state <= IDLE;
                            o_int <= 1;
                        end else begin
                            state <= READ;
                        end
                    end
                end
            endcase

            // Write Response Channel
            if (M_AXI_BVALID) begin
                axi_bready_reg <= 1;
            end else begin
                axi_bready_reg <= 0;
            end

            // Read Data Channel
            if (M_AXI_RVALID) begin
                axi_rready_reg <= 1;
            end else begin
                axi_rready_reg <= 0;
            end
        end
    end

    // Assign outputs
    assign S_AXIL_AWREADY = axil_awready_reg;
    assign S_AXIL_WREADY = axil_wready_reg;
    assign S_AXIL_BVALID = axil_bvalid_reg;
    assign S_AXIL_BRESP = axil_bresp_reg;
    assign S_AXIL_ARREADY = axil_arready_reg;
    assign S_AXIL_RVALID = axil_rvalid_reg;
    assign S_AXIL_RDATA = axil_rdata_reg;
    assign S_AXIL_RRESP = axil_rresp_reg;

    assign M_AXI_AWVALID = axi_awvalid_reg;
    assign M_AXI_AWID = AXI_WRITE_ID;
    assign M_AXI_AWADDR = axi_addr_reg;
    assign M_AXI_AWSIZE = 2'b10; // 32-bit
    assign M_AXI_AWBURST = 2'b01; // INCR
    assign M_AXI_AWLOCK = 0;
    assign M_AXI_AWCACHE = 3'b001; // Non-cacheable
    assign M_AXI_AWPROT = 0;
    assign M_AXI_AWQOS = 0;

    assign M_AXI_WVALID = axi_wvalid_reg;
    assign M_AXI_WDATA = axi_wdata_reg;
    assign M_AXI_WSTRB = axi_wstrb_reg;
    assign M_AXI_WLAST = axi_wlast_reg;

    assign M_AXI_BREADY = axi_bready_reg;

    assign M_AXI_ARVALID = axi_arvalid_reg;
    assign M_AXI_ARID = AXI_READ_ID;
    assign M_AXI_ARADDR = axi_addr_reg;
    assign M_AXI_ARSIZE = 2'b10; // 32-bit
    assign M_AXI_ARBURST = 2'b01; // INCR
    assign M_AXI_ARLOCK = 0;
    assign M_AXI_ARCACHE = 3'b001; // Non-cacheable
    assign M_AXI_ARPROT = 0;
    assign M_AXI_ARQOS = 0;

    assign M_AXI_RREADY = axi_rready_reg;

endmodule
