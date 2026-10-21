```verilog
module axixclk #(
	parameter integer C_S_AXI_ID_WIDTH	= 2,
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	parameter integer C_S_AXI_ADDR_WIDTH	= 6,
	parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
	parameter [0:0]	OPT_READ_ONLY = 1'b0,
	parameter XCLOCK_FFS = 2,
	parameter LGFIFO = 5
) (
	input	wire				S_AXI_ACLK,
	input	wire				S_AXI_ARESETN,
	input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID,
	input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR,
	input	wire [7 : 0]			S_AXI_AWLEN,
	input	wire [2 : 0]			S_AXI_AWSIZE,
	input	wire [1 : 0]			S_AXI_AWBURST,
	input	wire				S_AXI_AWLOCK,
	input	wire [3 : 0]			S_AXI_AWCACHE,
	input	wire [2 : 0]			S_AXI_AWPROT,
	input	wire [3 : 0]			S_AXI_AWQOS,
	input	wire				S_AXI_AWVALID,
	output	wire				S_AXI_AWREADY,
	input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA,
	input	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
	input	wire				S_AXI_WLAST,
	input	wire				S_AXI_WVALID,
	output	wire				S_AXI_WREADY,
	output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID,
	output	wire [1 : 0]			S_AXI_BRESP,
	output	wire				S_AXI_BVALID,
	input	wire				S_AXI_BREADY,
	input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID,
	input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR,
	input	wire [7 : 0]			S_AXI_ARLEN,
	input	wire [2 : 0]			S_AXI_ARSIZE,
	input	wire [1 : 0]			S_AXI_ARBURST,
	input	wire				S_AXI_ARLOCK,
	input	wire [3 : 0]			S_AXI_ARCACHE,
	input	wire [2 : 0]			S_AXI_ARPROT,
	input	wire [3 : 0]			S_AXI_ARQOS,
	input	wire				S_AXI_ARVALID,
	output	wire				S_AXI_ARREADY,
	output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID,
	output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA,
	output	wire [1 : 0]			S_AXI_RRESP,
	output	wire				S_AXI_RLAST,
	output	wire				S_AXI_RVALID,
	input	wire				S_AXI_RREADY,
	input	wire				M_AXI_ACLK,
	output	wire				M_AXI_ARESETN,
	output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID,
	output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR,
	output	wire [7 : 0]			M_AXI_AWLEN,
	output	wire [2 : 0]			M_AXI_AWSIZE,
	output	wire [1 : 0]			M_AXI_AWBURST,
	output	wire				M_AXI_AWLOCK,
	output	wire [3 : 0]			M_AXI_AWCACHE,
	output	wire [2 : 0]			M_AXI_AWPROT,
	output	wire [3 : 0]			M_AXI_AWQOS,
	output	wire				M_AXI_AWVALID,
	input	wire				M_AXI_AWREADY,
	output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA,
	output	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
	output	wire				M_AXI_WLAST,
	output	wire				M_AXI_WVALID,
	input	wire				M_AXI_WREADY,
	input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID,
	input	wire [1 : 0]			M_AXI_BRESP,
	input	wire				M_AXI_BVALID,
	output	wire				M_AXI_BREADY,
	output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID,
	output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR,
	output	wire [7 : 0]			M_AXI_ARLEN,
	output	wire [2 : 0]			M_AXI_ARSIZE,
	output	wire [1 : 0]			M_AXI_ARBURST,
	output	wire				M_AXI_ARLOCK,
	output	wire [3 : 0]			M_AXI_ARCACHE,
	output	wire [2 : 0]			M_AXI_ARPROT,
	output	wire [3 : 0]			M_AXI_ARQOS,
	output	wire				M_AXI_ARVALID,
	input	wire				M_AXI_ARREADY,
	input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID,
	input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA,
	input	wire [1 : 0]			M_AXI_RRESP,
	input	wire				M_AXI_RLAST,
	input	wire				M_AXI_RVALID,
	output	wire				M_AXI_RREADY
);

// Clock generation
reg S_AXI_ACLK;
reg M_AXI_ACLK;
reg M_AXI_ARESETN;

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		S_AXI_ACLK <= 1'b0;
		M_AXI_ARESETN <= 1'b0;
	end else begin
		S_AXI_ACLK <= ~S_AXI_ACLK;
		M_AXI_ARESETN <= 1'b1;
	end
end

always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if (!M_AXI_ARESETN) begin
		M_AXI_ACLK <= 1'b0;
	end else begin
		M_AXI_ACLK <= ~M_AXI_ACLK;
	end
end

// Cross Clock FIFO Parameters
parameter INTEGER FIFO_DEPTH = (1 << (XCLOCK_FFS + LGFIFO));
parameter INTEGER FIFO_ADDR_WIDTH = XCLOCK_FFS + LGFIFO;

// Write FIFO (AW)
reg [FIFO_ADDR_WIDTH-1:0] aw_fifo_addr;
reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id;
reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr_data;
reg [7:0] aw_fifo_len;
reg [2:0] aw_fifo_size;
reg [1:0] aw_fifo_burst;
reg aw_fifo_lock;
reg [3:0] aw_fifo_cache;
reg [2:0] aw_fifo_prot;
reg [3:0] aw_fifo_qos;
reg aw_fifo_valid;
reg aw_fifo_empty;
reg [FIFO_ADDR_WIDTH-1:0] aw_fifo_ptr;
reg [FIFO_ADDR_WIDTH-1:0] aw_fifo_tail;

// Write FIFO (W)
reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data;
reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb;
reg w_fifo_last;
reg w_fifo_valid;
reg w_fifo_empty;
reg [FIFO_ADDR_WIDTH-1:0] w_fifo_ptr;
reg [FIFO_ADDR_WIDTH-1:0] w_fifo_tail;

// Read FIFO (AR)
reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id;
reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr_data;
reg [7:0] ar_fifo_len;
reg [2:0] ar_fifo_size;
reg [1:0] ar_fifo_burst;
reg ar_fifo_lock;
reg [3:0] ar_fifo_cache;
reg [2:0] ar_fifo_prot;
reg [3:0] ar_fifo_qos;
reg ar_fifo_valid;
reg ar_fifo_empty;
reg [FIFO_ADDR_WIDTH-1:0] ar_fifo_ptr;
reg [FIFO_ADDR_WIDTH-1:0] ar_fifo_tail;

// Read FIFO (R)
reg [C_S_AXI_ID_WIDTH-1:0] r_fifo_id;
reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_data;
reg [1:0] r_fifo_resp;
reg r_fifo_last;
reg r_fifo_valid;
reg r_fifo_empty;
reg [FIFO_ADDR_WIDTH-1:0] r_fifo_ptr;
reg [FIFO_ADDR_WIDTH-1:0] r_fifo_tail;

// Write Response FIFO (B)
reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id;
reg [1:0] b_fifo_resp;
reg b_fifo_valid;
reg b_fifo_empty;
reg [FIFO_ADDR_WIDTH-1:0] b_fifo_ptr;
reg [FIFO_ADDR_WIDTH-1:0] b_fifo_tail;

// AW FIFO Logic
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		aw_fifo_addr <= 0;
		aw_fifo_id <= 0;
		aw_fifo_addr_data <= 0;
		aw_fifo_len <= 0;
		aw_fifo_size <= 0;
		aw_fifo_burst <= 0;
		aw_fifo_lock <= 0;
		aw_fifo_cache <= 0;
		aw_fifo_prot <= 0;
		aw_fifo_qos <= 0;
		aw_fifo_valid <= 0;
		aw_fifo_ptr <= 0;
		aw_fifo_tail <= 0;
		aw_fifo_empty <= 1;
	end else begin
		if (S_AXI_AWVALID && S_AXI_AWREADY) begin
			aw_fifo_addr[aw_fifo_ptr] <= aw_fifo_ptr;
			aw_fifo_id[aw_fifo_ptr] <= S_AXI_AWID;
			aw_fifo_addr_data[aw_fifo_ptr] <= S_AXI_AWADDR;
			aw_fifo_len[aw_fifo_ptr] <= S_AXI_AWLEN;
			aw_fifo_size[aw_fifo_ptr] <= S_AXI_AWSIZE;
			aw_fifo_burst[aw_fifo_ptr] <= S_AXI_AWBURST;
			aw_fifo_lock[aw_fifo_ptr] <= S_AXI_AWLOCK;
			aw_fifo_cache[aw_fifo_ptr] <= S_AXI_AWCACHE;
			aw_fifo_prot[aw_fifo_ptr] <= S_AXI_AWPROT;
			aw_fifo_qos[aw_fifo_ptr] <= S_AXI_AWQOS;
			aw_fifo_ptr <= aw_fifo_ptr + 1;
			aw_fifo_valid <= 1;
			if (aw_fifo_ptr == FIFO_DEPTH-1) begin
				aw_fifo_tail <= aw_fifo_ptr;
				aw_fifo_empty <= 0;
			end
		end
		if (aw_fifo_valid && M_AXI_AWREADY) begin
			aw_fifo_valid <= 0;
			if (aw_fifo_ptr == aw_fifo_tail) begin
				aw_fifo_empty <= 1;
			end
		end
	end
end

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		S_AXI_AWREADY <= 0;
	end else begin
		S_AXI_AWREADY <= (aw_fifo_valid && !aw_fifo_empty);
	end
end

always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if (!M_AXI_ARESETN) begin
		M_AXI_AWID <= 0;
		M_AXI_AWADDR <= 0;
		M_AXI_AWLEN <= 0;
		M_AXI_AWSIZE <= 0;
		M_AXI_AWBURST <= 0;
		M_AXI_AWLOCK <= 0;
		M_AXI_AWCACHE <= 0;
		M_AXI_AWPROT <= 0;
		M_AXI_AWQOS <= 0;
		M_AXI_AWVALID <= 0;
	end else begin
		if (aw_fifo_valid && !aw_fifo_empty) begin
			M_AXI_AWID <= aw_fifo_id[aw_fifo_tail];
			M_AXI_AWADDR <= aw_fifo_addr_data[aw_fifo_tail];
			M_AXI_AWLEN <= aw_fifo_len[aw_fifo_tail];
			M_AXI_AWSIZE <= aw_fifo_size[aw_fifo_tail];
			M_AXI_AWBURST <= aw_fifo_burst[aw_fifo_tail];
			M_AXI_AWLOCK <= aw_fifo_lock[aw_fifo_tail];
			M_AXI_AWCACHE <= aw_fifo_cache[aw_fifo_tail];
			M_AXI_AWPROT <= aw_fifo_prot[aw_fifo_tail];
			M_AXI_AWQOS <= aw_fifo_qos[aw_fifo_tail];
			M_AXI_AWVALID <= 1;
			if (M_AXI_AWREADY) begin
				aw_fifo_valid <= 0;
				aw_fifo_tail <= aw_fifo_tail + 1;
				if (aw_fifo_tail == aw_fifo_ptr) begin
					aw_fifo_empty <= 1;
				end
			end
		end else begin
			M_AXI_AWVALID <= 0;
		end
	end
end

// W FIFO Logic
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		w_fifo_data <= 0;
		w_fifo_strb <= 0;
		w_fifo_last <= 0;
		w_fifo_valid <= 0;
		w_fifo_ptr <= 0;
		w_fifo_tail <= 0;
		w_fifo_empty <= 1;
	end else begin
		if (S_AXI_WVALID && S_AXI_WREADY) begin
			w_fifo_data[w_fifo_ptr] <= S_AXI_WDATA;
			w_fifo_strb[w_fifo_ptr] <= S_AXI_WSTRB;
			w_fifo_last[w_fifo_ptr] <= S_AXI_WLAST;
			w_fifo_ptr <= w_fifo_ptr + 1;
			w_fifo_valid <= 1;
			if (w_fifo_ptr == FIFO_DEPTH-1) begin
				w_fifo_tail <= w_fifo_ptr;
				w_fifo_empty <= 0;
			end
		end
		if (w_fifo_valid && M_AXI_WREADY) begin
			w_fifo_valid <= 0;
			if (w_fifo_ptr == w_fifo_tail) begin
				w_fifo_empty <= 1;
			end
		end
	end
end

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		S_AXI_WREADY <= 0;
	end else begin
		S_AXI_WREADY <= (w_fifo_valid && !w_fifo_empty);
	end
end

always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if (!M_AXI_ARESETN) begin
		M_AXI_WDATA <= 0;
		M_AXI_WSTRB <= 0;
		M_AXI_WLAST <= 0;
		M_AXI_WVALID <= 0;
	end else begin
		if (w_fifo_valid && !w_fifo_empty) begin
			M_AXI_WDATA <= w_fifo_data[w_fifo_tail];
			M_AXI_WSTRB <= w_fifo_strb[w_fifo_tail];
			M_AXI_WLAST <= w_fifo_last[w_fifo_tail];
			M_AXI_WVALID <= 1;
			if (M_AXI_WREADY) begin
				w_fifo_valid <= 0;
				w_fifo_tail <= w_fifo_tail + 1;
				if (w_fifo_tail == w_fifo_ptr) begin
					w_fifo_empty <= 1;
				end
			end
		end else begin
			M_AXI_WVALID <= 0;
		end
	end
end

// AR FIFO Logic
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		ar_fifo_id <= 0;
		ar_fifo_addr_data <= 0;
		ar_fifo_len <= 0;
		ar_fifo_size <= 0;
		ar_fifo_burst <= 0;
		ar_fifo_lock <= 0;
		ar_fifo_cache <= 0;
		ar_fifo_prot <= 0;
		ar_fifo_qos <= 0;
		ar_fifo_valid <= 0;
		ar_fifo_ptr <= 0;
		ar_fifo_tail <= 0;
		ar_fifo_empty <= 1;
	end else begin
		if (S_AXI_ARVALID && S_AXI_ARREADY) begin
			ar_fifo_id[ar_fifo_ptr] <= S_AXI_ARID;
			ar_fifo_addr_data[ar_fifo_ptr] <= S_AXI_ARADDR;
			ar_fifo_len[ar_fifo_ptr] <= S_AXI_ARLEN;
			ar_fifo_size[ar_fifo_ptr] <= S_AXI_ARSIZE;
			ar_fifo_burst[ar_fifo_ptr] <= S_AXI_ARBURST;
			ar_fifo_lock[ar_fifo_ptr] <= S_AXI_ARLOCK;
			ar_fifo_cache[ar_fifo_ptr] <= S_AXI_ARCACHE;
			ar_fifo_prot[ar_fifo_ptr] <= S_AXI_ARPROT;
			ar_fifo_qos[ar_fifo_ptr] <= S_AXI_ARQOS;
			ar_fifo_ptr <= ar_fifo_ptr + 1;
			ar_fifo_valid <= 1;
			if (ar_fifo_ptr == FIFO_DEPTH-1) begin
				ar_fifo_tail <= ar_fifo_ptr;
				ar_fifo_empty <= 0;
			end
		end
		if (ar_fifo_valid && M_AXI_ARREADY) begin
			ar_fifo_valid <= 0;
			if (ar_fifo_ptr == ar_fifo_tail) begin
				ar_fifo_empty <= 1;
			end
		end
	end
end

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		S_AXI_ARREADY <= 0;
	end else begin
		S_AXI_ARREADY <= (ar_fifo_valid && !ar_fifo_empty);
	end
end

always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if (!M_AXI_ARESETN) begin
		M_AXI_ARID <= 0;
		M_AXI_ARADDR <= 0;
		M_AXI_ARLEN <= 0;
		M_AXI_ARSIZE <= 0;
		M_AXI_ARBURST <= 0;
		M_AXI_ARLOCK <= 0;
		M_AXI_ARCACHE <= 0;
		M_AXI_ARPROT <= 0;
		M_AXI_ARQOS <= 0;
		M_AXI_ARVALID <= 0;
	end else begin
		if (ar_fifo_valid && !ar_fifo_empty) begin
			M_AXI_ARID <= ar_fifo_id[ar_fifo_tail];
			M_AXI_ARADDR <= ar_fifo_addr_data[ar_fifo_tail];
			M_AXI_ARLEN <= ar_fifo_len[ar_fifo_tail];
			M_AXI_ARSIZE <= ar_fifo_size[ar_fifo_tail];
			M_AXI_ARBURST <= ar_fifo_burst[ar_fifo_tail];
			M_AXI_ARLOCK <= ar_fifo_lock[ar_fifo_tail];
			M_AXI_ARCACHE <= ar_fifo_cache[ar_fifo_tail];
			M_AXI_ARPROT <= ar_fifo_prot[ar_fifo_tail];
			M_AXI_ARQOS <= ar_fifo_qos[ar_fifo_tail];
			M_AXI_ARVALID <= 1;
			if (M_AXI_ARREADY) begin
				ar_fifo_valid <= 0;
				ar_fifo_tail <= ar_fifo_tail + 1;
				if (ar_fifo_tail == ar_fifo_ptr) begin
					ar_fifo_empty <= 1;
				end
			end
		end else begin
			M_AXI_ARVALID <= 0;
		end
	end
end

// R FIFO Logic
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		r_fifo_id <= 0;
		r_fifo_data <= 0;
		r_fifo_resp <= 0;
		r_fifo_last <= 0;
		r_fifo_valid <= 0;
		r_fifo_ptr <= 0;
		r_fifo_tail <= 0;
		r_fifo_empty <= 1;
	end else begin
		if (M_AXI_RVALID && M_AXI_RREADY) begin
			r_fifo_id[r_fifo_ptr] <= M_AXI_RID;
			r_fifo_data[r_fifo_ptr] <= M_AXI_RDATA;
			r_fifo_resp[r_fifo_ptr] <= M_AXI_RRESP;
			r_fifo_last[r_fifo_ptr] <= M_AXI_RLAST;
			r_fifo_ptr <= r_fifo_ptr + 1;
			r_fifo_valid <= 1;
			if (r_fifo_ptr == FIFO_DEPTH-1) begin
				r_fifo_tail <= r_fifo_ptr;
				r_fifo_empty <= 0;
			end
		end
		if (r_fifo_valid && S_AXI_RREADY) begin
			r_fifo_valid <= 0;
			if (r_fifo_ptr == r_fifo_tail) begin
				r_fifo_empty <= 1;
			end
		end
	end
end

always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if (!M_AXI_ARESETN) begin
		M_AXI_RREADY <= 0;
	end else begin
		M_AXI_RREADY <= (r_fifo_valid && !r_fifo_empty);
	end
end

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		S_AXI_RID <= 0;
		S_AXI_RDATA <= 0;
		S_AXI_RRESP <= 0;
		S_AXI_RLAST <= 0;
		S_AXI_RVALID <= 0;
	end else begin
		if (r_fifo_valid && !r_fifo_empty) begin
			S_AXI_RID <= r_fifo_id[r_fifo_tail];
			S_AXI_RDATA <= r_fifo_data[r_fifo_tail];
			S_AXI_RRESP <= r_fifo_resp[r_fifo_tail];
			S_AXI_RLAST <= r_fifo_last[r_fifo_tail];
			S_AXI_RVALID <= 1;
			if (S_AXI_RREADY) begin
				r_fifo_valid <= 0;
				r_fifo_tail <= r_fifo_tail + 1;
				if (r_fifo_tail == r_fifo_ptr) begin
					r_fifo_empty <= 1;
				end
			end
		end else begin
			S_AXI_RVALID <= 0;
		end
	end
end

// B FIFO Logic
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		b_fifo_id <= 0;
		b_fifo_resp <= 0;
		b_fifo_valid <= 0;
		b_fifo_ptr <= 0;
		b_fifo_tail <= 0;
		b_fifo_empty <= 1;
	end else begin
		if (M_AXI_BVALID && M_AXI_BREADY) begin
			b_fifo_id[b_fifo_ptr] <= M_AXI_BID;
			b_fifo_resp[b_fifo_ptr] <= M_AXI_BRESP;
			b_fifo_ptr <= b_fifo_ptr + 1;
			b_fifo_valid <= 1;
			if (b_fifo_ptr == FIFO_DEPTH-1) begin
				b_fifo_tail <= b_fifo_ptr;
				b_fifo_empty <= 0;
			end
		end
		if (b_fifo_valid && S_AXI_BREADY) begin
			b_fifo_valid <= 0;
			if (b_fifo_ptr == b_fifo_tail) begin
				b_fifo_empty <= 1;
			end
		end
	end
end

always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if (!M_AXI_ARESETN) begin
		M_AXI_BREADY <= 0;
	end else begin
		M_AXI_BREADY <= (b_fifo_valid && !b_fifo_empty);
	end
end

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		S_AXI_BID <= 0;
		S_AXI_BRESP <= 0;
		S_AXI_BVALID <= 0;
	end else begin
		if (b_fifo_valid && !b_fifo_empty) begin
			S_AXI_BID <= b_fifo_id[b_fifo_tail];
			S_AXI_BRESP <= b_fifo_resp[b_fifo_tail];
			S_AXI_BVALID <= 1;
			if (S_AXI_BREADY) begin
				b_fifo_valid <= 0;
				b_fifo_tail <= b_fifo_tail + 1;
				if (b_fifo_tail == b_fifo_ptr) begin
					b_fifo_empty <= 1;
				end
			end
		end else begin
			S_AXI_BVALID <= 0;
		end
	end
end

// Reset Generation
assign M_AXI_ARESETN = S_AXI_ARESETN;

endmodule
```<|im_end|>
