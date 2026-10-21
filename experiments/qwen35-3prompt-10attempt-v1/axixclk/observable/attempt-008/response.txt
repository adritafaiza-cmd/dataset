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

// Clock Domain Crossing Generation
// S_AXI -> M_AXI (Write Address)
genvar i;
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_addr
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] cross_write_addr_i;
    wire cross_write_addr_valid_i;
    wire cross_write_addr_ready_i;
    wire cross_write_addr_deassert_i;
    
    assign cross_write_addr_valid_i = S_AXI_AWVALID;
    assign cross_write_addr_ready_i = M_AXI_AWREADY;
    assign cross_write_addr_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(C_S_AXI_ADDR_WIDTH),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_addr_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_addr_i),
      .C_DATAVALID(cross_write_addr_valid_i),
      .C_DATAREADY(cross_write_addr_ready_i),
      .C_DATAOUT(M_AXI_AWADDR),
      .C_DATADEASSERT(cross_write_addr_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write ID)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_id
    wire [C_S_AXI_ID_WIDTH-1 : 0] cross_write_id_i;
    wire cross_write_id_valid_i;
    wire cross_write_id_ready_i;
    wire cross_write_id_deassert_i;
    
    assign cross_write_id_valid_i = S_AXI_AWVALID;
    assign cross_write_id_ready_i = M_AXI_AWREADY;
    assign cross_write_id_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_id_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_id_i),
      .C_DATAVALID(cross_write_id_valid_i),
      .C_DATAREADY(cross_write_id_ready_i),
      .C_DATAOUT(M_AXI_AWID),
      .C_DATADEASSERT(cross_write_id_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write LEN)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_len
    wire [7 : 0] cross_write_len_i;
    wire cross_write_len_valid_i;
    wire cross_write_len_ready_i;
    wire cross_write_len_deassert_i;
    
    assign cross_write_len_valid_i = S_AXI_AWVALID;
    assign cross_write_len_ready_i = M_AXI_AWREADY;
    assign cross_write_len_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(8),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_len_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_len_i),
      .C_DATAVALID(cross_write_len_valid_i),
      .C_DATAREADY(cross_write_len_ready_i),
      .C_DATAOUT(M_AXI_AWLEN),
      .C_DATADEASSERT(cross_write_len_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write SIZE)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_size
    wire [2 : 0] cross_write_size_i;
    wire cross_write_size_valid_i;
    wire cross_write_size_ready_i;
    wire cross_write_size_deassert_i;
    
    assign cross_write_size_valid_i = S_AXI_AWVALID;
    assign cross_write_size_ready_i = M_AXI_AWREADY;
    assign cross_write_size_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(3),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_size_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_size_i),
      .C_DATAVALID(cross_write_size_valid_i),
      .C_DATAREADY(cross_write_size_ready_i),
      .C_DATAOUT(M_AXI_AWSIZE),
      .C_DATADEASSERT(cross_write_size_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write BURST)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_burst
    wire [1 : 0] cross_write_burst_i;
    wire cross_write_burst_valid_i;
    wire cross_write_burst_ready_i;
    wire cross_write_burst_deassert_i;
    
    assign cross_write_burst_valid_i = S_AXI_AWVALID;
    assign cross_write_burst_ready_i = M_AXI_AWREADY;
    assign cross_write_burst_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(2),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_burst_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_burst_i),
      .C_DATAVALID(cross_write_burst_valid_i),
      .C_DATAREADY(cross_write_burst_ready_i),
      .C_DATAOUT(M_AXI_AWBURST),
      .C_DATADEASSERT(cross_write_burst_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write LOCK)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_lock
    wire cross_write_lock_i;
    wire cross_write_lock_valid_i;
    wire cross_write_lock_ready_i;
    wire cross_write_lock_deassert_i;
    
    assign cross_write_lock_valid_i = S_AXI_AWVALID;
    assign cross_write_lock_ready_i = M_AXI_AWREADY;
    assign cross_write_lock_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(1),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_lock_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_lock_i),
      .C_DATAVALID(cross_write_lock_valid_i),
      .C_DATAREADY(cross_write_lock_ready_i),
      .C_DATAOUT(M_AXI_AWLOCK),
      .C_DATADEASSERT(cross_write_lock_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write CACHE)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_cache
    wire [3 : 0] cross_write_cache_i;
    wire cross_write_cache_valid_i;
    wire cross_write_cache_ready_i;
    wire cross_write_cache_deassert_i;
    
    assign cross_write_cache_valid_i = S_AXI_AWVALID;
    assign cross_write_cache_ready_i = M_AXI_AWREADY;
    assign cross_write_cache_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(4),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_cache_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_cache_i),
      .C_DATAVALID(cross_write_cache_valid_i),
      .C_DATAREADY(cross_write_cache_ready_i),
      .C_DATAOUT(M_AXI_AWCACHE),
      .C_DATADEASSERT(cross_write_cache_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write PROT)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_prot
    wire [2 : 0] cross_write_prot_i;
    wire cross_write_prot_valid_i;
    wire cross_write_prot_ready_i;
    wire cross_write_prot_deassert_i;
    
    assign cross_write_prot_valid_i = S_AXI_AWVALID;
    assign cross_write_prot_ready_i = M_AXI_AWREADY;
    assign cross_write_prot_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(3),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_prot_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_prot_i),
      .C_DATAVALID(cross_write_prot_valid_i),
      .C_DATAREADY(cross_write_prot_ready_i),
      .C_DATAOUT(M_AXI_AWPROT),
      .C_DATADEASSERT(cross_write_prot_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write QOS)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_qos
    wire [3 : 0] cross_write_qos_i;
    wire cross_write_qos_valid_i;
    wire cross_write_qos_ready_i;
    wire cross_write_qos_deassert_i;
    
    assign cross_write_qos_valid_i = S_AXI_AWVALID;
    assign cross_write_qos_ready_i = M_AXI_AWREADY;
    assign cross_write_qos_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(4),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_qos_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_qos_i),
      .C_DATAVALID(cross_write_qos_valid_i),
      .C_DATAREADY(cross_write_qos_ready_i),
      .C_DATAOUT(M_AXI_AWQOS),
      .C_DATADEASSERT(cross_write_qos_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write VALID)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_write_valid
    wire cross_write_valid_i;
    wire cross_write_valid_out_i;
    wire cross_write_valid_ready_i;
    wire cross_write_valid_deassert_i;
    
    assign cross_write_valid_i = S_AXI_AWVALID;
    assign cross_write_valid_ready_i = M_AXI_AWREADY;
    assign cross_write_valid_deassert_i = S_AXI_AWVALID & M_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(1),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_write_valid_i (
      .C_CLK(M_AXI_ACLK),
      .C_RSTN(M_AXI_ARESETN),
      .C_DATAIN(cross_write_valid_i),
      .C_DATAVALID(cross_write_valid_out_i),
      .C_DATAREADY(cross_write_valid_ready_i),
      .C_DATAOUT(M_AXI_AWVALID),
      .C_DATADEASSERT(cross_write_valid_deassert_i)
    );
  end
