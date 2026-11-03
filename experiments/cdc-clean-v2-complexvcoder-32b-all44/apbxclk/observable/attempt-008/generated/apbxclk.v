module apbxclk #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		parameter [0:0]	OPT_REGISTERED = 1'b0,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH
	) (
		input	wire			S_APB_PCLK, S_PRESETn,
		input	wire			S_APB_PSEL,
		input	wire			S_APB_PENABLE,
		output	reg			S_APB_PREADY,
		input	wire	[AW-1:0]	S_APB_PADDR,
		input	wire			S_APB_PWRITE,
		input	wire	[DW-1:0]	S_APB_PWDATA,
		input	wire	[DW/8-1:0]	S_APB_PWSTRB,
		input	wire	[2:0]		S_APB_PPROT,
		output	wire	[DW-1:0]	S_APB_PRDATA,
		output	wire			S_APB_PSLVERR,
		input	wire			M_APB_PCLK,
		output	reg			M_PRESETn,
		output	reg			M_APB_PSEL,
		output	reg			M_APB_PENABLE,
		input	wire			M_APB_PREADY,
		output	wire	[AW-1:0]	M_APB_PADDR,
		output	wire			M_APB_PWRITE,
		output	wire	[DW-1:0]	M_APB_PWDATA,
		output	wire	[DW/8-1:0]	M_APB_PWSTRB,
		output	wire	[2:0]		M_APB_PPROT,
		input	wire	[DW-1:0]	M_APB_PRDATA,
		input	wire			M_APB_PSLVERR
	);

	// Internal signals for synchronization
	reg s_apb_pready_sync;
	reg m_apb_pready_sync;

	// Internal signals for request and response handling
	reg req_valid;
	reg [AW-1:0] req_addr;
	reg req_write;
	reg [DW-1:0] req_wdata;
	reg [DW/8-1:0] req_wstrb;
	reg [2:0] req_prot;

	reg resp_valid;
	reg [DW-1:0] resp_rdata;
	reg resp_slverr;

	// Synchronizer for S_PRESETn to M_APB_PCLK domain
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			M_PRESETn <= 1'b0;
		else
			M_PRESETn <= 1'b1;
	end

	// Synchronizer for M_APB_PREADY to S_APB_PCLK domain
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			s_apb_pready_sync <= 1'b0;
		else
			s_apb_pready_sync <= M_APB_PREADY;
	end

	// Capture request from S_APB to M_APB domain
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			req_valid <= 1'b0;
		end else if (!req_valid && S_APB_PSEL && S_APB_PENABLE && !s_apb_pready_sync) begin
			req_valid <= 1'b1;
			req_addr <= S_APB_PADDR;
			req_write <= S_APB_PWRITE;
			req_wdata <= S_APB_PWDATA;
			req_wstrb <= S_APB_PWSTRB;
			req_prot <= S_APB_PPROT;
		end else if (M_APB_PREADY) begin
			req_valid <= 1'b0;
		end
	end

	// Drive M_APB signals
	assign M_APB_PSEL = req_valid;
	assign M_APB_PENABLE = req_valid;
	assign M_APB_PADDR = req_addr;
	assign M_APB_PWRITE = req_write;
	assign M_APB_PWDATA = req_wdata;
	assign M_APB_PWSTRB = req_wstrb;
	assign M_APB_PPROT = req_prot;

	// Synchronizer for M_APB_PRDATA, M_APB_PSLVERR to S_APB_PCLK domain
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			resp_valid <= 1'b0;
			resp_rdata <= 32'b0;
			resp_slverr <= 1'b0;
		end else if (M_APB_PREADY) begin
			resp_valid <= 1'b1;
			resp_rdata <= M_APB_PRDATA;
			resp_slverr <= M_APB_PSLVERR;
		end else if (S_APB_PREADY) begin
			resp_valid <= 1'b0;
		end
	end

	// Drive S_APB signals
	assign S_APB_PREADY = !req_valid || s_apb_pready_sync;
	assign S_APB_PRDATA = resp_rdata;
	assign S_APB_PSLVERR = resp_slverr;

endmodule
