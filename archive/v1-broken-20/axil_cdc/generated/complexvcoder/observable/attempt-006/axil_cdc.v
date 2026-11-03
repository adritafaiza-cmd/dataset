module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [ADDR_WIDTH-1:0]  m_axil_awaddr,
    output wire [2:0]             m_axil_awprot,
    output wire                   m_axil_awvalid,
    input  wire                   m_axil_awready,
    output wire [DATA_WIDTH-1:0]  m_axil_wdata,
    output wire [STRB_WIDTH-1:0]  m_axil_wstrb,
    output wire                   m_axil_wvalid,
    input  wire                   m_axil_wready,
    input  wire [1:0]             m_axil_bresp,
    input  wire                   m_axil_bvalid,
    output wire                   m_axil_bready,
    output wire [ADDR_WIDTH-1:0]  m_axil_araddr,
    output wire [2:0]             m_axil_arprot,
    output wire                   m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output wire                   m_axil_rready
);

    wire [ADDR_WIDTH-1:0] slave_awaddr_reg;
    wire [2:0] slave_awprot_reg;
    wire slave_awvalid_reg;
    wire slave_awready_reg;
    wire [DATA_WIDTH-1:0] slave_wdata_reg;
    wire [STRB_WIDTH-1:0] slave_wstrb_reg;
    wire slave_wvalid_reg;
    wire slave_wready_reg;
    wire [1:0] slave_bresp_reg;
    wire slave_bvalid_reg;
    wire slave_bready_reg;
    wire [ADDR_WIDTH-1:0] slave_araddr_reg;
    wire [2:0] slave_arprot_reg;
    wire slave_arvalid_reg;
    wire slave_arready_reg;
    wire [DATA_WIDTH-1:0] slave_rdata_reg;
    wire [1:0] slave_rresp_reg;
    wire slave_rvalid_reg;
    wire slave_rready_reg;

    wire [ADDR_WIDTH-1:0] master_awaddr_reg;
    wire [2:0] master_awprot_reg;
    wire master_awvalid_reg;
    wire master_awready_reg;
    wire [DATA_WIDTH-1:0] master_wdata_reg;
    wire [STRB_WIDTH-1:0] master_wstrb_reg;
    wire master_wvalid_reg;
    wire master_wready_reg;
    wire [1:0] master_bresp_reg;
    wire master_bvalid_reg;
    wire master_bready_reg;
    wire [ADDR_WIDTH-1:0] master_araddr_reg;
    wire [2:0] master_arprot_reg;
    wire master_arvalid_reg;
    wire master_arready_reg;
    wire [DATA_WIDTH-1:0] master_rdata_reg;
    wire [1:0] master_rresp_reg;
    wire master_rvalid_reg;
    wire master_rready_reg;

    axil_cdc_slave #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .STRB_WIDTH(STRB_WIDTH)) slave
    (
        .clk(s_clk),
        .rst(s_rst),
        .awaddr(s_axil_awaddr),
        .awprot(s_axil_awprot),
        .awvalid(s_axil_awvalid),
        .awready(s_axil_awready),
        .wdata(s_axil_wdata),
        .wstrb(s_axil_wstrb),
        .wvalid(s_axil_wvalid),
        .wready(s_axil_wready),
        .bresp(s_axil_bresp),
        .bvalid(s_axil_bvalid),
        .bready(s_axil_bready),
        .araddr(s_axil_araddr),
        .arprot(s_axil_arprot),
        .arvalid(s_axil_arvalid),
        .arready(s_axil_arready),
        .rdata(s_axil_rdata),
        .rresp(s_axil_rresp),
        .rvalid(s_axil_rvalid),
        .rready(s_axil_rready),
        .awaddr_reg(slave_awaddr_reg),
        .awprot_reg(slave_awprot_reg),
        .awvalid_reg(slave_awvalid_reg),
        .awready_reg(slave_awready_reg),
        .wdata_reg(slave_wdata_reg),
        .wstrb_reg(slave_wstrb_reg),
        .wvalid_reg(slave_wvalid_reg),
        .wready_reg(slave_wready_reg),
        .bresp_reg(slave_bresp_reg),
        .bvalid_reg(slave_bvalid_reg),
        .bready_reg(slave_bready_reg),
        .araddr_reg(slave_araddr_reg),
        .arprot_reg(slave_arprot_reg),
        .arvalid_reg(slave_arvalid_reg),
        .arready_reg(slave_arready_reg),
        .rdata_reg(slave_rdata_reg),
        .rresp_reg(slave_rresp_reg),
        .rvalid_reg(slave_rvalid_reg),
        .rready_reg(slave_rready_reg)
    );

    axil_cdc_master #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .STRB_WIDTH(STRB_WIDTH)) master
    (
        .clk(m_clk),
        .rst(m_rst),
        .awaddr(m_axil_awaddr),
        .awprot(m_axil_awprot),
        .awvalid(m_axil_awvalid),
        .awready(m_axil_awready),
        .wdata(m_axil_wdata),
        .wstrb(m_axil_wstrb),
        .wvalid(m_axil_wvalid),
        .wready(m_axil_wready),
        .bresp(m_axil_bresp),
        .bvalid(m_axil_bvalid),
        .bready(m_axil_bready),
        .araddr(m_axil_araddr),
        .arprot(m_axil_arprot),
        .arvalid(m_axil_arvalid),
        .arready(m_axil_arready),
        .rdata(m_axil_rdata),
        .rresp(m_axil_rresp),
        .rvalid(m_axil_rvalid),
        .rready(m_axil_rready),
        .awaddr_reg(master_awaddr_reg),
        .awprot_reg(master_awprot_reg),
        .awvalid_reg(master_awvalid_reg),
        .awready_reg(master_awready_reg),
        .wdata_reg(master_wdata_reg),
        .wstrb_reg(master_wstrb_reg),
        .wvalid_reg(master_wvalid_reg),
        .wready_reg(master_wready_reg),
        .bresp_reg(master_bresp_reg),
        .bvalid_reg(master_bvalid_reg),
        .bready_reg(master_bready_reg),
        .araddr_reg(master_araddr_reg),
        .arprot_reg(master_arprot_reg),
        .arvalid_reg(master_arvalid_reg),
        .arready_reg(master_arready_reg),
        .rdata_reg(master_rdata_reg),
        .rresp_reg(master_rresp_reg),
        .rvalid_reg(master_rvalid_reg),
        .rready_reg(master_rready_reg)
    );

