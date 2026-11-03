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

	// Synchronizers for S_APB_PSEL and S_APB_PENABLE
	reg	sync_S_APB_PSEL;
	reg	sync_S_APB_PENABLE;

	// Registered signals for crossing to master clock domain
	reg	[AW-1:0]	master_PADDR;
	reg				master_PWRITE;
	reg	[DW-1:0]	master_PWDATA;
	reg	[DW/8-1:0]	master_PWSTRB;
	reg	[2:0]		master_PPROT;

	// Registered signals for crossing to slave clock domain
	reg	[DW-1:0]	slave_PRDATA;
	reg				slave_PSLVERR;

	// Flags to track transaction states
	reg				transaction_started;
	reg				transaction_completed;

	// Synchronizers for S_APB_PSEL and S_APB_PENABLE
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			sync_S_APB_PSEL <= 1'b0;
			sync_S_APB_PENABLE <= 1'b0;
		end else begin
			sync_S_APB_PSEL <= S_APB_PSEL;
			sync_S_APB_PENABLE <= S_APB_PENABLE;
		end
	end

	// Master clock domain logic
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			transaction_started <= 1'b0;
			transaction_completed <= 1'b0;
		end else begin
			M_PRESETn <= 1'b1;

			if (!transaction_started && sync_S_APB_PSEL && sync_S_APB_PENABLE) begin
				// Capture the request fields
				master_PADDR <= S_APB_PADDR;
				master_PWRITE <= S_APB_PWRITE;
				master_PWDATA <= S_APB_PWDATA;
				master_PWSTRB <= S_APB_PWSTRB;
				master_PPROT <= S_APB_PPROT;
				transaction_started <= 1'b1;
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
			end else if (M_APB_PREADY) begin
				// Transaction completed
				transaction_completed <= 1'b1;
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
			end
		end
	end

	// Slave clock domain logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			slave_PRDATA <= {DW{1'b0}};
			slave_PSLVERR <= 1'b0;
		end else begin
			if (transaction_completed) begin
				// Capture the response fields
				slave_PRDATA <= M_APB_PRDATA;
				slave_PSLVERR <= M_APB_PSLVERR;
				transaction_completed <= 1'b0;
				S_APB_PREADY <= 1'b1;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// Assign outputs
	assign S_APB_PRDATA = slave_PRDATA;
	assign S_APB_PSLVERR = slave_PSLVERR;

	assign M_APB_PADDR = master_PADDR;
	assign M_APB_PWRITE = master_PWRITE;
	assign M_APB_PWDATA = master_PWDATA;
	assign M_APB_PWSTRB = master_PWSTRB;
	assign M_APB_PPROT = master_PPROT;

endmodule
