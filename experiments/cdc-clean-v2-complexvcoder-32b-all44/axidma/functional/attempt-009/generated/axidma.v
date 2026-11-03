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

    // Internal states and registers
    reg [C_AXI_ADDR_WIDTH-1:0] source_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dest_addr;
    reg [LGLEN-1:0] length;
    reg [C_AXI_DATA_WIDTH-1:0] control_reg;
    reg [C_AXI_DATA_WIDTH-1:0] status_reg;
    reg [2:0] axil_awaddr_reg;
    reg [2:0] axil_araddr_reg;
    reg axil_awready_reg;
    reg axil_wready_reg;
    reg axil_arready_reg;
    reg axil_rvalid_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] axil_rdata_reg;
    reg [1:0] axil_rresp_reg;
    reg axi_awvalid_reg;
    reg axi_wvalid_reg;
    reg axi_bready_reg;
    reg axi_arvalid_reg;
    reg axi_rready_reg;
    reg [C_AXI_ADDR_WIDTH-1:0] axi_awaddr_reg;
    reg [C_AXI_ADDR_WIDTH-1:0] axi_araddr_reg;
    reg [LGLEN-1:0] remaining_length;
    reg [LGLENW-1:0] beat_count;
    reg [C_AXI_DATA_WIDTH-1:0] write_data_reg;
    reg [C_AXI_DATA_WIDTH/8-1:0] write_strb_reg;
    reg [1:0] axi_awburst_reg;
    reg [1:0] axi_arburst_reg;
    reg [2:0] axi_awsize_reg;
    reg [2:0] axi_arsize_reg;
    reg [3:0] axi_awcache_reg;
    reg [3:0] axi_arcache_reg;
    reg [3:0] axi_awqos_reg;
    reg [3:0] axi_arqos_reg;
    reg [1:0] axi_awprot_reg;
    reg [1:0] axi_arprot_reg;
    reg [C_AXI_ID_WIDTH-1:0] axi_awid_reg;
    reg [C_AXI_ID_WIDTH-1:0] axi_arid_reg;
    reg [1:0] axi_awlock_reg;
    reg [1:0] axi_arlock_reg;
    reg transfer_active;

    // Control register mapping
    localparam CONTROL_REG_ADDR = 5'b00000;
    localparam STATUS_REG_ADDR = 5'b00001;
    localparam SOURCE_ADDR_REG_ADDR = 5'b00010;
    localparam DEST_ADDR_REG_ADDR = 5'b00011;
    localparam LENGTH_REG_ADDR = 5'b00100;

    // AXIL Write FSM
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axil_awready_reg <= 0;
            axil_wready_reg <= 0;
            S_AXIL_BVALID <= 0;
        end else begin
            if (S_AXIL_AWVALID && axil_awready_reg) begin
                axil_awready_reg <= 0;
                axil_wready_reg <= 1;
                axil_awaddr_reg <= S_AXIL_AWADDR[C_AXIL_ADDR_WIDTH-1:C_AXIL_ADDR_WIDTH-C_AXIL_ADDR_WIDTH];
            end else if (S_AXIL_WVALID && axil_wready_reg) begin
                axil_wready_reg <= 0;
                S_AXIL_BVALID <= 1;
                case (axil_awaddr_reg)
                    CONTROL_REG_ADDR: control_reg <= S_AXIL_WDATA;
                    SOURCE_ADDR_REG_ADDR: source_addr <= S_AXIL_WDATA;
                    DEST_ADDR_REG_ADDR: dest_addr <= S_AXIL_WDATA;
                    LENGTH_REG_ADDR: length <= S_AXIL_WDATA;
                    default: ;
                endcase
            end else if (S_AXIL_BREADY && S_AXIL_BVALID) begin
                S_AXIL_BVALID <= 0;
                axil_awready_reg <= 1;
            end
        end
    end

    // AXIL Read FSM
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axil_arready_reg <= 0;
            axil_rvalid_reg <= 0;
        end else begin
            if (S_AXIL_ARVALID && axil_arready_reg) begin
                axil_arready_reg <= 0;
                axil_rvalid_reg <= 1;
                axil_araddr_reg <= S_AXIL_ARADDR[C_AXIL_ADDR_WIDTH-1:C_AXIL_ADDR_WIDTH-C_AXIL_ADDR_WIDTH];
                case (axil_araddr_reg)
                    CONTROL_REG_ADDR: axil_rdata_reg <= control_reg;
                    STATUS_REG_ADDR: axil_rdata_reg <= status_reg;
                    SOURCE_ADDR_REG_ADDR: axil_rdata_reg <= source_addr;
                    DEST_ADDR_REG_ADDR: axil_rdata_reg <= dest_addr;
                    LENGTH_REG_ADDR: axil_rdata_reg <= length;
                    default: axil_rdata_reg <= 32'b0;
                endcase
            end else if (S_AXIL_RREADY && axil_rvalid_reg) begin
                axil_rvalid_reg <= 0;
                axil_arready_reg <= 1;
            end
        end
    end

    // AXIL Read/Write Ready signals
    assign S_AXIL_AWREADY = axil_awready_reg;
    assign S_AXIL_WREADY = axil_wready_reg;
    assign S_AXIL_ARREADY = axil_arready_reg;
    assign S_AXIL_RVALID = axil_rvalid_reg;
    assign S_AXIL_RDATA = axil_rdata_reg;
    assign S_AXIL_BRESP = 2'b00;
    assign S_AXIL_RRESP = 2'b00;

    // AXI Write FSM
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_awvalid_reg <= 0;
            axi_wvalid_reg <= 0;
            axi_bready_reg <= 0;
            transfer_active <= 0;
            remaining_length <= 0;
            beat_count <= 0;
            write_data_reg <= 0;
            write_strb_reg <= 0;
            axi_awaddr_reg <= 0;
            axi_awburst_reg <= 2'b01;
            axi_awsize_reg <= 3'b010;
            axi_awcache_reg <= 4'b0011;
            axi_awqos_reg <= 4'b0000;
            axi_awprot_reg <= 3'b000;
            axi_awid_reg <= AXI_WRITE_ID;
            axi_awlock_reg <= 1'b0;
        end else begin
            if (!transfer_active && (control_reg[0] == 1'b1)) begin
                axi_awvalid_reg <= 1;
                axi_wvalid_reg <= 0;
                axi_bready_reg <= 0;
                transfer_active <= 1;
                remaining_length <= length;
                beat_count <= 0;
                axi_awaddr_reg <= source_addr;
            end else if (axi_awvalid_reg && M_AXI_AWREADY) begin
                axi_awvalid_reg <= 0;
                axi_wvalid_reg <= 1;
            end else if (axi_wvalid_reg && M_AXI_WREADY) begin
                if (remaining_length > 0) begin
                    axi_wvalid_reg <= 1;
                    remaining_length <= remaining_length - 1;
                    beat_count <= beat_count + 1;
                    if (remaining_length == 1) begin
                        M_AXI_WLAST <= 1;
                    end else begin
                        M_AXI_WLAST <= 0;
                    end
                end else begin
                    axi_wvalid_reg <= 0;
                    axi_bready_reg <= 1;
                end
            end else if (axi_bready_reg && M_AXI_BVALID) begin
                axi_bready_reg <= 0;
                transfer_active <= 0;
                control_reg[0] <= 1'b0;
                status_reg <= M_AXI_BRESP;
            end
        end
    end

    // AXI Write Data
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            write_data_reg <= 0;
            write_strb_reg <= 0;
        end else if (axi_wvalid_reg && M_AXI_WREADY) begin
            write_data_reg <= M_AXI_RDATA;
            write_strb_reg <= {C_AXI_DATA_WIDTH/8{1'b1}};
        end
    end

    // AXI Write Address
    assign M_AXI_AWVALID = axi_awvalid_reg;
    assign M_AXI_AWID = axi_awid_reg;
    assign M_AXI_AWADDR = axi_awaddr_reg;
    assign M_AXI_AWSIZE = axi_awsize_reg;
    assign M_AXI_AWBURST = axi_awburst_reg;
    assign M_AXI_AWLOCK = axi_awlock_reg;
    assign M_AXI_AWCACHE = axi_awcache_reg;
    assign M_AXI_AWPROT = axi_awprot_reg;
    assign M_AXI_AWQOS = axi_awqos_reg;

    // AXI Write Data
    assign M_AXI_WVALID = axi_wvalid_reg;
    assign M_AXI_WDATA = write_data_reg;
    assign M_AXI_WSTRB = write_strb_reg;

    // AXI Read FSM
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_arvalid_reg <= 0;
            axi_rready_reg <= 0;
            transfer_active <= 0;
            remaining_length <= 0;
            beat_count <= 0;
            axi_araddr_reg <= 0;
            axi_arburst_reg <= 2'b01;
            axi_arsize_reg <= 3'b010;
            axi_arcache_reg <= 4'b0011;
            axi_arqos_reg <= 4'b0000;
            axi_arprot_reg <= 3'b000;
            axi_arid_reg <= AXI_READ_ID;
            axi_arlock_reg <= 1'b0;
        end else begin
            if (!transfer_active && (control_reg[1] == 1'b1)) begin
                axi_arvalid_reg <= 1;
                axi_rready_reg <= 0;
                transfer_active <= 1;
                remaining_length <= length;
                beat_count <= 0;
                axi_araddr_reg <= source_addr;
            end else if (axi_arvalid_reg && M_AXI_ARREADY) begin
                axi_arvalid_reg <= 0;
                axi_rready_reg <= 1;
            end else if (axi_rready_reg && M_AXI_RVALID) begin
                if (remaining_length > 0) begin
                    axi_rready_reg <= 1;
                    remaining_length <= remaining_length - 1;
                    beat_count <= beat_count + 1;
                end else begin
                    axi_rready_reg <= 0;
                    transfer_active <= 0;
                    control_reg[1] <= 1'b0;
                    status_reg <= M_AXI_RRESP;
                end
            end
        end
    end

    // AXI Read Address
    assign M_AXI_ARVALID = axi_arvalid_reg;
    assign M_AXI_ARID = axi_arid_reg;
    assign M_AXI_ARADDR = axi_araddr_reg;
    assign M_AXI_ARSIZE = axi_arsize_reg;
    assign M_AXI_ARBURST = axi_arburst_reg;
    assign M_AXI_ARLOCK = axi_arlock_reg;
    assign M_AXI_ARCACHE = axi_arcache_reg;
    assign M_AXI_ARPROT = axi_arprot_reg;
    assign M_AXI_ARQOS = axi_arqos_reg;

    // AXI Read Data
    assign M_AXI_RREADY = axi_rready_reg;

    // Interrupt signal
    assign o_int = 0;

endmodule
