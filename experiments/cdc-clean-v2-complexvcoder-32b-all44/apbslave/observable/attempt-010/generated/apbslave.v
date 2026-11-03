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
	reg	[AW-1:0]	addr_latched;
	reg	[DW-1:0]	data_latched;
	reg	[DW/8-1:0]	strobe_latched;
	reg			write_latched;
	reg			read_latched;
	reg			write_enable;
	reg			read_enable;
	reg	[1:0]		state;
	reg	[1:0]		next_state;
	reg	[DW-1:0]	data_out;
	reg	[DW-1:0]	memory [0:(1<<AW)-1]; // Memory array

	// State definitions
	localparam IDLE = 2'b00;
	localparam SETUP = 2'b01;
	localparam ACCESS = 2'b10;

	// State machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
		end else begin
			state <= next_state;
		end
	end

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

	// Latching signals
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			addr_latched <= 0;
			data_latched <= 0;
			strobe_latched <= 0;
			write_latched <= 0;
			read_latched <= 0;
		end else if (state == SETUP) begin
			addr_latched <= PADDR;
			data_latched <= PWDATA;
			strobe_latched <= PWSTRB;
			write_latched <= PWRITE;
			read_latched <= !PWRITE;
		end
	end

	// Write enable and read enable
	always @(*) begin
		write_enable = (state == ACCESS) && write_latched;
		read_enable = (state == ACCESS) && read_latched;
	end

	// Memory operations
	always @(posedge PCLK) begin
		if (write_enable) begin
			for (integer i = 0; i < DW/8; i = i + 1) begin
				if (strobe_latched[i]) begin
					memory[addr_latched][i*8 +: 8] <= data_latched[i*8 +: 8];
				end
			end
		end
	end

	// Output data for read operations
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			data_out <= 0;
		end else if (read_enable) begin
			data_out <= memory[addr_latched];
		end
	end

	// Output assignments
	always @(*) begin
		PRDATA = data_out;
		PREADY = (state == ACCESS);
		PSLVERR = 0; // No error indication
	end

endmodule
