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

    // Internal registers for AXILite registers
    reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
    reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
    reg [LGLEN-1:0] length_reg;
    reg start_transfer;
    reg [1:0] axi_status;

    // Internal state machine states
    typedef enum reg [2:0] {
        IDLE,
        READ_ADDR,
        READ_DATA,
        WRITE_ADDR,
        WRITE_DATA,
        DONE
    } state_t;

    state_t state, next_state;

    // AXILite register map
    localparam REG_SRC_ADDR = 5'h00;
    localparam REG_DST_ADDR = 5'h01;
    localparam REG_LENGTH = 5'h02;
    localparam REG_CONTROL = 5'h03;
    localparam REG_STATUS = 5'h04;

    // AXILite FSM
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_AWREADY <= 0;
            S_AXIL_WREADY <= 0;
            S_AXIL_BVALID <= 0;
            S_AXIL_ARREADY <= 0;
            S_AXIL_RVALID <= 0;
            S_AXIL_RDATA <= 0;
            S_AXIL_BRESP <= 0;
            S_AXIL_RRESP <= 0;
        end else begin
            S_AXIL_AWREADY <= S_AXIL_AWVALID;
            S_AXIL_WREADY <= S_AXIL_WVALID & S_AXIL_AWVALID;
            S_AXIL_BVALID <= S_AXIL_BREADY ? 0 : (S_AXIL_WVALID & S_AXIL_AWVALID);
            S_AXIL_ARREADY <= S_AXIL_ARVALID;
            S_AXIL_RVALID <= S_AXIL_RREADY ? 0 : S_AXIL_ARVALID;

            if (S_AXIL_BVALID && S_AXIL_BREADY) begin
                S_AXIL_BRESP <= 2'b00; // OKAY response
            end

            if (S_AXIL_RVALID && S_AXIL_RREADY) begin
                S_AXIL_RRESP <= 2'b00; // OKAY response
            end

            if (S_AXIL_AWVALID && S_AXIL_WVALID && S_AXIL_BREADY) begin
                case (S_AXIL_AWADDR)
                    REG_SRC_ADDR: src_addr_reg <= S_AXIL_WDATA;
                    REG_DST_ADDR: dst_addr_reg <= S_AXIL_WDATA;
                    REG_LENGTH: length_reg <= S_AXIL_WDATA[LGLEN-1:0];
                    REG_CONTROL: start_transfer <= S_AXIL_WDATA[0];
                endcase
            end

            if (S_AXIL_ARVALID && S_AXIL_RREADY) begin
                case (S_AXIL_ARADDR)
                    REG_SRC_ADDR: S_AXIL_RDATA <= src_addr_reg;
                    REG_DST_ADDR: S_AXIL_RDATA <= dst_addr_reg;
                    REG_LENGTH: S_AXIL_RDATA <= length_reg;
                    REG_CONTROL: S_AXIL_RDATA <= start_transfer;
                    REG_STATUS: S_AXIL_RDATA <= axi_status;
                    default: S_AXIL_RDATA <= 0;
                endcase
            end
        end
    end

    // AXI DMA FSM
    reg [C_AXI_ADDR_WIDTH-1:0] current_addr;
    reg [LGLEN-1:0] remaining_length;
    reg [C_AXI_DATA_WIDTH-1:0] read_data;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_BREADY <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY <= 0;
            M_AXI_AWID <= AXI_WRITE_ID;
            M_AXI_AWADDR <= 0;
            M_AXI_AWSIZE <= $clog2(C_AXI_DATA_WIDTH/8);
            M_AXI_AWBURST <= 2'b01; // INCR
            M_AXI_AWLOCK <= 0;
            M_AXI_AWCACHE <= 4'b0011; // Non-cacheable, no buffer
            M_AXI_AWPROT <= 3'b000; // Normal, non-secure, data
            M_AXI_AWQOS <= 0;
            M_AXI_WDATA <= 0;
            M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b1}};
            M_AXI_WLAST <= 0;
            M_AXI_ARID <= AXI_READ_ID;
            M_AXI_ARADDR <= 0;
            M_AXI_ARSIZE <= $clog2(C_AXI_DATA_WIDTH/8);
            M_AXI_ARBURST <= 2'b01; // INCR
            M_AXI_ARLOCK <= 0;
            M_AXI_ARCACHE <= 4'b0011; // Non-cacheable, no buffer
            M_AXI_ARPROT <= 3'b000; // Normal, non-secure, data
            M_AXI_ARQOS <= 0;
            current_addr <= 0;
            remaining_length <= 0;
            read_data <= 0;
            axi_status <= 2'b00;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    if (start_transfer) begin
                        current_addr <= src_addr_reg;
                        remaining_length <= length_reg;
                        start_transfer <= 0;
                        next_state <= READ_ADDR;
                    end
                end

                READ_ADDR: begin
                    M_AXI_ARVALID <= 1;
                    M_AXI_ARADDR <= current_addr;
                    if (M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 0;
                        next_state <= READ_DATA;
                    end
                end

                READ_DATA: begin
                    M_AXI_RREADY <= 1;
                    if (M_AXI_RVALID) begin
                        M_AXI_RREADY <= 0;
                        read_data <= M_AXI_RDATA;
                        next_state <= WRITE_ADDR;
                    end
                end

                WRITE_ADDR: begin
                    M_AXI_AWVALID <= 1;
                    M_AXI_AWADDR <= dst_addr_reg;
                    if (M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 0;
                        next_state <= WRITE_DATA;
                    end
                end

                WRITE_DATA: begin
                    M_AXI_WVALID <= 1;
                    M_AXI_WDATA <= read_data;
                    M_AXI_WLAST <= remaining_length == 1;
                    if (M_AXI_WREADY) begin
                        M_AXI_WVALID <= 0;
                        if (M_AXI_WLAST) begin
                            next_state <= DONE;
                        end else begin
                            current_addr <= current_addr + C_AXI_DATA_WIDTH/8;
                            dst_addr_reg <= dst_addr_reg + C_AXI_DATA_WIDTH/8;
                            remaining_length <= remaining_length - 1;
                            next_state <= READ_ADDR;
                        end
                    end
                end

                DONE: begin
                    M_AXI_BREADY <= 1;
                    if (M_AXI_BVALID) begin
                        M_AXI_BREADY <= 0;
                        axi_status <= 2'b01; // Transfer done
                        next_state <= IDLE;
                    end
                end

                default: next_state <= IDLE;
            endcase
        end
    end

    assign o_int = state == DONE;

endmodule
