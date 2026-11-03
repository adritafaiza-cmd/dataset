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

    // Internal registers for control and status
    reg [C_AXI_ADDR_WIDTH-1:0] src_addr, dst_addr;
    reg [LGLENW-1:0] length;
    reg [1:0] state;
    reg [1:0] next_state;
    reg [1:0] read_state;
    reg [1:0] write_state;
    reg [1:0] read_next_state;
    reg [1:0] write_next_state;
    reg [C_AXI_DATA_WIDTH-1:0] read_data;
    reg [C_AXI_DATA_WIDTH/8-1:0] read_strb;
    reg [C_AXI_DATA_WIDTH-1:0] write_data;
    reg [C_AXI_DATA_WIDTH/8-1:0] write_strb;
    reg write_last;
    reg read_last;
    reg [C_AXIL_DATA_WIDTH-1:0] read_reg;
    reg [1:0] read_resp;
    reg [1:0] write_resp;
    reg [C_AXIL_DATA_WIDTH-1:0] write_reg;
    reg [1:0] bresp_reg;

    // Control state machine states
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;

    // AXI Lite Control
    reg [C_AXIL_ADDR_WIDTH-1:0] axil_awaddr_reg;
    reg [C_AXIL_DATA_WIDTH-1:0] axil_wdata_reg;
    reg axil_awvalid_reg;
    reg axil_wvalid_reg;
    reg axil_arvalid_reg;
    reg [C_AXIL_ADDR_WIDTH-1:0] axil_araddr_reg;

    // AXI Lite Write Address Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_AWREADY <= 1'b0;
            axil_awvalid_reg <= 1'b0;
            axil_awaddr_reg <= {C_AXIL_ADDR_WIDTH{1'b0}};
        end else begin
            S_AXIL_AWREADY <= ~axil_awvalid_reg & S_AXIL_AWVALID;
            if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
                axil_awvalid_reg <= 1'b1;
                axil_awaddr_reg <= S_AXIL_AWADDR;
            end else if (S_AXIL_WVALID && S_AXIL_WREADY) begin
                axil_awvalid_reg <= 1'b0;
            end
        end
    end

    // AXI Lite Write Data Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_WREADY <= 1'b0;
            axil_wvalid_reg <= 1'b0;
            axil_wdata_reg <= {C_AXIL_DATA_WIDTH{1'b0}};
        end else begin
            S_AXIL_WREADY <= ~axil_wvalid_reg & S_AXIL_WVALID;
            if (S_AXIL_WVALID && S_AXIL_WREADY) begin
                axil_wvalid_reg <= 1'b1;
                axil_wdata_reg <= S_AXIL_WDATA;
            end else if (S_AXIL_BVALID && S_AXIL_BREADY) begin
                axil_wvalid_reg <= 1'b0;
            end
        end
    end

    // AXI Lite Write Response Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_BVALID <= 1'b0;
            S_AXIL_BRESP <= 2'b00;
        end else if (axil_wvalid_reg && axil_awvalid_reg && M_AXI_BVALID && M_AXI_BREADY) begin
            S_AXIL_BVALID <= 1'b1;
            S_AXIL_BRESP <= write_resp;
        end else if (S_AXIL_BVALID && S_AXIL_BREADY) begin
            S_AXIL_BVALID <= 1'b0;
        end
    end

    // AXI Lite Read Address Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_ARREADY <= 1'b0;
            axil_arvalid_reg <= 1'b0;
            axil_araddr_reg <= {C_AXIL_ADDR_WIDTH{1'b0}};
        end else begin
            S_AXIL_ARREADY <= ~axil_arvalid_reg & S_AXIL_ARVALID;
            if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
                axil_arvalid_reg <= 1'b1;
                axil_araddr_reg <= S_AXIL_ARADDR;
            end else if (S_AXIL_RVALID && S_AXIL_RREADY) begin
                axil_arvalid_reg <= 1'b0;
            end
        end
    end

    // AXI Lite Read Data Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_RVALID <= 1'b0;
            S_AXIL_RDATA <= {C_AXIL_DATA_WIDTH{1'b0}};
            S_AXIL_RRESP <= 2'b00;
        end else if (axil_arvalid_reg && M_AXI_RVALID && M_AXI_RREADY) begin
            S_AXIL_RVALID <= 1'b1;
            S_AXIL_RDATA <= read_reg;
            S_AXIL_RRESP <= read_resp;
        end else if (S_AXIL_RVALID && S_AXIL_RREADY) begin
            S_AXIL_RVALID <= 1'b0;
        end
    end

    // AXI Write Address Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_AWVALID <= 1'b0;
            M_AXI_AWID <= {C_AXI_ID_WIDTH{1'b0}};
            M_AXI_AWADDR <= {C_AXI_ADDR_WIDTH{1'b0}};
            M_AXI_AWSIZE <= 3'b010;
            M_AXI_AWBURST <= 2'b01;
            M_AXI_AWLOCK <= 1'b0;
            M_AXI_AWCACHE <= 4'b0011;
            M_AXI_AWPROT <= 3'b000;
            M_AXI_AWQOS <= 4'b0000;
        end else begin
            M_AXI_AWVALID <= (state == WRITE) && ~M_AXI_AWREADY;
            M_AXI_AWID <= AXI_WRITE_ID;
            M_AXI_AWADDR <= dst_addr;
            M_AXI_AWSIZE <= 3'b010;
            M_AXI_AWBURST <= 2'b01;
            M_AXI_AWLOCK <= 1'b0;
            M_AXI_AWCACHE <= 4'b0011;
            M_AXI_AWPROT <= 3'b000;
            M_AXI_AWQOS <= 4'b0000;
        end
    end

    // AXI Write Data Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_WVALID <= 1'b0;
            M_AXI_WDATA <= {C_AXI_DATA_WIDTH{1'b0}};
            M_AXI_WSTRB <= {C_AXI_DATA_WIDTH/8{1'b0}};
            M_AXI_WLAST <= 1'b0;
        end else begin
            M_AXI_WVALID <= (state == WRITE) && ~M_AXI_WREADY;
            M_AXI_WDATA <= write_data;
            M_AXI_WSTRB <= write_strb;
            M_AXI_WLAST <= write_last;
        end
    end

    // AXI Write Response Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_BREADY <= 1'b0;
            write_resp <= 2'b00;
        end else if (M_AXI_BVALID && M_AXI_BREADY) begin
            write_resp <= M_AXI_BRESP;
        end else begin
            M_AXI_BREADY <= (state == WRITE) && M_AXI_BVALID;
        end
    end

    // AXI Read Address Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_ARVALID <= 1'b0;
            M_AXI_ARID <= {C_AXI_ID_WIDTH{1'b0}};
            M_AXI_ARADDR <= {C_AXI_ADDR_WIDTH{1'b0}};
            M_AXI_ARSIZE <= 3'b010;
            M_AXI_ARBURST <= 2'b01;
            M_AXI_ARLOCK <= 1'b0;
            M_AXI_ARCACHE <= 4'b0011;
            M_AXI_ARPROT <= 3'b000;
            M_AXI_ARQOS <= 4'b0000;
        end else begin
            M_AXI_ARVALID <= (state == READ) && ~M_AXI_ARREADY;
            M_AXI_ARID <= AXI_READ_ID;
            M_AXI_ARADDR <= src_addr;
            M_AXI_ARSIZE <= 3'b010;
            M_AXI_ARBURST <= 2'b01;
            M_AXI_ARLOCK <= 1'b0;
            M_AXI_ARCACHE <= 4'b0011;
            M_AXI_ARPROT <= 3'b000;
            M_AXI_ARQOS <= 4'b0000;
        end
    end

    // AXI Read Data Channel
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_RREADY <= 1'b0;
            read_reg <= {C_AXIL_DATA_WIDTH{1'b0}};
            read_resp <= 2'b00;
            read_last <= 1'b0;
        end else if (M_AXI_RVALID && M_AXI_RREADY) begin
            read_reg <= M_AXI_RDATA;
            read_resp <= M_AXI_RRESP;
            read_last <= M_AXI_RLAST;
        end else begin
            M_AXI_RREADY <= (state == READ) && M_AXI_RVALID;
        end
    end

    // State Machine for Read
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            read_state <= IDLE;
        end else begin
            read_state <= read_next_state;
        end
    end

    always @(*) begin
        read_next_state = read_state;
        case (read_state)
            IDLE: begin
                if (axil_arvalid_reg && M_AXI_ARREADY) begin
                    read_next_state = READ;
                end
            end
            READ: begin
                if (M_AXI_RVALID && M_AXI_RREADY && read_last) begin
                    read_next_state = IDLE;
                end
            end
            default: begin
                read_next_state = IDLE;
            end
        endcase
    end

    // State Machine for Write
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            write_state <= IDLE;
        end else begin
            write_state <= write_next_state;
        end
    end

    always @(*) begin
        write_next_state = write_state;
        case (write_state)
            IDLE: begin
                if (axil_awvalid_reg && axil_wvalid_reg && M_AXI_AWREADY) begin
                    write_next_state = WRITE;
                end
            end
            WRITE: begin
                if (M_AXI_BVALID && M_AXI_BREADY) begin
                    write_next_state = IDLE;
                end
            end
            default: begin
                write_next_state = IDLE;
            end
        endcase
    end

    // State Machine for overall control
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            state <= IDLE;
            src_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
            dst_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
            length <= {LGLENW{1'b0}};
        end else begin
            state <= next_state;
            case (next_state)
                READ: begin
                    if (read_last) begin
                        state <= IDLE;
                    end
                end
                WRITE: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        state <= IDLE;
                    end
                end
            endcase
            if (axil_awvalid_reg && axil_wvalid_reg && (axil_awaddr_reg[4:2] == 3'b000)) begin
                src_addr <= axil_wdata_reg;
            end else if (axil_awvalid_reg && axil_wvalid_reg && (axil_awaddr_reg[4:2] == 3'b001)) begin
                dst_addr <= axil_wdata_reg;
            end else if (axil_awvalid_reg && axil_wvalid_reg && (axil_awaddr_reg[4:2] == 3'b010)) begin
                length <= axil_wdata_reg[LGLENW-1:0];
            end
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (axil_awvalid_reg && axil_wvalid_reg && (axil_awaddr_reg[4:2] == 3'b011)) begin
                    next_state = READ;
                end else if (axil_awvalid_reg && axil_wvalid_reg && (axil_awaddr_reg[4:2] == 3'b100)) begin
                    next_state = WRITE;
                end
            end
            READ: begin
                if (read_last) begin
                    next_state = IDLE;
                end
            end
            WRITE: begin
                if (M_AXI_BVALID && M_AXI_BREADY) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Data Path for Read
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            read_data <= {C_AXI_DATA_WIDTH{1'b0}};
            read_strb <= {C_AXI_DATA_WIDTH/8{1'b0}};
        end else begin
            if (M_AXI_RVALID && M_AXI_RREADY) begin
                read_data <= M_AXI_RDATA;
                read_strb <= {C_AXI_DATA_WIDTH/8{1'b1}};
            end
        end
    end

    // Data Path for Write
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            write_data <= {C_AXI_DATA_WIDTH{1'b0}};
            write_strb <= {C_AXI_DATA_WIDTH/8{1'b0}};
            write_last <= 1'b0;
        end else begin
            if (M_AXI_WVALID && M_AXI_WREADY) begin
                write_data <= read_data;
                write_strb <= read_strb;
                write_last <= M_AXI_RLAST;
            end
        end
    end

    // Interrupt
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            o_int <= 1'b0;
        end else if (state == IDLE && (read_last || (M_AXI_BVALID && M_AXI_BREADY))) begin
            o_int <= 1'b1;
        end else if (S_AXIL_BVALID && S_AXIL_BREADY) begin
            o_int <= 1'b0;
        end
    end

endmodule
