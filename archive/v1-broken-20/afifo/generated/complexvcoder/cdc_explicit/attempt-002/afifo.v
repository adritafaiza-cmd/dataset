module afifo #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);

reg [WIDTH-1:0] memory [2**LGFIFO-1:0];
reg [LGFIFO-1:0] write_pointer, read_pointer;
reg [LGFIFO-1:0] write_counter, read_counter;

always @(posedge i_wclk or negedge i_wr_reset_n) begin
	if (!i_wr_reset_n) begin
		write_pointer <= 0;
		write_counter <= 0;
		o_wr_full <= 0;
	end else begin
		if (i_wr && !o_wr_full) begin
			memory[write_pointer] <= i_wr_data;
			write_pointer <= write_pointer + 1;
			write_counter <= write_counter + 1;
			if (write_counter == 2**LGFIFO) begin
				o_wr_full <= 1;
			end
		end
	end
end

always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		read_pointer <= 0;
		read_counter <= 0;
		o_rd_empty <= 1;
		o_rd_data <= 0;
	end else begin
		if (i_rd && !o_rd_empty) begin
			o_rd_data <= memory[read_pointer];
			read_pointer <= read_pointer + 1;
			read_counter <= read_counter + 1;
			if (read_counter == 2**LGFIFO) begin
				o_rd_empty <= 0;
			end
		end
	end
end

assign o_wr_full = (write_counter == 2**LGFIFO);
assign o_rd_empty = (read_counter == 0);

endmodule
