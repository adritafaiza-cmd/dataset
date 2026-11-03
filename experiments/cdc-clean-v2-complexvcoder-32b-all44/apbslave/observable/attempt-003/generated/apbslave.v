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
	reg [AW-1:0]	address;
	reg [DW/8-1:0]	write_strobe;
	reg [DW-1:0]	data_in;
	reg [DW-1:0]	data_out;
	reg [DW-1:0]	read_data;
	reg [DW-1:0]	write_data;
	reg [1:0]	state;
	reg [1:0]	next_state;
	reg		read_valid;
	reg		write_valid;

	// State definitions
	localparam	IDLE = 2'b00;
	localparam	ACCESS = 2'b01;

	// State machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
			PREADY <= 1'b0;
		end else begin
			state <= next_state;
			if (next_state == IDLE)
				PREADY <= 1'b0;
			else if (next_state == ACCESS)
				PREADY <= 1'b1;
		end
	end

	// Next state logic
	always @(*) begin
		case (state)
			IDLE: begin
				if (PSEL && PENABLE)
					next_state = ACCESS;
				else
					next_state = IDLE;
			end
			ACCESS: begin
				next_state = IDLE;
			end
			default: begin
				next_state = IDLE;
			end
		endcase
	end

	// Read/Write logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			data_out <= 32'b0;
			read_valid <= 1'b0;
			write_valid <= 1'b0;
		end else begin
			if (state == ACCESS) begin
				if (PWRITE) begin
					write_valid <= 1'b1;
					write_strobe <= PWSTRB;
					data_in <= PWDATA;
				end else begin
					read_valid <= 1'b1;
					read_data <= data_out;
				end
			end else begin
				read_valid <= 1'b0;
				write_valid <= 1'b0;
			end
		end
	end

	// Byte-strobed write operation
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn)
			data_out <= 32'b0;
		else if (write_valid) begin
			for (integer i = 0; i < DW/8; i = i + 1) begin
				if (write_strobe[i])
					data_out[i*8 +: 8] <= data_in[i*8 +: 8];
			end
		end
	end

	// Read data output
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn)
			PRDATA <= 32'b0;
		else if (read_valid)
			PRDATA <= read_data;
	end

	// Error signal (always low)
	assign PSLVERR = 1'b0;

endmodule
