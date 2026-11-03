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

    // Internal signals
    reg [1:0] state, next_state;
    reg [C_AXI_ADDR_WIDTH-1:0] source_addr, dest_addr;
    reg [LGLEN-1:0] length;
    reg [LGLEN-1:0] read_count, write_count;
    reg [C_AXI_DATA_WIDTH-1:0] read_data, write_data;
    reg read_valid, write_valid, read_ready, write_ready;

    // FIFO signals
    reg [C_AXI_DATA_WIDTH-1:0] fifo [0:LGFIFO-1];
    reg [$clog2(LGFIFO)-1:0] fifo_wptr, fifo_rptr;
    reg fifo_full, fifo_empty;

    // AXI-Lite control interface signals
    reg [C_AXIL_ADDR_WIDTH-1:0] ctrl_awaddr;
    reg [2:0] ctrl_awprot;
    reg ctrl_awvalid, ctrl_awready;
    reg [C_AXIL_DATA_WIDTH-1:0] ctrl_wdata;
    reg [C_AXIL_DATA_WIDTH/8-1:0] ctrl_wstrb;
    reg ctrl_wvalid, ctrl_wready;
    reg ctrl_bvalid, ctrl_bready;
    reg [1:0] ctrl_bresp;
    reg [C_AXIL_ADDR_WIDTH-1:0] ctrl_araddr;
    reg [2:0] ctrl_arprot;
    reg ctrl_arvalid, ctrl_arready;
    reg ctrl_rvalid, ctrl_rready;
    reg [C_AXIL_DATA_WIDTH-1:0] ctrl_rdata;
    reg [1:0] ctrl_rresp;

    // State definitions
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;

    // AXI-Lite control interface
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            ctrl_awready <= 0;
            ctrl_wready <= 0;
            ctrl_bvalid <= 0;
            ctrl_arready <= 0;
            ctrl_rvalid <= 0;
        end else begin
            // Write address channel
            if (S_AXIL_AWVALID && !ctrl_awready) begin
                ctrl_awaddr <= S_AXIL_AWADDR;
                ctrl_awprot <= S_AXIL_AWPROT;
                ctrl_awready <= 1;
            end else if (ctrl_awready && !S_AXIL_AWVALID) begin
                ctrl_awready <= 0;
            end

            // Write data channel
            if (S_AXIL_WVALID && !ctrl_wready) begin
                ctrl_wdata <= S_AXIL_WDATA;
                ctrl_wstrb <= S_AXIL_WSTRB;
                ctrl_wready <= 1;
            end else if (ctrl_wready && !S_AXIL_WVALID) begin
                ctrl_wready <= 0;
            end

            // Write response channel
            if (ctrl_bvalid && S_AXIL_BREADY) begin
                ctrl_bvalid <= 0;
            end else if (ctrl_awready && ctrl_wready && !ctrl_bvalid) begin
                ctrl_bvalid <= 1;
                ctrl_bresp <= 2'b00; // OKAY
            end

            // Read address channel
            if (S_AXIL_ARVALID && !ctrl_arready) begin
                ctrl_araddr <= S_AXIL_ARADDR;
                ctrl_arprot <= S_AXIL_ARPROT;
                ctrl_arready <= 1;
            end else if (ctrl_arready && !S_AXIL_ARVALID) begin
                ctrl_arready <= 0;
            end

            // Read data channel
            if (ctrl_rvalid && S_AXIL_RREADY) begin
                ctrl_rvalid <= 0;
            end else if (ctrl_rready && !ctrl_rvalid) begin
                ctrl_rvalid <= 1;
                ctrl_rdata <= 32'hDEADBEEF; // Dummy data
                ctrl_rresp <= 2'b00; // OKAY
            end
        end
    end

    // AXI read/write channels
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_WLAST <= 0;
            M_AXI_BREADY <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY <= 0;
            state <= IDLE;
            source_addr <= 0;
            dest_addr <= 0;
            length <= 0;
            read_count <= 0;
            write_count <= 0;
            read_valid <= 0;
            write_valid <= 0;
            read_ready <= 0;
            write_ready <= 0;
            fifo_wptr <= 0;
            fifo_rptr <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            o_int <= 0;
        end else begin
            // State machine
            state <= next_state;

            // FIFO control
            if (read_valid && !fifo_full) begin
                fifo[fifo_wptr] <= read_data;
                fifo_wptr <= fifo_wptr + 1;
                if (fifo_wptr == LGFIFO - 1)
                    fifo_full <= 1;
                fifo_empty <= 0;
            end

            if (write_ready && !fifo_empty) begin
                fifo_rptr <= fifo_rptr + 1;
                if (fifo_rptr == LGFIFO - 1)
                    fifo_empty <= 1;
                fifo_full <= 0;
            end

            // AXI read channel
            if (read_valid && M_AXI_RVALID && M_AXI_RREADY) begin
                read_valid <= 0;
                read_count <= read_count + 1;
                if (read_count == length - 1) begin
                    M_AXI_RREADY <= 0;
                    next_state <= WRITE;
                end
            end else if (read_ready && !M_AXI_ARVALID && !read_valid) begin
                M_AXI_ARVALID <= 1;
                M_AXI_ARADDR <= source_addr;
                read_ready <= 0;
                read_valid <= 1;
            end

            // AXI write channel
            if (write_ready && M_AXI_WREADY && M_AXI_BVALID && M_AXI_BREADY) begin
                write_ready <= 0;
                write_count <= write_count + 1;
                if (write_count == length - 1) begin
                    M_AXI_WLAST <= 0;
                    M_AXI_BREADY <= 0;
                    next_state <= IDLE;
                    o_int <= 1;
                end
            end else if (write_valid && !M_AXI_AWVALID && !write_ready) begin
                M_AXI_AWVALID <= 1;
                M_AXI_AWADDR <= dest_addr;
                M_AXI_WVALID <= 1;
                write_ready <= 0;
                write_valid <= 1;
            end

            // State transitions
            case (state)
                IDLE: begin
                    if (ctrl_awready && ctrl_wready && ctrl_bvalid) begin
                        source_addr <= ctrl_wdata[31:0];
                        dest_addr <= ctrl_wdata[63:32];
                        length <= ctrl_wdata[95:64];
                        next_state <= READ;
                        read_ready <= 1;
                        write_count <= 0;
                        read_count <= 0;
                        fifo_wptr <= 0;
                        fifo_rptr <= 0;
                        fifo_full <= 0;
                        fifo_empty <= 1;
                    end else begin
                        next_state <= IDLE;
                    end
                end

                READ: begin
                    if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 0;
                        M_AXI_ARADDR <= source_addr + C_AXI_DATA_WIDTH/8;
                        read_ready <= 1;
                    end

                    if (M_AXI_RVALID && M_AXI_RREADY) begin
                        read_data <= M_AXI_RDATA;
                        read_count <= read_count + 1;
                        if (read_count == length - 1) begin
                            next_state <= WRITE;
                            write_valid <= 1;
                            M_AXI_RREADY <= 0;
                        end else begin
                            read_ready <= 1;
                        end
                    end
                end

                WRITE: begin
                    if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 0;
                        M_AXI_AWADDR <= dest_addr + C_AXI_DATA_WIDTH/8;
                        write_valid <= 1;
                    end

                    if (M_AXI_WVALID && M_AXI_WREADY) begin
                        M_AXI_WDATA <= fifo[fifo_rptr];
                        M_AXI_WLAST <= (write_count == length - 1);
                        M_AXI_BREADY <= 1;
                        write_count <= write_count + 1;
                        if (write_count == length - 1) begin
                            next_state <= IDLE;
                            M_AXI_WLAST <= 0;
                            M_AXI_BREADY <= 0;
                            o_int <= 1;
                        end else begin
                            write_valid <= 1;
                        end
                    end
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

    // AXI-Lite control interface outputs
    assign S_AXIL_AWREADY = ctrl_awready;
    assign S_AXIL_WREADY = ctrl_wready;
    assign S_AXIL_BVALID = ctrl_bvalid;
    assign S_AXIL_BRESP = ctrl_bresp;
    assign S_AXIL_ARREADY = ctrl_arready;
    assign S_AXIL_RVALID = ctrl_rvalid;
    assign S_AXIL_RDATA = ctrl_rdata;
    assign S_AXIL_RRESP = ctrl_rresp;

    // AXI read/write channel outputs
    assign M_AXI_AWID = AXI_WRITE_ID;
    assign M_AXI_AWSIZE = 2'b10; // 4 bytes (32-bit)
    assign M_AXI_AWBURST = 2'b01; // INCR
    assign M_AXI_AWLOCK = 1'b0;
    assign M_AXI_AWCACHE = 4'b0011; // Normal, non-cacheable, buffered
    assign M_AXI_AWPROT = 3'b000; // Normal, non-secure, data
    assign M_AXI_AWQOS = 4'b0000; // Normal QoS

    assign M_AXI_WDATA = fifo[fifo_rptr];
    assign M_AXI_WSTRB = {C_AXI_DATA_WIDTH/8{1'b1}};

    assign M_AXI_ARID = AXI_READ_ID;
    assign M_AXI_ARSIZE = 2'b10; // 4 bytes (32-bit)
    assign M_AXI_ARBURST = 2'b01; // INCR
    assign M_AXI_ARLOCK = 1'b0;
    assign M_AXI_ARCACHE = 4'b0011; // Normal, non-cacheable, buffered
    assign M_AXI_ARPROT = 3'b000; // Normal, non-secure, data
    assign M_AXI_ARQOS = 4'b0000; // Normal QoS

    assign M_AXI_RREADY = read_ready;
    assign M_AXI_ARREADY = read_ready;
    assign M_AXI_WREADY = write_ready;
    assign M_AXI_BREADY = write_ready;

endmodule
