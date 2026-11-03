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
	reg [DW-1:0]	data_in;
	reg [DW-1:0]	data_out;
	reg [DW/8-1:0]	write_strobe;
	reg		read_enable;
	reg		write_enable;
	reg [1:0]	access_state;
	reg [1:0]	access_state_next;
	reg		slverr;

	// Register file declaration
	reg [DW-1:0] register_file [0:(1<<AW)-1];

	// State encoding
	localparam IDLE = 2'b00;
	localparam SETUP = 2'b01;
	localparam ACCESS = 2'b10;

	// Next state logic
	always @(*) begin
		access_state_next = access_state;
		case (access_state)
			IDLE: begin
				if (PSEL && !PENABLE)
					access_state_next = SETUP;
			end
			SETUP: begin
				access_state_next = ACCESS;
			end
			ACCESS: begin
				if (!PENABLE)
					access_state_next = IDLE;
			end
			default: begin
				access_state_next = IDLE;
			end
		endcase
	end

	// State register
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			access_state <= IDLE;
		end else begin
			access_state <= access_state_next;
		end
	end

	// Capture address and data during setup phase
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			address <= 0;
			data_in <= 0;
			read_enable <= 0;
			write_enable <= 0;
			slverr <= 0;
		end else if (access_state == SETUP) begin
			address <= PADDR;
			data_in <= PWDATA;
			read_enable <= !PWRITE;
			write_enable <= PWRITE;
			slverr <= 0; // Placeholder for error condition, add logic if needed
		end
	end

	// Perform read/write operations during access phase
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 0;
			PRDATA <= 0;
			PSLVERR <= 0;
		end else if (access_state == ACCESS) begin
			PREADY <= 1;
			if (read_enable) begin
				PRDATA <= register_file[address];
				PSLVERR <= 0; // Placeholder for error condition, add logic if needed
			end else if (write_enable) begin
				// Byte-strobed write
				for (integer i = 0; i < DW/8; i = i + 1) begin
					if (write_strobe[i]) begin
						register_file[address][i*8 +: 8] <= data_in[i*8 +: 8];
					end
				end
				PSLVERR <= 0; // Placeholder for error condition, add logic if needed
			end
		end else begin
			PREADY <= 0;
		end
	end

endmodule
