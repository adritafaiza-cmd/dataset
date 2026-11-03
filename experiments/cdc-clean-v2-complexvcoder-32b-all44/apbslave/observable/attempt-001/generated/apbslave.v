module apbslave #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH,
		localparam	APBLSB = $clog2(C_APB_DATA_WIDTH)-3
	) (
		input	wire			PCLK, PRESETn,
		input	wire			PSEL,
		input	wire			PENABLE,
		output	reg			PREADY,
		input	wire	[AW-1:0]	PADDR,
		input	wire			PWRITE,
		input	wire	[DW-1:0]	PWDATA,
		input	wire	[DW/8-1:0]	PWSTRB,
		input	wire	[2:0]		PPROT,
		output	reg	[DW-1:0]	PRDATA,
		output	wire			PSLVERR
	);

	// Internal signals
	reg	[AW-1:0]	reg_addr;
	reg			reg_write;
	reg	[DW-1:0]	reg_wdata;
	reg	[DW/8-1:0]	reg_wstrb;
	reg	[DW-1:0]	reg_rdata;
	reg			reg_slverr;
	reg	[1:0]		state;
	reg	[1:0]		next_state;

	// Define states
	localparam	IDLE = 2'b00;
	localparam	SETUP = 2'b01;
	localparam	ACCESS = 2'b10;

	// State machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
		end else begin
			state <= next_state;
		end
	end

	// Next state logic
	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (PSEL && !PENABLE) begin
					next_state = SETUP;
				end
			end
			SETUP: begin
				if (PSEL && PENABLE) begin
					next_state = ACCESS;
				end
			end
			ACCESS: begin
				next_state = IDLE;
			end
		endcase
	end

	// Capture signals in SETUP state
	always @(posedge PCLK) begin
		if (state == SETUP) begin
			reg_addr <= PADDR;
			reg_write <= PWRITE;
			reg_wdata <= PWDATA;
			reg_wstrb <= PWSTRB;
		end
	end

	// Register file
	reg [DW-1:0] register_file [0:(1<<AW)-1];

	// Read/Write operations in ACCESS state
	always @(posedge PCLK) begin
		if (state == ACCESS) begin
			if (reg_write) begin
				for (integer i = 0; i < DW/8; i = i + 1) begin
					if (reg_wstrb[i]) begin
						register_file[reg_addr][8*i +: 8] <= reg_wdata[8*i +: 8];
					end
				end
			end else begin
				reg_rdata <= register_file[reg_addr];
			end
		end
	end

	// Output data and signals
	always @(*) begin
		PRDATA = (state == ACCESS && !reg_write) ? reg_rdata : {DW{1'b0}};
		PREADY = (state == ACCESS);
		PSLVERR = (PPROT != 3'b000);
	end

endmodule
