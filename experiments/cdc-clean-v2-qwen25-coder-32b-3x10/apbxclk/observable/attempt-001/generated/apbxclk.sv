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

	// Synchronizers for signals crossing from S_APB to M_APB
	reg [AW-1:0]	sync_S_APB_PADDR;
	reg			sync_S_APB_PWRITE;
	reg [DW-1:0]	sync_S_APB_PWDATA;
	reg [DW/8-1:0]	sync_S_APB_PWSTRB;
	reg [2:0]		sync_S_APB_PPROT;
	reg			sync_S_APB_PSEL;
	reg			sync_S_APB_PENABLE;

	// Synchronizers for signals crossing from M_APB to S_APB
	reg [DW-1:0]	sync_M_APB_PRDATA;
	reg			sync_M_APB_PSLVERR;

	// Control signals
	reg			req_valid;
	reg			resp_valid;

	// Synchronizer for request valid signal
	reg [1:0]	req_valid_sync;

	// Synchronizer for response valid signal
	reg [1:0]	resp_valid_sync;

	// Synchronizer for reset signal
	reg [1:0]	sync_S_PRESETn;

	// Synchronizer for reset signal
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			sync_S_PRESETn <= 2'b00;
		end else begin
			sync_S_PRESETn <= {sync_S_PRESETn[0], S_PRESETn};
		end
	end

	assign M_PRESETn = sync_S_PRESETn[1];

	// Synchronizers for request signals
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_S_APB_PADDR <= {AW{1'b0}};
			sync_S_APB_PWRITE <= 1'b0;
			sync_S_APB_PWDATA <= {DW{1'b0}};
			sync_S_APB_PWSTRB <= {DW/8{1'b0}};
			sync_S_APB_PPROT <= 3'b000;
			sync_S_APB_PSEL <= 1'b0;
			sync_S_APB_PENABLE <= 1'b0;
		end else begin
			sync_S_APB_PADDR <= S_APB_PADDR;
			sync_S_APB_PWRITE <= S_APB_PWRITE;
			sync_S_APB_PWDATA <= S_APB_PWDATA;
			sync_S_APB_PWSTRB <= S_APB_PWSTRB;
			sync_S_APB_PPROT <= S_APB_PPROT;
			sync_S_APB_PSEL <= S_APB_PSEL;
			sync_S_APB_PENABLE <= S_APB_PENABLE;
		end
	end

	// Synchronizers for response signals
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			sync_M_APB_PRDATA <= {DW{1'b0}};
			sync_M_APB_PSLVERR <= 1'b0;
		end else begin
			sync_M_APB_PRDATA <= M_APB_PRDATA;
			sync_M_APB_PSLVERR <= M_APB_PSLVERR;
		end
	end

	// Request valid synchronizer
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			req_valid_sync <= 2'b00;
		end else begin
			req_valid_sync <= {req_valid_sync[0], (sync_S_APB_PSEL && sync_S_APB_PENABLE)};
		end
	end

	assign req_valid = req_valid_sync[1];

	// Response valid synchronizer
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			resp_valid_sync <= 2'b00;
		end else begin
			resp_valid_sync <= {resp_valid_sync[0], M_APB_PREADY};
		end
	end

	assign resp_valid = resp_valid_sync[1];

	// Master side signals
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
		end else begin
			if (req_valid && !M_APB_PSEL) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
				M_APB_PADDR <= sync_S_APB_PADDR;
				M_APB_PWRITE <= sync_S_APB_PWRITE;
				M_APB_PWDATA <= sync_S_APB_PWDATA;
				M_APB_PWSTRB <= sync_S_APB_PWSTRB;
				M_APB_PPROT <= sync_S_APB_PPROT;
			end else if (M_APB_PREADY) begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
			end
		end
	end

	// Slave side signals
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			S_APB_PRDATA <= {DW{1'b0}};
			S_APB_PSLVERR <= 1'b0;
		end else begin
			if (req_valid && !M_APB_PSEL) begin
				S_APB_PREADY <= 1'b0;
			end else if (resp_valid) begin
				S_APB_PREADY <= 1'b1;
				S_APB_PRDATA <= sync_M_APB_PRDATA;
				S_APB_PSLVERR <= sync_M_APB_PSLVERR;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

endmodule
