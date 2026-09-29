module axidma #(
    parameter C_AXI_ID_WIDTH = 1,
    parameter C_AXI_ADDR_WIDTH = 32,
    parameter C_AXI_DATA_WIDTH = 32,
    localparam C_AXIL_ADDR_WIDTH =5,
    localparam C_AXIL_DATA_WIDTH =32,
    parameter [0:0] OPT_UNALIGNED =1'b1,
    parameter [0:0] OPT_WRAPMEM =1'b1,
    parameter LGFIFO = LGMAXBURST+1,
    parameter LGLEN = C_AXI_ADDR_WIDTH,
    parameter [0:0] OPT_LOWPOWER =1'b0,
    parameter [0:0] OPT_CLKGATE = OPT_LOWPOWER,
    parameter [C_AXI_ID_WIDTH-1:0] AXI_READ_ID =0,
    parameter [C_AXI_ID_WIDTH-1:0] AXI_WRITE_ID =0,
    parameter [7:0] ABORT_KEY =8'h6d,
    localparam ADDRLSB = $clog2(C_AXI_DATA_WIDTH)-3,
    localparam AXILLSB = $clog2(C_AXIL_DATA_WIDTH)-3,
    localparam LGLENW = LGLEN-ADDRLSB
) (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    // AXI-Lite Control Interface
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
    // AXI4 Write Interface
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
    // AXI4 Read Interface
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
    reg [C_AXI_ADDR_WIDTH-1:0] source_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] dest_addr;
    reg [31:0] length;
    reg control_reg; // bit 0: start, bit 1: done

    // State machine
    localparam IDLE =0;
    localparam READING =1;
    localparam WRITING =2;
    localparam DONE_STATE =3;

    reg [1:0] state;

    // Counters and addresses
    reg [C_AXI_ADDR_WIDTH-1:0] read_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] write_addr;
    reg [31:0] count;

    // AXI signals
    reg [C_AXI_ADDR_WIDTH-1:0] read_data;

    // AXI-Lite interface handling
    assign S_AXIL_AWREADY =1'b1;
    assign S_AXIL_WREADY =1'b1;
    assign S_AXIL_BRESP =2'b00;
    assign S_AXIL_RRESP =2'b00;
    assign M_AXI_ARID = AXI_READ_ID;
    assign M_AXI_ARSIZE = (C_AXI_DATA_WIDTH ==32) ? 3 : $clog2(C_AXI_DATA_WIDTH/8);
    assign M_AXI_ARBURST =2'b01;
    assign M_AXI_ARLOCK =1'b0;
    assign M_AXI_ARCACHE =4'b0010;
    assign M_AXI_ARPROT =3'b000;
    assign M_AXI_ARQOS =4'b0000;
    assign M_AXI_RREADY =1'b1;

    // Busy and done flags
    reg busy;
    reg done;

    // AXI-Lite write handling
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            source_addr <=0;
            dest_addr <=0;
            length <=0;
            control_reg <=0;
            busy <=0;
            done <=0;
            state <= IDLE;
            count <=0;
            read_addr <=0;
            write_addr <=0;
            M_AXI_ARVALID <=0;
            M_AXI_AWVALID <=0;
            M_AXI_WVALID <=0;
            M_AXI_BREADY <=0;
            M_AXI_WLAST <=0;
            S_AXIL_BVALID <=0;
            S_AXIL_RVALID <=0;
            S_AXIL_RDATA <=0;
        end else begin
            // Handle AXI-Lite writes
            if (S_AXIL_AWVALID && S_AXIL_WVALID && S_AXIL_AWREADY && S_AXIL_WREADY) begin
                case (S_AXIL_AWADDR)
                    5'h00: control_reg <= S_AXIL_WDATA[0];
                    5'h04: source_addr <= S_AXIL_WDATA;
                    5'h08: dest_addr <= S_AXIL_WDATA;
                    5'h0C: length <= S_AXIL_WDATA;
                endcase
                S_AXIL_BVALID <=1;
            end else begin
                S_AXIL_BVALID <=0;
            end

            // Handle AXI-Lite reads
            if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
                case (S_AXIL_ARADDR)
                    5'h00: S_AXIL_RDATA <= {31'b0, busy};
                    5'h04: S_AXIL_RDATA <= source_addr;
                    5'h08: S_AXIL_RDATA <= dest_addr;
                    5'h0C: S_AXIL_RDATA <= length;
                    5'h10: S_AXIL_RDATA <= {30'b0, busy, done};
                    default: S_AXIL_RDATA <=0;
                endcase
                S_AXIL_RVALID <=1;
            end else begin
                S_AXIL_RVALID <=0;
            end

            // State machine
            case (state)
                IDLE: begin
                    if (control_reg[0]) begin
                        busy <=1;
                        done <=0;
                        count <=0;
                        read_addr <= source_addr;
                        write_addr <= dest_addr;
                        state <= READING;
                    end
                end
                READING: begin
                    if (!M_AXI_ARVALID) begin
                        M_AXI_ARVALID <=1;
                        M_AXI_ARADDR <= read_addr;
                    end else if (M_AXI_ARREADY) begin
                        M_AXI_ARVALID <=0;
                        if (M_AXI_RVALID) begin
                            read_data <= M_AXI_RDATA;
                            state <= WRITING;
                        end
                    end
                end
                WRITING: begin
                    if (!M_AXI_AWVALID) begin
                        M_AXI_AWVALID <=1;
                        M_AXI_AWADDR <= write_addr;
                        M_AXI_AWID <= AXI_WRITE_ID;
                        M_AXI_AWSIZE <= (C_AXI_DATA_WIDTH/8)-1;
                        M_AXI_AWBURST <=2'b01;
                        M_AXI_AWLOCK <=0;
                        M_AXI_AWCACHE <=4'b0010;
                        M_AXI_AWPROT <=3'b000;
                        M_AXI_AWQOS <=4'b0000;
                    end else if (M_AXI_AWREADY) begin
                        M_AXI_AWVALID <=0;
                        if (!M_AXI_WVALID) begin
                            M_AXI_WVALID <=1;
                            M_AXI_WDATA <= read_data;
                            M_AXI_WSTRB <= {C_AXIL_DATA_WIDTH/8{1'b1}};
                            M_AXI_WLAST <=1;
                        end else if (M_AXI_WREADY) begin
                            M_AXI_WVALID <=0;
                            M_AXI_WLAST <=0;
                            if (!M_AXI_BVALID) begin
                                M_AXI_BREADY <=1;
                            end else if (M_AXI_BVALID && M_AXI_BREADY) begin
                                M_AXI_BREADY <=0;
                                read_addr <= read_addr + (C_AXI_DATA_WIDTH/8);
                                write_addr <= write_addr + (C_AXI_DATA_WIDTH/8);
                                count <= count +1;
                                if (count == length) begin
                                    state <= DONE_STATE;
                                    busy <=0;
                                    done <=1;
                                end else begin
                                    state <= READING;
                                end
                            end
                        end
                    end
                end
                DONE_STATE: begin
                    if (!control_reg[0]) begin
                        state <= IDLE;
                        busy <=0;
                        done <=0;
                    end
                end
            endcase
        end
    end

    assign o_int = busy;

endmodule
