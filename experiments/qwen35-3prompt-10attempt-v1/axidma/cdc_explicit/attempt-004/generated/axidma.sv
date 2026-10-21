```verilog
module axidma #(
	parameter	C_AXI_ID_WIDTH = 1,
	parameter	C_AXI_ADDR_WIDTH = 32,
	parameter	C_AXI_DATA_WIDTH = 32,
	localparam	C_AXIL_ADDR_WIDTH = 5,
	localparam	C_AXIL_DATA_WIDTH = 32,
	parameter [0:0]	OPT_UNALIGNED = 1'b1,
	parameter [0:0]	OPT_WRAPMEM = 1'b1,
	parameter	LGFIFO = 8,
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

// ============================================================================
// Internal Parameters and Constants
// ============================================================================
localparam LG_FIFO_DEPTH = 1 << LGFIFO;
localparam LG_LEN_W = LGLENW;
localparam LG_ADDR_W = C_AXI_ADDR_WIDTH;

// State Machine States
localparam STATE_IDLE = 3'b000;
localparam STATE_CONFIG = 3'b001;
localparam STATE_PREPARE = 3'b010;
localparam STATE_READ = 3'b011;
localparam STATE_WRITE = 3'b100;
localparam STATE_DONE = 3'b101;
localparam STATE_ABORT = 3'b110;

// ============================================================================
// AXI4-Lite Control Interface (Slave)
// ============================================================================
reg [31:0] cfg_src_addr;
reg [31:0] cfg_dst_addr;
reg [31:0] cfg_len;
reg [31:0] cfg_ctrl;
reg [7:0]  cfg_abort_key;
reg        cfg_valid;
reg        cfg_ready;
reg        cfg_done;
reg        cfg_abort_req;
reg [31:0] cfg_abort_val;

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        cfg_src_addr <= 32'h0;
        cfg_dst_addr <= 32'h0;
        cfg_len      <= 32'h0;
        cfg_ctrl     <= 32'h0;
        cfg_abort_key<= 8'h0;
        cfg_valid    <= 1'b0;
        cfg_ready    <= 1'b1;
        cfg_done     <= 1'b0;
        cfg_abort_req<= 1'b0;
        cfg_abort_val<= 32'h0;
        o_int        <= 1'b0;
    end else begin
        // Write Address Decoding
        if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
            case (S_AXIL_AWADDR[4:0])
                5'h0: cfg_src_addr <= S_AXIL_AWADDR[31:0];
                5'h4: cfg_dst_addr <= S_AXIL_AWADDR[31:0];
                5'h8: cfg_len      <= S_AXIL_AWADDR[31:0];
                5'hC: cfg_ctrl     <= S_AXIL_AWADDR[31:0];
                5'h10: cfg_abort_key<= S_AXIL_AWADDR[31:0];
                default: ;
            endcase
            S_AXIL_AWREADY <= 1'b0;
        end

        // Write Data (for abort key)
        if (S_AXIL_WVALID && S_AXIL_WREADY) begin
            if (S_AXIL_AWADDR[4:0] == 5'h10)
                cfg_abort_key <= S_AXIL_WDATA[7:0];
            S_AXIL_WREADY <= 1'b0;
        end

        // Read Response
        if (S_AXIL_RVALID && S_AXIL_RREADY) begin
            S_AXIL_RREADY <= 1'b0;
            // Echo back status or specific value if needed
            S_AXIL_RDATA  <= 32'h0; 
            S_AXIL_RRESP  <= 2'b00;
        end
    end
end

// AXI-Lite Handshaking
S_AXIL_AWREADY <= cfg_ready;
S_AXIL_WREADY  <= cfg_ready;
S_AXIL_ARREADY <= cfg_ready;

// AXI-Lite Response Generation (Simplified)
S_AXIL_BVALID  <= cfg_valid;
S_AXIL_BREADY  <= 1'b1; // Assume master ready
S_AXIL_BRESP   <= 2'b00;
S_AXIL_BVALID  <= cfg_valid && S_AXIL_BREADY;
S_AXIL_BREADY  <= 1'b1; // Always ready for simplicity in this context, or toggle if needed

// Read Response
S_AXIL_RVALID  <= cfg_valid;
S_AXIL_RREADY  <= 1'b1; // Assume master ready
S_AXIL_RDATA   <= cfg_abort_val;
S_AXIL_RRESP   <= 2'b00;
S_AXIL_RVALID  <= cfg_valid && S_AXIL_RREADY;

// Configuration Logic
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        cfg_valid <= 1'b0;
        cfg_ready <= 1'b1;
        cfg_done  <= 1'b0;
    end else begin
        if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
            if (S_AXIL_AWADDR[4:0] == 5'h0) cfg_src_addr <= S_AXIL_AWADDR[31:0];
            else if (S_AXIL_AWADDR[4:0] == 5'h4) cfg_dst_addr <= S_AXIL_AWADDR[31:0];
            else if (S_AXIL_AWADDR[4:0] == 5'h8) cfg_len <= S_AXIL_AWADDR[31:0];
            else if (S_AXIL_AWADDR[4:0] == 5'hC) cfg_ctrl <= S_AXIL_AWADDR[31:0];
            else if (S_AXIL_AWADDR[4:0] == 5'h10) cfg_abort_key <= S_AXIL_AWADDR[31:0];
        end
        
        // Check for valid configuration
        if (cfg_src_addr !== 32'h0 && cfg_dst_addr !== 32'h0 && cfg_len !== 32'h0) begin
            cfg_valid <= 1'b1;
            cfg_ready <= 1'b0;
        end
        
        // Handle Abort
        if (cfg_abort_key == ABORT_KEY) begin
            cfg_abort_req <= 1'b1;
            cfg_abort_val <= cfg_ctrl;
        end
        
        // Transition to engine state
        if (cfg_valid && !cfg_done && !cfg_abort_req) begin
            // Start engine
            state_engine <= STATE_CONFIG;
            cfg_done <= 1'b1;
            cfg_valid <= 1'b0;
            cfg_ready <= 1'b1;
        end
    end
end

// ============================================================================
// Main Engine State Machine (Single Clock Domain)
// ============================================================================
reg [2:0] state_engine;
reg [31:0] curr_addr;
reg [31:0] remaining_len;
reg [31:0] burst_len;
reg [31:0] data_offset;
reg [31:0] src_addr_reg;
reg [31:0] dst_addr_reg;
reg [31:0] ctrl_reg;
reg [31:0] abort_val_reg;
reg        engine_running;
reg        burst_complete;
reg [C_AXI_ID_WIDTH-1:0] axi_id;
reg [2:0] axi_burst_type;
reg [2:0] axi_burst_size;
reg        axi_burst_lock;
reg [3:0] axi_burst_cache;
reg [2:0] axi_burst_prot;
reg [3:0] axi_burst_qos;
reg        w_last;
reg        r_last;
reg [C_AXI_DATA_WIDTH-1:0] w_data;
reg [C_AXI_DATA_WIDTH/8-1:0] w_strb;
reg [C_AXI_DATA_WIDTH-1:0] r_data;
reg [1:0] r_resp;
reg        abort_flag;

// FIFO for data buffering (Simple implementation)
// In a real scenario, this would be a dual-port FIFO or separate read/write FIFOs
// Here we use a simple register for the current transfer to keep code concise as per request
// but structure it to allow flow control.

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        state_engine <= STATE_IDLE;
        engine_running <= 1'b0;
        burst_complete <= 1'b0;
        abort_flag <= 1'b0;
        curr_addr <= 32'h0;
        remaining_len <= 32'h0;
        data_offset <= 32'h0;
        src_addr_reg <= 32'h0;
        dst_addr_reg <= 32'h0;
        ctrl_reg <= 32'h0;
        abort_val_reg <= 32'h0;
        w_last <= 1'b0;
        r_last <= 1'b0;
        burst_complete <= 1'b0;
    end else begin
        // State Machine Logic
        case (state_engine)
            STATE_IDLE: begin
                if (cfg_valid) begin
                    state_engine <= STATE_CONFIG;
                    src_addr_reg <= cfg_src_addr;
                    dst_addr_reg <= cfg_dst_addr;
                    ctrl_reg <= cfg_ctrl;
                    abort_val_reg <= cfg_abort_val;
                    remaining_len <= cfg_len;
                    curr_addr <= src_addr_reg;
                    engine_running <= 1'b1;
                    abort_flag <= 1'b0;
                    burst_complete <= 1'b0;
                end
            end

            STATE_CONFIG: begin
                // Determine burst parameters
                if (OPT_UNALIGNED) begin
                    axi_burst_size <= 3; // 256 bytes
                end else begin
                    axi_burst_size <= 0; // 8 bytes
                end
                
                if (OPT_WRAPMEM) begin
                    axi_burst_type <= 3'b001; // INCR
                end else begin
                    axi_burst_type <= 3'b000; // FIXED
                end
                
                // Calculate burst length based on remaining length and size
                // Simplified: Assume max burst length of 256 for this example
                // In production, calculate exact burst length
                burst_len <= 256; 
                
                if (remaining_len < burst_len) begin
                    burst_len <= remaining_len;
                end
                
                // Check for abort
                if (ctrl_reg[7:0] == ABORT_KEY) begin
                    abort_flag <= 1'b1;
                    state_engine <= STATE_ABORT;
                end else begin
                    state_engine <= STATE_PREPARE;
                end
            end

            STATE_PREPARE: begin
                // Prepare AXI Write Address
                M_AXI_AWID <= axi_id;
                M_AXI_AWADDR <= curr_addr;
                M_AXI_AWSIZE <= axi_burst_size;
                M_AXI_AWBURST <= axi_burst_type;
                M_AXI_AWLOCK <= axi_burst_lock;
                M_AXI_AWCACHE <= axi_burst_cache;
                M_AXI_AWPROT <= axi_burst_prot;
                M_AXI_AWQOS <= axi_burst_qos;
                
                M_AXI_WVALID <= 1'b0;
                M_AXI_WLAST <= 1'b0;
                M_AXI_WDATA <= 32'h0;
                M_AXI_WSTRB <= 4'hF;
                
                M_AXI_ARVALID <= 1'b0;
                M_AXI_ARID <= axi_id;
                M_AXI_ARADDR <= curr_addr;
                M_AXI_ARSIZE <= axi_burst_size;
                M_AXI_ARBURST <= axi_burst_type;
                M_AXI_ARLOCK <= axi_burst_lock;
                M_AXI_ARCACHE <= axi_burst_cache;
                M_AXI_ARPROT <= axi_burst_prot;
                M_AXI_ARQOS <= axi_burst_qos;
                
                M_AXI_BREADY <= 1'b1;
                M_AXI_RREADY <= 1'b1;
                
                M_AXI_AWVALID <= 1'b1;
                
                if (M_AXI_AWREADY) begin
                    M_AXI_AWVALID <= 1'b0;
                    state_engine <= STATE_WRITE;
                end
            end

            STATE_WRITE: begin
                // Issue Write Data
                M_AXI_WVALID <= 1'b1;
                M_AXI_WLAST <= 1'b0;
                
                // Data generation logic would go here (e.g., reading from a source FIFO)
                // For this example, we assume data is available or generated
                M_AXI_WDATA <= 32'h0; 
                M_AXI_WSTRB <= 4'hF;
                
                if (M_AXI_WREADY) begin
                    M_AXI_WVALID <= 1'b0;
                    
                    // Update address and length
                    if (OPT_WRAPMEM) begin
                        curr_addr <= curr_addr + burst_len;
                    end else begin
                        curr_addr <= curr_addr + burst_len;
                    end
                    
                    remaining_len <= remaining_len - burst_len;
                    
                    if (remaining_len == 0) begin
                        state_engine <= STATE_DONE;
                    end else if (remaining_len < burst_len) begin
                        burst_len <= remaining_len;
                        M_AXI_WLAST <= 1'b1;
                        state_engine <= STATE_WRITE;
                    end else begin
                        state_engine <= STATE_WRITE;
                    end
                end
            end

            STATE_DONE: begin
                engine_running <= 1'b0;
                state_engine <= STATE_IDLE;
            end

            STATE_ABORT: begin
                engine_running <= 1'b0;
                state_engine <= STATE_IDLE;
                o_int <= 1'b1;
            end

            default: state_engine <= STATE_IDLE;
        endcase
    end
end

// Output Ports
S_AXIL_BVALID <= 1'b0; // Handled in AXI-Lite block
S_AXIL_BREADY <= 1'b1;
S_AXIL_BRESP  <= 2'b00;

S_AXIL_ARREADY <= 1'b1;
S_AXIL_RVALID  <= 1'b0;
S_AXIL_RDATA   <= 32'h0;
S_AXIL_RRESP   <= 2'b00;

M_AXI_AWVALID  <= 1'b0;
M_AXI_AWID     <= 1'b0;
M_AXI_AWADDR   <= 32'h0;
M_AXI_AWSIZE   <= 3'b000;
M_AXI_AWBURST  <= 2'b00;
M_AXI_AWLOCK   <= 1'b0;
M_AXI_AWCACHE  <= 4'h0;
M_AXI_AWPROT   <= 3'b000;
M_AXI_AWQOS    <= 4'h0;

M_AXI_WVALID   <= 1'b0;
M_AXI_WDATA    <= 32'h0;
M_AXI_WSTRB    <= 4'hF;
M_AXI_WLAST    <= 1'b0;
M_AXI_BREADY   <= 1'b1;

M_AXI_ARVALID  <= 1'b0;
M_AXI_ARID     <= 1'b0;
M_AXI_ARADDR   <= 32'h0;
M_AXI_ARSIZE   <= 3'b000;
M_AXI_ARBURST  <= 2'b00;
M_AXI_ARLOCK   <= 1'b0;
M_AXI_ARCACHE  <= 4'h0;
M_AXI_ARPROT   <= 3'b000;
M_AXI_ARQOS    <= 4'h0;

M_AXI_RREADY   <= 1'b1;

o_int <= abort_flag;

endmodule
```<|im_end|>