endmodule

module axil_cdc_slave
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [ADDR_WIDTH-1:0]  awaddr,
    input  wire [2:0]             awprot,
    input  wire                   awvalid,
    output wire                   awready,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire [STRB_WIDTH-1:0]  wstrb,
    input  wire                   wvalid,
    output wire                   wready,
    output wire [1:0]             bresp,
    output wire                   bvalid,
    input  wire                   bready,
    input  wire [ADDR_WIDTH-1:0]  araddr,
    input  wire [2:0]             arprot,
    input  wire                   arvalid,
    output wire                   arready,
    output wire [DATA_WIDTH-1:0]  rdata,
    output wire [1:0]             rresp,
    output wire                   rvalid,
    input  wire                   rready,
    output reg [ADDR_WIDTH-1:0]  awaddr_reg,
    output reg [2:0]             awprot_reg,
    output reg                   awvalid_reg,
    output reg                   awready_reg,
    output reg [DATA_WIDTH-1:0]  wdata_reg,
    output reg [STRB_WIDTH-1:0]  wstrb_reg,
    output reg                   wvalid_reg,
    output reg                   wready_reg,
    output reg [1:0]             bresp_reg,
    output reg                   bvalid_reg,
    output reg                   bready_reg,
    output reg [ADDR_WIDTH-1:0]  araddr_reg,
    output reg [2:0]             arprot_reg,
    output reg                   arvalid_reg,
    output reg                   arready_reg,
    output reg [DATA_WIDTH-1:0]  rdata_reg,
    output reg [1:0]             rresp_reg,
    output reg                   rvalid_reg,
    output reg                   rready_reg
);

    reg [2:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 3'b000;
            awaddr_reg <= 0;
            awprot_reg <= 0;
            awvalid_reg <= 0;
            awready_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            wready_reg <= 0;
            bresp_reg <= 2'b00;
            bvalid_reg <= 0;
            bready_reg <= 0;
            araddr_reg <= 0;
            arprot_reg <= 0;
            arvalid_reg <= 0;
            arready_reg <= 0;
            rdata_reg <= 0;
            rresp_reg <= 2'b00;
            rvalid_reg <= 0;
            rready_reg <= 0;
        end else begin
            case (state)
                3'b000: begin
                    if (awvalid && arvalid) begin
                        awaddr_reg <= awaddr;
                        awprot_reg <= awprot;
                        awvalid_reg <= awvalid;
                        araddr_reg <= araddr;
                        arprot_reg <= arprot;
                        arvalid_reg <= arvalid;
                        state <= 3'b001;
                    end else if (awvalid) begin
                        awaddr_reg <= awaddr;
                        awprot_reg <= awprot;
                        awvalid_reg <= awvalid;
                        state <= 3'b010;
                    end else if (arvalid) begin
                        araddr_reg <= araddr;
                        arprot_reg <= arprot;
                        arvalid_reg <= arvalid;
                        state <= 3'b011;
                    end
                end
                3'b001: begin
                    awready_reg <= 1;
                    arready_reg <= 1;
                    if (bready) begin
                        awready_reg <= 0;
                        arready_reg <= 0;
                        state <= 3'b000;
                    end
                end
                3'b010: begin
                    awready_reg <= 1;
                    if (bready) begin
                        awready_reg <= 0;
                        state <= 3'b000;
                    end
                end
                3'b011: begin
                    arready_reg <= 1;
                    if (rready) begin
                        arready_reg <= 0;
                        state <= 3'b000;
                    end
                end
                default: state <= 3'b000;
            endcase
        end
    end

    assign awready = awready_reg;
    assign wready = wready_reg;
    assign bresp = bresp_reg;
    assign bvalid = bvalid_reg;
    assign arready = arready_reg;
    assign rdata = rdata_reg;
    assign rresp = rresp_reg;
    assign rvalid = rvalid_reg;

endmodule

module axil_cdc_master
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    input  wire                   clk,
    input  wire                   rst,
    output wire [ADDR_WIDTH-1:0]  awaddr,
    output wire [2:0]             awprot,
    output wire                   awvalid,
    input  wire                   awready,
    output wire [DATA_WIDTH-1:0]  wdata,
    output wire [STRB_WIDTH-1:0]  wstrb,
    output wire                   wvalid,
    input  wire                   wready,
    input  wire [1:0]             bresp,
    input  wire                   bvalid,
    output wire                   bready,
    output wire [ADDR_WIDTH-1:0]  araddr,
    output wire [2:0]             arprot,
    output wire                   arvalid,
    input  wire                   arready,
    input  wire [DATA_WIDTH-1:0]  rdata,
    input  wire [1:0]             rresp,
    input  wire                   rvalid,
    output wire                   rready,
    input  wire [ADDR_WIDTH-1:0]  awaddr_reg,
    input  wire [2:0]             awprot_reg,
    input  wire                   awvalid_reg,
    input  wire                   awready_reg,
    input  wire [DATA_WIDTH-1:0]  wdata_reg,
    input  wire [STRB_WIDTH-1:0]  wstrb_reg,
    input  wire                   wvalid_reg,
    input  wire                   wready_reg,
    input  wire [1:0]             bresp_reg,
    input  wire                   bvalid_reg,
    input  wire                   bready_reg,
    input  wire [ADDR_WIDTH-1:0]  araddr_reg,
    input  wire [2:0]             arprot_reg,
    input  wire                   arvalid_reg,
    input  wire                   arready_reg,
    input  wire [DATA_WIDTH-1:0]  rdata_reg,
    input  wire [1:0]             rresp_reg,
    input  wire                   rvalid_reg,
    input  wire                   rready_reg
);

    reg [2:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 3'b000;
            awaddr <= 0;
            awprot <= 0;
            awvalid <= 0;
            wdata <= 0;
            wstrb <= 0;
            wvalid <= 0;
            bready <= 0;
            araddr <= 0;
            arprot <= 0;
            arvalid <= 0;
            rready <= 0;
        end else begin
            case (state)
                3'b000: begin
                    if (awvalid_reg && arvalid_reg) begin
                        awaddr <= awaddr_reg;
                        awprot <= awprot_reg;
                        awvalid <= awvalid_reg;
                        araddr <= araddr_reg;
                        arprot <= arprot_reg;
                        arvalid <= arvalid_reg;
                        state <= 3'b001;
                    end else if (awvalid_reg) begin
                        awaddr <= awaddr_reg;
                        awprot <= awprot_reg;
                        awvalid <= awvalid_reg;
                        state <= 3'b010;
                    end else if (arvalid_reg) begin
                        araddr <= araddr_reg;
                        arprot <= arprot_reg;
                        arvalid <= arvalid_reg;
                        state <= 3'b011;
                    end
                end
                3'b001: begin
                    if (awready && arready) begin
                        state <= 3'b000;
                    end
                end
                3'b010: begin
                    if (awready) begin
                        state <= 3'b000;
                    end
                end
                3'b011: begin
                    if (arready) begin
                        state <= 3'b000;
                    end
                end
                default: state <= 3'b000;
            endcase
        end
    end

    assign awaddr = awaddr_reg;
    assign awprot = awprot_reg;
    assign awvalid = awvalid_reg;
    assign wdata = wdata_reg;
    assign wstrb = wstrb_reg;
    assign wvalid = wvalid_reg;
    assign bready = bready_reg;
    assign araddr = araddr_reg;
    assign arprot = arprot_reg;
    assign arvalid = arvalid_reg;
    assign rready = rready_reg;

endmodule
