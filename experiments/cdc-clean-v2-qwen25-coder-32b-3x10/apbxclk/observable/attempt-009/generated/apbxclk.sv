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

	// Synchronizers for crossing from S_APB_PCLK to M_APB_PCLK
	reg [AW-1:0]	sync_S_APB_PADDR;
	reg			sync_S_APB_PWRITE;
	reg [DW-1:0]	sync_S_APB_PWDATA;
	reg [DW/8-1:0]	sync_S_APB_PWSTRB;
	reg [2:0]		sync_S_APB_PPROT;
	reg			sync_S_APB_PSEL;
	reg			sync_S_APB_PENABLE;

	// Synchronizers for crossing from M_APB_PCLK to S_APB_PCLK
	reg [DW-1:0]	sync_M_APB_PRDATA;
	reg			sync_M_APB_PSLVERR;

	// Control signals
	reg			req_valid;
	reg			resp_valid;

	// Synchronizer for S_APB_PSEL and S_APB_PENABLE
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			sync_S_APB_PSEL <= 1'b0;
			sync_S_APB_PENABLE <= 1'b0;
		end else begin
			sync_S_APB_PSEL <= S_APB_PSEL;
			sync_S_APB_PENABLE <= S_APB_PENABLE;
		end
	end

	// Synchronizer for S_APB_PADDR, S_APB_PWRITE, S_APB_PWDATA, S_APB_PWSTRB, S_APB_PPROT
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			sync_S_APB_PADDR <= {AW{1'b0}};
			sync_S_APB_PWRITE <= 1'b0;
			sync_S_APB_PWDATA <= {DW{1'b0}};
			sync_S_APB_PWSTRB <= {DW/8{1'b0}};
			sync_S_APB_PPROT <= 3'b000;
		end else begin
			sync_S_APB_PADDR <= S_APB_PADDR;
			sync_S_APB_PWRITE <= S_APB_PWRITE;
			sync_S_APB_PWDATA <= S_APB_PWDATA;
			sync_S_APB_PWSTRB <= S_APB_PWSTRB;
			sync_S_APB_PPROT <= S_APB_PPROT;
		end
	end

	// Synchronizer for M_APB_PRDATA and M_APB_PSLVERR
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			sync_M_APB_PRDATA <= {DW{1'b0}};
			sync_M_APB_PSLVERR <= 1'b0;
		end else begin
			sync_M_APB_PRDATA <= M_APB_PRDATA;
			sync_M_APB_PSLVERR <= M_APB_PSLVERR;
		end
	end

	// Master side control
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			req_valid <= 1'b0;
		end else begin
			M_PRESETn <= 1'b1;
			if (sync_S_APB_PSEL && sync_S_APB_PENABLE && !req_valid) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
				req_valid <= 1'b1;
			end else if (M_APB_PREADY) begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
				req_valid <= 1'b0;
			end
		end
	end

	// Slave side control
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			resp_valid <= 1'b0;
		end else begin
			if (req_valid && M_APB_PREADY) begin
				resp_valid <= 1'b1;
			end
			if (resp_valid && sync_S_APB_PENABLE) begin
				S_APB_PREADY <= 1'b1;
				resp_valid <= 1'b0;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// Assignments
	assign M_APB_PADDR = sync_S_APB_PADDR;
	assign M_APB_PWRITE = sync_S_APB_PWRITE;
	assign M_APB_PWDATA = sync_S_APB_PWDATA;
	assign M_APB_PWSTRB = sync_S_APB_PWSTRB;
	assign M_APB_PPROT = sync_S_APB_PPROT;

	assign S_APB_PRDATA = sync_M_APB_PRDATA;
	assign S_APB_PSLVERR = sync_M_APB_PSLVERR;

endmodule
