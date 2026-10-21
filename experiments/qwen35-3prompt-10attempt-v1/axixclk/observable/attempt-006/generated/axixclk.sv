```verilog
`timescale 1ns/1ps

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

	// Clock and Reset Generation
	wire S_AXI_ACLK_INT = S_AXI_ACLK;
	wire M_AXI_ACLK_INT = M_AXI_ACLK;
	wire S_AXI_ARESETN_INT = S_AXI_ARESETN;
	wire M_AXI_ARESETN_INT = S_AXI_ARESETN;

	// Cross Clock Domain Generators
	// S_AXI to M_AXI Clock Domain Crossing
	wire S_M_AW_VALID;
	wire S_M_AW_READY;
	wire S_M_W_VALID;
	wire S_M_W_READY;
	wire S_M_B_VALID;
	wire S_M_B_READY;
	wire S_M_AR_VALID;
	wire S_M_AR_READY;
	wire S_M_R_VALID;
	wire S_M_R_READY;

	// M_AXI to S_AXI Clock Domain Crossing
	wire M_S_AW_VALID;
	wire M_S_AW_READY;
	wire M_S_W_VALID;
	wire M_S_W_READY;
	wire M_S_B_VALID;
	wire M_S_B_READY;
	wire M_S_AR_VALID;
	wire M_S_AR_READY;
	wire M_S_R_VALID;
	wire M_S_R_READY;

	// Generate Clocks for CDC
	// S_AXI side clocks for M side signals
	wire S_M_ACLK;
	wire S_M_ARESETN;
	// M_AXI side clocks for S side signals
	wire M_S_ACLK;
	wire M_S_ARESETN;

	// Simple CDC Generator for Clocks
	// S_AXI -> M_AXI Clock
	wire [XCLOCK_FFS-1:0] s_m_clk_ff;
	wire s_m_clk;
	genvar i;
	generate
		for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : s_m_clk_ff_gen
			always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
				if (!S_AXI_ARESETN)
					s_m_clk_ff[i] <= 1'b0;
				else
					s_m_clk_ff[i] <= s_m_clk_ff[i-1];
			end
		end
	endgenerate
	assign s_m_clk = s_m_clk_ff[XCLOCK_FFS-1];
	assign S_M_ACLK = s_m_clk;
	assign S_M_ARESETN = S_AXI_ARESETN;

	// M_AXI -> S_AXI Clock
	wire [XCLOCK_FFS-1:0] m_s_clk_ff;
	genvar j;
	generate
		for (j = 0; j < XCLOCK_FFS; j = j + 1) begin : m_s_clk_ff_gen
			always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
				if (!M_AXI_ARESETN)
					m_s_clk_ff[j] <= 1'b0;
				else
					m_s_clk_ff[j] <= m_s_clk_ff[j-1];
			end
		end
	endgenerate
	assign m_s_clk = m_s_clk_ff[XCLOCK_FFS-1];
	assign M_S_ACLK = m_s_clk;
	assign M_S_ARESETN = M_AXI_ARESETN;

	// Write FIFOs (S_AXI -> M_AXI)
	// AW Channel
	wire [C_S_AXI_ID_WIDTH-1:0] s_m_aw_id_in;
	wire [C_S_AXI_ADDR_WIDTH-1:0] s_m_aw_addr_in;
	wire [7:0] s_m_aw_len_in;
	wire [2:0] s_m_aw_size_in;
	wire [1:0] s_m_aw_burst_in;
	wire s_m_aw_lock_in;
	wire [3:0] s_m_aw_cache_in;
	wire [2:0] s_m_aw_prot_in;
	wire [3:0] s_m_aw_qos_in;
	wire s_m_aw_valid_in;
	wire s_m_aw_ready_in;
	wire s_m_aw_valid_out;
	wire s_m_aw_ready_out;
	wire [C_S_AXI_ID_WIDTH-1:0] s_m_aw_id_out;
	wire [C_S_AXI_ADDR_WIDTH-1:0] s_m_aw_addr_out;
	wire [7:0] s_m_aw_len_out;
	wire [2:0] s_m_aw_size_out;
	wire [1:0] s_m_aw_burst_out;
	wire s_m_aw_lock_out;
	wire [3:0] s_m_aw_cache_out;
	wire [2:0] s_m_aw_prot_out;
	wire [3:0] s_m_aw_qos_out;
	wire s_m_aw_valid_out_reg;
	wire s_m_aw_ready_out_reg;

	// W Channel
	wire [C_S_AXI_DATA_WIDTH-1:0] s_m_w_data_in;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_m_w_strb_in;
	wire s_m_w_last_in;
	wire s_m_w_valid_in;
	wire s_m_w_ready_in;
	wire s_m_w_valid_out;
	wire s_m_w_ready_out;
	wire [C_S_AXI_DATA_WIDTH-1:0] s_m_w_data_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_m_w_strb_out;
	wire s_m_w_last_out;
	wire s_m_w_valid_out_reg;
	wire s_m_w_ready_out_reg;

	// B Channel
	wire [C_S_AXI_ID_WIDTH-1:0] s_m_b_id_in;
	wire [1:0] s_m_b_resp_in;
	wire s_m_b_valid_in;
	wire s_m_b_ready_in;
	wire s_m_b_valid_out;
	wire s_m_b_ready_out;
	wire [C_S_AXI_ID_WIDTH-1:0] s_m_b_id_out;
	wire [1:0] s_m_b_resp_out;
	wire s_m_b_valid_out_reg;
	wire s_m_b_ready_out_reg;

	// AR Channel
	wire [C_S_AXI_ID_WIDTH-1:0] s_m_ar_id_in;
	wire [C_S_AXI_ADDR_WIDTH-1:0] s_m_ar_addr_in;
	wire [7:0] s_m_ar_len_in;
	wire [2:0] s_m_ar_size_in;
	wire [1:0] s_m_ar_burst_in;
	wire s_m_ar_lock_in;
	wire [3:0] s_m_ar_cache_in;
	wire [2:0] s_m_ar_prot_in;
	wire [3:0] s_m_ar_qos_in;
	wire s_m_ar_valid_in;
	wire s_m_ar_ready_in;
	wire s_m_ar_valid_out;
	wire s_m_ar_ready_out;
	wire [C_S_AXI_ID_WIDTH-1:0] s_m_ar_id_out;
	wire [C_S_AXI_ADDR_WIDTH-1:0] s_m_ar_addr_out;
	wire [7:0] s_m_ar_len_out;
	wire [2:0] s_m_ar_size_out;
	wire [1:0] s_m_ar_burst_out;
	wire s_m_ar_lock_out;
	wire [3:0] s_m_ar_cache_out;
	wire [2:0] s_m_ar_prot_out;
	wire [3:0] s_m_ar_qos_out;
	wire s_m_ar_valid_out_reg;
	wire s_m_ar_ready_out_reg;

	// R Channel
	wire [C_S_AXI_ID_WIDTH-1:0] s_m_r_id_in;
	wire [C_S_AXI_DATA_WIDTH-1:0] s_m_r_data_in;
	wire [1:0] s_m_r_resp_in;
	wire s_m_r_last_in;
	wire s_m_r_valid_in;
	wire s_m_r_ready_in;
	wire s_m_r_valid_out;
	wire s_m_r_ready_out;
	wire [C_S_AXI_ID_WIDTH-1:0] s_m_r_id_out;
	wire [C_S_AXI_DATA_WIDTH-1:0] s_m_r_data_out;
	wire [1:0] s_m_r_resp_out;
	wire s_m_r_last_out;
	wire s_m_r_valid_out_reg;
	wire s_m_r_ready_out_reg;

	// Generate Write FIFOs (S_AXI -> M_AXI)
	// AW FIFO
	genvar k;
	generate
		for (k = 0; k < LGFIFO; k = k + 1) begin : s_m_aw_fifo_gen
			reg [C_S_AXI_ID_WIDTH-1:0] id_reg;
			reg [C_S_AXI_ADDR_WIDTH-1:0] addr_reg;
			reg [7:0] len_reg;
			reg [2:0] size_reg;
			reg [1:0] burst_reg;
			reg lock_reg;
			reg [3:0] cache_reg;
			reg [2:0] prot_reg;
			reg [3:0] qos_reg;
			reg valid_reg;
			reg ready_reg;

			always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
				if (!S_AXI_ARESETN) begin
					id_reg <= 1'b0;
					addr_reg <= 1'b0;
					len_reg <= 1'b0;
					size_reg <= 1'b0;
					burst_reg <= 1'b0;
					lock_reg <= 1'b0;
					cache_reg <= 1'b0;
					prot_reg <= 1'b0;
					qos_reg <= 1'b0;
					valid_reg <= 1'b0;
					ready_reg <= 1'b0;
				end
				else begin
					id_reg <= id_reg;
					addr_reg <= addr_reg;
					len_reg <= len_reg;
					size_reg <= size_reg;
					burst_reg <= burst_reg;
					lock_reg <= lock_reg;
					cache_reg <= cache_reg;
					prot_reg <= prot_reg;
					qos_reg <= qos_reg;
					valid_reg <= valid_reg;
					ready_reg <= ready_reg;
				end
			end

			assign s_m_aw_id_in = id_reg;
			assign s_m_aw_addr_in = addr_reg;
			assign s_m_aw_len_in = len_reg;
			assign s_m_aw_size_in = size_reg;
			assign s_m_aw_burst_in = burst_reg;
			assign s_m_aw_lock_in = lock_reg;
			assign s_m_aw_cache_in = cache_reg;
			assign s_m_aw_prot_in = prot_reg;
			assign s_m_aw_qos_in = qos_reg;
			assign s_m_aw_valid_in = valid_reg;
			assign s_m_aw_ready_in = ready_reg;
		end
	endgenerate

	// W FIFO
	genvar l;
	generate
		for (l = 0; l < LGFIFO; l = l + 1) begin : s_m_w_fifo_gen
			reg [C_S_AXI_DATA_WIDTH-1:0] data_reg;
			reg [(C_S_AXI_DATA_WIDTH/8)-1:0] strb_reg;
			reg last_reg;
			reg valid_reg;
			reg ready_reg;

			always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
				if (!S_AXI_ARESETN) begin
					data_reg <= 1'b0;
					strb_reg <= 1'b0;
					last_reg <= 1'b0;
					valid_reg <= 1'b0;
					ready_reg <= 1'b0;
				end
				else begin
					data_reg <= data_reg;
					strb_reg <= strb_reg;
					last_reg <= last_reg;
					valid_reg <= valid_reg;
					ready_reg <= ready_reg;
				end
			end

			assign s_m_w_data_in = data_reg;
			assign s_m_w_strb_in = strb_reg;
			assign s_m_w_last_in = last_reg;
			assign s_m_w_valid_in = valid_reg;
			assign s_m_w_ready_in = ready_reg;
		end
	endgenerate

	// B FIFO
	genvar m;
	generate
		for (m = 0; m < LGFIFO; m = m + 1) begin : s_m_b_fifo_gen
			reg [C_S_AXI_ID_WIDTH-1:0] id_reg;
			reg [1:0] resp_reg;
			reg valid_reg;
			reg ready_reg;

			always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
				if (!S_AXI_ARESETN) begin
					id_reg <= 1'b0;
					resp_reg <= 1'b0;
					valid_reg <= 1'b0;
					ready_reg <= 1'b0;
				end
				else begin
					id_reg <= id_reg;
					resp_reg <= resp_reg;
					valid_reg <= valid_reg;
					ready_reg <= ready_reg;
				end
			end

			assign s_m_b_id_in = id_reg;
			assign s_m_b_resp_in = resp_reg;
			assign s_m_b_valid_in = valid_reg;
			assign s_m_b_ready_in = ready_reg;
		end
	endgenerate

	// AR FIFO
	genvar n;
	generate
		for (n = 0; n < LGFIFO; n = n + 1) begin : s_m_ar_fifo_gen
			reg [C_S_AXI_ID_WIDTH-1:0] id_reg;
			reg [C_S_AXI_ADDR_WIDTH-1:0] addr_reg;
			reg [7:0] len_reg;
			reg [2:0] size_reg;
			reg [1:0] burst_reg;
			reg lock_reg;
			reg [3:0] cache_reg;
			reg [2:0] prot_reg;
			reg [3:0] qos_reg;
			reg valid_reg;
			reg ready_reg;

			always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
				if (!S_AXI_ARESETN) begin
					id_reg <= 1'b0;
					addr_reg <= 1'b0;
					len_reg <= 1'b0;
					size_reg <= 1'b0;
					burst_reg <= 1'b0;
					lock_reg <= 1'b0;
					cache_reg <= 1'b0;
					prot_reg <= 1'b0;
					qos_reg <= 1'b0;
					valid_reg <= 1'b0;
					ready_reg <= 1'b0;
				end
				else begin
					id_reg <= id_reg;
					addr_reg <= addr_reg;
					len_reg <= len_reg;
					size_reg <= size_reg;
					burst_reg <= burst_reg;
					lock_reg <= lock_reg;
					cache_reg <= cache_reg;
					prot_reg <= prot_reg;
					qos_reg <= qos_reg;
					valid_reg <= valid_reg;
					ready_reg <= ready_reg;
				end
			end

			assign s_m_ar_id_in = id_reg;
			assign s_m_ar_addr_in = addr_reg;
			assign s_m_ar_len_in = len_reg;
			assign s_m_ar_size_in = size_reg;
			assign s_m_ar_burst_in = burst_reg;
			assign s_m_ar_lock_in = lock_reg;
			assign s_m_ar_cache_in = cache_reg;
			assign s_m_ar_prot_in = prot_reg;
			assign s_m_ar_qos_in = qos_reg;
			assign s_m_ar_valid_in = valid_reg;
			assign s_m_ar_ready_in = ready_reg;
		end
	endgenerate

	// R FIFO
	genvar o;
	generate
		for (o = 0; o < LGFIFO; o = o + 1) begin : s_m_r_fifo_gen
			reg [C_S_AXI_ID_WIDTH-1:0] id_reg;
			reg [C_S_AXI_DATA_WIDTH-1:0] data_reg;
			reg [1:0] resp_reg;
			reg last_reg;
			reg valid_reg;
			reg ready_reg;

			always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
				if (!S_AXI_ARESETN) begin
					id_reg <= 1'b0;
					data_reg <= 1'b0;
					resp_reg <= 1'b0;
					last_reg <= 1'b0;
					valid_reg <= 1'b0;
					ready_reg <= 1'b0;
				end
				else begin
					id_reg <= id_reg;
					data_reg <= data_reg;
					resp_reg <= resp_reg;
					last_reg <= last_reg;
					valid_reg <= valid_reg;
					ready_reg <= ready_reg;
				end
			end

			assign s_m_r_id_in = id_reg;
			assign s_m_r_data_in = data_reg;
			assign s_m_r_resp_in = resp_reg;
			assign s_m_r_last_in = last_reg;
			assign s_m_r_valid_in = valid_reg;
			assign s_m_r_ready_in = ready_reg;
		end
	endgenerate

	// Read FIFOs (M_AXI -> S_AXI)
	// AW Channel
	wire [C_S_AXI_ID_WIDTH-1:0] m_s_aw_id_in;
	wire [C_S_AXI_ADDR_WIDTH-1:0] m_s_aw_addr_in;
	wire [7:0] m_s_aw_len_in;
	wire [2:0] m_s_aw_size_in;
	wire [1:0] m_s_aw_burst_in;
	wire m_s_aw_lock_in;
	wire [3:0] m_s_aw_cache_in;
	wire [2:0] m_s_aw_prot_in;
	wire [3:0] m_s_aw_qos_in;
	wire m_s_aw_valid_in;
	wire m_s_aw_ready_in;
	wire m_s_aw_valid_out;
	wire m_s_aw_ready_out;
	wire [C_S_AXI_ID_WIDTH-1:0] m_s_aw_id_out;
	wire [C_S_AXI_ADDR_WIDTH-1:0] m_s_aw_addr_out;
	wire [7:0] m_s_aw_len_out;
	wire [2:0] m_s_aw_size_out;
	wire [1:0] m_s_aw_burst_out;
	wire m_s_aw_lock_out;
	wire [3:0] m_s_aw_cache_out;
	wire [2:0] m_s_aw_prot_out;
	wire [3:0] m_s_aw_qos_out;
	wire m_s_aw_valid_out_reg;
	wire m_s_aw_ready_out_reg;

	// W Channel
	wire [C_S_AXI_DATA_WIDTH-1:0] m_s_w_data_in;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] m_s_w_strb_in;
	wire m_s_w_last_in;
	wire m_s_w_valid_in;
	wire m_s_w_ready_in;
	wire m_s_w_valid_out;
	wire m_s_w_ready_out;
	wire [C_S_AXI_DATA_WIDTH-1:0] m_s_w_data_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] m_s_w_strb_out;
	wire m_s_w_last_out;
	wire m_s_w_valid_out_reg;
	wire m_s_w_ready_out_reg;

	// B Channel
	wire [C_S_AXI_ID_WIDTH-1:0] m_s_b_id_in;
	wire [1:0] m_s_b_resp_in;
	wire m_s_b_valid_in;
	wire m_s_b_ready_in;
	wire m_s_b_valid_out;
	wire m_s_b_ready_out;
	wire [C_S_AXI_ID_WIDTH-1:0] m_s_b_id_out;
	wire [1:0] m_s_b_resp_out;
	wire m_s_b_valid_out_reg;
	wire m_s_b_ready_out_reg;

	// AR Channel
	wire [C_S_AXI_ID_WIDTH-1:0] m_s_ar_id_in;
	wire [C_S_AXI_ADDR_WIDTH-1:0] m_s_ar_addr_in;
	wire [7:0] m_s_ar_len_in;
	wire [2:0] m_s_ar_size_in;
	wire [1:0] m_s_ar_burst_in;
	wire m_s_ar_lock_in;
	wire [3:0] m_s_ar_cache_in;
	wire [2:0] m_s_ar_prot_in;
	wire [3:0] m_s_ar_qos_in;
	wire m_s_ar_valid_in;
	wire m_s_ar_ready_in;
	wire m_s_ar_valid_out;
	wire m_s_ar_ready_out;
	wire [C_S_AXI_ID_WIDTH-1:0] m_s_ar_id_out;
	wire [C_S_AXI_ADDR_WIDTH-1:0] m_s_ar_addr_out;
	wire [7:0] m_s_ar_len_out;
	wire [2:0] m_s_ar_size_out;
	wire [1:0] m_s_ar_burst_out;
	wire m_s_ar_lock_out;
	wire [3:0] m_s_ar_cache_out;
	wire [2:0] m_s_ar_prot_out;
	wire [3:0] m_s_ar_qos_out;
	wire m_s_ar_valid_out_reg;
	wire m_s_ar_ready_out_reg;

	// R Channel
	wire [C_S_AXI_ID_WIDTH-1:0] m_s_r_id_in;
	wire [C_S_AXI_DATA_WIDTH-1:0] m_s_r_data_in;
	wire [1:0] m_s_r_resp_in;
	wire m_s_r_last_in;
	wire m_s_r_valid_in;
	wire m_s_r_ready_in;
	wire m_s_r_valid_out;
	wire m_s_r_ready_out;
	wire [C_S_AXI_ID_WIDTH-1:0] m_s_r_id_out;
	wire [C_S_AXI_DATA_WIDTH-1:0] m_s_r_data_out;
	wire [1:0] m_s_r_resp_out;
	wire m_s_r_last_out;
	wire m_s_r_valid_out_reg;
	wire m_s_r_ready_out_reg;

	// Generate Read FIFOs (M_AXI -> S_AXI)
	// AW FIFO
	genvar p;
	generate
		for (p = 0; p < LGFIFO; p = p + 1) begin : m_s_aw_fifo_gen
			reg [C_S_AXI_ID_WIDTH-1:0] id_reg;
			reg [C_S_AXI_ADDR_WIDTH-1:0] addr_reg;
			reg [7:0] len_reg;
			reg [2:0] size_reg;
			reg [1:0] burst_reg;
			reg lock_reg;
			reg [3:0] cache_reg;
			reg [2:0] prot_reg;
			reg [3:0] qos_reg;
			reg valid_reg;
			reg ready_reg;

			always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
				if (!M_AXI_ARESETN) begin
					id_reg <= 1'b0;
					addr_reg <= 1'b0;
					len_reg <= 1'b0;
					size_reg <= 1'b0;
					burst_reg <= 1'b0;
					lock_reg <= 1'b0;
					cache_reg <= 1'b0;
					prot_reg <= 1'b0;
					qos_reg <= 1'b0;
					valid_reg <= 1'b0;
					ready_reg <= 1'b0;
				end
				else begin
					id_reg <= id_reg;
					addr_reg <= addr_reg;
					len_reg <= len_reg;
					size_reg <= size_reg;
					burst_reg <= burst_reg;
					lock_reg <= lock_reg;
					cache_reg <= cache_reg;
					prot_reg <= prot_reg;
					qos_reg <= qos_reg;
					valid_reg <= valid_reg;
					ready_reg <= ready_reg;
				end
			end

			assign m_s_aw_id_in = id_reg;
			assign m_s_aw_addr_in = addr_reg;
			assign m_s_aw_len_in = len_reg;
			assign m_s_aw_size_in = size_reg;
			assign m_s_aw_burst_in = burst_reg;
			assign m_s_aw_lock_in = lock_reg;
			assign m_s_aw_cache_in = cache_reg;
			assign m_s_aw_prot_in = prot_reg;
			assign m_s_aw_qos_in = qos_reg;
			assign m_s_aw_valid_in = valid_reg;
			assign m_s_aw_ready_in = ready_reg;
		end
	endgenerate

	// W FIFO
	genvar q;
	generate
		for (q = 0; q < LGFIFO; q = q + 1) begin : m_s_w_fifo_gen
			reg [C_S_AXI_DATA_WIDTH-1:0] data_reg;
			reg [(C_S_AXI_DATA_WIDTH/8)-1:0] strb_reg;
			reg last_reg;
			reg valid_reg;
			reg ready_reg;

			always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
				if (!M_AXI_ARESETN) begin
					data_reg <= 1'b0;
					strb_reg <= 1'b0;
					last_reg <= 1'b0;
					valid_reg <= 1'b0;
					ready_reg <= 1'b0;
				end
				else begin
					data_reg <= data_reg;
					strb_reg <= strb_reg;
					last_reg <= last_reg;
					valid_reg <= valid_reg;
					ready_reg <= ready_reg;
				end
			end

			assign m_s_w_data_in = data_reg;
			assign m_s_w_strb_in = strb_reg;
			assign m_s_w_last_in = last_reg;
			assign m_s_w_valid_in = valid_reg;
			assign m_s_w_ready_in = ready_reg;
		end
	endgenerate

	// B FIFO
	genvar r;
	generate
		for (r = 0; r < LGFIFO; r = r + 1) begin : m_s_b_fifo_gen
			reg [C_S_AXI_ID_WIDTH-1:0] id_reg;
			reg [1:0] resp_reg;
			reg valid_reg;
			reg ready_reg;

			always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
				if (!M_AXI_ARESETN) begin
					id_reg <= 1'b0;
					resp_reg <= 1'b0;
					valid_reg <= 1'b0;
					ready_reg <= 1'b0;
				end
				else begin
					id_reg <= id_reg;
					resp_reg <= resp_reg;
					valid_reg <= valid_reg;
					ready_reg <= ready_reg;
				end
			end

			assign m_s_b_id_in = id_reg;
			assign m_s_b_resp_in = resp_reg;
			assign m_s_b_valid_in = valid_reg;
			assign m_s_b_ready_in = ready_reg;
		end
	endgenerate

	// AR FIFO
	genvar s;
	generate
		for (s = 0; s < LGFIFO; s = s + 1) begin : m_s_ar_fifo_gen
			reg [C_S_AXI_ID_WIDTH-1:0] id_reg;
			reg [C_S_AXI_ADDR_WIDTH-1:0] addr_reg;
			reg [7:0] len_reg;
			reg [2:0] size_reg;
			reg [1:0] burst_reg;
			reg lock_reg;
			reg [3:0] cache_reg;
			reg [2:0] prot_reg;
			reg [3:0] qos_reg;
			reg valid_reg;
			reg ready_reg;

			always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
				if (!M_AXI_ARESETN) begin
					id_reg <= 1'b0;
					addr_reg <= 1'b0;
					len_reg <= 1'b0;
					size_reg <= 1'b0;
					burst_reg <= 1'b0;
					lock_reg <= 1'b0;
					cache_reg <= 1'b0;
					prot_reg <= 1'b0;
					qos_reg <= 1'b0;
					valid_reg <= 1'b0;
					ready_reg <= 1'b0;
				end
				else begin
					id_reg <= id_reg;
					addr_reg <= addr_reg;
					len_reg <= len_reg;
					size_reg <= size_reg;
					burst_reg <= burst_reg;
					lock_reg <= lock_reg;
					cache_reg <= cache_reg;
					prot_reg <= prot_reg;
					qos_reg <= qos_reg;
					valid_reg <= valid_reg;
					ready_reg <= ready_reg;
				end
			end

			assign m_s_ar_id_in = id_reg;
			assign m_s_ar_addr_in = addr_reg;
			assign m_s_ar_len_in = len_reg;
			assign m_s_ar_size_in =