endgenerate

// S_AXI -> M_AXI (Write READY)
assign S_AXI_AWREADY = M_AXI_AWREADY;

// M_AXI -> S_AXI (Write Address)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_addr
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] cross_read_addr_i;
    wire cross_read_addr_valid_i;
    wire cross_read_addr_ready_i;
    wire cross_read_addr_deassert_i;
    
    assign cross_read_addr_valid_i = M_AXI_ARVALID;
    assign cross_read_addr_ready_i = S_AXI_ARREADY;
    assign cross_read_addr_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(C_S_AXI_ADDR_WIDTH),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_addr_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_addr_i),
      .C_DATAVALID(cross_read_addr_valid_i),
      .C_DATAREADY(cross_read_addr_ready_i),
      .C_DATAOUT(S_AXI_ARADDR),
      .C_DATADEASSERT(cross_read_addr_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write ID)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_id
    wire [C_S_AXI_ID_WIDTH-1 : 0] cross_read_id_i;
    wire cross_read_id_valid_i;
    wire cross_read_id_ready_i;
    wire cross_read_id_deassert_i;
    
    assign cross_read_id_valid_i = M_AXI_ARVALID;
    assign cross_read_id_ready_i = S_AXI_ARREADY;
    assign cross_read_id_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_id_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_id_i),
      .C_DATAVALID(cross_read_id_valid_i),
      .C_DATAREADY(cross_read_id_ready_i),
      .C_DATAOUT(S_AXI_ARID),
      .C_DATADEASSERT(cross_read_id_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write LEN)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_len
    wire [7 : 0] cross_read_len_i;
    wire cross_read_len_valid_i;
    wire cross_read_len_ready_i;
    wire cross_read_len_deassert_i;
    
    assign cross_read_len_valid_i = M_AXI_ARVALID;
    assign cross_read_len_ready_i = S_AXI_ARREADY;
    assign cross_read_len_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(8),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_len_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_len_i),
      .C_DATAVALID(cross_read_len_valid_i),
      .C_DATAREADY(cross_read_len_ready_i),
      .C_DATAOUT(S_AXI_ARLEN),
      .C_DATADEASSERT(cross_read_len_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write SIZE)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_size
    wire [2 : 0] cross_read_size_i;
    wire cross_read_size_valid_i;
    wire cross_read_size_ready_i;
    wire cross_read_size_deassert_i;
    
    assign cross_read_size_valid_i = M_AXI_ARVALID;
    assign cross_read_size_ready_i = S_AXI_ARREADY;
    assign cross_read_size_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(3),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_size_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_size_i),
      .C_DATAVALID(cross_read_size_valid_i),
      .C_DATAREADY(cross_read_size_ready_i),
      .C_DATAOUT(S_AXI_ARSIZE),
      .C_DATADEASSERT(cross_read_size_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write BURST)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_burst
    wire [1 : 0] cross_read_burst_i;
    wire cross_read_burst_valid_i;
    wire cross_read_burst_ready_i;
    wire cross_read_burst_deassert_i;
    
    assign cross_read_burst_valid_i = M_AXI_ARVALID;
    assign cross_read_burst_ready_i = S_AXI_ARREADY;
    assign cross_read_burst_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(2),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_burst_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_burst_i),
      .C_DATAVALID(cross_read_burst_valid_i),
      .C_DATAREADY(cross_read_burst_ready_i),
      .C_DATAOUT(S_AXI_ARBURST),
      .C_DATADEASSERT(cross_read_burst_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write LOCK)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_lock
    wire cross_read_lock_i;
    wire cross_read_lock_valid_i;
    wire cross_read_lock_ready_i;
    wire cross_read_lock_deassert_i;
    
    assign cross_read_lock_valid_i = M_AXI_ARVALID;
    assign cross_read_lock_ready_i = S_AXI_ARREADY;
    assign cross_read_lock_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(1),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_lock_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_lock_i),
      .C_DATAVALID(cross_read_lock_valid_i),
      .C_DATAREADY(cross_read_lock_ready_i),
      .C_DATAOUT(S_AXI_ARLOCK),
      .C_DATADEASSERT(cross_read_lock_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write CACHE)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_cache
    wire [3 : 0] cross_read_cache_i;
    wire cross_read_cache_valid_i;
    wire cross_read_cache_ready_i;
    wire cross_read_cache_deassert_i;
    
    assign cross_read_cache_valid_i = M_AXI_ARVALID;
    assign cross_read_cache_ready_i = S_AXI_ARREADY;
    assign cross_read_cache_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(4),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_cache_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_cache_i),
      .C_DATAVALID(cross_read_cache_valid_i),
      .C_DATAREADY(cross_read_cache_ready_i),
      .C_DATAOUT(S_AXI_ARCACHE),
      .C_DATADEASSERT(cross_read_cache_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write PROT)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_prot
    wire [2 : 0] cross_read_prot_i;
    wire cross_read_prot_valid_i;
    wire cross_read_prot_ready_i;
    wire cross_read_prot_deassert_i;
    
    assign cross_read_prot_valid_i = M_AXI_ARVALID;
    assign cross_read_prot_ready_i = S_AXI_ARREADY;
    assign cross_read_prot_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(3),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_prot_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_prot_i),
      .C_DATAVALID(cross_read_prot_valid_i),
      .C_DATAREADY(cross_read_prot_ready_i),
      .C_DATAOUT(S_AXI_ARPROT),
      .C_DATADEASSERT(cross_read_prot_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write QOS)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_qos
    wire [3 : 0] cross_read_qos_i;
    wire cross_read_qos_valid_i;
    wire cross_read_qos_ready_i;
    wire cross_read_qos_deassert_i;
    
    assign cross_read_qos_valid_i = M_AXI_ARVALID;
    assign cross_read_qos_ready_i = S_AXI_ARREADY;
    assign cross_read_qos_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(4),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_qos_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_qos_i),
      .C_DATAVALID(cross_read_qos_valid_i),
      .C_DATAREADY(cross_read_qos_ready_i),
      .C_DATAOUT(S_AXI_ARQOS),
      .C_DATADEASSERT(cross_read_qos_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write VALID)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_valid
    wire cross_read_valid_i;
    wire cross_read_valid_out_i;
    wire cross_read_valid_ready_i;
    wire cross_read_valid_deassert_i;
    
    assign cross_read_valid_i = M_AXI_ARVALID;
    assign cross_read_valid_ready_i = S_AXI_ARREADY;
    assign cross_read_valid_deassert_i = M_AXI_ARVALID & S_AXI_ARREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(1),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_valid_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_valid_i),
      .C_DATAVALID(cross_read_valid_out_i),
      .C_DATAREADY(cross_read_valid_ready_i),
      .C_DATAOUT(S_AXI_ARVALID),
      .C_DATADEASSERT(cross_read_valid_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Write READY)
