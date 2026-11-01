module axidma #(
	parameter	C_AXI_ID_WIDTH = 1,
	parameter	C_AXI_ADDR_WIDTH = 32,
	parameter	C_AXI_DATA_WIDTH = 32,
	localparam	C_AXIL_ADDR_WIDTH = 5,
	localparam	C_AXIL_DATA_WIDTH = 32,
	parameter [0:0]	OPT_UNALIGNED = 1'b1,
	parameter [0:0]	OPT_WRAPMEM = 1'b1,
	parameter	LGFIFO = 4,
	parameter	LGLEN = C_AXI_ADDR_WIDTH,
	parameter [0:0]	OPT_LOWPOWER = 1'b0,
	parameter [0:0]	OPT_CLKGATE = OPT_LOWPOWER,
	parameter	[C_AXI_ID_WIDTH-1:0]	AXI_READ_ID = 0,
	parameter	[C_AXI_ID_WIDTH-1:0]	AXI_WRITE_ID = 0,
	parameter	[7:0]			ABORT_KEY  = 8'h6d,
	localparam	ADDRLSB= $clog2(C_AXI_DATA_WIDTH)-3,
	localparam	AXILLSB= $clog2(C_AXIL_DATA_WIDTH)-3,
	localparam	LGLENW= LGLEN-ADDRLSB
) (
	input	wire	S_AXI_ACLK,
	input	wire	S_AXI_ARESETN,
	input	wire				S_AXIL_AWVALID,
	output	wire				S_AXIL_AWREADY,
	input	wire [C_AXIL_ADDR_WIDTH-1:0]	S_AXIL_AWADDR,
	input	wire 	[2:0]			S_AXIL_AWPROT,
	input	wire				S_AXIL_WVALID,
	output	wire				S_AXIL_WREADY,
	input	wire [C_AXIL_DATA_WIDTH-1:0]	S_AXIL_WDATA,
	input	wire [C_AXIL_DATA_WIDTH/8-1:0]	S_AXIL_WSTRB,
	output	reg				S_AXIL_BVALID,
	input	wire				S_AXIL_BREADY,
	output	wire	[1:0]			S_AXIL_BRESP,
	input	wire				S_AXIL_ARVALID,
	output	wire				S_AXIL_ARREADY,
	input	wire [C_AXIL_ADDR_WIDTH-1:0]	S_AXIL_ARADDR,
	input	wire 	[2:0]			S_AXIL_ARPROT,
	output	reg				S_AXIL_RVALID,
	input	wire				S_AXIL_RREADY,
	output	reg [C_AXIL_DATA_WIDTH-1:0]	S_AXIL_RDATA,
	output	wire	[1:0]			S_AXIL_RRESP,
	output	reg				M_AXI_AWVALID,
	input	wire				M_AXI_AWREADY,
	output	reg	[C_AXI_ID_WIDTH-1:0]	M_AXI_AWID,
	output	reg	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_AWADDR,
	output	reg	[2:0]			M_AXI_AWSIZE,
	output	reg	[1:0]			M_AXI_AWBURST,
	output	reg				M_AXI_AWLOCK,
	output	reg	[3:0]			M_AXI_AWCACHE,
	output	reg	[2:0]			M_AXI_AWPROT,
	output	reg	[3:0]			M_AXI_AWQOS,
	output	reg				M_AXI_WVALID,
	input	wire				M_AXI_WREADY,
	output	reg	[C_AXI_DATA_WIDTH-1:0]	M_AXI_WDATA,
	output	reg [C_AXI_DATA_WIDTH/8-1:0]	M_AXI_WSTRB,
	output	reg				M_AXI_WLAST,
	input	wire				M_AXI_BVALID,
	output	reg				M_AXI_BREADY,
	input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_BID,
	input	wire	[1:0]			M_AXI_BRESP,
	output	reg				M_AXI_ARVALID,
	input	wire				M_AXI_ARREADY,
	output	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_ARID,
	output	reg	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_ARADDR,
	output	wire	[2:0]			M_AXI_ARSIZE,
	output	wire	[1:0]			M_AXI_ARBURST,
	output	wire				M_AXI_ARLOCK,
	output	wire	[3:0]			M_AXI_ARCACHE,
	output	wire	[2:0]			M_AXI_ARPROT,
	output	wire	[3:0]			M_AXI_ARQOS,
	input	wire				M_AXI_RVALID,
	output	wire				M_AXI_RREADY,
	input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_RID,
	input	wire	[C_AXI_DATA_WIDTH-1:0]	M_AXI_RDATA,
	input	wire				M_AXI_RLAST,
	input	wire	[1:0]			M_AXI_RRESP,
	output	reg				o_int
);

    // Register addresses
    localparam REG_SRC_ADDR = 0;
    localparam REG_DST_ADDR = 1;
    localparam REG_LENGTH   = 2;
    localparam REG_CONTROL  = 3;
    localparam REG_STATUS   = 4;

    // Control register bits
    localparam CTRL_START = 0;
    localparam CTRL_ABORT = 1;

    // Status register bits
    localparam STAT_BUSY  = 0;
    localparam STAT_DONE  = 1;
    localparam STAT_ERROR = 2;

    // State machine states
    localparam ST_IDLE    = 3'd0;
    localparam ST_READ    = 3'd1;
    localparam ST_WRITE   = 3'd2;
    localparam ST_DONE    = 3'd3;
    localparam ST_ERROR   = 3'd4;

    // Internal signals
    reg [C_AXI_ADDR_WIDTH-1:0] src_addr_reg;
    reg [C_AXI_ADDR_WIDTH-1:0] dst_addr_reg;
    reg [31:0] length_reg;
    reg [31:0] remaining_len;
    reg [31:0] current_len;
    reg [31:0] read_count;
    reg [31:0] write_count;
    reg [2:0] state;
    reg [C_AXI_DATA_WIDTH-1:0] data_fifo [0:(1<<LGFIFO)-1];
    reg [LGFIFO-1:0] fifo_wr_ptr;
    reg [LGFIFO-1:0] fifo_rd_ptr;
    reg fifo_full;
    reg fifo_empty;
    reg [C_AXI_DATA_WIDTH-1:0] read_data_reg;
    reg read_valid;
    reg write_valid;
    reg [C_AXI_DATA_WIDTH-1:0] write_data_reg;
    reg [C_AXI_DATA_WIDTH/8-1:0] write_strb_reg;
    reg [C_AXI_ADDR_WIDTH-1:0] current_src_addr;
    reg [C_AXI_ADDR_WIDTH-1:0] current_dst_addr;
    reg [31:0] burst_len;
    reg [2:0] burst_size;
    reg [1:0] burst_type;
    reg [C_AXI_ID_WIDTH-1:0] read_id;
    reg [C_AXI_ID_WIDTH-1:0] write_id;
    reg [1:0] axi_bresp_reg;
    reg [1:0] axi_rresp_reg;
    reg bvalid_pending;
    reg rvalid_pending;
    reg [C_AXIL_DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg [1:0] bresp_reg;
    reg awvalid_reg;
    reg wvalid_reg;
    reg arvalid_reg;
    reg bready_reg;
    reg rready_reg;
    reg [C_AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [C_AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] awsize_reg;
    reg [2:0] arsize_reg;
    reg [1:0] awburst_reg;
    reg [1:0] arburst_reg;
    reg [C_AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [C_AXI_DATA_WIDTH/8-1:0] wstrb_reg;
    reg wlast_reg;
    reg [C_AXI_ID_WIDTH-1:0] awid_reg;
    reg [C_AXI_ID_WIDTH-1:0] arid_reg;
    reg [2:0] awprot_reg;
    reg [2:0] arprot_reg;
    reg [3:0] awcache_reg;
    reg [3:0] arcache_reg;
    reg [3:0] awqos_reg;
    reg [3:0] arqos_reg;
    reg awlock_reg;
    reg arlock_reg;

    // AXI4-Lite write address channel
    assign S_AXIL_AWREADY = (state == ST_IDLE) && !awvalid_reg;
    assign S_AXIL_WREADY  = (state == ST_IDLE) && !wvalid_reg;
    assign S_AXIL_ARREADY = (state == ST_IDLE) && !arvalid_reg;
    assign S_AXIL_BRESP   = bresp_reg;
    assign S_AXIL_RRESP   = rresp_reg;

    // AXI4 master address channels
    assign M_AXI_AWVALID = awvalid_reg;
    assign M_AXI_AWID    = awid_reg;
    assign M_AXI_AWADDR  = awaddr_reg;
    assign M_AXI_AWSIZE  = awsize_reg;
    assign M_AXI_AWBURST = awburst_reg;
    assign M_AXI_AWLOCK  = awlock_reg;
    assign M_AXI_AWCACHE = awcache_reg;
    assign M_AXI_AWPROT  = awprot_reg;
    assign M_AXI_AWQOS   = awqos_reg;

    assign M_AXI_WVALID  = wvalid_reg;
    assign M_AXI_WDATA   = wdata_reg;
    assign M_AXI_WSTRB   = wstrb_reg;
    assign M_AXI_WLAST   = wlast_reg;
    assign M_AXI_BREADY  = bready_reg;

    assign M_AXI_ARVALID = arvalid_reg;
    assign M_AXI_ARID    = arid_reg;
    assign M_AXI_ARADDR  = araddr_reg;
    assign M_AXI_ARSIZE  = arsize_reg;
    assign M_AXI_ARBURST = arburst_reg;
    assign M_AXI_ARLOCK  = arlock_reg;
    assign M_AXI_ARCACHE = arcache_reg;
    assign M_AXI_ARPROT  = arprot_reg;
    assign M_AXI_ARQOS   = arqos_reg;
    assign M_AXI_RREADY  = rready_reg;

    // Interrupt output
    assign o_int = (state == ST_DONE) || (state == ST_ERROR);

    // FIFO full/empty logic
    wire [LGFIFO:0] fifo_count = {1'b0, fifo_wr_ptr} - {1'b0, fifo_rd_ptr};
    assign fifo_full  = (fifo_count == (1<<LGFIFO));
    assign fifo_empty = (fifo_count == 0);

    // AXI4-Lite write address register
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            awvalid_reg <= 1'b0;
            awaddr_reg  <= {C_AXI_ADDR_WIDTH{1'b0}};
            awsize_reg  <= 3'b000;
            awburst_reg <= 2'b00;
            awlock_reg  <= 1'b0;
            awcache_reg <= 4'b0000;
            awprot_reg  <= 3'b000;
            awqos_reg   <= 4'b0000;
            awid_reg    <= {C_AXI_ID_WIDTH{1'b0}};
        end else begin
            if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
                awvalid_reg <= 1'b1;
                awaddr_reg  <= {C_AXI_ADDR_WIDTH{1'b0}};
                awsize_reg  <= 3'b000;
                awburst_reg <= 2'b00;
                awlock_reg  <= 1'b0;
                awcache_reg <= 4'b0000;
                awprot_reg  <= S_AXIL_AWPROT;
                awqos_reg   <= 4'b0000;
                awid_reg    <= {C_AXI_ID_WIDTH{1'b0}};
            end
            if (awvalid_reg && M_AXI_AWREADY) begin
                awvalid_reg <= 1'b0;
            end
        end
    end

    // AXI4-Lite write data register
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            wvalid_reg <= 1'b0;
            wdata_reg  <= {C_AXI_DATA_WIDTH{1'b0}};
            wstrb_reg  <= {C_AXI_DATA_WIDTH/8{1'b0}};
            wlast_reg  <= 1'b0;
        end else begin
            if (S_AXIL_WVALID && S_AXIL_WREADY) begin
                wvalid_reg <= 1'b1;
                wdata_reg  <= {C_AXI_DATA_WIDTH{1'b0}};
                wstrb_reg  <= {C_AXI_DATA_WIDTH/8{1'b0}};
                wlast_reg  <= 1'b1;
            end
            if (wvalid_reg && M_AXI_WREADY) begin
                wvalid_reg <= 1'b0;
            end
        end
    end

    // AXI4-Lite read address register
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            arvalid_reg <= 1'b0;
            araddr_reg  <= {C_AXI_ADDR_WIDTH{1'b0}};
            arsize_reg  <= 3'b000;
            arburst_reg <= 2'b00;
            arlock_reg  <= 1'b0;
            arcache_reg <= 4'b0000;
            arprot_reg  <= 3'b000;
            arqos_reg   <= 4'b0000;
            arid_reg    <= {C_AXI_ID_WIDTH{1'b0}};
        end else begin
            if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
                arvalid_reg <= 1'b1;
                araddr_reg  <= {C_AXI_ADDR_WIDTH{1'b0}};
                arsize_reg  <= 3'b000;
                arburst_reg <= 2'b00;
                arlock_reg  <= 1'b0;
                arcache_reg <= 4'b0000;
                arprot_reg  <= S_AXIL_ARPROT;
                arqos_reg   <= 4'b0000;
                arid_reg    <= {C_AXI_ID_WIDTH{1'b0}};
            end
            if (arvalid_reg && M_AXI_ARREADY) begin
                arvalid_reg <= 1'b0;
            end
        end
    end

    // AXI4-Lite write response
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_BVALID <= 1'b0;
            bresp_reg     <= 2'b00;
            bvalid_pending <= 1'b0;
        end else begin
            if (M_AXI_BVALID && M_AXI_BREADY) begin
                bvalid_pending <= 1'b1;
                bresp_reg      <= M_AXI_BRESP;
            end
            if (bvalid_pending && S_AXIL_BREADY) begin
                S_AXIL_BVALID  <= 1'b0;
                bvalid_pending <= 1'b0;
            end else if (bvalid_pending) begin
                S_AXIL_BVALID  <= 1'b1;
            end
        end
    end

    // AXI4-Lite read response
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXIL_RVALID <= 1'b0;
            rdata_reg     <= {C_AXIL_DATA_WIDTH{1'b0}};
            rresp_reg     <= 2'b00;
            rvalid_pending <= 1'b0;
        end else begin
            if (M_AXI_RVALID && M_AXI_RREADY) begin
                rvalid_pending <= 1'b1;
                rdata_reg      <= M_AXI_RDATA[C_AXIL_DATA_WIDTH-1:0];
                rresp_reg      <= M_AXI_RRESP;
            end
            if (rvalid_pending && S_AXIL_RREADY) begin
                S_AXIL_RVALID  <= 1'b0;
                rvalid_pending <= 1'b0;
            end else if (rvalid_pending) begin
                S_AXIL_RVALID  <= 1'b1;
            end
        end
    end

    // Register file
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            src_addr_reg  <= {C_AXI_ADDR_WIDTH{1'b0}};
            dst_addr_reg  <= {C_AXI_ADDR_WIDTH{1'b0}};
            length_reg    <= 32'd0;
            remaining_len <= 32'd0;
            current_len   <= 32'd0;
            read_count    <= 32'd0;
            write_count   <= 32'd0;
            state         <= ST_IDLE;
            fifo_wr_ptr   <= {LGFIFO{1'b0}};
            fifo_rd_ptr   <= {LGFIFO{1'b0}};
            current_src_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
            current_dst_addr <= {C_AXI_ADDR_WIDTH{1'b0}};
            burst_len     <= 32'd0;
            burst_size    <= 3'b000;
            burst_type    <= 2'b00;
            read_id       <= {C_AXI_ID_WIDTH{1'b0}};
            write_id      <= {C_AXI_ID_WIDTH{1'b0}};
            axi_bresp_reg <= 2'b00;
            axi_rresp_reg <= 2'b00;
            o_int         <= 1'b0;
        end else begin
            // Handle AXI4-Lite writes
            if (S_AXIL_AWVALID && S_AXIL_AWREADY && S_AXIL_WVALID && S_AXIL_WREADY) begin
                case (S_AXIL_AWADDR[C_AXIL_ADDR_WIDTH-1:0])
                    REG_SRC_ADDR: begin
                        src_addr_reg <= S_AXIL_WDATA[C_AXI_ADDR_WIDTH-1:0];
                    end
                    REG_DST_ADDR: begin
                        dst_addr_reg <= S_AXIL_WDATA[C_AXI_ADDR_WIDTH-1:0];
                    end
                    REG_LENGTH: begin
                        length_reg   <= S_AXIL_WDATA;
                        remaining_len <= S_AXIL_WDATA;
                    end
                    REG_CONTROL: begin
                        if (S_AXIL_WDATA[CTRL_START] && state == ST_IDLE) begin
                            state         <= ST_READ;
                            current_src_addr <= src_addr_reg;
                            current_dst_addr <= dst_addr_reg;
                            remaining_len  <= length_reg;
                            read_count     <= 32'd0;
                            write_count    <= 32'd0;
                            fifo_wr_ptr    <= {LGFIFO{1'b0}};
                            fifo_rd_ptr    <= {LGFIFO{1'b0}};
                            o_int          <= 1'b0;
                        end
                        if (S_AXIL_WDATA[CTRL_ABORT]) begin
                            state <= ST_IDLE;
                            o_int <= 1'b0;
                        end
                    end
                    default: ;
                endcase
            end

            // State machine
            case (state)
                ST_IDLE: begin
                    // Wait for start command
                end
                ST_READ: begin
                    // Issue read address
                    if (!arvalid_reg && remaining_len > 0) begin
                        arvalid_reg <= 1'b1;
                        araddr_reg  <= current_src_addr;
                        arsize_reg  <= $clog2(C_AXI_DATA_WIDTH) - 3;
                        arburst_reg <= 2'b01; // INCR
                        arlock_reg  <= 1'b0;
                        arcache_reg <= 4'b0000;
                        arprot_reg  <= 3'b000;
                        arqos_reg   <= 4'b0000;
                        arid_reg    <= AXI_READ_ID;
                    end
                    if (arvalid_reg && M_AXI_ARREADY) begin
                        arvalid_reg <= 1'b0;
                    end
                    // Receive read data
                    if (M_AXI_RVALID && M_AXI_RREADY) begin
                        // Store in FIFO
                        data_fifo[fifo_wr_ptr] <= M_AXI_RDATA;
                        fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                        current_src_addr <= current_src_addr + C_AXI_DATA_WIDTH/8;
                        remaining_len <= remaining_len - (C_AXI_DATA_WIDTH/8);
                        read_count <= read_count + 1'b1;
                        if (remaining_len <= C_AXI_DATA_WIDTH/8) begin
                            state <= ST_WRITE;
                        end
                    end
                end
                ST_WRITE: begin
                    // Issue write address
                    if (!awvalid_reg && !fifo_empty) begin
                        awvalid_reg <= 1'b1;
                        awaddr_reg  <= current_dst_addr;
                        awsize_reg  <= $clog2(C_AXI_DATA_WIDTH) - 3;
                        awburst_reg <= 2'b01; // INCR
                        awlock_reg  <= 1'b0;
                        awcache_reg <= 4'b0000;
                        awprot_reg  <= 3'b000;
                        awqos_reg   <= 4'b0000;
                        awid_reg    <= AXI_WRITE_ID;
                    end
                    if (awvalid_reg && M_AXI_AWREADY) begin
                        awvalid_reg <= 1'b0;
                    end
                    // Send write data
                    if (!wvalid_reg && !fifo_empty) begin
                        wvalid_reg <= 1'b1;
                        wdata_reg  <= data_fifo[fifo_rd_ptr];
                        wstrb_reg  <= {C_AXI_DATA_WIDTH/8{1'b1}};
                        wlast_reg  <= 1'b1;
                    end
                    if (wvalid_reg && M_AXI_WREADY) begin
                        wvalid_reg <= 1'b0;
                        fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                        current_dst_addr <= current_dst_addr + C_AXI_DATA_WIDTH/8;
                        write_count <= write_count + 1'b1;
                    end
                    // Check if done
                    if (fifo_empty && remaining_len == 0) begin
                        state <= ST_DONE;
                        o_int <= 1'b1;
                    end else if (fifo_empty && remaining_len > 0) begin
                        state <= ST_READ;
                    end
                end
                ST_DONE: begin
                    // Wait for software to clear interrupt
                    if (S_AXIL_AWVALID && S_AXIL_AWREADY && S_AXIL_WVALID && S_AXIL_WREADY &&
                        S_AXIL_AWADDR[C_AXIL_ADDR_WIDTH-1:0] == REG_CONTROL) begin
                        state <= ST_IDLE;
                        o_int <= 1'b0;
                    end
                end
                ST_ERROR: begin
                    // Wait for software to clear interrupt
                    if (S_AXIL_AWVALID && S_AXIL_AWREADY && S_AXIL_WVALID && S_AXIL_WREADY &&
                        S_AXIL_AWADDR[C_AXIL_ADDR_WIDTH-1:0] == REG_CONTROL) begin
                        state <= ST_IDLE;
                        o_int <= 1'b0;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

    // AXI4 master BREADY and RREADY
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            bready_reg <= 1'b1;
            rready_reg <= 1'b1;
        end else begin
            bready_reg <= 1'b1;
            rready_reg <= 1'b1;
        end
    end

endmodule