assign S_AXI_ARREADY = M_AXI_ARREADY;

// M_AXI -> S_AXI (Read Address)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_addr_r
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] cross_read_addr_r_i;
    wire cross_read_addr_r_valid_i;
    wire cross_read_addr_r_ready_i;
    wire cross_read_addr_r_deassert_i;
    
    assign cross_read_addr_r_valid_i = M_AXI_AWVALID;
    assign cross_read_addr_r_ready_i = S_AXI_AWREADY;
    assign cross_read_addr_r_deassert_i = M_AXI_AWVALID & S_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(C_S_AXI_ADDR_WIDTH),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_addr_r_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_addr_r_i),
      .C_DATAVALID(cross_read_addr_r_valid_i),
      .C_DATAREADY(cross_read_addr_r_ready_i),
      .C_DATAOUT(S_AXI_AWADDR),
      .C_DATADEASSERT(cross_read_addr_r_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Read ID)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_id_r
    wire [C_S_AXI_ID_WIDTH-1 : 0] cross_read_id_r_i;
    wire cross_read_id_r_valid_i;
    wire cross_read_id_r_ready_i;
    wire cross_read_id_r_deassert_i;
    
    assign cross_read_id_r_valid_i = M_AXI_AWVALID;
    assign cross_read_id_r_ready_i = S_AXI_AWREADY;
    assign cross_read_id_r_deassert_i = M_AXI_AWVALID & S_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_id_r_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_id_r_i),
      .C_DATAVALID(cross_read_id_r_valid_i),
      .C_DATAREADY(cross_read_id_r_ready_i),
      .C_DATAOUT(S_AXI_AWID),
      .C_DATADEASSERT(cross_read_id_r_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Read LEN)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_len_r
    wire [7 : 0] cross_read_len_r_i;
    wire cross_read_len_r_valid_i;
    wire cross_read_len_r_ready_i;
    wire cross_read_len_r_deassert_i;
    
    assign cross_read_len_r_valid_i = M_AXI_AWVALID;
    assign cross_read_len_r_ready_i = S_AXI_AWREADY;
    assign cross_read_len_r_deassert_i = M_AXI_AWVALID & S_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(8),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_len_r_i (
      .C_CLK(S_AXI_ACLK),
      .C_RSTN(S_AXI_ARESETN),
      .C_DATAIN(cross_read_len_r_i),
      .C_DATAVALID(cross_read_len_r_valid_i),
      .C_DATAREADY(cross_read_len_r_ready_i),
      .C_DATAOUT(S_AXI_AWLEN),
      .C_DATADEASSERT(cross_read_len_r_deassert_i)
    );
  end
endgenerate

// M_AXI -> S_AXI (Read SIZE)
generate
  for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_cross_read_size_r
    wire [2 : 0] cross_read_size_r_i;
    wire cross_read_size_r_valid_i;
    wire cross_read_size_r_ready_i;
    wire cross_read_size_r_deassert_i;
    
    assign cross_read_size_r_valid_i = M_AXI_AWVALID;
    assign cross_read_size_r_ready_i = S_AXI_AWREADY;
    assign cross_read_size_r_deassert_i = M_AXI_AWVALID & S_AXI_AWREADY;
    
    cross_fifoclk #(
      .C_DATA_WIDTH(3),
      .C_DEPTH(2**LGFIFO)
    ) u_cross_read_size_r_i (
      .C